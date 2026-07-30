import 'package:flutter/material.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/services/transaction_service.dart';

typedef _DailyTotal = ({DateTime day, int income, int expense});

// ─── HomeSummarySection ─────────────────────────────────────────────────────
//
// Section ringkasan di HomeScreen, di bawah grid menu — total pemasukan &
// pengeluaran bulan berjalan plus saldo, dan grafik batang tren 7 hari
// terakhir (pemasukan vs pengeluaran per hari). Ambil data langsung dari
// TransactionService.watch (dua tipe sekaligus, tanpa cubit) karena section
// ini murni tampilan, tidak ada aksi apa pun yang perlu ditampung state.

class HomeSummarySection extends StatelessWidget {
  final String ownerId;

  const HomeSummarySection({super.key, required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService.watch(ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Gagal memuat ringkasan', style: AppTextStyle.bodySm.copyWith(color: AppColors.error)),
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
          final ofDay = all.where((t) => t.date.year == day.year && t.date.month == day.month && t.date.day == day.day);
          return (
            day: day,
            income: ofDay.where((t) => t.type == CategoryType.income).fold<int>(0, (sum, t) => sum + t.amount),
            expense: ofDay.where((t) => t.type == CategoryType.expense).fold<int>(0, (sum, t) => sum + t.amount),
          );
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan Bulan Ini', style: AppTextStyle.titleMd),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTotalCard(
                    label: 'Pemasukan',
                    amount: totalIncome,
                    color: AppColors.income,
                    background: AppColors.incomeBackground,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTotalCard(
                    label: 'Pengeluaran',
                    amount: totalExpense,
                    color: AppColors.expense,
                    background: AppColors.expenseBackground,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildBalanceCard(totalIncome - totalExpense),
            const SizedBox(height: 20),
            const Text('Tren 7 Hari Terakhir', style: AppTextStyle.titleMd),
            const SizedBox(height: 12),
            _buildChart(dailyTotals),
          ],
        );
      },
    );
  }

  Widget _buildTotalCard({
    required String label,
    required int amount,
    required Color color,
    required Color background,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: AppTextStyle.labelMd, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppCurrency.format(amount),
            style: AppTextStyle.titleSm.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(int balance) {
    final color = balance >= 0 ? AppColors.income : AppColors.expense;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text('Laba/Rugi', style: AppTextStyle.labelLg),
          const Spacer(),
          Text(
            '${balance < 0 ? '-' : ''}${AppCurrency.format(balance)}',
            style: AppTextStyle.titleSm.copyWith(color: color),
          ),
        ],
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

    const chartHeight = 120.0;

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
}
