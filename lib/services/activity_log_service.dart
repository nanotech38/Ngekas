import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/services/auth_service.dart';
import 'package:ngekas/services/database_service.dart';

// ─── ActivityLogService ─────────────────────────────────────────────────────
//
// Riwayat Aktivitas in-memory. Pelakunya otomatis diambil dari user yang
// sedang login. `log()` sengaja tidak pernah melempar exception — gagal
// mencatat log tidak boleh menggagalkan aksi utama yang sudah sukses.

class ActivityLogService {
  ActivityLogService._();

  static DatabaseService get _db => DatabaseService.instance;

  static Future<void> log({
    required ActivityAction action,
    required ActivityEntity entity,
    required String description,
    String subject = '',
    List<ActivityDetail> details = const [],
  }) async {
    final user = AuthService.currentUser;
    _db.activityLogs.insert(
      ActivityLogModel(
        id: _db.newId('l'),
        actorName: user?.name ?? '-',
        actorRole: user?.role.label ?? '',
        action: action,
        entity: entity,
        subject: subject,
        details: details,
        description: description,
        timestamp: DateTime.now(),
      ),
    );
  }

  static Stream<List<ActivityLogModel>> watch() {
    return _db.activityLogs.watch().map(
      (logs) => [...logs]..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
    );
  }
}
