import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/transaction/transaction_cubit.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_text_field.dart';
import 'package:ngekas/widget/app_toast.dart';
import 'package:ngekas/widget/category_dropdown_field.dart';

class AddTransactionSheet extends StatefulWidget {
  final String ownerId;
  final CategoryType initialType;

  const AddTransactionSheet({super.key, required this.ownerId, required this.initialType});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late CategoryType _type = widget.initialType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransactionCubit>(
      key: ValueKey(_type),
      create: (_) => TransactionCubit(ownerId: widget.ownerId, type: _type),
      child: _AddTransactionForm(
        ownerId: widget.ownerId,
        type: _type,
        onTypeChanged: (type) => setState(() => _type = type),
      ),
    );
  }
}

class _AddTransactionForm extends StatefulWidget {
  final String ownerId;
  final CategoryType type;
  final ValueChanged<CategoryType> onTypeChanged;

  const _AddTransactionForm({required this.ownerId, required this.type, required this.onTypeChanged});

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _categoryId;
  String _categoryName = '';
  DateTime _date = DateTime.now();

  bool get _isIncome => widget.type == CategoryType.income;

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    context.read<TransactionCubit>().addTransaction(
      categoryId: _categoryId!,
      categoryName: _categoryName,
      itemName: _itemNameController.text.trim(),
      quantity: int.tryParse(_quantityController.text) ?? 1,
      amount: int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0,
      date: _date,
      note: _noteController.text.trim(),
    );
  }

  void _handleTypeChanged(CategoryType type) {
    if (type == widget.type) return;
    setState(() {
      _categoryId = null;
      _categoryName = '';
    });
    widget.onTypeChanged(type);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        // Sheet lama yang masih animasi tutup (mis. abis ganti tipe, cubit
        // lama close()) bisa ikut kebagian emit sisa — abaikan kalau route
        // ini sudah bukan yang teratas lagi (sama pola dengan ReportEntryFormSheet).
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

        if (state.status == TransactionStatus.addSuccess) {
          Navigator.of(context).pop();
          AppToast.showSuccess(context, 'Laporan ditambahkan');
        } else if (state.status == TransactionStatus.addError) {
          AppDialog.showError(context, title: 'Gagal', message: state.errorMessage);
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_isIncome ? 'Tambah Pemasukan' : 'Tambah Pengeluaran', style: AppTextStyle.titleLg),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTypeToggle(),
            const SizedBox(height: 20),
            const Text('Kategori', style: AppTextStyle.labelLg),
            const SizedBox(height: 8),
            CategoryDropdownField(
              ownerId: widget.ownerId,
              type: widget.type,
              value: _categoryId,
              onChanged: (category) => setState(() {
                _categoryId = category?.id;
                _categoryName = category?.name ?? '';
              }),
              validator: (value) => value == null ? 'Pilih kategori dulu' : null,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    label: 'Nama Item',
                    hint: 'Nama Item',
                    controller: _itemNameController,
                    isRequired: true,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Nama Item wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: 'Jumlah',
                    hint: '1',
                    type: FieldType.number,
                    controller: _quantityController,
                    isRequired: true,
                    validator: (value) {
                      final n = int.tryParse(value ?? '');
                      if (n == null || n < 1) return 'Min. 1';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Nominal',
              hint: '0',
              type: FieldType.currency,
              controller: _amountController,
              isRequired: true,
              validator: (value) {
                final digits = (value ?? '').replaceAll('.', '');
                if (digits.isEmpty || int.tryParse(digits) == 0) return 'Nominal wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Tanggal', style: AppTextStyle.labelLg),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(AppDate.format(_date)),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Catatan',
              hint: 'Opsional',
              type: FieldType.multiline,
              controller: _noteController,
              isRequired: false,
              showRequiredMark: false,
            ),
            const SizedBox(height: 20),
            BlocSelector<TransactionCubit, TransactionState, bool>(
              selector: (state) => state.isSubmitting,
              builder: (context, isSubmitting) =>
                  AppButton(label: 'Simpan', isLoading: isSubmitting, onPressed: _handleSave),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: _buildToggleOption('Pemasukan', CategoryType.income, AppColors.income)),
          Expanded(child: _buildToggleOption('Pengeluaran', CategoryType.expense, AppColors.expense)),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, CategoryType type, Color color) {
    final selected = widget.type == type;
    return GestureDetector(
      onTap: () => _handleTypeChanged(type),
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
