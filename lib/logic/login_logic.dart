import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_log_const.dart';

// ─── LoginLogic ─────────────────────────────────────────────────────────────
//
// Menampung proses (bukan tampilan) dari LoginScreen: apa yang terjadi saat
// tombol "Masuk" ditekan. Tidak menyimpan state apa pun, jadi cukup dipanggil
// lewat method statis (LoginLogic.handleLogin(...)) tanpa perlu instance.
// Proses & state Firebase sesungguhnya (loading/sukses/error) ada di AuthCubit.

class LoginLogic {
  LoginLogic._();

  static const tag = 'LoginLogic';

  static void handleLogin({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String email,
    required String password,
  }) {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      AppLog.w(tag, 'handleLogin: validasi form gagal');
      return;
    }

    AppLog.i(tag, 'handleLogin: form valid');
    context.read<AuthCubit>().login(email: email, password: password);
  }
}
