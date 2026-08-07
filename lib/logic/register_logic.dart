import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_log_const.dart';

// ─── RegisterLogic ──────────────────────────────────────────────────────────
//
// Menampung proses (bukan tampilan) dari RegisterScreen: apa yang terjadi
// saat tombol "Daftar" ditekan. Sama seperti LoginLogic, tidak menyimpan
// state — proses & state Firebase sesungguhnya ada di AuthCubit.

class RegisterLogic {
  RegisterLogic._();

  static const tag = 'RegisterLogic';

  static void handleRegister({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String email,
    required String password,
    String? inviteCode,
  }) {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      AppLog.w(tag, 'handleRegister: validasi form gagal');
      return;
    }

    AppLog.i(tag, 'handleRegister: form valid');
    context.read<AuthCubit>().register(
      email: email,
      password: password,
      inviteCode: inviteCode,
    );
  }
}
