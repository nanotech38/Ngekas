import 'dart:async';

import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/stock_movement_model.dart';
import 'package:ngekas/models/transaction_model.dart';

class DataException implements Exception {
  final String message;

  DataException(this.message);

  @override
  String toString() => message;
}

class MemoryTable<T> {
  MemoryTable(this._idOf);

  final String Function(T row) _idOf;
  final List<T> _rows = [];
  final StreamController<List<T>> _controller = StreamController<List<T>>.broadcast();

  List<T> get rows => List.unmodifiable(_rows);

  T? find(String id) => _rows.where((r) => _idOf(r) == id).firstOrNull;

  Stream<List<T>> watch() async* {
    yield rows;
    yield* _controller.stream;
  }

  void insert(T row) {
    _rows.add(row);
    _notify();
  }

  void update(T row) {
    final index = _rows.indexWhere((r) => _idOf(r) == _idOf(row));
    if (index == -1) throw DataException('Data tidak ditemukan, mungkin sudah dihapus');
    _rows[index] = row;
    _notify();
  }

  void delete(String id) {
    _rows.removeWhere((r) => _idOf(r) == id);
    _notify();
  }

  void seed(Iterable<T> rows) {
    _rows
      ..clear()
      ..addAll(rows);
    _notify();
  }

  void _notify() => _controller.add(rows);
}

class UserRecord {
  final AppUser user;
  final String password;

  const UserRecord({required this.user, required this.password});
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  static const storeName = 'Toko Ngekas';

  final users = MemoryTable<UserRecord>((r) => r.user.uid);
  final categories = MemoryTable<CategoryModel>((c) => c.id);
  final products = MemoryTable<ProductModel>((p) => p.id);
  final transactions = MemoryTable<TransactionModel>((t) => t.id);
  final activityLogs = MemoryTable<ActivityLogModel>((l) => l.id);
  final stockMovements = MemoryTable<StockMovementModel>((m) => m.id);

  bool _isReady = false;
  int _sequence = 1000;
  int _invoiceSequence = 0;

  String newId(String prefix) => '$prefix-${++_sequence}';

  String newInvoiceNo([DateTime? date]) {
    final d = date ?? DateTime.now();
    final ymd = '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    return 'INV-$ymd-${(++_invoiceSequence).toString().padLeft(3, '0')}';
  }

  // delay kecil biar loading state di UI tetap kelihatan
  Future<void> simulateLatency([int milliseconds = 250]) =>
      Future.delayed(Duration(milliseconds: milliseconds));

  Future<void> init(void Function(String message, double progress) onProgress) async {
    onProgress('Menyiapkan data toko...', 0.2);
    await simulateLatency(300);

    if (!_isReady) {
      onProgress('Memuat data barang...', 0.5);
      _seed();
      await simulateLatency(300);
      _isReady = true;
    }

    onProgress('Data siap!', 0.9);
    await simulateLatency(200);
    onProgress('Aplikasi siap!', 1.0);
  }

  void reset() {
    _seed();
    _isReady = true;
  }

  void _seed() {
    const admin = AppUser(uid: 'u-admin', username: 'admin', name: 'Admin Toko', role: UserRole.admin);
    const kasir = AppUser(uid: 'u-kasir', username: 'kasir', name: 'Kasir Toko', role: UserRole.kasir);

    users.seed(const [
      UserRecord(user: admin, password: 'admin123'),
      UserRecord(user: kasir, password: 'admin123'),
    ]);

    const categoryRows = [
      CategoryModel(id: 'c-oli', name: 'Oli & Pelumas'),
      CategoryModel(id: 'c-sparepart', name: 'Suku Cadang'),
      CategoryModel(id: 'c-kelistrikan', name: 'Kelistrikan'),
      CategoryModel(id: 'c-ban', name: 'Ban & Velg'),
      CategoryModel(id: 'c-aksesoris', name: 'Aksesoris'),
    ];
    categories.seed(categoryRows);

    String categoryName(String id) => categoryRows.firstWhere((c) => c.id == id).name;

    ProductModel product(
      String id,
      String sku,
      String name,
      String categoryId,
      String unit,
      int buyPrice,
      int sellPrice,
      int stock,
      int minStock, {
      List<String> barcodes = const [],
      List<ProductPack> packs = const [],
    }) {
      return ProductModel(
        id: id,
        sku: sku,
        barcodes: barcodes,
        packs: packs,
        name: name,
        categoryId: categoryId,
        categoryName: categoryName(categoryId),
        unit: unit,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: stock,
        minStock: minStock,
      );
    }

    const minStock = ProductModel.defaultMinStock;
    final productRows = [
      product('p-01', 'OLP-121', 'Oli Mesin Matic 0.8L', 'c-oli', 'botol', 42000, 55000, 24, minStock,
          barcodes: ['8997011930011', '8997011930028'],
          packs: [const ProductPack(name: 'Dus', factor: 12, barcodes: ['18997011930018'])]),
      product('p-02', 'SKK-305', 'Kampas Rem Depan', 'c-sparepart', 'set', 35000, 50000, 4, minStock,
          barcodes: ['8991234500305']),
      product('p-03', 'KLS-472', 'Busi Motor Standar', 'c-kelistrikan', 'pcs', 15000, 22000, 20, minStock,
          barcodes: ['4549526600472'],
          packs: [const ProductPack(name: 'Box', factor: 10, barcodes: ['14549526600479'])]),
      product('p-04', 'BNV-218', 'Ban Dalam Ring 17', 'c-ban', 'pcs', 28000, 38000, 0, minStock),
    ];
    products.seed(productRows);

    final now = DateTime.now();
    var txSequence = 0;
    _invoiceSequence = 0;

    TransactionModel line({
      required DateTime date,
      required TransactionType type,
      required String productId,
      required int quantity,
      String invoiceNo = '',
    }) {
      final p = productRows.firstWhere((p) => p.id == productId);
      final isSale = type == TransactionType.sale;
      return TransactionModel(
        id: 't-seed-${++txSequence}',
        invoiceNo: invoiceNo,
        type: type,
        productId: p.id,
        itemName: p.name,
        categoryId: p.categoryId,
        categoryName: p.categoryName,
        quantity: quantity,
        unitPrice: isSale ? p.sellPrice : p.buyPrice,
        date: date,
        note: isSale ? '' : 'Restok dari supplier',
        actorName: isSale ? kasir.name : admin.name,
      );
    }

    DateTime at(int daysAgo, int hour, int minute) => DateTime(now.year, now.month, now.day - daysAgo, hour, minute);

    List<TransactionModel> nota(int daysAgo, int hour, int minute, List<(String, int)> items) {
      final date = at(daysAgo, hour, minute);
      final invoiceNo = newInvoiceNo(date);
      return [
        for (final (productId, quantity) in items)
          line(date: date, type: TransactionType.sale, productId: productId, quantity: quantity, invoiceNo: invoiceNo),
      ];
    }

    TransactionModel restock(int daysAgo, int hour, String productId, int quantity) =>
        line(date: at(daysAgo, hour, 0), type: TransactionType.purchase, productId: productId, quantity: quantity);

    final txRows = [
      ...nota(9, 10, 12, [('p-04', 3)]),
      restock(8, 8, 'p-02', 12),
      ...nota(8, 13, 40, [('p-03', 1)]),
      ...nota(7, 11, 5, [('p-02', 2)]),
      ...nota(6, 10, 22, [('p-04', 3)]),
      ...nota(5, 9, 31, [('p-01', 5)]),
      ...nota(4, 10, 17, [('p-03', 1)]),
      restock(3, 8, 'p-03', 12),
      ...nota(3, 11, 48, [('p-02', 2)]),
      ...nota(2, 10, 9, [('p-01', 6)]),
      restock(1, 8, 'p-01', 24),
      ...nota(1, 9, 26, [('p-02', 4), ('p-04', 2)]),
      ...nota(0, 9, 14, [('p-01', 3), ('p-03', 2)]),
    ];
    transactions.seed(txRows);

    var movementSequence = 0;
    final movementRows = <StockMovementModel>[];
    final ordered = [...txRows]..sort((a, b) => a.date.compareTo(b.date));
    for (final p in productRows) {
      final lines = ordered.where((t) => t.productId == p.id).toList();
      int effect(TransactionModel t) => t.type == TransactionType.sale ? -t.quantity : t.quantity;
      var balance = p.stock - lines.fold<int>(0, (sum, t) => sum + effect(t));
      movementRows.add(
        StockMovementModel(
          id: 'm-seed-${++movementSequence}',
          productId: p.id,
          productName: p.name,
          unit: p.unit,
          type: StockMovementType.initial,
          change: balance,
          balance: balance,
          note: 'Stok awal saat mulai pakai aplikasi',
          actorName: admin.name,
          date: at(12, 8, 0),
        ),
      );
      for (final t in lines) {
        balance += effect(t);
        final isSale = t.type == TransactionType.sale;
        movementRows.add(
          StockMovementModel(
            id: 'm-seed-${++movementSequence}',
            productId: p.id,
            productName: p.name,
            unit: p.unit,
            type: isSale ? StockMovementType.sale : StockMovementType.purchase,
            change: effect(t),
            balance: balance,
            note: t.note,
            refNo: t.invoiceNo,
            actorName: t.actorName,
            date: t.date,
          ),
        );
      }
    }
    stockMovements.seed(movementRows);

    var logSequence = 0;
    ActivityLogModel log(
      int daysAgo,
      int hour,
      AppUser actor,
      ActivityAction action,
      ActivityEntity entity,
      String subject,
      List<ActivityDetail> details,
    ) {
      return ActivityLogModel(
        id: 'l-seed-${++logSequence}',
        actorName: actor.name,
        actorRole: actor.role.label,
        action: action,
        entity: entity,
        subject: subject,
        details: details,
        description: details.isEmpty ? subject : '$subject (${details.map((d) => d.summary).join(', ')})',
        timestamp: DateTime(now.year, now.month, now.day - daysAgo, hour, 5),
      );
    }

    activityLogs.seed([
      log(0, 11, kasir, ActivityAction.created, ActivityEntity.transaction, 'Busi Motor Standar', const [
        ActivityDetail('Jenis', 'Penjualan'),
        ActivityDetail('Jumlah', '2'),
        ActivityDetail('Total', 'Rp44.000'),
      ]),
      log(1, 8, admin, ActivityAction.created, ActivityEntity.transaction, 'Oli Mesin Matic 0.8L', const [
        ActivityDetail('Jenis', 'Pembelian Stok'),
        ActivityDetail('Jumlah', '24'),
        ActivityDetail('Harga Satuan', 'Rp42.000'),
        ActivityDetail('Total', 'Rp1.008.000'),
        ActivityDetail('Catatan', 'Restok dari supplier'),
      ]),
      log(2, 9, admin, ActivityAction.updated, ActivityEntity.product, 'Kampas Rem Depan', const [
        ActivityDetail.change('Harga Jual', 'Rp45.000', 'Rp50.000'),
      ]),
      log(4, 7, admin, ActivityAction.created, ActivityEntity.product, 'Ban Dalam Ring 17', const [
        ActivityDetail('Kategori', 'Ban & Velg'),
        ActivityDetail('Stok Awal', '10 pcs'),
        ActivityDetail('Harga Jual', 'Rp38.000'),
      ]),
      log(9, 7, admin, ActivityAction.created, ActivityEntity.category, 'Aksesoris', const []),
    ]);
  }
}
