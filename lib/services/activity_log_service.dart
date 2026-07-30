import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/activity_log_model.dart';

// ─── ActivityLogService ─────────────────────────────────────────────────────
//
// Wrapper ke Firestore /workspaces/{ownerId}/activity_logs. Beda dengan
// service lain, `log()` sengaja tidak melempar exception ke pemanggil —
// kegagalan nulis log tidak boleh menggagalkan aksi utama (add/update/delete
// transaksi/kategori) yang sudah sukses duluan, cukup dicatat ke console.

class ActivityLogService {
  ActivityLogService._();

  static const tag = 'ActivityLogService';

  static CollectionReference<Map<String, dynamic>> _collection(String ownerId) =>
      FirebaseFirestore.instance
          .collection('workspaces')
          .doc(ownerId)
          .collection('activity_logs');

  static Future<void> log({
    required String ownerId,
    required String actorEmail,
    required ActivityAction action,
    required ActivityEntity entity,
    required String description,
  }) async {
    try {
      await _collection(ownerId).add({
        'actorEmail': actorEmail,
        'action': action.name,
        'entity': entity.name,
        'description': description,
        'timestamp': Timestamp.now(),
      });
    } catch (e, st) {
      AppLog.e(tag, 'log: error', error: e, stackTrace: st);
    }
  }

  static Stream<List<ActivityLogModel>> watch(String ownerId) {
    return _collection(
      ownerId,
    ).orderBy('timestamp', descending: true).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ActivityLogModel.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }
}
