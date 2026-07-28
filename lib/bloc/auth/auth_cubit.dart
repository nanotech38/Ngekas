import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/services/auth_service.dart';
import 'package:ngekas/services/user_profile_service.dart';

enum AuthStatus {
  initial,
  loading,
  loginSuccess,
  registerSuccess,
  error,
  loggedOut,
}

class AuthState {
  final AuthStatus status;
  final String errorMessage;
  final AppUser? user;

  AuthState({required this.status, required this.errorMessage, this.user});

  AuthState.initial() : this(status: AuthStatus.initial, errorMessage: '');

  AuthState.loading() : this(status: AuthStatus.loading, errorMessage: '');

  // Emit khusus saat login (termasuk auto-login) berhasil — HANYA LoginScreen
  // yang bereaksi ke status ini. Dipisah dari registerSuccess supaya
  // LoginScreen & RegisterScreen (yang sama-sama tetap mounted selagi
  // Register di-push di atas Login) tidak berdua-duaan bereaksi ke event
  // yang sama dan rebutan manipulasi Navigator.
  AuthState.loginSuccess({AppUser? user})
    : this(status: AuthStatus.loginSuccess, errorMessage: '', user: user);

  AuthState.registerSuccess()
    : this(status: AuthStatus.registerSuccess, errorMessage: '');

  AuthState.error(String message)
    : this(status: AuthStatus.error, errorMessage: message);

  AuthState.loggedOut()
    : this(status: AuthStatus.loggedOut, errorMessage: '');
}

class AuthCubit extends Cubit<AuthState> {
  static const tag = 'AuthCubit';

  AuthCubit() : super(AuthState.initial());

  Future<void> login({required String email, required String password}) async {
    AppLog.i(tag, 'login: start');
    emit(AuthState.loading());
    try {
      final credential = await AuthService.login(
        email: email,
        password: password,
      );
      final profile = await UserProfileService.fetchProfile(
        credential.user!.uid,
      );
      AppLog.i(tag, 'login: success');
      emit(AuthState.loginSuccess(user: profile));
    } catch (e, st) {
      AppLog.e(tag, 'login: error', error: e, stackTrace: st);
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    AppLog.i(tag, 'register: start');
    emit(AuthState.loading());
    try {
      final credential = await AuthService.register(
        email: email,
        password: password,
      );
      // Bikin profil workspace (owner) selagi masih sesi user baru ini,
      // sebelum di-sign-out lagi (security rules mensyaratkan yang bikin
      // dokumen /users/{uid} adalah uid itu sendiri).
      await UserProfileService.createOwnerProfile(
        uid: credential.user!.uid,
        email: email,
      );
      // Firebase otomatis sign-in akun baru — sign-out lagi supaya user
      // tetap harus login manual di LoginScreen setelah daftar.
      await AuthService.logout();
      AppLog.i(tag, 'register: success');
      emit(AuthState.registerSuccess());
    } catch (e, st) {
      AppLog.e(tag, 'register: error', error: e, stackTrace: st);
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> logout() async {
    AppLog.i(tag, 'logout: start');
    try {
      await AuthService.logout();
      AppLog.i(tag, 'logout: success');
      emit(AuthState.loggedOut());
    } catch (e, st) {
      AppLog.e(tag, 'logout: error', error: e, stackTrace: st);
      emit(AuthState.error(e.toString()));
    }
  }

  // Dipanggil saat auto-login (splash mendeteksi user sudah login
  // sebelumnya) supaya role/ownerId ikut ke-load tanpa user login ulang.
  Future<void> loadCurrentProfile() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    AppLog.i(tag, 'loadCurrentProfile: start');
    try {
      final profile = await UserProfileService.fetchProfile(currentUser.uid);
      AppLog.i(tag, 'loadCurrentProfile: success');
      emit(AuthState.loginSuccess(user: profile));
    } catch (e, st) {
      AppLog.e(tag, 'loadCurrentProfile: error', error: e, stackTrace: st);
      emit(AuthState.error(e.toString()));
    }
  }
}
