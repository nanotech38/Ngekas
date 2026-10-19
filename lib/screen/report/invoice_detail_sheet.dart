import 'package:flutter/material.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/report_logic.dart';
import 'package:ngekas/models/sales_report.dart';
import 'package:ngekas/services/database_service.dart';

// ─── InvoiceDetailSheet ─────────────────────────────────────────────────────
//
// Detail satu nota penjualan dalam bentuk struk. Bagian struk dibungkus
// RepaintBoundary supaya bisa dirender jadi gambar dan dibagikan.

class InvoiceDetailSheet extends StatefulWidget {
  final SalesInvoice invoice;

  // Diisi dari Kasir setelah transaksi disimpan: struk ikut menampilkan uang
  // diterima & kembalian, ada banner "Transaksi Tercatat" dan tombol
  // "Selesai".
  final int? cash;
  final bool justSaved;

  const InvoiceDetailSheet({super.key, required this.invoice, this.cash, this.justSaved = false});

  @override
  State<InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<InvoiceDetailSheet> {
  final _receiptKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    await ReportLogic.shareReceipt(context, _receiptKey, widget.invoice);
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.justSaved) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transaksi Tercatat',
                    style: AppTextStyle.labelLg.copyWith(color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // AppBottomSheet sudah scrollable, jadi struk panjang tetap aman.
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: RepaintBoundary(
            key: _receiptKey,
            child: _Receipt(invoice: widget.invoice, cash: widget.cash),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: widget.justSaved
              ? OutlinedButton.icon(
                  onPressed: _isSharing ? null : _share,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Bagikan Struk'),
                )
              : ElevatedButton.icon(
                  onPressed: _isSharing ? null : _share,
                  icon: _isSharing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Bagikan Struk'),
                ),
        ),
        if (widget.justSaved) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            // Kasir yang membuka sheet ini lanjut kembali ke Beranda setelah
            // sheet ditutup.
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Selesai'),
            ),
          ),
        ],
      ],
    );
  }
}

// Tampilan struk — ini yang jadi gambar saat dibagikan, jadi latarnya putih
// solid dan tidak bergantung warna sheet.
class _Receipt extends StatelessWidget {
  final SalesInvoice invoice;
  final int? cash;

  const _Receipt({required this.invoice, this.cash});

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyle.labelSm.copyWith(color: AppColors.textMuted);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 32),
          const SizedBox(height: 6),
          Text(DatabaseService.storeName, style: AppTextStyle.titleLg, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text('Struk Penjualan', style: muted, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          const _DashedLine(),
          const SizedBox(height: 10),
          _InfoRow(label: 'No. Nota', value: invoice.displayNo),
          _InfoRow(label: 'Tanggal', value: '${AppDate.format(invoice.date)} ${AppDate.time(invoice.date)}'),
          _InfoRow(label: 'Kasir', value: invoice.actorName),
          const SizedBox(height: 10),
          const _DashedLine(),
          const SizedBox(height: 10),
          for (final line in invoice.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.itemName, style: AppTextStyle.labelLg),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text('${line.quantity} x ${AppCurrency.format(line.unitPrice)}', style: muted),
                      ),
                      Text(AppCurrency.format(line.amount), style: AppTextStyle.labelLg),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          const _DashedLine(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('Total (${invoice.quantity} item)', style: AppTextStyle.labelLg)),
              Text(
                AppCurrency.format(invoice.total),
                style: AppTextStyle.titleLg.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
          if (cash != null) ...[
            const SizedBox(height: 6),
            _InfoRow(label: 'Tunai', value: AppCurrency.format(cash!)),
            _InfoRow(label: 'Kembalian', value: AppCurrency.format(cash! - invoice.total)),
          ],
          if (invoice.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Catatan: ${invoice.note}', style: muted),
          ],
          const SizedBox(height: 16),
          Text('Terima kasih sudah berbelanja!', style: muted, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(child: Text(value, style: AppTextStyle.labelMd, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) => Container(width: 4, height: 1, color: AppColors.border)),
        );
      },
    );
  }
}
