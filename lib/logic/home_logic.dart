import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/menu_item.dart';
import 'package:ngekas/screen/activity_log_screen.dart';
import 'package:ngekas/screen/category_screen.dart';
import 'package:ngekas/screen/report/report_type_picker.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_toast.dart';

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

  static void handleMenuTap(BuildContext context, MenuItem menu) {
    AppLog.i(tag, 'handleMenuTap: id=${menu.id} (${menu.label})');
    switch (menu.id) {
      case 1: // Laporan
        AppBottomSheet.show(context, builder: (_) => const ReportTypePicker());
        break;
      case 2: // Kelola Kategori
        NavigationService.get().push(const CategoryScreen());
        break;
      case 3: // Staff
        _comingSoon(context, menu.label);
        break;
      case 4: // Pengaturan
        _comingSoon(context, menu.label);
        break;
      case 5: // Riwayat Aktivitas
        NavigationService.get().push(const ActivityLogScreen());
        break;
      default:
        AppLog.w(tag, 'handleMenuTap: id tidak dikenali (${menu.id})');
    }
  }

  static void _comingSoon(BuildContext context, String label) {
    AppToast.showWarning(context, '$label belum tersedia');
  }
}
