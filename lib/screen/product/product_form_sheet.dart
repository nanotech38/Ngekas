import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/product/product_cubit.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/stock_movement_model.dart';
import 'package:ngekas/screen/product/barcode_list_editor.dart';
import 'package:ngekas/screen/product/pack_editor_sheet.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_text_field.dart';
import 'package:ngekas/widget/app_toast.dart';
import 'package:ngekas/widget/category_dropdown_field.dart';

// ─── ProductFormSheet ───────────────────────────────────────────────────────
//
// Bottom sheet "Tambah Barang" (admin & kasir) / "Ubah Barang" (admin: semua
// field; kasir: nama & stok saja). Isian: nama, kategori, harga jual, satuan
// dasar, stok, barcode satuan dasar (boleh banyak), dan kemasan (mis. Dus isi
// 12, masing-masing dengan barcode). Stok selalu dalam satuan dasar; tombol
// "Tambah per kemasan" membantu input barang datang per dus.
//
// Saat ubah: kalau stok berubah, alasan perubahan WAJIB dipilih (Barang
// Datang / Stock Opname / Rusak / ...) — tercatat di kartu stok & Riwayat
// Aktivitas. Harga beli & kode internal tidak ditampilkan (nilainya tetap
// dibawa saat simpan).

class ProductFormSheet extends StatefulWidget {
  final ProductModel? existing;

  const ProductFormSheet({super.key, this.existing});

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _unitController;
  final _stockNoteController = TextEditingController();
  String? _categoryId;
  late List<String> _barcodes;
  late List<ProductPack> _packs;
  StockAdjustReason? _reason;
  String? _reasonError;

  bool get _isEdit => widget.existing != null;
  int get _stock => int.tryParse(_stockController.text) ?? 0;
  bool get _stockChanged => _isEdit && _stock != widget.existing!.stock;
  String get _unit => _unitController.text.trim().isEmpty ? 'pcs' : _unitController.text.trim();

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameController = TextEditingController(text: p?.name ?? '');
    _sellPriceController = TextEditingController(text: p == null ? '' : AppCurrency.formatDigits(p.sellPrice));
    _stockController = TextEditingController(text: p == null ? '' : p.stock.toString());
    _unitController = TextEditingController(text: p?.unit ?? 'pcs');
    _categoryId = p?.categoryId;
    _barcodes = [...?p?.barcodes];
    _packs = [...?p?.packs];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    _stockNoteController.dispose();
    super.dispose();
  }

  int _parseCurrency(TextEditingController c) => int.tryParse(c.text.replaceAll('.', '')) ?? 0;

  Set<String> _packBarcodes({ProductPack? except}) => {
    for (final pack in _packs)
      if (!identical(pack, except)) ...pack.barcodes,
  };

  // ─── Kemasan ──────────────────────────────────────────────────────────────

  Future<void> _editPack([ProductPack? pack]) async {
    final result = await PackEditorSheet.show(
      context,
      baseUnit: _unit,
      existing: pack,
      productId: widget.existing?.id,
      otherNames: {
        for (final p in _packs)
          if (!identical(p, pack)) p.name.toLowerCase(),
      },
      takenInForm: {..._barcodes, ..._packBarcodes(except: pack)},
    );
    if (result == null || !mounted) return;
    setState(() {
      if (pack == null) {
        _packs = [..._packs, result];
      } else {
        _packs = [for (final p in _packs) identical(p, pack) ? result : p];
      }
    });
  }

  // ─── Stok ─────────────────────────────────────────────────────────────────

  // "Tambah per kemasan": mis. barang datang 13 Dus -> stok + 13 x isi.
  Future<void> _addStockByUnit() async {
    final added = await AppBottomSheet.show<int>(
      context,
      builder: (_) => _AddStockSheet(baseUnit: _unit, packs: _packs),
    );
    if (added == null || added <= 0 || !mounted) return;
    setState(() {
      _stockController.text = '${_stock + added}';
      if (_isEdit) _reason ??= StockAdjustReason.incoming;
    });
  }

  // ─── Simpan ───────────────────────────────────────────────────────────────

  void _handleSave() {
    final formValid = _formKey.currentState!.validate();
    setState(() {
      _reasonError = null;
      if (_stockChanged && _reason == null) _reasonError = 'Pilih alasan perubahan stok';
    });
    if (!formValid || _reasonError != null) return;

    final cubit = context.read<ProductCubit>();
    final p = widget.existing;
    if (p != null) {
      cubit.updateProduct(
        id: p.id,
        barcodes: _barcodes,
        packs: _packs,
        name: _nameController.text.trim(),
        categoryId: _categoryId!,
        unit: _unit,
        buyPrice: p.buyPrice,
        sellPrice: _parseCurrency(_sellPriceController),
        stock: _stock,
        stockReason: _stockChanged ? _reason!.label : '',
        stockNote: _stockChanged ? _stockNoteController.text : '',
      );
    } else {
      cubit.addProduct(
        barcodes: _barcodes,
        packs: _packs,
        name: _nameController.text.trim(),
        categoryId: _categoryId!,
        unit: _unit,
        buyPrice: 0,
        sellPrice: _parseCurrency(_sellPriceController),
        stock: _stock,
      );
    }
  }

  String? _requiredText(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? '$label wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    // Kasir boleh ubah barang tapi cuma nama & stok — field lain disembunyikan
    // (nilainya tetap dari data lama saat disimpan) dan tampil sebagai info.
    final isAdmin = context.read<AuthCubit>().state.user?.isAdmin ?? false;
    final limitedEdit = _isEdit && !isAdmin;

    return BlocListener<ProductCubit, ProductState>(
      listener: (context, state) {
        // Abaikan kalau sheet ini sudah bukan route teratas (mis. masih
        // animasi tutup) supaya tidak pop/toast dobel.
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

        if (state.status == ProductStatus.addSuccess) {
          Navigator.of(context).pop();
          final added = state.lastAdded;
          AppToast.showSuccess(context, added == null ? 'Barang ditambahkan' : '${added.name} ditambahkan');
        } else if (state.status == ProductStatus.updateSuccess) {
          Navigator.of(context).pop();
          AppToast.showSuccess(context, 'Barang diperbarui');
        } else if (state.status == ProductStatus.addError || state.status == ProductStatus.updateError) {
          AppDialog.showError(context, title: 'Gagal', message: state.errorMessage);
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Ubah Barang' : 'Tambah Barang', style: AppTextStyle.titleLg),
            const SizedBox(height: 20),
            if (limitedEdit) ..._buildLimitedFields() else ..._buildFullFields(),
            if (_stockChanged) ...[const SizedBox(height: 16), _buildReasonSection()],
            const SizedBox(height: 20),
            BlocSelector<ProductCubit, ProductState, bool>(
              selector: (state) => state.isSubmitting,
              builder: (context, isSubmitting) => AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Tambah Barang',
                isLoading: isSubmitting,
                onPressed: _handleSave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kasir: nama & stok saja, sisanya info read-only.
  List<Widget> _buildLimitedFields() {
    final p = widget.existing!;
    return [
      AppTextField(
        label: 'Nama Item',
        hint: 'Contoh: Kampas Rem Belakang',
        controller: _nameController,
        isRequired: true,
        validator: (v) => _requiredText(v, 'Nama item'),
      ),
      const SizedBox(height: 16),
      _buildStockField(label: 'Stok Sekarang (${p.unit})'),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Barcode', p.hasBarcode ? p.barcodes.join(', ') : '-'),
            _buildInfoRow(
              'Kemasan',
              p.packs.isEmpty ? '-' : p.packs.map((k) => k.label(p.unit)).join(', '),
            ),
            _buildInfoRow('Kategori', p.categoryName),
            _buildInfoRow('Harga Jual', '${AppCurrency.format(p.sellPrice)} / ${p.unit}'),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Data lain hanya bisa diubah admin.',
                    style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(child: Text(value, style: AppTextStyle.labelMd)),
        ],
      ),
    );
  }

  List<Widget> _buildFullFields() {
    return [
      AppTextField(
        label: 'Nama Item',
        hint: 'Contoh: Kampas Rem Belakang',
        controller: _nameController,
        isRequired: true,
        validator: (v) => _requiredText(v, 'Nama item'),
      ),
      const SizedBox(height: 16),
      const Text('Kategori', style: AppTextStyle.labelLg),
      const SizedBox(height: 8),
      CategoryDropdownField(
        value: _categoryId,
        onChanged: (category) => setState(() => _categoryId = category?.id),
        validator: (value) => value == null ? 'Pilih kategori dulu' : null,
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField(
              label: 'Satuan Dasar',
              hint: 'pcs, botol, bungkus',
              controller: _unitController,
              isRequired: true,
              onChanged: (_) => setState(() {}),
              validator: (v) => _requiredText(v, 'Satuan'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              label: 'Harga Jual / $_unit',
              hint: '0',
              type: FieldType.currency,
              controller: _sellPriceController,
              isRequired: true,
              validator: (v) => _parseCurrency(_sellPriceController) <= 0 ? 'Wajib diisi' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Stok & harga selalu dihitung dalam satuan dasar (satuan terkecil yang dijual).',
        style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
      ),
      const SizedBox(height: 16),
      _buildStockField(label: _isEdit ? 'Stok Sekarang ($_unit)' : 'Stok Awal ($_unit)'),
      const SizedBox(height: 20),
      _buildSectionHeader('Barcode $_unit', 'Boleh lebih dari satu, mis. kemasan lama & baru.'),
      const SizedBox(height: 8),
      BarcodeListEditor(
        barcodes: _barcodes,
        productId: widget.existing?.id,
        takenInForm: _packBarcodes(),
        emptyText: 'Opsional — kosongkan kalau barang tidak punya barcode (mis. baut eceran).',
        onChanged: (list) => setState(() => _barcodes = list),
      ),
      const SizedBox(height: 20),
      _buildSectionHeader('Kemasan', 'Mis. Dus isi 12 — scan barcode dus langsung dihitung 12 $_unit.'),
      const SizedBox(height: 8),
      for (final pack in _packs) _buildPackTile(pack),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _editPack(),
          icon: const Icon(Icons.add_box_outlined, size: 18),
          label: const Text('Tambah Kemasan'),
        ),
      ),
    ];
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyle.labelLg),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildPackTile(ProductPack pack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${pack.name} = ${pack.factor} $_unit', style: AppTextStyle.labelLg),
                const SizedBox(height: 2),
                Text(
                  pack.barcodes.isEmpty ? 'Tanpa barcode' : pack.barcodes.join(', '),
                  style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ubah kemasan',
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
            onPressed: () => _editPack(pack),
          ),
          IconButton(
            tooltip: 'Hapus kemasan',
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
            onPressed: () => setState(() => _packs = [..._packs]..remove(pack)),
          ),
        ],
      ),
    );
  }

  Widget _buildStockField({required String label}) {
    final p = widget.existing;
    final breakdown = (p ?? _previewProduct).packBreakdown(_stock);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: label,
          hint: '0',
          type: FieldType.number,
          controller: _stockController,
          isRequired: true,
          onChanged: (_) => setState(() {}),
          validator: (v) => int.tryParse(v ?? '') == null ? 'Stok wajib diisi' : null,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                breakdown.isEmpty ? '' : '= $breakdown',
                style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
              ),
            ),
            TextButton.icon(
              onPressed: _addStockByUnit,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(_packs.isEmpty ? 'Tambah stok' : 'Tambah per kemasan'),
              style: TextButton.styleFrom(textStyle: AppTextStyle.labelMd),
            ),
          ],
        ),
      ],
    );
  }

  // Barang "sementara" dari isian form, untuk rincian stok per kemasan saat
  // tambah barang.
  ProductModel get _previewProduct => ProductModel(
    id: '',
    sku: '',
    packs: _packs,
    name: '',
    categoryId: '',
    categoryName: '',
    unit: _unit,
    buyPrice: 0,
    sellPrice: 0,
    stock: _stock,
    minStock: 0,
  );

  // Alasan perubahan stok — muncul begitu angka stok diubah saat Ubah Barang.
  Widget _buildReasonSection() {
    final old = widget.existing!.stock;
    final diff = _stock - old;
    final unit = widget.existing!.unit;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _reasonError != null ? AppColors.error : AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_vert_rounded, size: 18, color: Color(0xFFB45309)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Stok $old → $_stock $unit (${diff > 0 ? '+' : ''}$diff)',
                  style: AppTextStyle.labelLg.copyWith(color: const Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Alasan perubahan stok *', style: AppTextStyle.labelMd),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final reason in StockAdjustReason.values)
                ChoiceChip(
                  label: Text(reason.label, style: AppTextStyle.labelMd),
                  selected: _reason == reason,
                  selectedColor: AppColors.primaryContainer,
                  onSelected: (_) => setState(() {
                    _reason = reason;
                    _reasonError = null;
                  }),
                ),
            ],
          ),
          if (_reasonError != null) ...[
            const SizedBox(height: 4),
            Text(_reasonError!, style: AppTextStyle.labelSm.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: 10),
          AppTextField(
            label: 'Catatan',
            hint: _reason == StockAdjustReason.incoming ? 'Mis. nama supplier / No. faktur' : 'Keterangan tambahan',
            controller: _stockNoteController,
            isRequired: _reason == StockAdjustReason.other,
            showRequiredMark: _reason == StockAdjustReason.other,
            validator: (v) =>
                _reason == StockAdjustReason.other && (v ?? '').trim().isEmpty ? 'Jelaskan alasannya' : null,
          ),
        ],
      ),
    );
  }
}

// ─── _AddStockSheet ─────────────────────────────────────────────────────────
//
// Tambah stok per satuan: pilih satuan (dasar / kemasan) + jumlah, hasilnya
// dikembalikan dalam satuan dasar (jumlah x isi kemasan).

class _AddStockSheet extends StatefulWidget {
  final String baseUnit;
  final List<ProductPack> packs;

  const _AddStockSheet({required this.baseUnit, required this.packs});

  @override
  State<_AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<_AddStockSheet> {
  final _controller = TextEditingController(text: '1');
  late ProductPack? _pack = widget.packs.isEmpty ? null : widget.packs.first;

  int get _count => int.tryParse(_controller.text) ?? 0;
  int get _factor => _pack?.factor ?? 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _count * _factor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tambah Stok', style: AppTextStyle.titleLg),
        const SizedBox(height: 4),
        const Text('Mis. barang datang dari supplier.', style: AppTextStyle.bodySm),
        const SizedBox(height: 16),
        const Text('Satuan', style: AppTextStyle.labelLg),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pack in widget.packs)
              ChoiceChip(
                label: Text(pack.label(widget.baseUnit)),
                selected: identical(_pack, pack),
                onSelected: (_) => setState(() => _pack = pack),
              ),
            ChoiceChip(
              label: Text(widget.baseUnit),
              selected: _pack == null,
              onSelected: (_) => setState(() => _pack = null),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: 'Jumlah (${_pack?.name ?? widget.baseUnit})'),
        ),
        const SizedBox(height: 8),
        Text(
          _pack == null ? '+$total ${widget.baseUnit}' : '$_count ${_pack!.name} × $_factor = +$total ${widget.baseUnit}',
          style: AppTextStyle.labelLg.copyWith(color: AppColors.primaryDark),
        ),
        const SizedBox(height: 20),
        AppButton(label: 'Tambahkan', onPressed: total > 0 ? () => Navigator.of(context).pop(total) : null),
      ],
    );
  }
}
