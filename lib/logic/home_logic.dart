import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/screen/report/report_type_picker.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_toast.dart';

// ─── HomeLogic ──────────────────────────────────────────────────────────────
//
// Menampung proses (bukan tampilan) dari HomeScreen (shell) & tab-tab di
// dalamnya. Navigasi balik ke LoginScreen dipicu lewat AuthState.loggedOut
// (didengar di HomeScreen), bukan dipanggil langsung di sini, supaya
// konsisten dengan LoginScreen & RegisterScreen yang navigasinya juga
// digerakkan oleh AuthCubit.

class HomeLogic {
  HomeLogic._();

  static const tag = 'HomeLogic';

  static void handleLogout(BuildContext context) {
    AppLog.i(tag, 'handleLogout');
    context.read<AuthCubit>().logout();
  }

  // Dipanggil dari FAB tengah bottom nav & link "Lihat Semua" di HomeTab —
  // user pilih dulu mau lihat laporan Pemasukan atau Pengeluaran.
  static void openReportPicker(BuildContext context) {
    AppLog.i(tag, 'openReportPicker');
    AppBottomSheet.show(context, builder: (_) => const ReportTypePicker());
  }

  static void comingSoon(BuildContext context, String label) {
    AppToast.showWarning(context, '$label beloman dibuat');
  }
}
