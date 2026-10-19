import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/cart_item_model.dart';
import 'package:ngekas/models/stock_movement_model.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/services/auth_service.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/services/stock_movement_service.dart';

// ─── TransactionService ─────────────────────────────────────────────────────
//
// CRUD transaksi barang di DatabaseService.transactions (in-memory), sekaligus
// menjaga stok barang tetap sinkron:
// - Penjualan mengurangi stok, Pembelian Stok menambah stok.
// - Ubah transaksi = batalkan efek lama lalu terapkan efek baru.
// - Hapus transaksi = batalkan efeknya.
// Semua perubahan stok divalidasi dulu (tidak boleh minus) sebelum diterapkan,
// jadi kalau gagal tidak ada data yang setengah berubah.

class TransactionService {
  TransactionService._();

  static const tag = 'TransactionService';

  static DatabaseService get _db => DatabaseService.instance;

  static Stream<List<TransactionModel>> watch() {
    return _db.transactions.watch().map((rows) => [...rows]..sort((a, b) => b.date.compareTo(a.date)));
  }

  static Future<TransactionModel> add({
    required TransactionType type,
    required String productId,
    required int quantity,
    required int unitPrice,
    required DateTime date,
    required String note,
  }) async {
    await _db.simulateLatency();
    final product = _db.products.find(productId);
    if (product == null) throw DataException('Barang tidak ditemukan, mungkin sudah dihapus');

    _applyStockChanges({productId: _stockEffect(type, quantity)}, type: _movementType(type), note: note);

    final transaction = TransactionModel(
      id: _db.newId('t'),
      type: type,
      productId: product.id,
      itemName: product.name,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      quantity: quantity,
      unitPrice: unitPrice,
      date: date,
      note: note,
      actorName: AuthService.currentUser?.name ?? '-',
    );
    _db.transactions.insert(transaction);
    AppLog.i(tag, 'add: ${type.name} ${product.name} x$quantity');
    return transaction;
  }

  static Future<TransactionModel> update({
    required String id,
    required String productId,
    required int quantity,
    required int unitPrice,
    required DateTime date,
    required String note,
  }) async {
    await _db.simulateLatency();
    final old = _db.transactions.find(id);
    if (old == null) throw DataException('Transaksi tidak ditemukan, mungkin sudah dihapus');
    final product = _db.products.find(productId);
    if (product == null) throw DataException('Barang tidak ditemukan, mungkin sudah dihapus');

    final changes = <String, int>{};
    // Barang lama yang sudah dihapus tidak perlu dikembalikan stoknya.
    if (_db.products.find(old.productId) != null) {
      changes[old.productId] = -_stockEffect(old.type, old.quantity);
    }
    changes[productId] = (changes[productId] ?? 0) + _stockEffect(old.type, quantity);
    _applyStockChanges(changes, type: _movementType(old.type), refNo: old.invoiceNo, reason: 'Koreksi transaksi');

    final updated = TransactionModel(
      id: old.id,
      invoiceNo: old.invoiceNo,
      type: old.type,
      productId: product.id,
      itemName: product.name,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      quantity: quantity,
      unitPrice: unitPrice,
      date: date,
      note: note,
      actorName: old.actorName,
    );
    _db.transactions.update(updated);
    AppLog.i(tag, 'update: $id');
    return updated;
  }

  static Future<void> delete({required String id}) async {
    await _db.simulateLatency();
    final old = _db.transactions.find(id);
    if (old == null) return;

    if (_db.products.find(old.productId) != null) {
      _applyStockChanges(
        {old.productId: -_stockEffect(old.type, old.quantity)},
        type: _movementType(old.type),
        refNo: old.invoiceNo,
        reason: 'Transaksi dihapus',
      );
    }
    _db.transactions.delete(id);
    AppLog.i(tag, 'delete: $id');
  }

  // Bayar keranjang Kasir: satu transaksi penjualan per barang, semuanya
  // ditandai nomor nota yang sama. Mengembalikan nomor nota.
  static Future<String> checkout({required List<CartItem> items, required String note}) async {
    await _db.simulateLatency(500);
    if (items.isEmpty) throw DataException('Keranjang masih kosong');

    final changes = <String, int>{};
    for (final item in items) {
      changes[item.product.id] = (changes[item.product.id] ?? 0) - item.quantity;
    }
    // Validasi stok dulu supaya nomor nota tidak terpakai kalau gagal.
    _validateStockChanges(changes);
    final invoiceNo = _db.newInvoiceNo();
    _applyStockChanges(changes, type: StockMovementType.sale, refNo: invoiceNo, note: note.trim());

    final now = DateTime.now();
    final actor = AuthService.currentUser?.name ?? '-';
    final noteText = note.trim();

    for (final item in items) {
      final product = _db.products.find(item.product.id)!;
      _db.transactions.insert(
        TransactionModel(
          id: _db.newId('t'),
          invoiceNo: invoiceNo,
          type: TransactionType.sale,
          productId: product.id,
          itemName: product.name,
          categoryId: product.categoryId,
          categoryName: product.categoryName,
          quantity: item.quantity,
          unitPrice: item.product.sellPrice,
          date: now,
          note: noteText,
          actorName: actor,
        ),
      );
    }
    AppLog.i(tag, 'checkout: $invoiceNo (${items.length} item)');
    return invoiceNo;
  }

  static int _stockEffect(TransactionType type, int quantity) =>
      type == TransactionType.sale ? -quantity : quantity;

  static StockMovementType _movementType(TransactionType type) =>
      type == TransactionType.sale ? StockMovementType.sale : StockMovementType.purchase;

  // Validasi semua dulu, baru terapkan; tiap perubahan dicatat di kartu stok.
  static void _applyStockChanges(
    Map<String, int> changes, {
    required StockMovementType type,
    String refNo = '',
    String reason = '',
    String note = '',
  }) {
    _validateStockChanges(changes);
    for (final entry in changes.entries) {
      if (entry.value == 0) continue;
      final product = _db.products.find(entry.key)!;
      final updated = product.copyWith(stock: product.stock + entry.value);
      _db.products.update(updated);
      StockMovementService.record(
        product: updated,
        type: type,
        change: entry.value,
        refNo: refNo,
        reason: reason,
        note: note,
      );
    }
  }

  static void _validateStockChanges(Map<String, int> changes) {
    for (final entry in changes.entries) {
      final product = _db.products.find(entry.key);
      if (product == null) throw DataException('Barang tidak ditemukan, mungkin sudah dihapus');
      final next = product.stock + entry.value;
      if (next < 0) {
        throw DataException(
          'Stok "${product.name}" tidak cukup (sisa ${product.stock} ${product.unit}).',
        );
      }
    }
  }
}
