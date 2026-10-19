import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/transaction/transaction_cubit.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_text_field.dart';
import 'package:ngekas/widget/app_toast.dart';
import 'package:ngekas/widget/product_dropdown_field.dart';

// ─── ReportEntryFormSheet ───────────────────────────────────────────────────
//
// Isi bottom sheet "Tambah/Ubah Penjualan" atau "Tambah/Ubah Pembelian Stok".
// Tipe transaksi mengikuti TransactionCubit yang di-provide pemanggil
// (ReportScreen atau AddTransactionSheet). Harga satuan otomatis terisi dari
// harga jual/beli barang yang dipilih (tetap bisa diubah, mis. ada diskon).
// `existing` diisi kalau dibuka dari tombol "Ubah" di kartu transaksi.

class ReportEntryFormSheet extends StatefulWidget {
  final TransactionModel? existing;
  final String? initialProductId;
  // Widget tambahan di samping & di bawah judul (dipakai AddTransactionSheet
  // untuk tombol tutup & toggle tipe).
  final Widget? headerAction;
  final Widget? headerBelowTitle;

  const ReportEntryFormSheet({
    super.key,
    this.existing,
    this.initialProductId,
    this.headerAction,
    this.headerBelowTitle,
  });

  @override
  State<ReportEntryFormSheet> createState() => _ReportEntryFormSheetState();
}

class _ReportEntryFormSheetState extends State<ReportEntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _noteController;
  late final TransactionCubit _cubit;

  String? _productId;
  late DateTime _date;

  bool get _isSale => _cubit.type == TransactionType.sale;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<TransactionCubit>();

    final existing = widget.existing;
    _quantityController = TextEditingController(text: (existing?.quantity ?? 1).toString());
    _unitPriceController = TextEditingController(
      text: existing == null ? '' : AppCurrency.formatDigits(existing.unitPrice),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _productId = existing?.productId ?? widget.initialProductId;
    _date = existing?.date ?? DateTime.now();

    if (existing == null && _productId != null) {
      final product = DatabaseService.instance.products.find(_productId!);
      if (product != null) _unitPriceController.text = _priceText(product);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int _priceOf(ProductModel product) => _isSale ? product.sellPrice : product.buyPrice;

  // Harga beli boleh kosong (0) — biarkan field kosong supaya user isi sendiri.
  String _priceText(ProductModel product) {
    final price = _priceOf(product);
    return price > 0 ? AppCurrency.formatDigits(price) : '';
  }

  int get _quantity => int.tryParse(_quantityController.text) ?? 0;
  int get _unitPrice => int.tryParse(_unitPriceController.text.replaceAll('.', '')) ?? 0;

  // Stok yang bisa dijual untuk barang terpilih. Saat mengubah penjualan
  // barang yang sama, jumlah lama dihitung "kembali" ke stok.
  int? get _availableStock {
    if (_productId == null) return null;
    final product = DatabaseService.instance.products.find(_productId!);
    if (product == null) return null;
    final existing = widget.existing;
    final reserved = (existing != null && existing.productId == _productId) ? existing.quantity : 0;
    return product.stock + reserved;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  void _handleProductChanged(ProductModel? product) {
    setState(() {
      _productId = product?.id;
      if (product != null) _unitPriceController.text = _priceText(product);
    });
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    if (_isEdit) {
      _cubit.updateTransaction(
        id: widget.existing!.id,
        productId: _productId!,
        quantity: _quantity,
        unitPrice: _unitPrice,
        date: _date,
        note: _noteController.text.trim(),
      );
    } else {
      _cubit.addTransaction(
        productId: _productId!,
        quantity: _quantity,
        unitPrice: _unitPrice,
        date: _date,
        note: _noteController.text.trim(),
      );
    }
  }

  String get _title {
    final label = _isSale ? 'Penjualan' : 'Pembelian Stok';
    return _isEdit ? 'Ubah $label' : 'Tambah $label';
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableStock;

    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        // Sheet lama yang masih animasi tutup bisa ikut kebagian emit ini —
        // abaikan kalau route ini sudah bukan yang teratas lagi.
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

        if (state.status == TransactionStatus.addSuccess) {
          Navigator.of(context).pop();
          AppToast.showSuccess(context, '${_isSale ? 'Penjualan' : 'Stok masuk'} dicatat');
        } else if (state.status == TransactionStatus.updateSuccess) {
          Navigator.of(context).pop();
          AppToast.showSuccess(context, 'Transaksi diperbarui');
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
            Row(
              children: [
                Expanded(child: Text(_title, style: AppTextStyle.titleLg)),
                if (widget.headerAction != null) widget.headerAction!,
              ],
            ),
            if (widget.headerBelowTitle != null) ...[const SizedBox(height: 16), widget.headerBelowTitle!],
            const SizedBox(height: 20),
            const Text('Barang', style: AppTextStyle.labelLg),
            const SizedBox(height: 8),
            ProductDropdownField(
              value: _productId,
              showBuyPrice: !_isSale,
              onChanged: _handleProductChanged,
              validator: (value) => value == null ? 'Pilih barang dulu' : null,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: 'Jumlah',
                    hint: '1',
                    type: FieldType.number,
                    controller: _quantityController,
                    isRequired: true,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final n = int.tryParse(value ?? '');
                      if (n == null || n < 1) return 'Min. 1';
                      if (_isSale && available != null && n > available) return 'Maks. $available';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    label: _isSale ? 'Harga Jual Satuan' : 'Harga Beli Satuan',
                    hint: '0',
                    type: FieldType.currency,
                    controller: _unitPriceController,
                    isRequired: true,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final digits = (value ?? '').replaceAll('.', '');
                      if (digits.isEmpty || int.tryParse(digits) == 0) return 'Harga wajib diisi';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (available != null) ...[
              const SizedBox(height: 6),
              Text(
                'Stok tersedia: $available',
                style: AppTextStyle.labelSm.copyWith(
                  color: available <= 0 ? AppColors.error : AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _isSale ? AppColors.incomeBackground : AppColors.expenseBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text('Total', style: AppTextStyle.labelLg),
                  const Spacer(),
                  Text(
                    AppCurrency.format(_quantity * _unitPrice),
                    style: AppTextStyle.titleMd.copyWith(color: _isSale ? AppColors.income : AppColors.expense),
                  ),
                ],
              ),
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
              hint: _isSale ? 'Opsional, mis. nama pelanggan' : 'Opsional, mis. nama supplier',
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
