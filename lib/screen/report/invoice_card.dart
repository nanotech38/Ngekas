import 'package:flutter/material.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/report_logic.dart';
import 'package:ngekas/models/sales_report.dart';

// ─── InvoiceCard ────────────────────────────────────────────────────────────
//
// Kartu satu nota penjualan (nomor nota, waktu, kasir, ringkasan barang,
// total). Ketuk = buka struk (InvoiceDetailSheet). Dipakai di Laporan
// Penjualan dan "Transaksi Terbaru" di Beranda.
// `showDate`: tampilkan tanggal + jam (Beranda); false = jam saja karena
// Laporan sudah dikelompokkan per tanggal.

class InvoiceCard extends StatelessWidget {
  final SalesInvoice invoice;
  final bool showDate;

  const InvoiceCard({super.key, required this.invoice, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final itemsText = invoice.lines.map((t) => '${t.itemName} ×${t.quantity}').join(', ');
    final when = showDate ? AppDate.formatDateTime(invoice.date) : AppDate.time(invoice.date);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ReportLogic.openInvoiceDetail(context, invoice),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.incomeBackground, shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.income, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.displayNo, style: AppTextStyle.labelLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '$when · ${invoice.actorName} · ${invoice.quantity} item',
                      style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      itemsText,
                      style: AppTextStyle.labelSm.copyWith(color: AppColors.textDisabled),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(AppCurrency.format(invoice.total), style: AppTextStyle.currencySm.copyWith(color: AppColors.income)),
            ],
          ),
        ),
      ),
    );
  }
}
