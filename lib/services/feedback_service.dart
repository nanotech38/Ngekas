import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngekas/const/app_log_const.dart';

class FeedbackException implements Exception {
  final String message;

  FeedbackException(this.message);

  @override
  String toString() => message;
}

// ─── FeedbackService ────────────────────────────────────────────────────────
//
// Wrapper ke Firestore /app_feedback — kotak masukan soal aplikasi, terpisah
// dari /workspaces/{ownerId} karena bukan data bisnis satu owner, melainkan
// masukan lintas user buat pengembangan Ngekas sendiri. Sengaja cuma
// create (lihat firestore.rules) — belum ada UI admin buat baca balik lewat
// app, dicek langsung dari Firebase Console.

class FeedbackService {
  FeedbackService._();

  static const tag = 'FeedbackService';

  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('app_feedback');

  static Future<void> submit({
    required String authorUid,
    required String authorEmail,
    required String menu,
    required String message,
  }) async {
    try {
      await _collection.add({
        'authorUid': authorUid,
        'authorEmail': authorEmail,
        'menu': menu,
        'message': message,
        'createdAt': Timestamp.now(),
      });
      AppLog.i(tag, 'submit: success');
    } catch (e, st) {
      AppLog.e(tag, 'submit: error', error: e, stackTrace: st);
      throw FeedbackException(_mapError(e));
    }
  }

  static String _mapError(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Kamu tidak punya izin untuk melakukan ini';
    }
    return 'Terjadi kesalahan, silakan coba lagi';
  }
}
