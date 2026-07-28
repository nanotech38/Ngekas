import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_log_const.dart';

// ─── HomeLogic ──────────────────────────────────────────────────────────────
//
// Menampung proses (bukan tampilan) dari HomeScreen. Navigasi balik ke
// LoginScreen dipicu lewat AuthState.loggedOut (didengar di HomeScreen),
// bukan dipanggil langsung di sini, supaya konsisten dengan LoginScreen &
// RegisterScreen yang navigasinya juga digerakkan oleh AuthCubit.

class HomeLogic {
  HomeLogic._();

  static const tag = 'HomeLogic';

  static void handleLogout(BuildContext context) {
    AppLog.i(tag, 'handleLogout');
    context.read<AuthCubit>().logout();
  }
}
