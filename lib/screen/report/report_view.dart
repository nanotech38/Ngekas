import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/transaction/transaction_cubit.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/report_logic.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_toast.dart';

// ─── ReportView ─────────────────────────────────────────────────────────────
//
// Isi utama ReportScreen (header filter + list kartu riwayat). Dipisah dari
// ReportScreen supaya ReportScreen sendiri cuma jadi wiring BlocProvider.

class ReportView extends StatelessWidget {
  final CategoryType type;
  final String ownerId;

  const ReportView({super.key, required this.type, required this.ownerId});

  bool get _isIncome => type == CategoryType.income;

  @override
  Widget build(BuildContext context) {
    final isOwner = context.read<AuthCubit>().state.user?.role == UserRole.owner;

    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        if (state.status == TransactionStatus.streamError) {
          AppDialog.showError(context, title: 'Gagal Memuat', message: state.errorMessage);
        } else if (state.status == TransactionStatus.deleteSuccess) {
          AppToast.showSuccess(context, 'Laporan dihapus');
        } else if (state.status == TransactionStatus.deleteError) {
          AppDialog.showError(context, title: 'Gagal', message: state.errorMessage);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isIncome ? 'Laporan Pemasukan' : 'Laporan Pengeluaran'),
          actions: [
            BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) => IconButton(
                tooltip: 'Filter',
                icon: Badge(
                  isLabelVisible: state.filter.isActive,
                  smallSize: 8,
                  backgroundColor: AppColors.secondary,
                  child: const Icon(Icons.filter_list_rounded),
                ),
                onPressed: () => ReportLogic.openFilterSheet(context),
              ),
            ),
          ],
        ),
        body: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            if (state.status == TransactionStatus.loading && state.all.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = state.filtered;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      label: 'Tambah Laporan',
                      fontSize: AppFontSize.sm,
                      icon: Icons.add_rounded,
                      height: 30,
                      borderRadius: 8,
                      expand: false,
                      onPressed: () => ReportLogic.openAddEntrySheet(context),
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              state.filter.isActive
                                  ? 'Tidak ada data yang cocok dengan filter ini.'
                                  : (_isIncome ? 'Belum ada catatan pemasukan.' : 'Belum ada catatan pengeluaran.'),
                              style: AppTextStyle.bodyMd,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _buildCard(context, items[index], isOwner),
                        ),
                ),
                _buildSummaryCard(items),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<TransactionModel> items) {
    final color = _isIncome ? AppColors.income : AppColors.expense;
    final total = items.fold<int>(0, (sum, item) => sum + item.amount);

    // SafeArea(top: false) supaya card ini tidak ketutupan gesture/nav bar
    // bawaan HP — Scaffold tidak otomatis menghindari inset bawah untuk body.
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Laporan', style: AppTextStyle.labelMd),
                  const SizedBox(height: 4),
                  Text('${items.length}', style: AppTextStyle.titleMd),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 36, color: AppColors.border),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Nominal', style: AppTextStyle.labelMd),
                  const SizedBox(height: 4),
                  Text(AppCurrency.format(total), style: AppTextStyle.titleMd.copyWith(color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, TransactionModel item, bool isOwner) {
    final color = _isIncome ? AppColors.income : AppColors.expense;
    final background = _isIncome ? AppColors.incomeBackground : AppColors.expenseBackground;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                child: Icon(
                  _isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.itemName} ×${item.quantity}',
                      style: AppTextStyle.labelLg,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(item.categoryName, style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      AppDate.format(item.date),
                      style: AppTextStyle.labelSm.copyWith(color: AppColors.textDisabled),
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Catatan:', style: AppTextStyle.labelSm.copyWith(fontWeight: AppFontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(item.note, style: AppTextStyle.labelSm.copyWith(color: AppColors.textDisabled)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_isIncome ? '+' : '-'}${AppCurrency.format(item.amount)}',
                style: AppTextStyle.currencySm.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                label: 'Ubah',
                icon: Icons.edit_outlined,
                color: AppColors.textMuted,
                onPressed: () => ReportLogic.openEditEntrySheet(context, item),
              ),
              if (isOwner)
                _buildActionButton(
                  label: 'Hapus',
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  onPressed: () => ReportLogic.confirmDeleteEntry(context, item),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: AppTextStyle.labelSm.copyWith(color: color)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
