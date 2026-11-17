import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/cashier/cashier_cubit.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/screen/cashier/cashier_screen.dart';
import 'package:ngekas/screen/report/report_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/widget/app_toast.dart';

class HomeLogic {
  HomeLogic._();

  static const tag = 'HomeLogic';

  static void handleLogout(BuildContext context) {
    AppLog.i(tag, 'handleLogout');
    // keranjang kasir disimpan di level app, kosongin biar ga kebawa ke user berikutnya
    context.read<CashierCubit>().clear();
    context.read<AuthCubit>().logout();
  }

  static void openCashier() {
    AppLog.i(tag, 'openCashier');
    NavigationService.get().push(const CashierScreen());
  }

  static void openSalesReport() {
    AppLog.i(tag, 'openSalesReport');
    NavigationService.get().push(const ReportScreen());
  }

  static void comingSoon(BuildContext context, String label) {
    AppToast.showWarning(context, '$label belum tersedia');
  }
}
