import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/screen/cashier/product_picker_sheet.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/services/product_service.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';

class LinkBarcodeSheet extends StatefulWidget {
  final String barcode;
  final String source;

  const LinkBarcodeSheet({super.key, required this.barcode, required this.source});

  static Future<ProductUnitMatch?> show(BuildContext context, {required String barcode, required String source}) {
    return AppBottomSheet.show<ProductUnitMatch>(
      context,
      builder: (_) => LinkBarcodeSheet(barcode: barcode, source: source),
    );
  }

  @override
  State<LinkBarcodeSheet> createState() => _LinkBarcodeSheetState();
}

enum _Target { base, pack, newPack }

class _LinkBarcodeSheetState extends State<LinkBarcodeSheet> {
  ProductModel? _product;
  _Target _target = _Target.base;
  ProductPack? _pack;
  final _packNameController = TextEditingController(text: 'Dus');
  final _packFactorController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _packNameController.dispose();
    _packFactorController.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final product = await ProductPickerSheet.show(
      context,
      title: 'Hubungkan ke Barang',
      subtitle: 'Pilih barang yang sama dengan barang yang di-scan.',
      allowOutOfStock: true,
    );
    if (product == null || !mounted) return;
    setState(() {
      _product = product;
      _target = _Target.base;
      _pack = null;
    });
  }

  String? get _validationError {
    if (_product == null) return 'Pilih barangnya dulu';
    if (_target == _Target.pack && _pack == null) return 'Pilih kemasannya';
    if (_target == _Target.newPack) {
      final name = _packNameController.text.trim();
      if (name.isEmpty) return 'Isi nama kemasan';
      if (_product!.packs.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
        return 'Kemasan "$name" sudah ada — pilih dari daftar';
      }
      if ((int.tryParse(_packFactorController.text) ?? 0) < 2) return 'Isi kemasan minimal 2 ${_product!.unit}';
    }
    return null;
  }

  Future<void> _submit() async {
    final product = _product!;
    setState(() => _isSubmitting = true);
    try {
      final packName = switch (_target) {
        _Target.base => null,
        _Target.pack => _pack!.name,
        _Target.newPack => _packNameController.text.trim(),
      };
      final match = await ProductService.linkBarcode(
        productId: product.id,
        barcode: widget.barcode,
        packName: packName,
        packFactor: _target == _Target.newPack ? int.parse(_packFactorController.text) : null,
      );
      await ActivityLogService.log(
        action: ActivityAction.updated,
        entity: ActivityEntity.product,
        subject: product.name,
        details: [
          ActivityDetail('Barcode Baru', widget.barcode),
          ActivityDetail(
            'Sebagai',
            match.pack == null ? 'Satuan dasar (${product.unit})' : match.pack!.label(product.unit),
          ),
          if (_target == _Target.newPack) const ActivityDetail('Kemasan', 'Kemasan baru ditambahkan'),
          ActivityDetail('Dihubungkan dari', widget.source),
        ],
        description: 'Barcode ${widget.barcode} dihubungkan ke ${product.name} (${match.unitName})',
      );
      if (mounted) Navigator.of(context).pop(match);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppDialog.showError(context, title: 'Gagal', message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final error = _validationError;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hubungkan Barcode', style: AppTextStyle.titleLg),
        const SizedBox(height: 4),
        const Text(
          'Barcode ini belum terdaftar. Kalau barangnya sudah ada di Gudang (mis. kemasan baru / beda '
          'distributor), hubungkan supaya scan berikutnya langsung dikenali.',
          style: AppTextStyle.bodySm,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.barcode, style: AppTextStyle.titleSm)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('1. Barang', style: AppTextStyle.labelLg),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickProduct,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: product == null ? AppColors.primary : AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: product == null ? AppColors.primary : AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      product?.name ?? 'Pilih barang...',
                      style: AppTextStyle.labelLg.copyWith(color: product == null ? AppColors.primary : null),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                ],
              ),
            ),
          ),
        ),
        if (product != null) ...[
          const SizedBox(height: 16),
          const Text('2. Barcode ini untuk satuan apa?', style: AppTextStyle.labelLg),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('Per ${product.unit}'),
                selected: _target == _Target.base,
                onSelected: (_) => setState(() => _target = _Target.base),
              ),
              for (final pack in product.packs)
                ChoiceChip(
                  label: Text(pack.label(product.unit)),
                  selected: _target == _Target.pack && identical(_pack, pack),
                  onSelected: (_) => setState(() {
                    _target = _Target.pack;
                    _pack = pack;
                  }),
                ),
              ChoiceChip(
                avatar: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Kemasan baru'),
                selected: _target == _Target.newPack,
                onSelected: (_) => setState(() => _target = _Target.newPack),
              ),
            ],
          ),
          if (_target == _Target.newPack) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _packNameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Nama kemasan', hintText: 'Dus, Box'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _packFactorController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: 'Isi (${product.unit})', hintText: '12'),
                  ),
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 20),
        if (error != null && product != null) ...[
          Text(error, style: AppTextStyle.labelSm.copyWith(color: AppColors.error)),
          const SizedBox(height: 8),
        ],
        AppButton(
          label: 'Hubungkan Barcode',
          icon: Icons.link_rounded,
          isLoading: _isSubmitting,
          onPressed: error == null ? _submit : null,
        ),
      ],
    );
  }
}
