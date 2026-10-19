import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/services/auth_service.dart';
import 'package:ngekas/services/database_service.dart';

// ─── UserProfileService ─────────────────────────────────────────────────────
//
// Dipakai layar "Kelola Pengguna" (admin-only): daftar akun yang terdaftar
// di toko ini, membuat akun kasir baru, & mengeluarkan akun kasir. Tidak ada
// pendaftaran mandiri — akun kasir hanya bisa dibuat admin. Data dari
// DatabaseService.users.

class UserProfileService {
  UserProfileService._();

  static const tag = 'UserProfileService';

  static DatabaseService get _db => DatabaseService.instance;

  static Stream<List<AppUser>> watchMembers() {
    return _db.users.watch().map((records) => records.map((r) => r.user).toList());
  }

  static Future<AppUser> createKasir({
    required String name,
    required String username,
    required String password,
  }) async {
    await _db.simulateLatency();
    _ensureAdmin();
    final normalized = username.trim().toLowerCase();
    if (_db.users.rows.any((r) => r.user.username.toLowerCase() == normalized)) {
      throw DataException('Username "$normalized" sudah dipakai, coba yang lain');
    }

    final user = AppUser(uid: _db.newId('u'), username: normalized, name: name.trim(), role: UserRole.kasir);
    _db.users.insert(UserRecord(user: user, password: password));
    AppLog.i(tag, 'createKasir: $normalized');
    return user;
  }

  static Future<void> removeMember(String uid) async {
    await _db.simulateLatency();
    _ensureAdmin();
    final record = _db.users.find(uid);
    if (record == null) throw DataException('Pengguna tidak ditemukan');
    if (record.user.isAdmin) throw DataException('Akun admin tidak bisa dikeluarkan');
    _db.users.delete(uid);
    AppLog.i(tag, 'removeMember: $uid');
  }

  static void _ensureAdmin() {
    if (!(AuthService.currentUser?.isAdmin ?? false)) {
      throw DataException('Hanya admin yang bisa mengelola pengguna');
    }
  }
}
