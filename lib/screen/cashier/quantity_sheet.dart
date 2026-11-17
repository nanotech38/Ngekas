import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_button.dart';

class QuantitySheet extends StatefulWidget {
  final ProductModel product;
  final int currentQuantity;
  final ProductPack? initialPack;

  const QuantitySheet({super.key, required this.product, this.currentQuantity = 0, this.initialPack});

  static Future<int?> show(
    BuildContext context,
    ProductModel product, {
    int currentQuantity = 0,
    ProductPack? initialPack,
  }) {
    return AppBottomSheet.show<int>(
      context,
      builder: (_) => QuantitySheet(product: product, currentQuantity: currentQuantity, initialPack: initialPack),
    );
  }

  @override
  State<QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<QuantitySheet> {
  late final TextEditingController _controller;
  late ProductPack? _pack = widget.initialPack;

  bool get _isEdit => widget.currentQuantity > 0;
  int get _factor => _pack?.factor ?? 1;
  String get _unitName => _pack?.name ?? widget.product.unit;
  int get _max => widget.product.stock ~/ _factor;
  int get _quantity => int.tryParse(_controller.text) ?? 0;
  int get _baseQuantity => _quantity * _factor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${_isEdit && _pack == null ? widget.currentQuantity : 1}');
  }

  void _selectPack(ProductPack? pack) {
    setState(() {
      _pack = pack;
      _controller.text = '1';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuantity(int value) {
    // _max bisa 0 kalau sisa stok kurang dari 1 kemasan
    final clamped = _max < 1 ? 1 : value.clamp(1, _max);
    setState(() {
      _controller.text = '$clamped';
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  String? get _error {
    if (_quantity < 1) return 'Jumlah minimal 1';
    if (_quantity > _max) {
      return _pack == null
          ? 'Stok hanya ${widget.product.stock} ${widget.product.unit}'
          : 'Stok hanya ${widget.product.stock} ${widget.product.unit} (maks. $_max $_unitName)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final error = _error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isEdit ? 'Ubah Jumlah' : 'Berapa yang dibeli?', style: AppTextStyle.titleLg),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTextStyle.titleSm),
                    const SizedBox(height: 2),
                    Text(
                      '${AppCurrency.format(product.sellPrice)} / ${product.unit} · Stok ${product.stock} ${product.unit}',
                      style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (product.packs.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Satuan', style: AppTextStyle.labelLg),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(product.unit),
                selected: _pack == null,
                onSelected: (_) => _selectPack(null),
              ),
              for (final pack in product.packs)
                ChoiceChip(
                  label: Text(pack.label(product.unit)),
                  selected: identical(_pack, pack),
                  onSelected: (_) => _selectPack(pack),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepButton(Icons.remove_rounded, _quantity > 1 ? () => _setQuantity(_quantity - 1) : null),
            const SizedBox(width: 16),
            SizedBox(
              width: 96,
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyle.h3.copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(vertical: 10)),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            _buildStepButton(Icons.add_rounded, _quantity < _max ? () => _setQuantity(_quantity + 1) : null),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            error ??
                (_pack == null
                    ? 'Subtotal ${AppCurrency.format(product.sellPrice * _baseQuantity)}'
                    : '$_quantity $_unitName = $_baseQuantity ${product.unit} · '
                          '${AppCurrency.format(product.sellPrice * _baseQuantity)}'),
            textAlign: TextAlign.center,
            style: AppTextStyle.labelLg.copyWith(color: error != null ? AppColors.error : AppColors.primaryDark),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: _isEdit ? 'Simpan Jumlah' : 'Masukkan ke Keranjang',
          icon: _isEdit ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
          onPressed: error == null ? () => Navigator.of(context).pop(_baseQuantity) : null,
        ),
        if (_isEdit) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(0),
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
              label: const Text('Keluarkan dari Keranjang', style: TextStyle(color: AppColors.error)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: onTap == null ? AppColors.surfaceVariant : AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: onTap == null ? AppColors.textDisabled : Colors.white),
        ),
      ),
    );
  }
}
