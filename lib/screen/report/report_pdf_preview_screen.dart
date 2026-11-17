import 'package:flutter/material.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/sales_report.dart';
import 'package:ngekas/services/report_pdf_service.dart';
import 'package:printing/printing.dart';

class ReportPdfPreviewScreen extends StatelessWidget {
  final SalesReport report;
  final ReportRange range;
  final List<String> filterLabels;
  final String printedBy;

  const ReportPdfPreviewScreen({
    super.key,
    required this.report,
    required this.range,
    required this.filterLabels,
    required this.printedBy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Export PDF')),
      body: PdfPreview(
        pdfFileName: ReportPdfService.fileName(range),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        loadingWidget: const CircularProgressIndicator(),
        build: (format) => ReportPdfService.build(
          report: report,
          range: range,
          filterLabels: filterLabels,
          printedBy: printedBy,
          pageFormat: format,
        ),
      ),
    );
  }
}
