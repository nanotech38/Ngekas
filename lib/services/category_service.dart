import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/category_model.dart';

class CategoryException implements Exception {
  final String message;

  CategoryException(this.message);

  @override
  String toString() => message;
}

// ─── CategoryService ────────────────────────────────────────────────────────
//
// Wrapper ke Firestore /workspaces/{ownerId}/categories — sama pola statis
// dengan UserProfileService. update/delete dibatasi ke owner lewat
// firestore.rules, jadi permission-denied dari staff ditangkap di sini dan
// diterjemahkan jadi pesan yang bisa ditampilkan lewat AppDialog.

class CategoryService {
  CategoryService._();

  static const tag = 'CategoryService';

  static CollectionReference<Map<String, dynamic>> _collection(String ownerId) =>
      FirebaseFirestore.instance
          .collection('workspaces')
          .doc(ownerId)
          .collection('categories');

  static Stream<List<CategoryModel>> watch(String ownerId) {
    return _collection(ownerId).orderBy('name').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  static Future<void> add({
    required String ownerId,
    required String name,
    required CategoryType type,
  }) async {
    try {
      await _collection(ownerId).add({'name': name, 'type': type.name});
      AppLog.i(tag, 'add: $name');
    } catch (e, st) {
      AppLog.e(tag, 'add: error', error: e, stackTrace: st);
      throw CategoryException(_mapError(e));
    }
  }

  static Future<void> update({
    required String ownerId,
    required String id,
    required String name,
  }) async {
    try {
      await _collection(ownerId).doc(id).update({'name': name});
      AppLog.i(tag, 'update: $id');
    } catch (e, st) {
      AppLog.e(tag, 'update: error', error: e, stackTrace: st);
      throw CategoryException(_mapError(e));
    }
  }

  static Future<void> delete({required String ownerId, required String id}) async {
    try {
      await _collection(ownerId).doc(id).delete();
      AppLog.i(tag, 'delete: $id');
    } catch (e, st) {
      AppLog.e(tag, 'delete: error', error: e, stackTrace: st);
      throw CategoryException(_mapError(e));
    }
  }

  static String _mapError(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Kamu tidak punya izin untuk melakukan ini';
    }
    return 'Terjadi kesalahan, silakan coba lagi';
  }
}
