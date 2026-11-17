import 'dart:math';

import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/stock_movement_model.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/services/stock_movement_service.dart';

class ProductService {
  ProductService._();

  static const tag = 'ProductService';

  static final _random = Random();

  static DatabaseService get _db => DatabaseService.instance;

  static Stream<List<ProductModel>> watch() {
    return _db.products.watch().map(
      (rows) => [...rows]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );
  }

  static ProductModel? findByBarcode(String barcode, {String? exceptId}) {
    final code = barcode.trim();
    if (code.isEmpty) return null;
    return _db.products.rows.where((p) => p.id != exceptId && p.allBarcodes.contains(code)).firstOrNull;
  }

  static ProductUnitMatch? findByCode(String code) {
    final value = code.trim();
    if (value.isEmpty) return null;
    for (final p in _db.products.rows) {
      final match = p.unitForBarcode(value);
      if (match != null) return match;
    }
    final bySku = _db.products.rows.where((p) => p.sku.toUpperCase() == value.toUpperCase()).firstOrNull;
    return bySku == null ? null : ProductUnitMatch(bySku, null);
  }

  static Future<ProductModel> add({
    List<String> barcodes = const [],
    List<ProductPack> packs = const [],
    required String name,
    required String categoryId,
    required String unit,
    required int buyPrice,
    required int sellPrice,
    required int stock,
    String stockNote = 'Stok awal barang baru',
  }) async {
    await _db.simulateLatency();
    return insertNow(
      barcodes: barcodes,
      packs: packs,
      name: name,
      categoryId: categoryId,
      unit: unit,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      stock: stock,
      stockNote: stockNote,
    );
  }

  static ProductModel insertNow({
    List<String> barcodes = const [],
    List<ProductPack> packs = const [],
    required String name,
    required String categoryId,
    required String unit,
    required int buyPrice,
    required int sellPrice,
    required int stock,
    String stockNote = 'Stok awal barang baru',
  }) {
    final cleanBarcodes = _clean(barcodes);
    final cleanPacks = [for (final pack in packs) pack.copyWith(name: pack.name.trim(), barcodes: _clean(pack.barcodes))];
    _ensureUniqueBarcodes([...cleanBarcodes, for (final pack in cleanPacks) ...pack.barcodes]);
    if (stock < 0) throw DataException('Stok tidak boleh minus');
    final categoryName = _categoryName(categoryId);
    final product = ProductModel(
      id: _db.newId('p'),
      sku: generateCode(categoryName, existingCodes: _db.products.rows.map((p) => p.sku).toSet()),
      barcodes: cleanBarcodes,
      packs: cleanPacks,
      name: name,
      categoryId: categoryId,
      categoryName: categoryName,
      unit: unit,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      stock: stock,
      minStock: ProductModel.defaultMinStock,
    );
    _db.products.insert(product);
    StockMovementService.record(product: product, type: StockMovementType.initial, change: stock, note: stockNote);
    AppLog.i(tag, 'add: $name (${product.sku})');
    return product;
  }

  // stockReason wajib diisi kalau stoknya berubah
  static Future<ProductModel> update({
    required String id,
    List<String> barcodes = const [],
    List<ProductPack> packs = const [],
    required String name,
    required String categoryId,
    required String unit,
    required int buyPrice,
    required int sellPrice,
    required int stock,
    String stockReason = '',
    String stockNote = '',
  }) async {
    await _db.simulateLatency();
    final existing = _db.products.find(id);
    if (existing == null) throw DataException('Barang tidak ditemukan, mungkin sudah dihapus');
    final cleanBarcodes = _clean(barcodes);
    final cleanPacks = [for (final pack in packs) pack.copyWith(name: pack.name.trim(), barcodes: _clean(pack.barcodes))];
    _ensureUniqueBarcodes([...cleanBarcodes, for (final pack in cleanPacks) ...pack.barcodes], exceptId: id);
    if (stock < 0) throw DataException('Stok tidak boleh minus');
    final change = stock - existing.stock;
    if (change != 0 && stockReason.trim().isEmpty) {
      throw DataException('Stok berubah — pilih alasan perubahan stok dulu');
    }

    final updated = existing.copyWith(
      barcodes: cleanBarcodes,
      packs: cleanPacks,
      name: name,
      categoryId: categoryId,
      categoryName: _categoryName(categoryId),
      unit: unit,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      stock: stock,
    );
    _db.products.update(updated);
    StockMovementService.record(
      product: updated,
      type: StockMovementType.adjustment,
      change: change,
      reason: stockReason.trim(),
      note: stockNote.trim(),
    );
    AppLog.i(tag, 'update: $id');
    return updated;
  }

  static Future<ProductUnitMatch> linkBarcode({
    required String productId,
    required String barcode,
    String? packName,
    int? packFactor,
  }) async {
    await _db.simulateLatency();
    final product = _db.products.find(productId);
    if (product == null) throw DataException('Barang tidak ditemukan, mungkin sudah dihapus');
    final code = barcode.trim();
    if (code.isEmpty) throw DataException('Barcode kosong');
    _ensureUniqueBarcodes([code]);

    ProductModel updated;
    if (packName == null) {
      updated = product.copyWith(barcodes: [...product.barcodes, code]);
    } else {
      final index = product.packs.indexWhere((p) => p.name.toLowerCase() == packName.trim().toLowerCase());
      final packs = [...product.packs];
      if (index == -1) {
        if (packFactor == null || packFactor < 2) throw DataException('Isi kemasan minimal 2 ${product.unit}');
        packs.add(ProductPack(name: packName.trim(), factor: packFactor, barcodes: [code]));
      } else {
        packs[index] = packs[index].copyWith(barcodes: [...packs[index].barcodes, code]);
      }
      updated = product.copyWith(packs: packs);
    }
    _db.products.update(updated);
    AppLog.i(tag, 'linkBarcode: $code -> ${product.name} (${packName ?? product.unit})');
    return updated.unitForBarcode(code)!;
  }

  static Future<void> delete({required String id}) async {
    await _db.simulateLatency();
    _db.products.delete(id);
    AppLog.i(tag, 'delete: $id');
  }

  // format: PREFIX-123. angka diacak ulang kalau bentrok,
  // kalau 3 digit udah habis naik ke 4 digit
  static String generateCode(String categoryName, {required Set<String> existingCodes, Random? random}) {
    final rng = random ?? _random;
    final prefix = codePrefix(categoryName);
    final taken = existingCodes.map((c) => c.toUpperCase()).toSet();

    var digits = 3;
    while (true) {
      final min = pow(10, digits - 1).toInt();
      final max = pow(10, digits).toInt();
      final usedForPrefix = taken.where((c) {
        final number = c.startsWith('$prefix-') ? c.substring(prefix.length + 1) : '';
        return number.length == digits;
      }).length;
      if (usedForPrefix >= max - min) {
        digits++;
        continue;
      }

      while (true) {
        final code = '$prefix-${min + rng.nextInt(max - min)}';
        if (!taken.contains(code)) return code;
        AppLog.i(tag, 'generateCode: $code sudah dipakai, re-roll');
      }
    }
  }

  // Minuman -> MNM, Sembako -> SMB
  static String codePrefix(String categoryName) {
    final letters = categoryName.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    if (letters.isEmpty) return 'BRG';

    final buffer = StringBuffer(letters[0]);
    final rest = letters.substring(1);
    for (final char in rest.split('')) {
      if (buffer.length == 3) break;
      if (!'AEIOU'.contains(char)) buffer.write(char);
    }
    for (final char in rest.split('')) {
      if (buffer.length == 3) break;
      if ('AEIOU'.contains(char)) buffer.write(char);
    }
    while (buffer.length < 3) {
      buffer.write('X');
    }
    return buffer.toString();
  }

  static List<String> _clean(List<String> barcodes) =>
      {for (final b in barcodes) if (b.trim().isNotEmpty) b.trim()}.toList();

  static void _ensureUniqueBarcodes(List<String> barcodes, {String? exceptId}) {
    final seen = <String>{};
    for (final code in barcodes) {
      if (!seen.add(code)) throw DataException('Barcode $code terdaftar dua kali di barang ini');
      final duplicate = findByBarcode(code, exceptId: exceptId);
      if (duplicate != null) throw DataException('Barcode $code sudah dipakai barang "${duplicate.name}"');
    }
  }

  static String _categoryName(String categoryId) {
    final category = _db.categories.find(categoryId);
    if (category == null) throw DataException('Kategori tidak ditemukan');
    return category.name;
  }
}
