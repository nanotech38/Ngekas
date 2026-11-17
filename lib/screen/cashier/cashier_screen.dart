import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/cashier/cashier_cubit.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/cart_item_model.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/sales_report.dart';
import 'package:ngekas/screen/cashier/checkout_sheet.dart';
import 'package:ngekas/screen/cashier/product_picker_sheet.dart';
import 'package:ngekas/screen/cashier/quantity_sheet.dart';
import 'package:ngekas/screen/product/barcode_scanner_screen.dart';
import 'package:ngekas/screen/product/link_barcode_sheet.dart';
import 'package:ngekas/screen/report/invoice_detail_sheet.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/services/product_service.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_toast.dart';

class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) => const _CashierView();
}

class _CashierView extends StatefulWidget {
  const _CashierView();

  @override
  State<_CashierView> createState() => _CashierViewState();
}

class _CashierViewState extends State<_CashierView> {
  StreamSubscription<List<ProductModel>>? _subscription;
  List<ProductModel> _products = const [];

  @override
  void initState() {
    super.initState();
    _subscription = ProductService.watch().listen((products) {
      if (!mounted) return;
      _products = products;
      context.read<CashierCubit>().syncProducts(products);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  ProductModel _latest(ProductModel product) => _products.where((p) => p.id == product.id).firstOrNull ?? product;

  Future<void> _scanBarcode() async {
    final result = await NavigationService.get().push(const BarcodeScannerScreen());
    if (!mounted || result is! String || result.isEmpty) return;

    final match = ProductService.findByCode(result);
    if (match == null) {
      AppDialog.show(
        context,
        type: AppDialogType.warning,
        title: 'Barcode Belum Terdaftar',
        message:
            'Barcode $result belum terdaftar. Kalau barangnya sudah ada di Gudang (mis. kemasan baru), '
            'hubungkan barcode ini ke barangnya. Kalau barang baru, tambahkan dulu di menu Gudang.',
        confirmText: 'Hubungkan ke Barang',
        cancelText: 'Tutup',
        onConfirm: () => _linkBarcode(result),
      );
      return;
    }
    await _askQuantity(match.product, pack: match.pack);
  }

  Future<void> _linkBarcode(String barcode) async {
    final match = await LinkBarcodeSheet.show(context, barcode: barcode, source: 'Kasir');
    if (!mounted || match == null) return;
    AppToast.showSuccess(context, 'Barcode dihubungkan ke ${match.product.name}');
    await _askQuantity(match.product, pack: match.pack);
  }

  Future<void> _pickManually() async {
    final cart = context.read<CashierCubit>().state;
    final product = await ProductPickerSheet.show(
      context,
      cartQuantities: {for (final item in cart.items) item.product.id: item.quantity},
    );
    if (!mounted || product == null) return;
    await _askQuantity(product);
  }

  // kalau yg discan barcode kemasan, jumlahnya DITAMBAH ke keranjang.
  // selain itu angka di sheet = total di keranjang.
  Future<void> _askQuantity(ProductModel product, {ProductPack? pack}) async {
    final latest = _latest(product);
    final cubit = context.read<CashierCubit>();
    final current = cubit.state.quantityOf(latest.id);

    if (latest.isOutOfStock && current == 0) {
      AppToast.showWarning(context, 'Stok ${latest.name} sedang habis');
      return;
    }

    if (pack != null) {
      if (latest.stock - current <= 0) {
        AppToast.showWarning(context, 'Semua stok ${latest.name} sudah ada di keranjang');
        return;
      }
      final added = await QuantitySheet.show(
        context,
        latest.copyWith(stock: latest.stock - current),
        initialPack: latest.packs.where((p) => p.name == pack.name).firstOrNull ?? pack,
      );
      if (!mounted || added == null || added == 0) return;
      if (cubit.setQuantity(latest, current + added)) {
        AppToast.showSuccess(context, '${latest.name} +$added ${latest.unit} (total ${current + added})');
      } else {
        AppToast.showWarning(context, 'Stok ${latest.name} hanya ${latest.stock} ${latest.unit}');
      }
      return;
    }

    final quantity = await QuantitySheet.show(context, latest, currentQuantity: current);
    if (!mounted || quantity == null) return;

    if (quantity == 0) {
      cubit.remove(latest);
      AppToast.showSuccess(context, '${latest.name} dikeluarkan dari keranjang');
    } else if (cubit.setQuantity(latest, quantity)) {
      AppToast.showSuccess(context, '${latest.name} ×$quantity di keranjang');
    } else {
      AppToast.showWarning(context, 'Stok ${latest.name} hanya ${latest.stock} ${latest.unit}');
    }
  }

  void _openCheckout() {
    final cubit = context.read<CashierCubit>();
    AppBottomSheet.show(
      context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: CheckoutSheet(onPaid: _showReceipt),
      ),
    );
  }

  Future<void> _showReceipt(String invoiceNo, int total, int cash) async {
    if (!mounted) return;
    final lines = DatabaseService.instance.transactions.rows.where((t) => t.invoiceNo == invoiceNo).toList();
    if (lines.isEmpty) {
      NavigationService.get().popUntilHome();
      return;
    }
    final first = lines.first;
    final invoice = SalesInvoice(
      key: invoiceNo,
      invoiceNo: invoiceNo,
      date: first.date,
      actorName: first.actorName,
      note: first.note,
      lines: lines,
    );
    await AppBottomSheet.show(
      context,
      builder: (_) => InvoiceDetailSheet(invoice: invoice, cash: cash, justSaved: true),
    );
    if (mounted) NavigationService.get().popUntilHome();
  }

  void _confirmClear() {
    AppDialog.show(
      context,
      type: AppDialogType.warning,
      title: 'Kosongkan Keranjang?',
      message: 'Semua barang di keranjang akan dihapus.',
      confirmText: 'Kosongkan',
      cancelText: 'Batal',
      onConfirm: () => context.read<CashierCubit>().clear(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kasir')),
      child: BlocBuilder<CashierCubit, CashierState>(
        builder: (context, cart) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    _buildStepGuide(hasItems: cart.items.isNotEmpty),
                    const SizedBox(height: 14),
                    _buildAddButtons(hasItems: cart.items.isNotEmpty),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: cart.items.isEmpty ? _buildEmptyCart() : _buildCart(cart)),
              if (cart.items.isNotEmpty) _buildPayBar(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepGuide({required bool hasItems}) {
    final activeStep = hasItems ? 3 : 1;
    const steps = ['Pilih barang', 'Isi jumlah', 'Bayar'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(top: 13),
                color: i < activeStep ? AppColors.primary : AppColors.border,
              ),
            ),
          _buildStep(number: i + 1, label: steps[i], active: i + 1 == activeStep, done: i + 1 < activeStep),
        ],
      ],
    );
  }

  Widget _buildStep({required int number, required String label, required bool active, required bool done}) {
    final highlighted = active || done;
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlighted ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: highlighted ? AppColors.primary : AppColors.border, width: 1.5),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '$number',
                    style: AppTextStyle.labelMd.copyWith(color: highlighted ? Colors.white : AppColors.textMuted),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTextStyle.labelSm.copyWith(
              color: active ? AppColors.primaryDark : AppColors.textMuted,
              fontWeight: active ? AppFontWeight.bold : AppFontWeight.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButtons({required bool hasItems}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hasItems ? 'Tambah barang lain:' : 'Tambahkan barang yang dibeli pelanggan:', style: AppTextStyle.labelLg),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildBigButton(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan Barcode',
                filled: true,
                onTap: _scanBarcode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBigButton(
                icon: Icons.list_alt_rounded,
                label: 'Pilih Manual',
                filled: false,
                onTap: _pickManually,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBigButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final foreground = filled ? Colors.white : AppColors.primary;
    return Material(
      color: filled ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: foreground, size: 28),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyle.labelLg.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('Keranjang masih kosong', style: AppTextStyle.titleSm),
            const SizedBox(height: 4),
            Text(
              'Scan barcode di kemasan barang, atau ketuk "Pilih Manual" untuk memilih dari daftar barang.',
              style: AppTextStyle.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart(CashierState cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Keranjang (${cart.items.length} barang)', style: AppTextStyle.titleSm),
                    Text(
                      'Ketuk barang untuk ubah jumlah atau keluarkan',
                      style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _confirmClear,
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                label: const Text('Kosongkan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: AppTextStyle.labelMd,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: cart.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildCartTile(cart.items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCartTile(CartItem item) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _askQuantity(item.product),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Text('${item.quantity}×', style: AppTextStyle.labelLg.copyWith(color: AppColors.primaryDark)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name, style: AppTextStyle.labelLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${AppCurrency.format(item.product.sellPrice)} × ${item.quantity} ${item.product.unit}',
                      style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(AppCurrency.format(item.subtotal), style: AppTextStyle.titleSm),
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, size: 16, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayBar(CashierState cart) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total ${cart.totalQuantity} item',
                    style: AppTextStyle.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppCurrency.format(cart.total),
                      style: AppTextStyle.titleLg.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openCheckout,
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('Bayar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
