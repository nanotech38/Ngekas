import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/sales_report/sales_report_cubit.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/report_logic.dart';
import 'package:ngekas/models/sales_report.dart';
import 'package:ngekas/screen/report/invoice_card.dart';
import 'package:ngekas/template/base_template.dart';

// ─── ReportView ─────────────────────────────────────────────────────────────
//
// Isi Laporan Penjualan:
// - Periode: Harian / Bulanan (dengan panah ‹ › untuk pindah periode) atau
//   Pilih Tanggal (rentang custom), selalu dengan label tanggal pasti.
// - Ringkasan: omzet, jumlah nota, barang terjual, rata-rata per nota, laba
//   kotor.
// - Cari No. Nota / nama barang + filter kategori & kasir (AppBar).
// - Tab "Nota" (dikelompokkan per tanggal + subtotal harian, ketuk untuk
//   detail) & "Per Barang" (rekap jumlah & omzet).
// - Export PDF sesuai periode & filter yang aktif (ikon PDF di AppBar).

enum _ReportTab { invoices, products }

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  _ReportTab _tab = _ReportTab.invoices;

  @override
  Widget build(BuildContext context) {
    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          BlocSelector<SalesReportCubit, SalesReportState, bool>(
            selector: (state) => state.hasExtraFilter,
            builder: (context, hasFilter) => IconButton(
              tooltip: 'Filter',
              icon: Badge(
                isLabelVisible: hasFilter,
                smallSize: 8,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.filter_list_rounded),
              ),
              onPressed: () => ReportLogic.openFilterSheet(context),
            ),
          ),
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => ReportLogic.exportPdf(context),
          ),
        ],
      ),
      child: BlocBuilder<SalesReportCubit, SalesReportState>(
        builder: (context, state) {
          if (state.status == SalesReportStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = state.report;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _buildPeriodSelector(context, state),
              const SizedBox(height: 16),
              _buildSummary(report.summary),
              const SizedBox(height: 16),
              _buildSearchField(context),
              if (state.hasExtraFilter) ...[const SizedBox(height: 10), _buildActiveFilters(context, state)],
              const SizedBox(height: 16),
              _buildTabSwitcher(report),
              const SizedBox(height: 12),
              if (_tab == _ReportTab.invoices) ..._buildInvoiceList(context, report) else ..._buildProductList(report),
            ],
          );
        },
      ),
    );
  }

  // ─── Periode ──────────────────────────────────────────────────────────────

  Widget _buildPeriodSelector(BuildContext context, SalesReportState state) {
    final cubit = context.read<SalesReportCubit>();
    final range = state.range;
    final isCustom = range.period == ReportPeriod.custom;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final (index, period) in ReportPeriod.values.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodChip(
                    label: period.label,
                    selected: range.period == period,
                    onTap: period == ReportPeriod.custom
                        ? () => ReportLogic.pickCustomRange(context)
                        : () => cubit.setPeriod(period),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!isCustom)
                IconButton(
                  tooltip: 'Sebelumnya',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => cubit.shift(-1),
                ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: isCustom ? () => ReportLogic.pickCustomRange(context) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            range.label,
                            style: AppTextStyle.titleSm,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_calendar_outlined, size: 16, color: AppColors.textMuted),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (!isCustom)
                IconButton(
                  tooltip: 'Berikutnya',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: state.canGoNext ? () => cubit.shift(1) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip({required String label, required bool selected, required VoidCallback onTap}) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.labelMd.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  // ─── Ringkasan ────────────────────────────────────────────────────────────

  Widget _buildSummary(SalesSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Omzet', style: AppTextStyle.labelMd.copyWith(color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(AppCurrency.format(summary.revenue), style: AppTextStyle.h3.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('Nota', '${summary.invoiceCount}')),
              Expanded(child: _buildSummaryItem('Barang Terjual', '${summary.quantity}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyle.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyle.titleSm.copyWith(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── Cari & filter aktif ──────────────────────────────────────────────────

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      onChanged: context.read<SalesReportCubit>().setQuery,
      style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: 'Cari No. Nota atau nama barang...',
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: AppFontSize.sm),
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textDisabled, size: 20),
        isDense: true,
      ),
    );
  }

  Widget _buildActiveFilters(BuildContext context, SalesReportState state) {
    final cubit = context.read<SalesReportCubit>();
    final categoryName = ReportLogic.categoryName(state.categoryId);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (categoryName != null)
          InputChip(
            label: Text('Kategori: $categoryName', style: AppTextStyle.labelMd),
            onDeleted: () => cubit.setFilter(cashierName: state.cashierName),
          ),
        if (state.cashierName != null)
          InputChip(
            label: Text('Kasir: ${state.cashierName}', style: AppTextStyle.labelMd),
            onDeleted: () => cubit.setFilter(categoryId: state.categoryId),
          ),
      ],
    );
  }

  // ─── Tab ──────────────────────────────────────────────────────────────────

  Widget _buildTabSwitcher(SalesReport report) {
    Widget option(_ReportTab tab, String label) {
      final selected = _tab == tab;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = tab),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: selected
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Text(
              label,
              style: AppTextStyle.labelLg.copyWith(color: selected ? AppColors.primaryDark : AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          option(_ReportTab.invoices, 'Nota (${report.invoices.length})'),
          option(_ReportTab.products, 'Per Barang (${report.products.length})'),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppTextStyle.bodySm, textAlign: TextAlign.center),
    );
  }

  // ─── Tab Nota ─────────────────────────────────────────────────────────────

  List<Widget> _buildInvoiceList(BuildContext context, SalesReport report) {
    if (report.days.isEmpty) return [_buildEmpty('Tidak ada penjualan pada periode ini.')];

    return [
      for (final day in report.days) ...[
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(AppDate.weekdayDate(day.day), style: AppTextStyle.titleSm)),
              Text(
                '${day.invoices.length} nota · ${AppCurrency.format(day.total)}',
                style: AppTextStyle.labelMd.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
        ),
        for (final invoice in day.invoices)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildInvoiceCard(context, invoice)),
        const SizedBox(height: 8),
      ],
    ];
  }

  Widget _buildInvoiceCard(BuildContext context, SalesInvoice invoice) => InvoiceCard(invoice: invoice);

  // ─── Tab Per Barang ───────────────────────────────────────────────────────

  List<Widget> _buildProductList(SalesReport report) {
    if (report.products.isEmpty) return [_buildEmpty('Tidak ada barang terjual pada periode ini.')];
    final maxQuantity = report.products.first.quantity;

    return [
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (final (index, item) in report.products.indexed) ...[
              if (index > 0) const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('${index + 1}', style: AppTextStyle.labelLg.copyWith(color: AppColors.textMuted)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: AppTextStyle.labelLg,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(AppCurrency.format(item.revenue), style: AppTextStyle.labelLg),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxQuantity == 0 ? 0 : item.quantity / maxQuantity,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceVariant,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.quantity} terjual · ${item.categoryName}',
                            style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }
}
