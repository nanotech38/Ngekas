import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_log_const.dart';

class LoginLogic {
  LoginLogic._();

  static const tag = 'LoginLogic';

  static void handleLogin({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String username,
    required String password,
  }) {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      AppLog.w(tag, 'handleLogin: validasi form gagal');
      return;
    }

    AppLog.i(tag, 'handleLogin: form valid');
    context.read<AuthCubit>().login(username: username, password: password);
  }
}
