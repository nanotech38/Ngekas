import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/cashier/cashier_cubit.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/cart_item_model.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_text_field.dart';

class CheckoutSheet extends StatefulWidget {
  final void Function(String invoiceNo, int total, int cash) onPaid;

  const CheckoutSheet({super.key, required this.onPaid});

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _noteController = TextEditingController();

  int get _cash => int.tryParse(_cashController.text.replaceAll('.', '')) ?? 0;

  @override
  void dispose() {
    _cashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _setCash(int amount) {
    setState(() => _cashController.text = AppCurrency.formatDigits(amount));
  }

  void _handlePay() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CashierCubit>().checkout(note: _noteController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CashierCubit, CashierState>(
      listener: (context, state) {
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

        if (state.status == CashierStatus.checkoutSuccess) {
          final cash = _cash;
          Navigator.of(context).pop();
          widget.onPaid(state.lastInvoiceNo, state.lastTotal, cash);
        } else if (state.status == CashierStatus.checkoutError) {
          AppDialog.showError(context, title: 'Pembayaran Gagal', message: state.errorMessage);
        } else if (state.items.isEmpty && !state.isSubmitting) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final total = state.total;
        final change = _cash - total;

        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pembayaran', style: AppTextStyle.titleLg),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, index) => _buildCartRow(state.items[index]),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(child: Text('Total (${state.totalQuantity} item)', style: AppTextStyle.labelLg)),
                    const SizedBox(width: 8),
                    Text(AppCurrency.format(total), style: AppTextStyle.titleLg.copyWith(color: AppColors.primaryDark)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Uang Diterima',
                hint: '0',
                type: FieldType.currency,
                controller: _cashController,
                isRequired: true,
                onChanged: (_) => setState(() {}),
                validator: (_) {
                  if (_cash <= 0) return 'Masukkan uang yang diterima';
                  if (_cash < total) return 'Uang kurang ${AppCurrency.format(total - _cash)}';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _buildQuickButton('Uang Pas', total),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Kembalian', style: AppTextStyle.labelLg),
                  const Spacer(),
                  Text(
                    change >= 0 ? AppCurrency.format(change) : '-',
                    style: AppTextStyle.titleMd.copyWith(color: change >= 0 ? AppColors.success : AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Catatan',
                hint: 'Opsional, mis. nama pelanggan',
                controller: _noteController,
                isRequired: false,
                showRequiredMark: false,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              AppButton(label: 'Bayar & Selesai', isLoading: state.isSubmitting, onPressed: _handlePay),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartRow(CartItem item) {
    final cubit = context.read<CashierCubit>();
    final canAdd = item.quantity < item.product.stock;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: AppTextStyle.labelLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${AppCurrency.format(item.product.sellPrice)} · ${AppCurrency.format(item.subtotal)}',
                  style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _buildStepButton(Icons.remove_rounded, () => cubit.decrement(item.product)),
          SizedBox(
            width: 32,
            child: Text('${item.quantity}', textAlign: TextAlign.center, style: AppTextStyle.titleSm),
          ),
          _buildStepButton(Icons.add_rounded, canAdd ? () => cubit.add(item.product) : null),
        ],
      ),
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: onTap == null ? AppColors.surfaceVariant : AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: onTap == null ? AppColors.textDisabled : AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, int amount) {
    final selected = _cash == amount;
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _setCash(amount),
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
