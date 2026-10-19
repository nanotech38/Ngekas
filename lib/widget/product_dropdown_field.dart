import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/services/product_service.dart';
import 'package:ngekas/widget/category_dropdown_field.dart';

// ─── ProductDropdownField ───────────────────────────────────────────────────
//
// Dropdown pilih barang (searchable nama/kode/barcode) untuk form transaksi. Tiap item
// menampilkan sisa stok & harga supaya user tidak perlu bolak-balik ke layar
// Barang. `onChanged` mengembalikan ProductModel penuh (harga dipakai form
// untuk mengisi harga satuan otomatis).

class ProductDropdownField extends StatefulWidget {
  final String? value;
  final ValueChanged<ProductModel?> onChanged;
  final FormFieldValidator<String>? validator;
  // true -> tampilkan harga beli (Pembelian Stok), false -> harga jual.
  final bool showBuyPrice;

  const ProductDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
    this.showBuyPrice = false,
  });

  @override
  State<ProductDropdownField> createState() => _ProductDropdownFieldState();
}

class _ProductDropdownFieldState extends State<ProductDropdownField> {
  late final ValueNotifier<String?> _notifier;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notifier = ValueNotifier<String?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant ProductDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _notifier.value) {
      _notifier.value = widget.value;
    }
  }

  @override
  void dispose() {
    _notifier.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: ProductService.watch(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <ProductModel>[];
        final selectedId = widget.value;
        final hasSelectedInList = selectedId == null || products.any((p) => p.id == selectedId);

        if (snapshot.hasData && products.isEmpty && selectedId == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: const Text('Belum ada barang. Tambahkan barang dulu di menu Barang.', style: AppTextStyle.bodySm),
          );
        }

        return DropdownButtonFormField2<String>(
          isExpanded: true,
          hint: Text('Pilih barang', style: AppTextStyle.labelMd.copyWith(color: AppColors.textHint)),
          items: [
            if (selectedId != null && !hasSelectedInList)
              DropdownItem<String>(
                value: selectedId,
                child: Text('Barang sudah dihapus', style: AppTextStyle.bodySm.copyWith(color: AppColors.textMuted)),
              ),
            ...products.map((p) => DropdownItem<String>(value: p.id, height: 56, child: _buildItem(p))),
          ],
          selectedItemBuilder: (context) => [
            if (selectedId != null && !hasSelectedInList)
              Text('Barang sudah dihapus', style: AppTextStyle.bodySm.copyWith(color: AppColors.textMuted)),
            ...products.map(
              (p) => Text(
                p.name,
                style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          valueListenable: _notifier,
          onChanged: (id) {
            _notifier.value = id;
            final product = products.where((p) => p.id == id).firstOrNull;
            widget.onChanged(product);
          },
          validator: widget.validator,
          buttonStyleData: const FormFieldButtonStyleData(padding: EdgeInsets.zero),
          menuItemStyleData: const MenuItemStyleData(useDecorationHorizontalPadding: true),
          decoration: appDropdownDecoration(),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 340,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          ),
          dropdownSearchData: DropdownSearchData<String>(
            searchController: _searchController,
            searchBarWidgetHeight: 50,
            searchBarWidget: appDropdownSearchBar(_searchController, 'Cari nama / kode / barcode...'),
            searchMatchFn: (item, searchValue) {
              final product = products.where((p) => p.id == item.value).firstOrNull;
              if (product == null) return false;
              return product.matchesQuery(searchValue);
            },
            noResultsWidget: const Padding(padding: EdgeInsets.all(12), child: Text('Barang tidak ditemukan')),
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) _searchController.clear();
          },
        );
      },
    );
  }

  Widget _buildItem(ProductModel p) {
    final price = widget.showBuyPrice ? p.buyPrice : p.sellPrice;
    final stockColor = p.isOutOfStock
        ? AppColors.error
        : (p.isLowStock ? AppColors.warning : AppColors.textMuted);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary, fontWeight: AppFontWeight.semiBold),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${p.sku} · ${price > 0 ? AppCurrency.format(price) : 'Harga beli -'} · '),
              TextSpan(text: 'Stok ${p.stock} ${p.unit}', style: TextStyle(color: stockColor)),
            ],
          ),
          style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
