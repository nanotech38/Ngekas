import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/services/auth_service.dart';
import 'package:ngekas/services/user_profile_cache_service.dart';
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
      if (profile == null) {
        await _rejectMissingProfile();
        return;
      }
      await UserProfileCacheService.saveProfile(profile);
      AppLog.i(tag, 'login: success');
      emit(AuthState.loginSuccess(user: profile));
    } catch (e, st) {
      AppLog.e(tag, 'login: error', error: e, stackTrace: st);
      emit(AuthState.error(e.toString()));
    }
  }

  // `inviteCode` kosong/null -> daftar sebagai owner workspace baru (alur
  // lama). Diisi -> daftar sebagai staff gabung ke workspace pemilik kode
  // itu (kode-nya = uid owner, lihat UserProfileService). Kode tidak valid
  // -> akun FirebaseAuth yang baru dibuat langsung dihapus lagi (rollback)
  // supaya tidak ada akun menggantung tanpa profil workspace.
  Future<void> register({
    required String email,
    required String password,
    String? inviteCode,
  }) async {
    AppLog.i(tag, 'register: start');
    emit(AuthState.loading());
    try {
      final credential = await AuthService.register(
        email: email,
        password: password,
      );
      final code = inviteCode?.trim();

      if (code != null && code.isNotEmpty) {
        final isValid = await UserProfileService.verifyInviteCode(code);
        if (!isValid) {
          await credential.user!.delete();
          AppLog.w(tag, 'register: kode undangan tidak valid');
          emit(AuthState.error('Kode undangan tidak ditemukan. Periksa kembali kode dari pemilik workspace.'));
          return;
        }
        await UserProfileService.createStaffProfile(
          uid: credential.user!.uid,
          email: email,
          ownerId: code,
        );
        // Dicatat selagi masih authenticated sebagai user baru ini (rules
        // activity_logs mensyaratkan isMemberOfWorkspace, yang baru
        // terpenuhi setelah createStaffProfile di atas selesai).
        await ActivityLogService.log(
          ownerId: code,
          actorEmail: email,
          action: ActivityAction.created,
          entity: ActivityEntity.member,
          description: '$email bergabung ke workspace',
        );
      } else {
        // Bikin profil workspace (owner) selagi masih sesi user baru ini,
        // sebelum di-sign-out lagi (security rules mensyaratkan yang bikin
        // dokumen /users/{uid} adalah uid itu sendiri).
        await UserProfileService.createOwnerProfile(
          uid: credential.user!.uid,
          email: email,
        );
      }

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
      await UserProfileCacheService.clear();
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
      // Cek cache lokal dulu — kalau ada dan masih untuk uid yang sama,
      // langsung pakai tanpa fetch ke Firestore supaya auto-login lebih cepat.
      final cached = await UserProfileCacheService.getCachedProfile();
      if (cached != null && cached.uid == currentUser.uid) {
        AppLog.i(tag, 'loadCurrentProfile: pakai cache');
        emit(AuthState.loginSuccess(user: cached));
        return;
      }

      final profile = await UserProfileService.fetchProfile(currentUser.uid);
      if (profile == null) {
        await _rejectMissingProfile();
        return;
      }
      await UserProfileCacheService.saveProfile(profile);
      AppLog.i(tag, 'loadCurrentProfile: success');
      emit(AuthState.loginSuccess(user: profile));
    } catch (e, st) {
      AppLog.e(tag, 'loadCurrentProfile: error', error: e, stackTrace: st);
      emit(AuthState.error(e.toString()));
    }
  }

  // Akun FirebaseAuth valid tapi profil /users/{uid}-nya tidak ada —
  // biasanya karena owner sudah "mengeluarkan" orang ini lewat Kelola
  // Orang. Tidak ada workspace buat ditampilkan, jadi sign-out paksa balik
  // ke LoginScreen dengan pesan yang jelas, daripada nyangkut di layar
  // kosong (ownerId null).
  Future<void> _rejectMissingProfile() async {
    AppLog.w(tag, 'rejectMissingProfile: profil tidak ditemukan, sign-out');
    await AuthService.logout();
    await UserProfileCacheService.clear();
    emit(
      AuthState.error(
        'Akun kamu sudah tidak terhubung ke workspace manapun. Hubungi pemilik workspace kalau ini keliru.',
      ),
    );
  }
}
