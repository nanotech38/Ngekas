import 'package:flutter/material.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/screen/product/stock_card_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/services/product_service.dart';
import 'package:ngekas/services/transaction_service.dart';
import 'package:ngekas/template/base_template.dart';

// ─── StockReportScreen ──────────────────────────────────────────────────────
//
// Laporan Stok: kondisi stok semua barang saat ini.
// - Ringkasan: jumlah barang, stok habis, stok menipis, tidak laku.
// - Filter: Semua / Habis / Menipis / Tidak Laku (stok ada tapi tidak
//   terjual 30 hari terakhir) + cari nama/barcode.
// - Tiap barang: stok (+ rincian per kemasan), terjual 30 hari, terakhir
//   terjual. Ketuk = Kartu Stok barang itu.

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

enum _StockFilter { all, out, low, idle }

extension on _StockFilter {
  String get label => switch (this) {
    _StockFilter.all => 'Semua',
    _StockFilter.out => 'Habis',
    _StockFilter.low => 'Menipis',
    _StockFilter.idle => 'Tidak Laku',
  };
}

// Ringkasan penjualan satu barang untuk laporan.
class _SalesInfo {
  int soldLast30 = 0;
  DateTime? lastSold;
}

class _StockReportScreenState extends State<StockReportScreen> {
  static const _idleDays = 30;

  _StockFilter _filter = _StockFilter.all;
  String _query = '';

  bool _isLow(ProductModel p) => !p.isOutOfStock && p.isLowStock;

  bool _isIdle(ProductModel p, _SalesInfo info) {
    if (p.isOutOfStock) return false;
    final cutoff = DateTime.now().subtract(const Duration(days: _idleDays));
    return info.lastSold == null || info.lastSold!.isBefore(cutoff);
  }

  Map<String, _SalesInfo> _salesInfo(List<TransactionModel> all) {
    final cutoff = DateTime.now().subtract(const Duration(days: _idleDays));
    final map = <String, _SalesInfo>{};
    for (final t in all.where((t) => t.type == TransactionType.sale)) {
      final info = map.putIfAbsent(t.productId, _SalesInfo.new);
      if (info.lastSold == null || t.date.isAfter(info.lastSold!)) info.lastSold = t.date;
      if (t.date.isAfter(cutoff)) info.soldLast30 += t.quantity;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Laporan Stok')),
      child: StreamBuilder<List<ProductModel>>(
        stream: ProductService.watch(),
        builder: (context, productSnap) {
          return StreamBuilder<List<TransactionModel>>(
            stream: TransactionService.watch(),
            builder: (context, txSnap) {
              if (!productSnap.hasData || !txSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final products = productSnap.data!;
              final sales = _salesInfo(txSnap.data!);
              _SalesInfo infoOf(ProductModel p) => sales[p.id] ?? _SalesInfo();

              final outCount = products.where((p) => p.isOutOfStock).length;
              final lowCount = products.where(_isLow).length;
              final idleCount = products.where((p) => _isIdle(p, infoOf(p))).length;

              final visible = products.where((p) {
                if (!p.matchesQuery(_query)) return false;
                return switch (_filter) {
                  _StockFilter.all => true,
                  _StockFilter.out => p.isOutOfStock,
                  _StockFilter.low => _isLow(p),
                  _StockFilter.idle => _isIdle(p, infoOf(p)),
                };
              }).toList()..sort((a, b) => _compare(a, b, infoOf(a), infoOf(b)));

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildSummary(products.length, outCount, lowCount, idleCount),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Cari nama atau barcode...',
                      hintStyle: TextStyle(color: AppColors.textHint, fontSize: AppFontSize.sm),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.textDisabled, size: 20),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final filter in _StockFilter.values)
                        ChoiceChip(
                          label: Text(switch (filter) {
                            _StockFilter.all => '${filter.label} (${products.length})',
                            _StockFilter.out => '${filter.label} ($outCount)',
                            _StockFilter.low => '${filter.label} ($lowCount)',
                            _StockFilter.idle => '${filter.label} ($idleCount)',
                          }),
                          selected: _filter == filter,
                          selectedColor: AppColors.primary,
                          labelStyle: AppTextStyle.labelMd.copyWith(
                            color: _filter == filter ? Colors.white : AppColors.textSecondary,
                          ),
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                    ],
                  ),
                  if (_filter == _StockFilter.idle) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Barang yang masih ada stoknya tapi tidak terjual $_idleDays hari terakhir.',
                      style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    _buildEmpty()
                  else
                    for (final p in visible)
                      Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildRow(p, infoOf(p))),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Urutan: habis -> menipis -> sisanya; "Tidak Laku" diurutkan dari yang
  // paling lama tidak terjual.
  int _compare(ProductModel a, ProductModel b, _SalesInfo ia, _SalesInfo ib) {
    if (_filter == _StockFilter.idle) {
      final da = ia.lastSold ?? DateTime(2000);
      final db = ib.lastSold ?? DateTime(2000);
      return da.compareTo(db);
    }
    int rank(ProductModel p) => p.isOutOfStock ? 0 : (_isLow(p) ? 1 : 2);
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    final byStock = a.stock.compareTo(b.stock);
    return byStock != 0 ? byStock : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  Widget _buildSummary(int total, int out, int low, int idle) {
    Widget tile(String label, int value, Color color, Color background, _StockFilter filter) {
      return Expanded(
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _filter = filter),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: AppTextStyle.titleLg.copyWith(color: color)),
                  const SizedBox(height: 2),
                  Text(label, style: AppTextStyle.labelSm.copyWith(color: color), maxLines: 1),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('Barang', total, AppColors.secondary, AppColors.secondaryContainer, _StockFilter.all),
        const SizedBox(width: 8),
        tile('Habis', out, AppColors.error, AppColors.errorLight, _StockFilter.out),
        const SizedBox(width: 8),
        tile('Menipis', low, const Color(0xFFB45309), AppColors.warningLight, _StockFilter.low),
        const SizedBox(width: 8),
        tile('Tdk Laku', idle, AppColors.info, AppColors.infoLight, _StockFilter.idle),
      ],
    );
  }

  Widget _buildRow(ProductModel p, _SalesInfo info) {
    final (color, background, status) = p.isOutOfStock
        ? (AppColors.error, AppColors.errorLight, 'Habis')
        : _isLow(p)
        ? (const Color(0xFFB45309), AppColors.warningLight, 'Menipis')
        : (AppColors.success, AppColors.successLight, 'Aman');
    final breakdown = p.packBreakdown(p.stock);
    final lastSold = info.lastSold == null ? 'Belum pernah terjual' : 'Terakhir terjual ${AppDate.format(info.lastSold!)}';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => NavigationService.get().push(StockCardScreen(product: p)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: AppTextStyle.labelLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${p.categoryName} · Terjual ${info.soldLast30} ${p.unit} (30 hari)',
                      style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(lastSold, style: AppTextStyle.labelSm.copyWith(color: AppColors.textDisabled)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${p.stock} ${p.unit}', style: AppTextStyle.labelLg.copyWith(color: color)),
                    Text(breakdown.isEmpty ? status : breakdown, style: AppTextStyle.labelSm.copyWith(color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      child: const Text('Tidak ada barang untuk filter ini.', style: AppTextStyle.bodySm, textAlign: TextAlign.center),
    );
  }
}
