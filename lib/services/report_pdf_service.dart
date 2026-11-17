import 'dart:typed_data';

import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/models/sales_report.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// teks sengaja ASCII aja ("x", "-"), font standar PDF belum tentu
// bisa render "×" atau "·"
class ReportPdfService {
  ReportPdfService._();

  static const _primary = PdfColor.fromInt(0xFFEA580C);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _headerBackground = PdfColor.fromInt(0xFFFFEDD5);

  static String fileName(ReportRange range) {
    String ymd(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    final period = range.start == range.end ? ymd(range.start) : '${ymd(range.start)}-${ymd(range.end)}';
    return 'laporan-penjualan-$period.pdf';
  }

  static Future<Uint8List> build({
    required SalesReport report,
    required ReportRange range,
    required List<String> filterLabels,
    required String printedBy,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final doc = pw.Document(title: 'Laporan Penjualan ${range.label}', author: DatabaseService.storeName);
    final summary = report.summary;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        build: (context) => [
          _buildHeader(range: range, filterLabels: filterLabels, printedBy: printedBy),
          pw.SizedBox(height: 16),
          _buildSummary(summary),
          pw.SizedBox(height: 20),
          if (report.invoices.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 24),
              child: pw.Center(
                child: pw.Text('Tidak ada penjualan pada periode ini.', style: const pw.TextStyle(color: _muted)),
              ),
            )
          else ...[
            _sectionTitle('Daftar Nota (${report.invoices.length})'),
            _buildInvoiceTable(report),
            pw.SizedBox(height: 20),
            _sectionTitle('Rekap per Barang'),
            _buildProductTable(report),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader({
    required ReportRange range,
    required List<String> filterLabels,
    required String printedBy,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          DatabaseService.storeName,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primary),
        ),
        pw.SizedBox(height: 2),
        pw.Text('Laporan Penjualan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Periode: ${range.label} (${range.period.label})', style: const pw.TextStyle(fontSize: 10)),
        if (filterLabels.isNotEmpty)
          pw.Text('Filter: ${filterLabels.join(', ')}', style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
          'Dicetak: ${AppDate.formatDateTime(DateTime.now())} oleh $printedBy',
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _border),
      ],
    );
  }

  static pw.Widget _buildSummary(SalesSummary summary) {
    final cells = [
      ('Omzet', AppCurrency.format(summary.revenue)),
      ('Jumlah Nota', '${summary.invoiceCount}'),
      ('Barang Terjual', '${summary.quantity}'),
    ];

    return pw.Row(
      children: [
        for (final (label, value) in cells)
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(right: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: _headerBackground,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
                  pw.SizedBox(height: 2),
                  pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildInvoiceTable(SalesReport report) {
    var number = 0;
    return pw.TableHelper.fromTextArray(
      headers: ['No', 'No. Nota', 'Tanggal', 'Kasir', 'Barang', 'Total'],
      data: [
        for (final invoice in report.invoices)
          [
            '${++number}',
            invoice.displayNo,
            AppDate.formatDateTime(invoice.date),
            invoice.actorName,
            invoice.lines.map((t) => '${t.itemName} x${t.quantity}').join('\n'),
            AppCurrency.format(invoice.total),
          ],
      ],
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FlexColumnWidth(2.2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FlexColumnWidth(3),
        5: pw.FlexColumnWidth(1.6),
      },
      cellAlignments: const {0: pw.Alignment.center, 5: pw.Alignment.centerRight},
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: _headerBackground),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      border: pw.TableBorder.all(color: _border, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }

  static pw.Widget _buildProductTable(SalesReport report) {
    var number = 0;
    return pw.TableHelper.fromTextArray(
      headers: ['No', 'Barang', 'Kategori', 'Qty', 'Omzet'],
      data: [
        for (final p in report.products)
          ['${++number}', p.name, p.categoryName, '${p.quantity}', AppCurrency.format(p.revenue)],
      ],
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(0.8),
        4: pw.FlexColumnWidth(1.6),
      },
      cellAlignments: const {0: pw.Alignment.center, 3: pw.Alignment.center, 4: pw.Alignment.centerRight},
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: _headerBackground),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      border: pw.TableBorder.all(color: _border, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }
}
