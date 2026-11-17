import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/sales_report/sales_report_cubit.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/sales_report.dart';
import 'package:ngekas/screen/report/invoice_detail_sheet.dart';
import 'package:ngekas/screen/report/report_filter_sheet.dart';
import 'package:ngekas/screen/report/report_pdf_preview_screen.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:share_plus/share_plus.dart';

class ReportLogic {
  ReportLogic._();

  static const tag = 'ReportLogic';

  static Future<void> pickCustomRange(BuildContext context) async {
    AppLog.i(tag, 'pickCustomRange');
    final cubit = context.read<SalesReportCubit>();
    final current = cubit.state.range;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // date picker assert kalau rentangnya lewat hari ini (mis. dari mode Bulanan)
    final end = current.end.isAfter(today) ? today : current.end;
    final start = current.start.isAfter(end) ? end : current.start;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: DateTimeRange(start: start, end: end),
      helpText: 'Pilih rentang tanggal laporan',
      saveText: 'Terapkan',
    );
    if (picked != null) cubit.setCustomRange(picked.start, picked.end);
  }

  static void openFilterSheet(BuildContext context) {
    AppLog.i(tag, 'openFilterSheet');
    final cubit = context.read<SalesReportCubit>();
    AppBottomSheet.show(context, builder: (_) => BlocProvider.value(value: cubit, child: const ReportFilterSheet()));
  }

  static void openInvoiceDetail(BuildContext context, SalesInvoice invoice) {
    AppLog.i(tag, 'openInvoiceDetail: ${invoice.key}');
    AppBottomSheet.show(context, builder: (_) => InvoiceDetailSheet(invoice: invoice));
  }

  static Future<void> shareReceipt(BuildContext context, GlobalKey receiptKey, SalesInvoice invoice) async {
    AppLog.i(tag, 'shareReceipt: ${invoice.key}');
    try {
      final boundary = receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Struk belum siap');
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('Gagal membuat gambar struk');

      final name = 'struk_${invoice.displayNo.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '_')}.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png', name: name)],
          fileNameOverrides: [name],
          text: 'Struk ${invoice.displayNo} - ${DatabaseService.storeName}',
        ),
      );
    } catch (e, st) {
      AppLog.e(tag, 'shareReceipt: error', error: e, stackTrace: st);
      // biasanya habis hot reload setelah nambah package, perlu full rebuild
      final message = e is MissingPluginException
          ? 'Fitur bagikan belum siap. Tutup aplikasi lalu jalankan ulang (bukan hot reload).'
          : e.toString();
      if (context.mounted) AppDialog.showError(context, title: 'Gagal Membagikan', message: message);
    }
  }

  static void exportPdf(BuildContext context) {
    AppLog.i(tag, 'exportPdf');
    final state = context.read<SalesReportCubit>().state;
    final user = context.read<AuthCubit>().state.user;

    final filterLabels = <String>[
      if (state.categoryId != null)
        'Kategori ${categoryName(state.categoryId) ?? '-'}',
      if (state.cashierName != null) 'Kasir ${state.cashierName}',
      if (state.query.trim().isNotEmpty) 'Cari "${state.query.trim()}"',
    ];

    NavigationService.get().push(
      ReportPdfPreviewScreen(
        report: state.report,
        range: state.range,
        filterLabels: filterLabels,
        printedBy: user?.name ?? '-',
      ),
    );
  }

  static String? categoryName(String? categoryId) =>
      categoryId == null ? null : DatabaseService.instance.categories.find(categoryId)?.name;
}
