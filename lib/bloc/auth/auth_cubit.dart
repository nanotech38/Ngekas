import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  loginSuccess,
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

  AuthState.loginSuccess({AppUser? user})
    : this(status: AuthStatus.loginSuccess, errorMessage: '', user: user);

  AuthState.error(String message)
    : this(status: AuthStatus.error, errorMessage: message);

  AuthState.loggedOut()
    : this(status: AuthStatus.loggedOut, errorMessage: '');
}

class AuthCubit extends Cubit<AuthState> {
  static const tag = 'AuthCubit';

  AuthCubit() : super(AuthState.initial());

  Future<void> login({required String username, required String password}) async {
    AppLog.i(tag, 'login: start');
    emit(AuthState.loading());
    try {
      final user = await AuthService.login(username: username, password: password);
      AppLog.i(tag, 'login: success (${user.role.name})');
      emit(AuthState.loginSuccess(user: user));
    } catch (e, st) {
      AppLog.e(tag, 'login: error', error: e, stackTrace: st);
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
}
