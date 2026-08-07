import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/const/app_rc_const.dart';
import 'package:ngekas/services/auth_service.dart';
import 'package:ngekas/services/database_service.dart';

class SplashState {
  final bool inLoading;
  final String rc;
  final String errorMsg;
  final String message;
  final double progress;
  final bool isLoggedIn;

  SplashState({
    required this.inLoading,
    required this.rc,
    required this.errorMsg,
    required this.message,
    required this.progress,
    required this.isLoggedIn,
  });

  SplashState.init()
    : this(
        inLoading: false,
        rc: '',
        errorMsg: '',
        message: '',
        progress: 0.0,
        isLoggedIn: false,
      );

  SplashState.loading({required String message, required double progress})
    : this(
        inLoading: true,
        rc: '',
        errorMsg: '',
        message: message,
        progress: progress,
        isLoggedIn: false,
      );

  SplashState.done({
    required String rc,
    required String errorMsg,
    bool isLoggedIn = false,
  }) : this(
         inLoading: false,
         rc: rc,
         errorMsg: errorMsg,
         message: rc == rcSuccess ? 'Aplikasi siap!' : errorMsg,
         progress: rc == rcSuccess ? 1.0 : 0.0,
         isLoggedIn: isLoggedIn,
       );
}

class SplashCubit extends Cubit<SplashState> {
  static const tag = 'SplashCubit';

  SplashCubit() : super(SplashState.init());

  // `loadProfile` dijalankan di titik progress 50% (setelah database siap),
  // supaya progress bar bukan cuma animasi kosong tapi memang menunggu kerja
  // nyata: separuh pertama untuk init database, separuh kedua untuk
  // memuat profil user (role/ownerId) sebelum masuk homepage.
  Future<void> initialize({required Future<void> Function() loadProfile}) async {
    AppLog.i(tag, 'initialize: start');
    try {
      await DatabaseService.instance.init((message, progress) {
        emit(SplashState.loading(message: message, progress: progress * 0.5));
      });

      final wasLoggedIn = AuthService.currentUser != null;
      if (wasLoggedIn) {
        emit(SplashState.loading(message: 'Memuat profil...', progress: 0.5));
        await loadProfile();
        emit(SplashState.loading(message: 'Aplikasi siap!', progress: 0.9));
      }

      // Cek ulang SETELAH loadProfile, bukan cuma pakai `wasLoggedIn` di
      // atas — AuthCubit.loadCurrentProfile bisa sign-out paksa di tengah
      // jalan (mis. akun sudah dikeluarkan owner dari workspace, lihat
      // AuthCubit._rejectMissingProfile), dan kalau itu terjadi splash
      // harus tetap arahkan ke LoginScreen, bukan HomeScreen dengan user
      // null (bakal crash di beberapa layar yang pakai `.user!`).
      final isLoggedIn = AuthService.currentUser != null;
      AppLog.i(tag, 'initialize: done, isLoggedIn=$isLoggedIn');
      emit(
        SplashState.done(
          rc: rcSuccess,
          errorMsg: '',
          isLoggedIn: isLoggedIn,
        ),
      );
    } catch (e, st) {
      AppLog.e(tag, 'initialize: error', error: e, stackTrace: st);
      emit(SplashState.done(rc: rcError, errorMsg: e.toString()));
    }
  }
}
