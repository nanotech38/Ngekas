import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/services/database_service.dart';

// Exception dengan pesan yang sudah siap ditampilkan ke user.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

// ─── AuthService ────────────────────────────────────────────────────────────
//
// Login username/password terhadap akun hardcode di DatabaseService.users.
// Sesi login hanya disimpan di memori — aplikasi ditutup berarti harus login
// ulang (sejalan dengan data yang juga reset).

class AuthService {
  AuthService._();

  static const tag = 'AuthService';

  static AppUser? _currentUser;
  static AppUser? get currentUser => _currentUser;

  static DatabaseService get _db => DatabaseService.instance;

  static Future<AppUser> login({required String username, required String password}) async {
    await _db.simulateLatency(400);
    final normalized = username.trim().toLowerCase();
    final record = _db.users.rows
        .where((r) => r.user.username.toLowerCase() == normalized && r.password == password)
        .firstOrNull;

    if (record == null) {
      AppLog.w(tag, 'login: kredensial salah untuk "$normalized"');
      throw AuthException('Username atau kata sandi salah');
    }

    _currentUser = record.user;
    return record.user;
  }

  static Future<void> logout() async {
    await _db.simulateLatency(150);
    _currentUser = null;
  }
}
