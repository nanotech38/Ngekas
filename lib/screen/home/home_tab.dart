import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/home_logic.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/models/sales_report.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/screen/activity_log_screen.dart';
import 'package:ngekas/screen/report/invoice_card.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/services/transaction_service.dart';
import 'package:ngekas/template/base_template.dart';

enum _SalesPeriod { today, month }

extension on _SalesPeriod {
  String get label => this == _SalesPeriod.today ? 'Harian' : 'Bulanan';

  // Tanggal pasti periode ini, mis. "12 Okt 2026" atau "Oktober 2026".
  String rangeLabel(DateTime now) => this == _SalesPeriod.today ? AppDate.format(now) : AppDate.monthYear(now);
}

// Ringkasan penjualan satu barang dalam periode terpilih (untuk "Barang
// Paling Laku").
typedef _BestSeller = ({String name, String categoryName, int quantity, int revenue});

// ─── HomeTab ────────────────────────────────────────────────────────────────
//
// Tab "Beranda" — ringkasan toko:
// 1. Total penjualan barang (toggle Harian / Bulanan, bisa disembunyikan
//    lewat ikon mata).
// 2. Tombol pintas Kasir & Barang.
// 3. Barang paling laku pada periode yang sama dengan toggle di atas.
// 4. Transaksi terbaru (5 nota terakhir, ketuk = lihat struk).
// Murni tampilan, data langsung dari TransactionService.watch.
// `onOpenProducts` dipanggil tombol Barang untuk pindah ke tab Barang.

class HomeTab extends StatefulWidget {
  final VoidCallback? onOpenProducts;

  const HomeTab({super.key, this.onOpenProducts});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _obscureAmount = false;
  _SalesPeriod _period = _SalesPeriod.today;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;

    return BaseTemplate(
      backgroundColor: AppColors.background,
      safeAreaBottom: false,
      safeAreaTop: false,
      child: user == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: StreamBuilder<List<TransactionModel>>(
                stream: TransactionService.watch(),
                builder: (context, snapshot) {
                  final all = snapshot.data ?? const <TransactionModel>[];
                  return _buildContent(context, user, all, isLoading: !snapshot.hasData);
                },
              ),
            ),
    );
  }

  bool _isInPeriod(DateTime date) {
    final now = DateTime.now();
    if (date.year != now.year || date.month != now.month) return false;
    return _period == _SalesPeriod.month || date.day == now.day;
  }

  List<_BestSeller> _bestSellers(Iterable<TransactionModel> sales) {
    final byProduct = <String, _BestSeller>{};
    for (final t in sales) {
      final current = byProduct[t.productId];
      byProduct[t.productId] = (
        name: t.itemName,
        categoryName: t.categoryName,
        quantity: (current?.quantity ?? 0) + t.quantity,
        revenue: (current?.revenue ?? 0) + t.amount,
      );
    }
    return byProduct.values.toList()
      ..sort((a, b) {
        final byQuantity = b.quantity.compareTo(a.quantity);
        return byQuantity != 0 ? byQuantity : b.revenue.compareTo(a.revenue);
      });
  }

  Widget _buildContent(
    BuildContext context,
    AppUser user,
    List<TransactionModel> all, {
    required bool isLoading,
  }) {
    final sales = all.where((t) => t.type == TransactionType.sale && _isInPeriod(t.date)).toList();
    final totalRevenue = sales.fold<int>(0, (sum, t) => sum + t.amount);
    final totalQuantity = sales.fold<int>(0, (sum, t) => sum + t.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(user),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSalesCard(revenue: totalRevenue, quantity: totalQuantity, transactionCount: {for (final t in sales) t.invoiceKey}.length),
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildBestSellerSection(_bestSellers(sales)),
                const SizedBox(height: 24),
                _buildRecentSection(context, all),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(AppUser user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront_rounded, size: 14, color: Colors.white.withValues(alpha: 0.85)),
                    const SizedBox(width: 6),
                    Text(
                      DatabaseService.storeName,
                      style: AppTextStyle.labelMd.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Halo, ${user.name}',
                  style: AppTextStyle.titleLg.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(user.role.label, style: AppTextStyle.labelSm.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildIconButton(
            icon: Icons.history_rounded,
            onTap: () => NavigationService.get().push(const ActivityLogScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.white, size: 20)),
      ),
    );
  }

  Widget _buildSalesCard({required int revenue, required int quantity, required int transactionCount}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildPeriodToggle()),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _obscureAmount = !_obscureAmount),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _obscureAmount ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Total Penjualan · ${_period.rangeLabel(DateTime.now())}', style: AppTextStyle.bodySm),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _obscureAmount ? '••••••••' : AppCurrency.format(revenue),
              style: AppTextStyle.h3.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Barang Terjual',
                  value: '$quantity item',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStat(
                  icon: Icons.receipt_long_outlined,
                  label: 'Nota',
                  value: '$transactionCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: _SalesPeriod.values.map((period) {
          final selected = _period == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period.label,
                  style: AppTextStyle.labelMd.copyWith(color: selected ? Colors.white : AppColors.textMuted),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStat({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.incomeBackground, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.income),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyle.labelSm.copyWith(color: AppColors.income), overflow: TextOverflow.ellipsis),
                Text(
                  _obscureAmount ? '••' : value,
                  style: AppTextStyle.labelLg.copyWith(color: AppColors.income),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Kasir',
            icon: Icons.point_of_sale_rounded,
            color: AppColors.primary,
            onTap: HomeLogic.openCashier,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: 'Gudang',
            icon: Icons.warehouse_rounded,
            color: AppColors.secondary,
            onTap: () => widget.onOpenProducts?.call(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: AppTextStyle.labelLg.copyWith(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBestSellerSection(List<_BestSeller> bestSellers) {
    final top = bestSellers.take(5).toList();
    final maxQuantity = top.isEmpty ? 0 : top.first.quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Barang Paling Laku', style: AppTextStyle.titleMd)),
            Text(_period.rangeLabel(DateTime.now()), style: AppTextStyle.labelMd.copyWith(color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: top.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Belum ada barang terjual pada ${_period.rangeLabel(DateTime.now())}.',
                    style: AppTextStyle.bodySm,
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: [
                    for (final (index, item) in top.indexed) ...[
                      if (index > 0) const Divider(height: 1, color: AppColors.divider),
                      _buildBestSellerTile(rank: index + 1, item: item, maxQuantity: maxQuantity),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildBestSellerTile({required int rank, required _BestSeller item, required int maxQuantity}) {
    final isTop = rank == 1;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTop ? AppColors.primary : AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: AppTextStyle.labelMd.copyWith(color: isTop ? Colors.white : AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: AppTextStyle.labelLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('${item.quantity} terjual', style: AppTextStyle.labelMd.copyWith(color: AppColors.primaryDark)),
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
                  '${item.categoryName} · ${_obscureAmount ? '••••' : AppCurrency.format(item.revenue)}',
                  style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5 nota penjualan terakhir — kartunya sama dengan Laporan Penjualan dan
  // bisa diketuk untuk lihat struk.
  Widget _buildRecentSection(BuildContext context, List<TransactionModel> all) {
    final sales = all.where((t) => t.type == TransactionType.sale).toList();
    final recent = SalesReport.build(sales, const {}).invoices.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Transaksi Terbaru', style: AppTextStyle.titleMd)),
            GestureDetector(
              onTap: HomeLogic.openSalesReport,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(color: AppColors.primary, fontWeight: AppFontWeight.semiBold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: Text('Belum ada transaksi.', style: AppTextStyle.bodySm)),
          )
        else
          for (final invoice in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InvoiceCard(invoice: invoice, showDate: true),
            ),
      ],
    );
  }
}
