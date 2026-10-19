import 'package:flutter/material.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/stock_movement_model.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/services/stock_movement_service.dart';
import 'package:ngekas/template/base_template.dart';

// ─── StockCardScreen ────────────────────────────────────────────────────────
//
// Kartu stok satu barang: riwayat stok awal, penjualan, stok masuk &
// penyesuaian (beserta alasan), lengkap dengan saldo berjalan, siapa & kapan.
// Terbaru di atas, dikelompokkan per tanggal; bisa difilter Masuk / Keluar /
// Penyesuaian.

class StockCardScreen extends StatefulWidget {
  final ProductModel product;

  const StockCardScreen({super.key, required this.product});

  @override
  State<StockCardScreen> createState() => _StockCardScreenState();
}

enum _Filter { all, incoming, outgoing, adjustment }

extension on _Filter {
  String get label => switch (this) {
    _Filter.all => 'Semua',
    _Filter.incoming => 'Masuk',
    _Filter.outgoing => 'Keluar',
    _Filter.adjustment => 'Penyesuaian',
  };

  bool matches(StockMovementModel m) => switch (this) {
    _Filter.all => true,
    _Filter.incoming => m.change > 0,
    _Filter.outgoing => m.change < 0,
    _Filter.adjustment => m.type == StockMovementType.adjustment,
  };
}

class _StockCardScreenState extends State<StockCardScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kartu Stok')),
      child: StreamBuilder<List<ProductModel>>(
        stream: DatabaseService.instance.products.watch(),
        builder: (context, productSnap) {
          // Data barang terbaru (stok bisa berubah selama layar terbuka); kalau
          // barangnya sudah dihapus, pakai data terakhir yang diketahui.
          final product =
              productSnap.data?.where((p) => p.id == widget.product.id).firstOrNull ?? widget.product;

          return StreamBuilder<List<StockMovementModel>>(
            stream: StockMovementService.watchFor(product.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final all = snapshot.data!;
              final movements = all.where(_filter.matches).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildHeader(product, all),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 12),
                  if (movements.isEmpty) _buildEmpty() else ..._buildList(product, movements),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(ProductModel product, List<StockMovementModel> all) {
    final incoming = all.where((m) => m.change > 0).fold<int>(0, (sum, m) => sum + m.change);
    final outgoing = all.where((m) => m.change < 0).fold<int>(0, (sum, m) => sum - m.change);
    final breakdown = product.packBreakdown(product.stock);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: AppTextStyle.titleMd.copyWith(color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            [
              product.categoryName,
              if (product.packs.isNotEmpty) product.packs.map((p) => p.label(product.unit)).join(', '),
            ].join(' · '),
            style: AppTextStyle.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 14),
          Text('Stok Sekarang', style: AppTextStyle.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.85))),
          Text('${product.stock} ${product.unit}', style: AppTextStyle.h3.copyWith(color: Colors.white)),
          if (breakdown.isNotEmpty)
            Text('= $breakdown', style: AppTextStyle.labelMd.copyWith(color: Colors.white.withValues(alpha: 0.9))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildHeaderStat('Total Masuk', '+$incoming ${product.unit}')),
              Expanded(child: _buildHeaderStat('Total Keluar', '-$outgoing ${product.unit}')),
              Expanded(child: _buildHeaderStat('Riwayat', '${all.length} baris')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyle.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyle.labelLg.copyWith(color: Colors.white)),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in _Filter.values)
          ChoiceChip(
            label: Text(filter.label),
            selected: _filter == filter,
            selectedColor: AppColors.primary,
            labelStyle: AppTextStyle.labelMd.copyWith(
              color: _filter == filter ? Colors.white : AppColors.textSecondary,
            ),
            onSelected: (_) => setState(() => _filter = filter),
          ),
      ],
    );
  }

  List<Widget> _buildList(ProductModel product, List<StockMovementModel> movements) {
    final byDay = <DateTime, List<StockMovementModel>>{};
    for (final m in movements) {
      byDay.putIfAbsent(DateTime(m.date.year, m.date.month, m.date.day), () => []).add(m);
    }

    return [
      for (final entry in byDay.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(AppDate.weekdayDate(entry.key), style: AppTextStyle.titleSm),
        ),
        for (final m in entry.value) Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildRow(product, m)),
        const SizedBox(height: 4),
      ],
    ];
  }

  Widget _buildRow(ProductModel product, StockMovementModel m) {
    final (icon, color, background) = switch (m.type) {
      StockMovementType.initial => (Icons.flag_outlined, AppColors.info, AppColors.infoLight),
      StockMovementType.sale => (Icons.shopping_bag_outlined, AppColors.expense, AppColors.expenseBackground),
      StockMovementType.purchase => (Icons.move_to_inbox_rounded, AppColors.income, AppColors.incomeBackground),
      StockMovementType.adjustment => (Icons.tune_rounded, AppColors.primary, AppColors.primaryContainer),
    };
    final changeColor = m.change > 0 ? AppColors.success : (m.change < 0 ? AppColors.error : AppColors.textMuted);
    final breakdown = product.packBreakdown(m.change.abs());
    final meta = [
      if (m.type == StockMovementType.adjustment) m.type.label,
      if (m.refNo.isNotEmpty) m.refNo,
      m.actorName,
      AppDate.time(m.date),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title, style: AppTextStyle.labelLg),
                const SizedBox(height: 2),
                Text(meta, style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
                if (m.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('"${m.note}"', style: AppTextStyle.labelSm.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                m.type == StockMovementType.initial ? '${m.change}' : '${m.change > 0 ? '+' : ''}${m.change}',
                style: AppTextStyle.titleSm.copyWith(color: changeColor),
              ),
              if (breakdown.isNotEmpty)
                Text(breakdown, style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text('Saldo ${m.balance}', style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text('Belum ada riwayat stok untuk filter ini.', style: AppTextStyle.bodySm, textAlign: TextAlign.center),
    );
  }
}
