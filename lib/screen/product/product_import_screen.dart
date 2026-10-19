import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/services/product_import_service.dart';
import 'package:ngekas/services/spreadsheet_reader.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:share_plus/share_plus.dart';

// ─── ProductImportScreen ────────────────────────────────────────────────────
//
// Import data barang dari file Excel (.xlsx) / CSV (khusus admin). Pilih
// file -> pratinjau tiap baris (siap / dilewati / error) -> "Import". Ada
// tombol bagikan template CSV supaya format kolomnya pas.

class ProductImportScreen extends StatefulWidget {
  const ProductImportScreen({super.key});

  @override
  State<ProductImportScreen> createState() => _ProductImportScreenState();
}

class _ProductImportScreenState extends State<ProductImportScreen> {
  static const tag = 'ProductImportScreen';

  String? _fileName;
  List<ImportRow>? _rows;
  bool _isLoading = false;
  bool _isImporting = false;

  int _count(ImportRowStatus status) => _rows?.where((r) => r.status == status).length ?? 0;

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['xlsx', 'csv']);
      if (file == null || !mounted) return;
      setState(() => _isLoading = true);
      final bytes = await file.readAsBytes();
      final table = SpreadsheetReader.read(file.name, bytes);
      final rows = ProductImportService.parse(table);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _rows = rows;
        _isLoading = false;
      });
    } catch (e, st) {
      AppLog.e(tag, 'pickFile: error', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppDialog.showError(context, title: 'File Tidak Bisa Diimport', message: e.toString());
    }
  }

  Future<void> _shareTemplate() async {
    try {
      const name = 'template_import_barang.csv';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(utf8.encode(ProductImportService.templateCsv()), mimeType: 'text/csv', name: name)],
          fileNameOverrides: [name],
          text: 'Template import barang Ngekas',
        ),
      );
    } catch (e) {
      if (mounted) AppDialog.showError(context, title: 'Gagal Membagikan', message: e.toString());
    }
  }

  void _import() {
    final rows = _rows!;
    setState(() => _isImporting = true);
    final result = ProductImportService.commit(rows);
    setState(() => _isImporting = false);
    AppDialog.showSuccess(
      context,
      title: 'Import Selesai',
      message:
          '${result.created} barang ditambahkan ke Gudang.'
          '${result.newCategories > 0 ? '\n${result.newCategories} kategori baru dibuat.' : ''}'
          '${result.skipped > 0 ? '\n${result.skipped} baris dilewati.' : ''}',
      confirmText: 'Selesai',
      onConfirm: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Import Barang')),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildGuide(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareTemplate,
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Template'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickFile,
                        icon: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(rows == null ? 'Pilih File' : 'Ganti File'),
                      ),
                    ),
                  ],
                ),
                if (rows != null) ...[
                  const SizedBox(height: 20),
                  Text(_fileName ?? '', style: AppTextStyle.titleSm),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCountChip('Siap', _count(ImportRowStatus.ready), AppColors.success, AppColors.successLight),
                      _buildCountChip(
                        'Dilewati',
                        _count(ImportRowStatus.skipped),
                        const Color(0xFFB45309),
                        AppColors.warningLight,
                      ),
                      _buildCountChip('Error', _count(ImportRowStatus.error), AppColors.error, AppColors.errorLight),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final row in rows) _buildRow(row),
                ],
              ],
            ),
          ),
          if (rows != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: AppButton(
                  label: 'Import ${_count(ImportRowStatus.ready)} Barang',
                  icon: Icons.download_done_rounded,
                  isLoading: _isImporting,
                  onPressed: _count(ImportRowStatus.ready) > 0 ? _import : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuide() {
    const columns = [
      ('Nama *', 'Nama barang'),
      ('Kategori *', 'Dibuat otomatis kalau belum ada'),
      ('Satuan *', 'Satuan dasar, mis. botol / bungkus / pcs'),
      ('Harga Jual *', 'Per satuan dasar'),
      ('Stok', 'Stok awal dalam satuan dasar'),
      ('Barcode', 'Lebih dari satu dipisah | (garis tegak)'),
      ('Kemasan', 'Opsional, mis. Dus'),
      ('Isi Kemasan', 'Mis. 12 (botol per dus)'),
      ('Barcode Kemasan', 'Barcode dus'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Format File', style: AppTextStyle.titleSm),
          const SizedBox(height: 4),
          const Text(
            'File .xlsx atau .csv dengan baris pertama berisi judul kolom berikut (urutan bebas). '
            'Barang yang namanya sudah ada di Gudang akan dilewati.',
            style: AppTextStyle.bodySm,
          ),
          const SizedBox(height: 10),
          for (final (name, desc) in columns)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 120, child: Text(name, style: AppTextStyle.labelMd)),
                  Expanded(child: Text(desc, style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted))),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.info),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Di Excel, ubah format kolom Barcode jadi "Teks" supaya angkanya tidak berubah jadi 8,99E+12.',
                  style: AppTextStyle.labelSm.copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text('$label: $count', style: AppTextStyle.labelMd.copyWith(color: color)),
    );
  }

  Widget _buildRow(ImportRow row) {
    final (icon, color) = switch (row.status) {
      ImportRowStatus.ready => (Icons.check_circle_rounded, AppColors.success),
      ImportRowStatus.skipped => (Icons.remove_circle_outline_rounded, const Color(0xFFB45309)),
      ImportRowStatus.error => (Icons.error_outline_rounded, AppColors.error),
    };
    final details = [
      row.categoryName,
      if (row.sellPrice > 0) '${AppCurrency.format(row.sellPrice)} / ${row.unit}',
      'stok ${row.stock} ${row.unit}',
      if (row.hasPack) '${row.packName} isi ${row.packFactor}',
      if (row.barcodes.isNotEmpty || row.packBarcodes.isNotEmpty)
        '${row.barcodes.length + row.packBarcodes.length} barcode',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: row.status == ImportRowStatus.ready ? AppColors.border : color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name.isEmpty ? '(tanpa nama)' : row.name,
                  style: AppTextStyle.labelLg,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(details, style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
                if (row.message.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(row.message, style: AppTextStyle.labelSm.copyWith(color: color)),
                ],
              ],
            ),
          ),
          Text('Baris ${row.line}', style: AppTextStyle.labelSm.copyWith(color: AppColors.textDisabled)),
        ],
      ),
    );
  }
}
