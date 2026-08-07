import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/category/category_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/models/category_model.dart';
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
    final ownerId = context.read<AuthCubit>().state.user!.ownerId;
    return BlocProvider(
      create: (_) => CategoryCubit(ownerId: ownerId)..watch(),
      child: const _CategoryView(),
    );
  }
}

class _CategoryView extends StatefulWidget {
  const _CategoryView();

  @override
  State<_CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<_CategoryView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  CategoryType get _activeTabType => _tabController.index == 0 ? CategoryType.income : CategoryType.expense;

  void _openForm(BuildContext context, {CategoryModel? existing}) {
    final cubit = context.read<CategoryCubit>();
    AppBottomSheet.show(
      context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _CategoryFormSheet(type: existing?.type ?? _activeTabType, existing: existing),
      ),
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
      onConfirm: () => context.read<CategoryCubit>().deleteCategory(
        id: category.id,
        name: category.name,
        type: category.type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.read<AuthCubit>().state.user?.role == UserRole.owner;

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
        appBar: AppBar(
          title: const Text('Kelola Kategori'),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            onTap: (_) => setState(() {}),
            tabs: const [
              Tab(text: 'Pemasukan'),
              Tab(text: 'Pengeluaran'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'category_add_fab',
          onPressed: () => _openForm(context),
          backgroundColor: AppColors.primaryLight,
          child: const Icon(Icons.add_rounded),
        ),
        child: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state.status == CategoryStatus.loading && state.categories.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(context, state.categories, CategoryType.income, isOwner),
                _buildList(context, state.categories, CategoryType.expense, isOwner),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<CategoryModel> all, CategoryType type, bool isOwner) {
    final items = all.where((c) => c.type == type).toList();

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            type == CategoryType.income
                ? 'Belum ada kategori pemasukan.\nTekan tombol + untuk menambahkan.'
                : 'Belum ada kategori pengeluaran.\nTekan tombol + untuk menambahkan.',
            style: AppTextStyle.bodyMd,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildCategoryTile(context, items[index], isOwner),
    );
  }

  Widget _buildCategoryTile(BuildContext context, CategoryModel category, bool isOwner) {
    final isIncome = category.type == CategoryType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final background = isIncome ? AppColors.incomeBackground : AppColors.expenseBackground;

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
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(category.name, style: AppTextStyle.titleSm)),
          if (isOwner) ...[
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
  final CategoryType type;
  final CategoryModel? existing;

  const _CategoryFormSheet({required this.type, this.existing});

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
    if (_isEdit) {
      cubit.updateCategory(
        id: widget.existing!.id,
        name: _nameController.text.trim(),
        type: widget.type,
      );
    } else {
      cubit.addCategory(name: _nameController.text.trim(), type: widget.type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == CategoryType.income;

    return BlocListener<CategoryCubit, CategoryState>(
      listener: (context, state) {
        // ModalRoute masih ter-mount selagi animasi tutup sheet berjalan, jadi
        // listener sheet SEBELUMNYA (kalau user buka sheet baru sebelum sheet
        // lama selesai animasi) masih ikut menerima emit ini juga. Kalau
        // sheet ini bukan lagi route teratas, abaikan sepenuhnya — jangan pop
        // (bisa nge-pop CategoryScreen di baliknya) atau toast dobel.
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isIncome ? AppColors.incomeBackground : AppColors.expenseBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isIncome ? 'Pemasukan' : 'Pengeluaran',
                style: AppTextStyle.labelMd.copyWith(color: isIncome ? AppColors.income : AppColors.expense),
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Nama Kategori',
              hint: 'Contoh: Gaji, Belanja Bahan',
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
