import 'package:flutter/material.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/screen/product/barcode_scanner_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/services/product_service.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_toast.dart';

class BarcodeListEditor extends StatefulWidget {
  final List<String> barcodes;
  final ValueChanged<List<String>> onChanged;
  final String? productId;
  final Set<String> takenInForm;
  final String emptyText;

  const BarcodeListEditor({
    super.key,
    required this.barcodes,
    required this.onChanged,
    this.productId,
    this.takenInForm = const {},
    this.emptyText = 'Belum ada barcode',
  });

  @override
  State<BarcodeListEditor> createState() => _BarcodeListEditorState();
}

class _BarcodeListEditorState extends State<BarcodeListEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final code = raw.trim();
    if (code.isEmpty) return;
    if (widget.barcodes.contains(code) || widget.takenInForm.contains(code)) {
      AppToast.showWarning(context, 'Barcode $code sudah ada di barang ini');
      return;
    }
    final owner = ProductService.findByBarcode(code, exceptId: widget.productId);
    if (owner != null) {
      AppDialog.showWarning(
        context,
        title: 'Barcode Sudah Terdaftar',
        message: 'Barcode $code sudah dipakai barang "${owner.name}". Satu barcode hanya boleh untuk satu barang.',
      );
      return;
    }
    widget.onChanged([...widget.barcodes, code]);
    _controller.clear();
  }

  Future<void> _scan() async {
    FocusScope.of(context).unfocus();
    final result = await NavigationService.get().push(const BarcodeScannerScreen());
    if (!mounted || result is! String || result.isEmpty) return;
    _add(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.barcodes.isEmpty)
          Text(widget.emptyText, style: AppTextStyle.labelSm.copyWith(color: AppColors.textDisabled))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final code in widget.barcodes)
                InputChip(
                  avatar: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: Text(code, style: AppTextStyle.labelMd),
                  onDeleted: () => widget.onChanged([...widget.barcodes]..remove(code)),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onSubmitted: _add,
                style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ketik barcode lalu tekan +',
                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: AppFontSize.sm),
                  isDense: true,
                  suffixIcon: IconButton(
                    tooltip: 'Tambah',
                    icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                    onPressed: () => _add(_controller.text),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Scan'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                minimumSize: Size.zero,
                textStyle: AppTextStyle.labelMd,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
