import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/cashier/cashier_cubit.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/screen/cashier/cashier_screen.dart';
import 'package:ngekas/screen/report/report_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/widget/app_toast.dart';

// ─── HomeLogic ──────────────────────────────────────────────────────────────
//
// Menampung proses (bukan tampilan) dari HomeScreen (shell) & tab-tab di
// dalamnya. Navigasi balik ke LoginScreen dipicu lewat AuthState.loggedOut
// (didengar di HomeScreen), bukan dipanggil langsung di sini.

class HomeLogic {
  HomeLogic._();

  static const tag = 'HomeLogic';

  static void handleLogout(BuildContext context) {
    AppLog.i(tag, 'handleLogout');
    // Keranjang Kasir disimpan di level aplikasi — kosongkan supaya tidak
    // terbawa ke user berikutnya.
    context.read<CashierCubit>().clear();
    context.read<AuthCubit>().logout();
  }

  // Dipanggil dari FAB tengah bottom nav & tombol pintas di Beranda.
  static void openCashier() {
    AppLog.i(tag, 'openCashier');
    NavigationService.get().push(const CashierScreen());
  }

  // Dipanggil dari link "Lihat Semua" transaksi terbaru di Beranda.
  static void openSalesReport() {
    AppLog.i(tag, 'openSalesReport');
    NavigationService.get().push(const ReportScreen());
  }

  static void comingSoon(BuildContext context, String label) {
    AppToast.showWarning(context, '$label belum tersedia');
  }
}
