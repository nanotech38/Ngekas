import 'package:firebase_auth/firebase_auth.dart';
import 'package:ngekas/const/app_log_const.dart';

// Exception dengan pesan yang sudah diterjemahkan ke Indonesia untuk ditampilkan ke user.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

// ─── AuthService ────────────────────────────────────────────────────────────
//
// Wrapper ke FirebaseAuth.instance (yang sudah singleton bawaan Firebase),
// jadi tidak perlu instance sendiri di sini — sama gaya dengan AppValidator.
// Firebase Auth otomatis persist sesi login di device, itu sebabnya "stay
// logged in" cukup dicek lewat currentUser, tidak perlu simpan token manual.

class AuthService {
  AuthService._();

  static const tag = 'AuthService';

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      AppLog.e(tag, 'login: ${e.code}', error: e, stackTrace: e.stackTrace);
      throw AuthException(_mapError(e));
    }
  }

  static Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      AppLog.e(tag, 'register: ${e.code}', error: e, stackTrace: e.stackTrace);
      throw AuthException(_mapError(e));
    }
  }

  static Future<void> logout() => FirebaseAuth.instance.signOut();

  static String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'email-already-in-use':
        return 'Email sudah terdaftar, silakan masuk';
      case 'weak-password':
        return 'Kata sandi terlalu lemah';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet';
      default:
        return e.message ?? 'Terjadi kesalahan, silakan coba lagi';
    }
  }
}
