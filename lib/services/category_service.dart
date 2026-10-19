import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/services/database_service.dart';

// ─── CategoryService ────────────────────────────────────────────────────────
//
// CRUD kategori barang di DatabaseService.categories (in-memory). Nama
// kategori yang didenormalisasi di barang ikut diperbarui saat kategori
// diubah, dan kategori yang masih dipakai barang tidak boleh dihapus.

class CategoryService {
  CategoryService._();

  static const tag = 'CategoryService';

  static DatabaseService get _db => DatabaseService.instance;

  static Stream<List<CategoryModel>> watch() {
    return _db.categories.watch().map(
      (rows) => [...rows]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );
  }

  static Future<void> add({required String name}) async {
    await _db.simulateLatency();
    _ensureUniqueName(name);
    _db.categories.insert(CategoryModel(id: _db.newId('c'), name: name));
    AppLog.i(tag, 'add: $name');
  }

  static Future<void> update({required String id, required String name}) async {
    await _db.simulateLatency();
    final existing = _db.categories.find(id);
    if (existing == null) throw DataException('Kategori tidak ditemukan');
    _ensureUniqueName(name, exceptId: id);

    _db.categories.update(existing.copyWith(name: name));
    for (final product in _db.products.rows.where((p) => p.categoryId == id)) {
      _db.products.update(product.copyWith(categoryName: name));
    }
    AppLog.i(tag, 'update: $id');
  }

  static Future<void> delete({required String id}) async {
    await _db.simulateLatency();
    final usedBy = _db.products.rows.where((p) => p.categoryId == id).length;
    if (usedBy > 0) {
      throw DataException('Kategori ini masih dipakai $usedBy barang. Pindahkan barangnya ke kategori lain dulu.');
    }
    _db.categories.delete(id);
    AppLog.i(tag, 'delete: $id');
  }

  static void _ensureUniqueName(String name, {String? exceptId}) {
    final normalized = name.trim().toLowerCase();
    final duplicate = _db.categories.rows.any((c) => c.id != exceptId && c.name.toLowerCase() == normalized);
    if (duplicate) throw DataException('Kategori "$name" sudah ada');
  }
}
