import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/transaction/transaction_cubit.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/category_model.dart' show CategoryType;
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_text_field.dart';
import 'package:ngekas/widget/app_toast.dart';
import 'package:ngekas/widget/category_dropdown_field.dart';

// ─── ReportEntryFormSheet ───────────────────────────────────────────────────
//
// Isi bottom sheet "Tambah Laporan"/"Ubah Laporan" di ReportScreen. Dipisah
// dari report_screen.dart supaya file itu tidak terlalu panjang. Kategori
// sudah difilter sesuai tipe cubit (Pemasukan/Pengeluaran ditentukan lewat
// submenu di Home), jadi form ini tidak perlu tahap pilih tipe lagi.
// `existing` diisi kalau sheet ini dibuka dari tombol "Ubah" di kartu
// laporan — form otomatis terisi data lama dan _handleSave memanggil
// updateTransaction, bukan addTransaction.

class ReportEntryFormSheet extends StatefulWidget {
  final TransactionModel? existing;

  const ReportEntryFormSheet({super.key, this.existing});

  @override
  State<ReportEntryFormSheet> createState() => _ReportEntryFormSheetState();
}

class _ReportEntryFormSheetState extends State<ReportEntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _itemNameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TransactionCubit _cubit;

  String? _categoryId;
  String _categoryName = '';
  late DateTime _date;

  bool get _isIncome => _cubit.type == CategoryType.income;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<TransactionCubit>();

    final existing = widget.existing;
    _itemNameController = TextEditingController(text: existing?.itemName ?? '');
    _quantityController = TextEditingController(text: (existing?.quantity ?? 1).toString());
    _amountController = TextEditingController(text: existing == null ? '' : AppCurrency.formatDigits(existing.amount));
    _noteController = TextEditingController(text: existing?.note ?? '');
    _categoryId = existing?.categoryId;
    _categoryName = existing?.categoryName ?? '';
    _date = existing?.date ?? DateTime.now();
  }

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

    final amount = int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final itemName = _itemNameController.text.trim();

    if (_isEdit) {
      _cubit.updateTransaction(
        id: widget.existing!.id,
        categoryId: _categoryId!,
        categoryName: _categoryName,
        itemName: itemName,
        quantity: quantity,
        amount: amount,
        date: _date,
        note: _noteController.text.trim(),
      );
    } else {
      _cubit.addTransaction(
        categoryId: _categoryId!,
        categoryName: _categoryName,
        itemName: itemName,
        quantity: quantity,
        amount: amount,
        date: _date,
        note: _noteController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        // Sheet lama yang masih animasi tutup bisa ikut kebagian emit ini
        // (lihat catatan yang sama di CategoryScreen) — abaikan kalau route
        // ini sudah bukan yang teratas lagi.
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

        if (state.status == TransactionStatus.addSuccess) {
          Navigator.of(context).pop();
          AppToast.showSuccess(context, 'Laporan ditambahkan');
        } else if (state.status == TransactionStatus.updateSuccess) {
          Navigator.of(context).pop();
          AppToast.showSuccess(context, 'Laporan diperbarui');
        } else if (state.status == TransactionStatus.addError || state.status == TransactionStatus.updateError) {
          AppDialog.showError(context, title: 'Gagal', message: state.errorMessage);
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit
                  ? (_isIncome ? 'Ubah Pemasukan' : 'Ubah Pengeluaran')
                  : (_isIncome ? 'Tambah Pemasukan' : 'Tambah Pengeluaran'),
              style: AppTextStyle.titleLg,
            ),
            const SizedBox(height: 20),
            Text('Kategori', style: AppTextStyle.labelLg),
            const SizedBox(height: 8),
            CategoryDropdownField(
              ownerId: _cubit.ownerId,
              type: _cubit.type,
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
                if (digits.isEmpty || int.tryParse(digits) == 0) {
                  return 'Nominal wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Tanggal', style: AppTextStyle.labelLg),
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
              builder: (context, isSubmitting) => AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Simpan',
                isLoading: isSubmitting,
                onPressed: _handleSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
