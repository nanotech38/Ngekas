import 'package:flutter/material.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/services/category_service.dart';
import 'package:ngekas/services/product_service.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';

// ─── ProductPickerSheet ─────────────────────────────────────────────────────
//
// Langkah 1 (manual) di Kasir: pilih barang dari daftar barang terdaftar.
// Cari nama/kode/barcode, filter kategori, tiap baris jelas menampilkan
// harga & sisa stok. Barang yang stoknya habis tidak bisa dipilih.
// Mengembalikan barang yang dipilih lewat Navigator.pop.
//
//   final product = await ProductPickerSheet.show(context, cartQuantities: {...});

class ProductPickerSheet extends StatefulWidget {
  // productId -> jumlah di keranjang, untuk penanda "Di keranjang: N".
  final Map<String, int> cartQuantities;
  final String title;
  final String subtitle;
  // True saat memilih barang untuk dihubungkan dengan barcode (stok habis
  // tetap boleh dipilih).
  final bool allowOutOfStock;

  const ProductPickerSheet({
    super.key,
    this.cartQuantities = const {},
    this.title = 'Pilih Barang',
    this.subtitle = 'Ketuk barang yang dibeli pelanggan.',
    this.allowOutOfStock = false,
  });

  static Future<ProductModel?> show(
    BuildContext context, {
    Map<String, int> cartQuantities = const {},
    String title = 'Pilih Barang',
    String subtitle = 'Ketuk barang yang dibeli pelanggan.',
    bool allowOutOfStock = false,
  }) {
    return AppBottomSheet.show<ProductModel>(
      context,
      builder: (_) => ProductPickerSheet(
        cartQuantities: cartQuantities,
        title: title,
        subtitle: subtitle,
        allowOutOfStock: allowOutOfStock,
      ),
    );
  }

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  String _query = '';
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: AppTextStyle.titleLg),
          const SizedBox(height: 4),
          Text(widget.subtitle, style: AppTextStyle.bodySm),
          const SizedBox(height: 16),
          TextField(
            autofocus: false,
            onChanged: (value) => setState(() => _query = value),
            style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Cari nama atau barcode...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: AppFontSize.sm),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textDisabled, size: 20),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          _buildCategoryChips(),
          const SizedBox(height: 10),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return StreamBuilder<List<CategoryModel>>(
      stream: CategoryService.watch(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <CategoryModel>[];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChip('Semua', _categoryId == null, () => setState(() => _categoryId = null)),
              for (final c in categories) ...[
                const SizedBox(width: 8),
                _buildChip(c.name, _categoryId == c.id, () => setState(() => _categoryId = c.id)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
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

  Widget _buildList() {
    return StreamBuilder<List<ProductModel>>(
      stream: ProductService.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final products = snapshot.data!
            .where((p) => (_categoryId == null || p.categoryId == _categoryId) && p.matchesQuery(_query))
            .toList();
        if (products.isEmpty) {
          return const Center(child: Text('Barang tidak ditemukan.', style: AppTextStyle.bodyMd));
        }

        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (context, index) => _buildTile(products[index]),
        );
      },
    );
  }

  Widget _buildTile(ProductModel p) {
    final inCart = widget.cartQuantities[p.id] ?? 0;
    final disabled = p.isOutOfStock && !widget.allowOutOfStock;

    return InkWell(
      onTap: disabled ? null : () => Navigator.of(context).pop(p),
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: AppTextStyle.labelLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      p.isOutOfStock ? 'Stok habis · ${p.categoryName}' : 'Stok ${p.stock} ${p.unit} · ${p.categoryName}',
                      style: AppTextStyle.labelSm.copyWith(color: p.isOutOfStock ? AppColors.error : AppColors.textMuted),
                    ),
                    if (inCart > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Di keranjang: $inCart',
                        style: AppTextStyle.labelSm.copyWith(color: AppColors.primary, fontWeight: AppFontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(AppCurrency.format(p.sellPrice), style: AppTextStyle.titleSm.copyWith(color: AppColors.primaryDark)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: disabled ? AppColors.textHint : AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
