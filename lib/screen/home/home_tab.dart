import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/home_logic.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/screen/activity_log_screen.dart';
import 'package:ngekas/screen/home/add_transaction_sheet.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/services/transaction_service.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';

typedef _DailyTotal = ({DateTime day, int income, int expense});

// ─── HomeTab ────────────────────────────────────────────────────────────────
//
// Tab "Beranda" di bottom nav HomeScreen — header sapaan + saldo bulan
// berjalan (bisa disembunyikan lewat ikon mata), tombol pintas tambah
// pemasukan/pengeluaran, tren 7 hari terakhir, dan transaksi terbaru. Data
// diambil langsung dari TransactionService.watch (murni tampilan, tidak ada
// aksi yang perlu ditampung state selain toggle sembunyikan saldo).

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _obscureBalance = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final ownerId = user?.ownerId;

    return BaseTemplate(
      backgroundColor: AppColors.background,
      safeAreaBottom: false,
      child: ownerId == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(user),
                  StreamBuilder<List<TransactionModel>>(
                      stream: TransactionService.watch(ownerId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Gagal memuat ringkasan',
                              style: AppTextStyle.bodySm.copyWith(color: AppColors.error),
                            ),
                          );
                        }

                        final all = snapshot.data ?? const <TransactionModel>[];
                        final now = DateTime.now();
                        final thisMonth = all.where((t) => t.date.year == now.year && t.date.month == now.month);

                        final totalIncome = thisMonth
                            .where((t) => t.type == CategoryType.income)
                            .fold<int>(0, (sum, t) => sum + t.amount);
                        final totalExpense = thisMonth
                            .where((t) => t.type == CategoryType.expense)
                            .fold<int>(0, (sum, t) => sum + t.amount);

                        final dailyTotals = List.generate(7, (i) {
                          final day = DateTime(now.year, now.month, now.day - (6 - i));
                          final ofDay = all.where(
                            (t) => t.date.year == day.year && t.date.month == day.month && t.date.day == day.day,
                          );
                          return (
                            day: day,
                            income: ofDay
                                .where((t) => t.type == CategoryType.income)
                                .fold<int>(0, (sum, t) => sum + t.amount),
                            expense: ofDay
                                .where((t) => t.type == CategoryType.expense)
                                .fold<int>(0, (sum, t) => sum + t.amount),
                          );
                        });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -28),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildBalanceCard(income: totalIncome, expense: totalExpense),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildActionButtons(context, ownerId),
                                  const SizedBox(height: 24),
                                  const Text('Tren 7 Hari Terakhir', style: AppTextStyle.titleMd),
                                  const SizedBox(height: 12),
                                  _buildChart(dailyTotals),
                                  const SizedBox(height: 24),
                                  _buildRecentSection(all),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildHeader(AppUser? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 44),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24.0),
                Text(
                  'Selamat datang kembali',
                  style: AppTextStyle.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  style: AppTextStyle.titleLg.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: _buildIconButton(
              icon: Icons.history_rounded,
              onTap: () => NavigationService.get().push(const ActivityLogScreen()),
            ),
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
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildBalanceCard({required int income, required int expense}) {
    final balance = income - expense;
    final balanceColor = balance < 0 ? AppColors.error : AppColors.textPrimary;
    final balanceText = _obscureBalance ? '••••••••' : '${balance < 0 ? '-' : ''}${AppCurrency.format(balance)}';

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
              const Text('Saldo Bulan Ini', style: AppTextStyle.bodySm),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _obscureBalance = !_obscureBalance),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _obscureBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(balanceText, style: AppTextStyle.h3.copyWith(color: balanceColor)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPill(
                  label: 'Pemasukan',
                  amount: income,
                  color: AppColors.income,
                  background: AppColors.incomeBackground,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPill(
                  label: 'Pengeluaran',
                  amount: expense,
                  color: AppColors.expense,
                  background: AppColors.expenseBackground,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required int amount,
    required Color color,
    required Color background,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyle.labelSm.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _obscureBalance ? '••••••' : AppCurrency.format(amount),
            style: AppTextStyle.labelLg.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String ownerId) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: '+ Pemasukan',
            color: AppColors.income,
            onTap: () => _openAddSheet(context, ownerId, CategoryType.income),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: '+ Pengeluaran',
            color: AppColors.expense,
            onTap: () => _openAddSheet(context, ownerId, CategoryType.expense),
          ),
        ),
      ],
    );
  }

  void _openAddSheet(BuildContext context, String ownerId, CategoryType type) {
    AppBottomSheet.show(
      context,
      builder: (_) => AddTransactionSheet(ownerId: ownerId, initialType: type),
    );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: AppTextStyle.labelLg.copyWith(color: Colors.white)),
      ),
    );
  }

  Widget _buildChart(List<_DailyTotal> dailyTotals) {
    final maxValue = dailyTotals.fold<int>(0, (max, d) {
      final dayMax = d.income > d.expense ? d.income : d.expense;
      return dayMax > max ? dayMax : max;
    });

    if (maxValue == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text('Belum ada data transaksi minggu ini.', style: AppTextStyle.bodySm, textAlign: TextAlign.center),
        ),
      );
    }

    const chartHeight = 110.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyTotals.map((d) {
                final incomeHeight = (d.income / maxValue) * chartHeight;
                final expenseHeight = (d.expense / maxValue) * chartHeight;
                return Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(incomeHeight, AppColors.income),
                      const SizedBox(width: 3),
                      _buildBar(expenseHeight, AppColors.expense),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: dailyTotals
                .map(
                  (d) => Expanded(
                    child: Text(
                      AppDate.weekdayShort(d.day),
                      textAlign: TextAlign.center,
                      style: AppTextStyle.labelSm.copyWith(color: AppColors.textDisabled),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Pemasukan', AppColors.income),
              const SizedBox(width: 16),
              _buildLegend('Pengeluaran', AppColors.expense),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 10,
      height: height < 2 ? 2 : height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyle.labelSm.copyWith(color: AppColors.textDisabled)),
      ],
    );
  }

  Widget _buildRecentSection(List<TransactionModel> all) {
    final recent = all.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Transaksi Terbaru', style: AppTextStyle.titleMd),
            const Spacer(),
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => HomeLogic.openReportPicker(context),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(color: AppColors.primary, fontWeight: AppFontWeight.semiBold),
                ),
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
          ...recent.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _buildTransactionTile(t))),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel t) {
    final isIncome = t.type == CategoryType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final background = isIncome ? AppColors.incomeBackground : AppColors.expenseBackground;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.itemName, style: AppTextStyle.labelLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${t.categoryName} · ${_relativeDate(t.date)}',
                  style: AppTextStyle.labelSm.copyWith(color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '-'}${AppCurrency.format(t.amount)}',
            style: AppTextStyle.labelLg.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return AppDate.format(date);
  }
}
