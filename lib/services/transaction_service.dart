import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/transaction_model.dart';

class TransactionException implements Exception {
  final String message;

  TransactionException(this.message);

  @override
  String toString() => message;
}

// ─── TransactionService ─────────────────────────────────────────────────────
//
// Wrapper ke Firestore /workspaces/{ownerId}/transactions — dipakai layar
// Laporan. Ordering dilakukan di query (single field, tidak perlu composite
// index), filter tipe/kategori/tanggal dilakukan di TransactionCubit supaya
// konsisten dengan pola CategoryService.

class TransactionService {
  TransactionService._();

  static const tag = 'TransactionService';

  static CollectionReference<Map<String, dynamic>> _collection(String ownerId) =>
      FirebaseFirestore.instance
          .collection('workspaces')
          .doc(ownerId)
          .collection('transactions');

  static Stream<List<TransactionModel>> watch(String ownerId) {
    return _collection(ownerId).orderBy('date', descending: true).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  static Future<void> add({
    required String ownerId,
    required CategoryType type,
    required String categoryId,
    required String categoryName,
    required String itemName,
    required int quantity,
    required int amount,
    required DateTime date,
    required String note,
  }) async {
    try {
      await _collection(ownerId).add({
        'type': type.name,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'itemName': itemName,
        'quantity': quantity,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'note': note,
      });
      AppLog.i(tag, 'add: $categoryName ($amount)');
    } catch (e, st) {
      AppLog.e(tag, 'add: error', error: e, stackTrace: st);
      throw TransactionException(_mapError(e));
    }
  }

  static Future<void> update({
    required String ownerId,
    required String id,
    required String categoryId,
    required String categoryName,
    required String itemName,
    required int quantity,
    required int amount,
    required DateTime date,
    required String note,
  }) async {
    try {
      await _collection(ownerId).doc(id).update({
        'categoryId': categoryId,
        'categoryName': categoryName,
        'itemName': itemName,
        'quantity': quantity,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'note': note,
      });
      AppLog.i(tag, 'update: $id');
    } catch (e, st) {
      AppLog.e(tag, 'update: error', error: e, stackTrace: st);
      throw TransactionException(_mapError(e));
    }
  }

  static Future<void> delete({required String ownerId, required String id}) async {
    try {
      await _collection(ownerId).doc(id).delete();
      AppLog.i(tag, 'delete: $id');
    } catch (e, st) {
      AppLog.e(tag, 'delete: error', error: e, stackTrace: st);
      throw TransactionException(_mapError(e));
    }
  }

  static String _mapError(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Kamu tidak punya izin untuk melakukan ini';
    }
    return 'Terjadi kesalahan, silakan coba lagi';
  }
}
