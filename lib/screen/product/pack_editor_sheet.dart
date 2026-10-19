import 'package:flutter/material.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/screen/product/barcode_list_editor.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_text_field.dart';

// ─── PackEditorSheet ────────────────────────────────────────────────────────
//
// Tambah/ubah satu satuan kemasan barang: nama (Dus/Box/Pak), isi dalam
// satuan dasar, dan barcode kemasan (boleh lebih dari satu). Mengembalikan
// ProductPack lewat Navigator.pop.

class PackEditorSheet extends StatefulWidget {
  final String baseUnit;
  final ProductPack? existing;
  final String? productId;
  // Nama kemasan lain di barang ini (tidak boleh sama).
  final Set<String> otherNames;
  // Barcode lain di form barang (satuan dasar & kemasan lain).
  final Set<String> takenInForm;

  const PackEditorSheet({
    super.key,
    required this.baseUnit,
    this.existing,
    this.productId,
    this.otherNames = const {},
    this.takenInForm = const {},
  });

  static Future<ProductPack?> show(
    BuildContext context, {
    required String baseUnit,
    ProductPack? existing,
    String? productId,
    Set<String> otherNames = const {},
    Set<String> takenInForm = const {},
  }) {
    return AppBottomSheet.show<ProductPack>(
      context,
      builder: (_) => PackEditorSheet(
        baseUnit: baseUnit,
        existing: existing,
        productId: productId,
        otherNames: otherNames,
        takenInForm: takenInForm,
      ),
    );
  }

  @override
  State<PackEditorSheet> createState() => _PackEditorSheetState();
}

class _PackEditorSheetState extends State<PackEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _factorController;
  late List<String> _barcodes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? 'Dus');
    _factorController = TextEditingController(text: widget.existing == null ? '' : '${widget.existing!.factor}');
    _barcodes = [...?widget.existing?.barcodes];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _factorController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ProductPack(
        name: _nameController.text.trim(),
        factor: int.parse(_factorController.text),
        barcodes: _barcodes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final factor = int.tryParse(_factorController.text) ?? 0;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.existing == null ? 'Tambah Kemasan' : 'Ubah Kemasan', style: AppTextStyle.titleLg),
          const SizedBox(height: 4),
          Text(
            'Mis. Dus isi 12 ${widget.baseUnit}. Scan barcode kemasan = stok/jumlah otomatis dikali isinya.',
            style: AppTextStyle.bodySm,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Nama Kemasan',
                  hint: 'Dus, Box, Pak',
                  controller: _nameController,
                  isRequired: true,
                  validator: (v) {
                    final name = (v ?? '').trim();
                    if (name.isEmpty) return 'Wajib diisi';
                    if (name.toLowerCase() == widget.baseUnit.toLowerCase()) return 'Sama dengan satuan dasar';
                    if (widget.otherNames.contains(name.toLowerCase())) return 'Nama sudah dipakai';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Isi (${widget.baseUnit})',
                  hint: '12',
                  type: FieldType.number,
                  controller: _factorController,
                  isRequired: true,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 2 ? 'Minimal 2' : null,
                ),
              ),
            ],
          ),
          if (factor >= 2) ...[
            const SizedBox(height: 6),
            Text(
              '1 ${_nameController.text.trim().isEmpty ? 'kemasan' : _nameController.text.trim()} = $factor ${widget.baseUnit}',
              style: AppTextStyle.labelMd.copyWith(color: AppColors.primaryDark),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Barcode Kemasan', style: AppTextStyle.labelLg),
          const SizedBox(height: 8),
          BarcodeListEditor(
            barcodes: _barcodes,
            productId: widget.productId,
            takenInForm: widget.takenInForm,
            emptyText: 'Opsional — kosongkan kalau kemasannya tidak punya barcode',
            onChanged: (list) => setState(() => _barcodes = list),
          ),
          const SizedBox(height: 24),
          AppButton(label: widget.existing == null ? 'Tambah Kemasan' : 'Simpan Kemasan', onPressed: _save),
        ],
      ),
    );
  }
}
