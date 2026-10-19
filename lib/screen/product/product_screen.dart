import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/product/product_cubit.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/screen/category_screen.dart';
import 'package:ngekas/screen/product/product_form_sheet.dart';
import 'package:ngekas/screen/product/product_import_screen.dart';
import 'package:ngekas/screen/product/stock_card_screen.dart';
import 'package:ngekas/services/category_service.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_toast.dart';

// ─── ProductScreen ──────────────────────────────────────────────────────────
//
// Tab "Gudang" — daftar stok barang dengan pencarian (nama/kode/barcode) dan
// filter kategori. Admin & kasir bisa tambah barang dan ubah (ketuk kartu —
// kasir hanya nama & stok); hapus (ikon tempat sampah) khusus admin.

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ProductCubit()..watch(), child: const _ProductView());
  }
}

class _ProductView extends StatelessWidget {
  const _ProductView();

  void _openForm(BuildContext context, {ProductModel? existing}) {
    final cubit = context.read<ProductCubit>();
    AppBottomSheet.show(
      context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ProductFormSheet(existing: existing),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel product) {
    AppDialog.show(
      context,
      type: AppDialogType.warning,
      title: 'Hapus Barang?',
      message:
          'Yakin ingin menghapus "${product.name}"? Barang ini tidak bisa dikembalikan. '
          'Riwayat penjualannya tetap tersimpan di Laporan.',
      confirmText: 'Ya, Hapus',
      cancelText: 'Batal',
      onConfirm: () => context.read<ProductCubit>().deleteProduct(id: product.id, name: product.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthCubit>().state.user?.isAdmin ?? false;

    return BlocListener<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state.status == ProductStatus.deleteSuccess) {
          AppToast.showSuccess(context, 'Barang dihapus');
        } else if (state.status == ProductStatus.deleteError || state.status == ProductStatus.streamError) {
          AppDialog.showError(context, title: 'Gagal', message: state.errorMessage);
        }
      },
      child: BaseTemplate(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Gudang'),
          actions: [
            IconButton(
              tooltip: 'Kategori Barang',
              icon: const Icon(Icons.category_outlined),
              onPressed: () => NavigationService.get().push(const CategoryScreen()),
            ),
            if (isAdmin)
              IconButton(
                tooltip: 'Import Barang (Excel/CSV)',
                icon: const Icon(Icons.upload_file_rounded),
                onPressed: () => NavigationService.get().push(const ProductImportScreen()),
              ),
            // Admin & kasir sama-sama bisa tambah barang (tercatat di Riwayat
            // Aktivitas).
            IconButton(
              tooltip: 'Tambah Barang',
              icon: const Icon(Icons.add_box_outlined),
              onPressed: () => _openForm(context),
            ),
          ],
        ),
        child: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) {
            if (state.status == ProductStatus.loading && state.all.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = state.filtered;

            return Column(
              children: [
                _buildToolbar(context, state, isAdmin),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              state.all.isEmpty
                                  ? 'Belum ada barang.\nTekan ikon + di atas untuk menambahkan.'
                                  : 'Tidak ada barang yang cocok.',
                              style: AppTextStyle.bodyMd,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _buildProductCard(context, items[index], isAdmin),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ProductState state, bool isAdmin) {
    final cubit = context.read<ProductCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: cubit.setQuery,
            style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Cari nama atau barcode...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: AppFontSize.sm),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textDisabled, size: 20),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<CategoryModel>>(
            stream: CategoryService.watch(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const <CategoryModel>[];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip(
                      label: 'Semua',
                      selected: state.filter.categoryId == null,
                      onTap: () => cubit.setCategory(null),
                    ),
                    for (final c in categories) ...[
                      const SizedBox(width: 8),
                      _buildChip(
                        label: c.name,
                        selected: state.filter.categoryId == c.id,
                        onTap: () => cubit.setCategory(c.id),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text('${state.filtered.length} barang', style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildChip({required String label, required bool selected, required VoidCallback onTap}) {
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

  Widget _buildProductCard(BuildContext context, ProductModel p, bool isAdmin) {
    return _ProductCard(
      product: p,
      isAdmin: isAdmin,
      // Admin ubah semua data; kasir cuma nama & stok (dibatasi di form).
      onTap: () => _openForm(context, existing: p),
      onDelete: () => _confirmDelete(context, p),
    );
  }
}

// ─── _ProductCard ───────────────────────────────────────────────────────────
//
// Kartu satu barang:
// - Atas  : avatar inisial (warna per kategori), nama, chip kategori,
//           ringkasan barcode, kemasan (mis. Dus isi 12), ikon hapus (admin).
// - Bawah : harga jual, tombol Kartu Stok, dan jumlah stok berwarna (hijau /
//           kuning menipis / merah habis) + rinciannya per kemasan.
// Barang habis diberi garis kiri merah & sedikit diredupkan supaya cepat
// kelihatan saat scroll.

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.isAdmin, required this.onTap, required this.onDelete});

  // Warna avatar per kategori — dipilih stabil dari id kategori.
  static const _palette = [
    (AppColors.primary, AppColors.primaryContainer),
    (AppColors.info, AppColors.infoLight),
    (AppColors.success, AppColors.successLight),
    (Color(0xFF8B5CF6), Color(0xFFEDE9FE)),
    (Color(0xFFDB2777), Color(0xFFFCE7F3)),
    (AppColors.secondaryLight, AppColors.secondaryContainer),
  ];

  (Color, Color) get _categoryColors {
    final hash = product.categoryId.codeUnits.fold<int>(0, (sum, c) => sum + c);
    return _palette[hash % _palette.length];
  }

  String get _initials {
    final words = product.name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, words.first.length.clamp(1, 2)).toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  // "8997011930011 +2 barcode lain" / "Tanpa barcode".
  String get _barcodeSummary {
    final all = product.allBarcodes.toList();
    if (all.isEmpty) return 'Tanpa barcode';
    return all.length == 1 ? all.first : '${all.first} +${all.length - 1} barcode lain';
  }

  // Warna stok: merah = habis, kuning = menipis, hijau = cukup.
  ({Color color, Color background}) get _stockStatus {
    if (product.isOutOfStock) return (color: AppColors.error, background: AppColors.errorLight);
    if (product.isLowStock) return (color: const Color(0xFFB45309), background: AppColors.warningLight);
    return (color: AppColors.success, background: AppColors.successLight);
  }

  @override
  Widget build(BuildContext context) {
    final p = product;
    final (accent, accentBackground) = _categoryColors;
    final stock = _stockStatus;
    final muted = AppTextStyle.labelSm.copyWith(color: AppColors.textMuted);

    return Opacity(
      opacity: p.isOutOfStock ? 0.85 : 1,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.isOutOfStock ? AppColors.errorLight : AppColors.border),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Garis status stok di sisi kiri.
                  Container(width: 4, color: stock.color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: accentBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(_initials, style: AppTextStyle.labelLg.copyWith(color: accent)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: AppTextStyle.labelLg,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        // Kode barang sengaja tidak ditampilkan.
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: accentBackground,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            p.categoryName,
                                            style: AppTextStyle.labelSm.copyWith(color: accent),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          p.hasAnyBarcode ? Icons.qr_code_scanner_rounded : Icons.qr_code_2_rounded,
                                          size: 12,
                                          color: p.hasAnyBarcode ? AppColors.textMuted : AppColors.textDisabled,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _barcodeSummary,
                                            style: AppTextStyle.labelSm.copyWith(
                                              color: p.hasAnyBarcode ? AppColors.textMuted : AppColors.textDisabled,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (p.packs.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              p.packs.map((k) => '${k.name} isi ${k.factor}').join(' · '),
                                              style: muted,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isAdmin)
                                IconButton(
                                  tooltip: 'Hapus Barang',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                  onPressed: onDelete,
                                )
                              else
                                const SizedBox(width: 8),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            // Tombol Kartu Stok & kotak stok dibuat sama tinggi
                            // (stretch) supaya sejajar, walau kotak stok punya
                            // baris rincian kemasan.
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Harga Jual / ${p.unit}', style: muted),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppCurrency.format(p.sellPrice),
                                          style: AppTextStyle.labelLg.copyWith(color: AppColors.primaryDark),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Kartu stok: riwayat masuk/keluar/penyesuaian barang ini.
                                  OutlinedButton.icon(
                                    onPressed: () => NavigationService.get().push(StockCardScreen(product: p)),
                                    icon: const Icon(Icons.history_rounded, size: 16),
                                    label: const Text('Kartu Stok'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textSecondary,
                                      side: const BorderSide(color: AppColors.border),
                                      textStyle: AppTextStyle.labelSm,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: stock.background,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${p.stock} ${p.unit}',
                                          style: AppTextStyle.labelLg.copyWith(color: stock.color),
                                        ),
                                        if (p.packBreakdown(p.stock).isNotEmpty)
                                          Text(
                                            p.packBreakdown(p.stock),
                                            style: AppTextStyle.labelSm.copyWith(color: stock.color),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
