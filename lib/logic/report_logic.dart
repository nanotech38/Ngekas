import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/transaction/transaction_cubit.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/screen/report/report_entry_form_sheet.dart';
import 'package:ngekas/screen/report/report_filter_sheet.dart';
import 'package:ngekas/screen/report/report_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_dialog.dart';

// ─── ReportLogic ────────────────────────────────────────────────────────────
//
// Menampung proses (bukan tampilan) dari ReportScreen & ReportTypePicker.
// Aksi yang butuh local widget state (mis. date range picker di
// _FilterSheet, yang pakai setState) tetap di widget-nya sendiri — di sini
// cuma yang murni "panggil cubit lalu navigasi", sama pola dengan
// LoginLogic/HomeLogic.

class ReportLogic {
  ReportLogic._();

  static const tag = 'ReportLogic';

  // Dipanggil dari ReportTypePicker saat user pilih Pemasukan/Pengeluaran.
  static void openReport(BuildContext context, CategoryType type) {
    AppLog.i(tag, 'openReport: type=$type');
    Navigator.of(context).pop();
    NavigationService.get().push(ReportScreen(type: type));
  }

  // Dipanggil dari tombol filter di AppBar ReportScreen.
  static void openFilterSheet(BuildContext context) {
    AppLog.i(tag, 'openFilterSheet');
    final cubit = context.read<TransactionCubit>();
    AppBottomSheet.show(
      context,
      builder: (_) => BlocProvider.value(value: cubit, child: const ReportFilterSheet()),
    );
  }

  // Dipanggil dari tombol "Terapkan" di ReportFilterSheet.
  static void applyFilter(
    BuildContext context, {
    DateTimeRange? dateRange,
    String? categoryId,
  }) {
    AppLog.i(tag, 'applyFilter');
    context.read<TransactionCubit>().applyFilter(
      TransactionFilter(dateRange: dateRange, categoryId: categoryId),
    );
    Navigator.of(context).pop();
  }

  // Dipanggil dari tombol "Reset Filter" di ReportFilterSheet.
  static void resetFilter(BuildContext context) {
    AppLog.i(tag, 'resetFilter');
    context.read<TransactionCubit>().clearFilter();
    Navigator.of(context).pop();
  }

  // Dipanggil dari FAB "+" di ReportScreen.
  static void openAddEntrySheet(BuildContext context) {
    AppLog.i(tag, 'openAddEntrySheet');
    final cubit = context.read<TransactionCubit>();
    AppBottomSheet.show(
      context,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const ReportEntryFormSheet()),
    );
  }

  // Dipanggil dari tombol "Ubah" di kartu laporan.
  static void openEditEntrySheet(BuildContext context, TransactionModel item) {
    AppLog.i(tag, 'openEditEntrySheet: id=${item.id}');
    final cubit = context.read<TransactionCubit>();
    AppBottomSheet.show(
      context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ReportEntryFormSheet(existing: item),
      ),
    );
  }

  // Dipanggil dari tombol "Hapus" di kartu laporan — dibatasi ke role owner
  // di ReportView, jadi di sini cukup tampilkan konfirmasi lalu hapus.
  static void confirmDeleteEntry(BuildContext context, TransactionModel item) {
    AppLog.i(tag, 'confirmDeleteEntry: id=${item.id}');
    final cubit = context.read<TransactionCubit>();
    AppDialog.show(
      context,
      type: AppDialogType.warning,
      title: 'Hapus Laporan?',
      message: 'Laporan "${item.itemName}" akan dihapus permanen.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      onConfirm: () => cubit.deleteTransaction(
        id: item.id,
        categoryName: item.categoryName,
        itemName: item.itemName,
        quantity: item.quantity,
        amount: item.amount,
      ),
    );
  }
}
