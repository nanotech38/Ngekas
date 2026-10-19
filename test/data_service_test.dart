import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ngekas/models/cart_item_model.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/services/auth_service.dart';
import 'package:ngekas/services/category_service.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/services/product_service.dart';
import 'package:ngekas/services/transaction_service.dart';
import 'package:ngekas/services/user_profile_service.dart';

// Test logika data hardcode in-memory: login 2 role, sinkronisasi stok saat
// transaksi ditambah/diubah/dihapus, checkout kasir, dan aturan kategori.

void main() {
  final db = DatabaseService.instance;

  int stockOf(String productId) => db.products.find(productId)!.stock;

  setUp(() async {
    db.reset();
    await AuthService.logout();
  });

  group('AuthService', () {
    test('admin & kasir bisa login dengan admin123', () async {
      final admin = await AuthService.login(username: 'admin', password: 'admin123');
      expect(admin.isAdmin, isTrue);

      final kasir = await AuthService.login(username: 'KASIR', password: 'admin123');
      expect(kasir.isAdmin, isFalse);
      expect(AuthService.currentUser?.username, 'kasir');
    });

    test('kata sandi salah ditolak', () async {
      expect(() => AuthService.login(username: 'admin', password: 'salah123'), throwsA(isA<AuthException>()));
    });

    test('akun kasir baru hanya bisa dibuat admin', () async {
      await AuthService.login(username: 'kasir', password: 'admin123');
      expect(
        () => UserProfileService.createKasir(name: 'Kasir 2', username: 'kasir2', password: 'rahasia1'),
        throwsA(isA<DataException>()),
      );

      await AuthService.login(username: 'admin', password: 'admin123');
      await UserProfileService.createKasir(name: 'Kasir 2', username: 'kasir2', password: 'rahasia1');
      final user = await AuthService.login(username: 'kasir2', password: 'rahasia1');
      expect(user.isAdmin, isFalse);
    });
  });

  group('TransactionService', () {
    test('penjualan mengurangi stok, hapus mengembalikan stok', () async {
      final before = stockOf('p-01');
      final sale = await TransactionService.add(
        type: TransactionType.sale,
        productId: 'p-01',
        quantity: 5,
        unitPrice: 4000,
        date: DateTime.now(),
        note: '',
      );
      expect(stockOf('p-01'), before - 5);
      expect(sale.amount, 20000);

      await TransactionService.delete(id: sale.id);
      expect(stockOf('p-01'), before);
    });

    test('penjualan melebihi stok ditolak tanpa mengubah data', () async {
      final countBefore = db.transactions.rows.length;
      expect(
        () => TransactionService.add(
          type: TransactionType.sale,
          productId: 'p-04', // stok awal 0
          quantity: 1,
          unitPrice: 3000,
          date: DateTime.now(),
          note: '',
        ),
        throwsA(isA<DataException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(stockOf('p-04'), 0);
      expect(db.transactions.rows.length, countBefore);
    });

    test('pembelian stok menambah stok, ubah barang memindahkan efek stok', () async {
      final stockA = stockOf('p-02');
      final stockB = stockOf('p-03');

      final purchase = await TransactionService.add(
        type: TransactionType.purchase,
        productId: 'p-02',
        quantity: 10,
        unitPrice: 3500,
        date: DateTime.now(),
        note: '',
      );
      expect(stockOf('p-02'), stockA + 10);

      await TransactionService.update(
        id: purchase.id,
        productId: 'p-03',
        quantity: 4,
        unitPrice: 5500,
        date: DateTime.now(),
        note: '',
      );
      expect(stockOf('p-02'), stockA);
      expect(stockOf('p-03'), stockB + 4);
    });

    test('checkout kasir mengurangi stok & membuat satu transaksi per barang', () async {
      final countBefore = db.transactions.rows.length;
      final stockA = stockOf('p-01');
      final stockB = stockOf('p-03');

      final invoiceNo = await TransactionService.checkout(
        items: [
          CartItem(product: db.products.find('p-01')!, quantity: 2),
          CartItem(product: db.products.find('p-03')!, quantity: 1),
        ],
        note: '',
      );

      expect(invoiceNo, startsWith('INV-'));
      expect(stockOf('p-01'), stockA - 2);
      expect(stockOf('p-03'), stockB - 1);
      expect(db.transactions.rows.length, countBefore + 2);
    });
  });

  group('ProductService', () {
    test('data awal berisi 4 barang', () {
      expect(db.products.rows.length, 4);
    });

    test('prefiks kode diambil dari nama kategori', () {
      expect(ProductService.codePrefix('Minuman'), 'MNM');
      expect(ProductService.codePrefix('Sembako'), 'SMB');
      expect(ProductService.codePrefix('Alat Tulis'), 'ALT');
      expect(ProductService.codePrefix('Es'), 'ESX');
    });

    test('kode yang sudah dipakai di-re-roll', () {
      // Angka acak pertama (121 -> MNM-121) bentrok, kedua (456) dipakai.
      final code = ProductService.generateCode(
        'Minuman',
        existingCodes: {'MNM-121'},
        random: _SequenceRandom([21, 356]),
      );
      expect(code, 'MNM-456');
    });

    test('tambah barang membuat kode unik otomatis dengan stok minimum bawaan', () async {
      final codes = <String>{};
      for (var i = 0; i < 5; i++) {
        final product = await ProductService.add(
          barcodes: const [],
          name: 'Teh Botol $i',
          categoryId: 'c-oli',
          unit: 'pcs',
          buyPrice: 0,
          sellPrice: 5000,
          stock: 10,
        );
        expect(product.sku, matches(RegExp(r'^OLP-\d{3}$')));
        expect(product.minStock, ProductModel.defaultMinStock);
        expect(product.hasBuyPrice, isFalse);
        codes.add(product.sku);
      }
      final allCodes = db.products.rows.map((p) => p.sku).toList();
      expect(allCodes.toSet().length, allCodes.length);
      expect(codes.length, 5);
    });

    test('ubah barang tidak mengganti kodenya', () async {
      final before = db.products.find('p-01')!.sku;
      await ProductService.update(
        id: 'p-01',
        barcodes: ['8997011930011'],
        name: 'Oli Mesin Matic 1L',
        categoryId: 'c-kelistrikan',
        unit: 'botol',
        buyPrice: 5000,
        sellPrice: 7000,
        stock: 30,
        stockReason: 'Stock Opname',
      );
      expect(db.products.find('p-01')!.sku, before);
    });

    test('barcode hasil scan tersimpan dan bisa dicari', () async {
      final product = await ProductService.add(
        barcodes: [' 8991002101234 '],
        name: 'Kampas Rem Depan',
        categoryId: 'c-sparepart',
        unit: 'set',
        buyPrice: 0,
        sellPrice: 45000,
        stock: 3,
      );
      expect(product.barcode, '8991002101234');
      expect(ProductService.findByBarcode('8991002101234')?.id, product.id);
      expect(product.matchesQuery('89910021'), isTrue);
    });

    test('barcode yang sudah dipakai barang lain ditolak', () async {
      expect(
        () => ProductService.add(
          barcodes: ['8997011930011'], // milik Oli Mesin Matic
          name: 'Barang Lain',
          categoryId: 'c-oli',
          unit: 'pcs',
          buyPrice: 0,
          sellPrice: 1000,
          stock: 1,
        ),
        throwsA(isA<DataException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(db.products.rows.length, 4);
    });

    test('barang tanpa barcode boleh lebih dari satu', () async {
      await ProductService.add(
        barcodes: const [],
        name: 'Baut M8',
        categoryId: 'c-sparepart',
        unit: 'pcs',
        buyPrice: 0,
        sellPrice: 1000,
        stock: 100,
      );
      await ProductService.add(
        barcodes: const [],
        name: 'Mur M8',
        categoryId: 'c-sparepart',
        unit: 'pcs',
        buyPrice: 0,
        sellPrice: 1000,
        stock: 100,
      );
      expect(db.products.rows.where((p) => !p.hasBarcode).length, 3);
    });
  });

  group('CategoryService', () {
    test('kategori yang masih dipakai barang tidak bisa dihapus', () async {
      expect(() => CategoryService.delete(id: 'c-oli'), throwsA(isA<DataException>()));
    });

    test('ubah nama kategori ikut memperbarui nama di barang', () async {
      await CategoryService.update(id: 'c-ban', name: 'Toiletries');
      expect(db.products.find('p-04')!.categoryName, 'Toiletries');
    });
  });

  test('reset mengembalikan data ke kondisi awal', () async {
    await TransactionService.add(
      type: TransactionType.sale,
      productId: 'p-01',
      quantity: 1,
      unitPrice: 4000,
      date: DateTime.now(),
      note: '',
    );
    db.reset();
    expect(stockOf('p-01'), 24);
  });
}

// Random palsu yang mengembalikan angka berurutan dari list — dipakai untuk
// menguji re-roll kode barang secara deterministik.
class _SequenceRandom implements Random {
  _SequenceRandom(this._values);

  final List<int> _values;
  var _index = 0;

  @override
  int nextInt(int max) => _values[_index++ % _values.length];

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
