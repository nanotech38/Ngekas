import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/transaction/transaction_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/screen/report/report_entry_form_sheet.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionType initialType;
  final String? initialProductId;

  const AddTransactionSheet({super.key, required this.initialType, this.initialProductId});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late TransactionType _type = widget.initialType;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthCubit>().state.user?.isAdmin ?? false;

    return BlocProvider<TransactionCubit>(
      key: ValueKey(_type),
      create: (_) => TransactionCubit(type: _type),
      child: ReportEntryFormSheet(
        initialProductId: widget.initialProductId,
        headerAction: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
          ),
        ),
        headerBelowTitle: isAdmin ? _buildTypeToggle() : null,
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: _buildToggleOption('Penjualan', TransactionType.sale, AppColors.income)),
          Expanded(child: _buildToggleOption('Stok Masuk', TransactionType.purchase, AppColors.expense)),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, TransactionType type, Color color) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () {
        if (type != _type) setState(() => _type = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyle.labelLg.copyWith(color: selected ? Colors.white : AppColors.textMuted)),
      ),
    );
  }
}
