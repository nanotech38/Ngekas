import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/sales_report/sales_report_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/category_dropdown_field.dart';

class ReportFilterSheet extends StatefulWidget {
  const ReportFilterSheet({super.key});

  @override
  State<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<ReportFilterSheet> {
  late final SalesReportCubit _cubit;
  String? _categoryId;
  String? _cashierName;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<SalesReportCubit>();
    _categoryId = _cubit.state.categoryId;
    _cashierName = _cubit.state.cashierName;
  }

  void _apply({String? categoryId, String? cashierName}) {
    _cubit.setFilter(categoryId: categoryId, cashierName: cashierName);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthCubit>().state.user?.isAdmin ?? false;
    final cashiers = _cubit.state.cashierNames;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter Laporan', style: AppTextStyle.titleLg),
        const SizedBox(height: 20),
        const Text('Kategori Barang', style: AppTextStyle.labelLg),
        const SizedBox(height: 8),
        CategoryDropdownField(
          value: _categoryId,
          includeAllOption: true,
          hintText: 'Semua Kategori',
          onChanged: (category) => setState(() => _categoryId = category?.id),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 20),
          const Text('Kasir', style: AppTextStyle.labelLg),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('Semua Kasir', _cashierName == null, () => setState(() => _cashierName = null)),
              for (final name in cashiers)
                _buildChip(name, _cashierName == name, () => setState(() => _cashierName = name)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: () => _apply(), child: const Text('Reset Filter')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Terapkan',
                onPressed: () => _apply(categoryId: _categoryId, cashierName: _cashierName),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: AppTextStyle.labelMd.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
