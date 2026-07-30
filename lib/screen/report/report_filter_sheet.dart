import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/transaction/transaction_cubit.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/report_logic.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/category_dropdown_field.dart';

// ─── ReportFilterSheet ──────────────────────────────────────────────────────
//
// Isi bottom sheet filter dari tombol filter di AppBar ReportScreen.

class ReportFilterSheet extends StatefulWidget {
  const ReportFilterSheet({super.key});

  @override
  State<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<ReportFilterSheet> {
  late final TransactionCubit _cubit;
  DateTimeRange? _dateRange;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<TransactionCubit>();
    _dateRange = _cubit.state.filter.dateRange;
    _categoryId = _cubit.state.filter.categoryId;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter Laporan', style: AppTextStyle.titleLg),
        const SizedBox(height: 20),
        Text('Rentang Tanggal', style: AppTextStyle.labelLg),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickDateRange,
          icon: const Icon(Icons.calendar_today_rounded, size: 18),
          label: Text(
            _dateRange == null
                ? 'Pilih rentang tanggal'
                : '${AppDate.format(_dateRange!.start)} — ${AppDate.format(_dateRange!.end)}',
          ),
        ),
        const SizedBox(height: 20),
        Text('Kategori', style: AppTextStyle.labelLg),
        const SizedBox(height: 8),
        CategoryDropdownField(
          ownerId: _cubit.ownerId,
          type: _cubit.type,
          value: _categoryId,
          includeAllOption: true,
          hintText: 'Semua Kategori',
          onChanged: (category) => setState(() => _categoryId = category?.id),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ReportLogic.resetFilter(context),
                child: const Text('Reset Filter'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Terapkan',
                onPressed: () => ReportLogic.applyFilter(
                  context,
                  dateRange: _dateRange,
                  categoryId: _categoryId,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
