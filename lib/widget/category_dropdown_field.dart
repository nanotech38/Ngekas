import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/screen/category_screen.dart';
import 'package:ngekas/services/category_service.dart';
import 'package:ngekas/services/navigation_services.dart';

// ─── CategoryDropdownField ──────────────────────────────────────────────────
//
// Dropdown pilih kategori (searchable, via dropdown_button2) yang dipakai
// bareng oleh ReportEntryFormSheet (kategori wajib dipilih) & ReportFilterSheet
// (kategori sebagai filter opsional, ada pilihan "Semua Kategori"). Kalau
// belum ada kategori sama sekali untuk tipe ini, tampil ajakan ke Kelola
// Kategori sebagai pengganti dropdown-nya.
//
// `value` cukup id kategori yang sedang dipilih; `onChanged` mengembalikan
// CategoryModel penuh (bukan cuma id) supaya pemanggil yang butuh nama
// kategori (mis. ReportEntryFormSheet) tidak perlu simpan+cari sendiri daftar
// kategorinya lagi — null berarti "Semua Kategori"/tidak ada yang dipilih.

class CategoryDropdownField extends StatefulWidget {
  final String ownerId;
  final CategoryType type;
  final String? value;
  final ValueChanged<CategoryModel?> onChanged;
  final String hintText;
  final bool includeAllOption;
  final String allOptionLabel;
  final FormFieldValidator<String>? validator;

  const CategoryDropdownField({
    super.key,
    required this.ownerId,
    required this.type,
    required this.value,
    required this.onChanged,
    this.hintText = 'Pilih kategori',
    this.includeAllOption = false,
    this.allOptionLabel = 'Semua Kategori',
    this.validator,
  });

  @override
  State<CategoryDropdownField> createState() => _CategoryDropdownFieldState();
}

class _CategoryDropdownFieldState extends State<CategoryDropdownField> {
  late final ValueNotifier<String?> _notifier;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notifier = ValueNotifier<String?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant CategoryDropdownField oldWidget) {
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
    return StreamBuilder<List<CategoryModel>>(
      stream: CategoryService.watch(widget.ownerId),
      builder: (context, snapshot) {
        final categories = (snapshot.data ?? const [])
            .where((c) => c.type == widget.type)
            .toList();

        // DropdownButton2 mengharuskan PERSIS satu item cocok dengan value
        // yang sedang dipilih. Kalau widget ini dibuka lagi dengan value
        // lama (mis. filter yang sudah diterapkan sebelumnya) sebelum
        // StreamBuilder sempat dapat snapshot pertama — atau kategorinya
        // sudah dihapus — value itu tidak akan ketemu di `categories` dan
        // dropdown_button2 crash. Sisipkan placeholder biar tetap konsisten
        // sampai data aslinya kebaca (atau tetap valid kalau memang sudah
        // dihapus).
        final selectedId = widget.value;
        final hasSelectedInList =
            selectedId == null || categories.any((c) => c.id == selectedId);

        if (categories.isEmpty && !widget.includeAllOption && selectedId == null) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Belum ada kategori untuk tipe ini.',
                  style: AppTextStyle.bodySm,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    NavigationService.get().push(const CategoryScreen());
                  },
                  child: const Text('Kelola Kategori'),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField2<String>(
          isExpanded: true,
          hint: Text(
            widget.hintText,
            style: AppTextStyle.labelMd.copyWith(color: AppColors.textHint),
          ),
          items: [
            if (widget.includeAllOption)
              DropdownItem<String>(
                value: null,
                child: Text(
                  widget.allOptionLabel,
                  style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary),
                ),
              ),
            if (selectedId != null && !hasSelectedInList)
              DropdownItem<String>(
                value: selectedId,
                child: Text(
                  'Memuat...',
                  style: AppTextStyle.bodySm.copyWith(color: AppColors.textMuted),
                ),
              ),
            ...categories.map(
              (c) => DropdownItem<String>(
                value: c.id,
                child: Text(
                  c.name,
                  style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
          valueListenable: _notifier,
          onChanged: (id) {
            _notifier.value = id;
            if (id == null) {
              widget.onChanged(null);
              return;
            }
            final category = categories.where((c) => c.id == id).firstOrNull;
            if (category == null) return;
            widget.onChanged(category);
          },
          validator: widget.validator,
          buttonStyleData: const FormFieldButtonStyleData(padding: EdgeInsets.zero),
          menuItemStyleData: const MenuItemStyleData(
            useDecorationHorizontalPadding: true,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintStyle: AppTextStyle.labelMd.copyWith(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 300,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          dropdownSearchData: DropdownSearchData<String>(
            searchController: _searchController,
            searchBarWidgetHeight: 50,
            searchBarWidget: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  hintText: 'Cari kategori...',
                  hintStyle: AppTextStyle.labelMd.copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              if (item.value == null) {
                return widget.allOptionLabel.toLowerCase().contains(
                  searchValue.toLowerCase(),
                );
              }
              final category = categories.where((c) => c.id == item.value).firstOrNull;
              if (category == null) return false;
              return category.name.toLowerCase().contains(
                searchValue.toLowerCase(),
              );
            },
            noResultsWidget: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Kategori tidak ditemukan'),
            ),
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) _searchController.clear();
          },
        );
      },
    );
  }
}
