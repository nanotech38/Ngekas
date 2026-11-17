import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/category/category_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/services/product_service.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_text_field.dart';
import 'package:ngekas/widget/app_toast.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => CategoryCubit()..watch(), child: const _CategoryView());
  }
}

class _CategoryView extends StatelessWidget {
  const _CategoryView();

  void _openForm(BuildContext context, {CategoryModel? existing}) {
    final cubit = context.read<CategoryCubit>();
    AppBottomSheet.show(
      context,
      builder: (_) => BlocProvider.value(value: cubit, child: _CategoryFormSheet(existing: existing)),
    );
  }

  void _confirmDelete(BuildContext context, CategoryModel category) {
    AppDialog.show(
      context,
      type: AppDialogType.warning,
      title: 'Hapus Kategori?',
      message: 'Kategori "${category.name}" akan dihapus permanen.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      onConfirm: () => context.read<CategoryCubit>().deleteCategory(id: category.id, name: category.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthCubit>().state.user?.isAdmin ?? false;

    return BlocListener<CategoryCubit, CategoryState>(
      listener: (context, state) {
        if (state.status == CategoryStatus.deleteSuccess) {
          AppToast.showSuccess(context, 'Kategori dihapus');
        } else if (state.status == CategoryStatus.deleteError || state.status == CategoryStatus.streamError) {
          AppDialog.showError(context, title: 'Gagal', message: state.errorMessage);
        }
      },
      child: BaseTemplate(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Kategori Barang')),
        floatingActionButton: FloatingActionButton(
          heroTag: 'category_add_fab',
          tooltip: 'Tambah Kategori',
          onPressed: () => _openForm(context),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded),
        ),
        child: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state.status == CategoryStatus.loading && state.categories.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.categories.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Belum ada kategori.\nTekan tombol + untuk menambahkan.',
                    style: AppTextStyle.bodyMd,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return StreamBuilder<List<ProductModel>>(
              stream: ProductService.watch(),
              builder: (context, snapshot) {
                final products = snapshot.data ?? const <ProductModel>[];
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: state.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    final count = products.where((p) => p.categoryId == category.id).length;
                    return _buildCategoryTile(context, category, count, isAdmin);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, CategoryModel category, int productCount, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.category_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: AppTextStyle.titleSm),
                const SizedBox(height: 2),
                Text('$productCount barang', style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          if (isAdmin) ...[
            IconButton(
              tooltip: 'Ubah',
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
              onPressed: () => _openForm(context, existing: category),
            ),
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () => _confirmDelete(context, category),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  final CategoryModel? existing;

  const _CategoryFormSheet({this.existing});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<CategoryCubit>();
    final name = _nameController.text.trim();
    if (_isEdit) {
      cubit.updateCategory(id: widget.existing!.id, name: name);
    } else {
      cubit.addCategory(name: name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryCubit, CategoryState>(
      listener: (context, state) {
        // sheet lama yg masih animasi nutup ikut dapet emit, skip biar ga pop/toast dobel
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

        if (state.status == CategoryStatus.addSuccess) {
          Navigator.of(context).pop();
          AppToast.showSuccess(context, 'Kategori ditambahkan');
        } else if (state.status == CategoryStatus.updateSuccess) {
          Navigator.of(context).pop();
          AppToast.showSuccess(context, 'Kategori diperbarui');
        } else if (state.status == CategoryStatus.addError || state.status == CategoryStatus.updateError) {
          AppDialog.showError(context, title: 'Gagal', message: state.errorMessage);
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Ubah Kategori' : 'Tambah Kategori', style: AppTextStyle.titleLg),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Nama Kategori',
              hint: 'Contoh: Oli & Pelumas, Suku Cadang',
              controller: _nameController,
              isRequired: true,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Nama kategori wajib diisi' : null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 20),
            BlocSelector<CategoryCubit, CategoryState, bool>(
              selector: (state) => state.isSubmitting,
              builder: (context, isSubmitting) => AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Tambah Kategori',
                isLoading: isSubmitting,
                onPressed: _handleSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
