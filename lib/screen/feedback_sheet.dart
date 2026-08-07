import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/services/feedback_service.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_text_field.dart';
import 'package:ngekas/widget/app_toast.dart';

// ─── FeedbackMenuTopic ──────────────────────────────────────────────────────
//
// Daftar menu/fitur Ngekas yang bisa dipilih user sebagai konteks feedback-
// nya — biar pas dibaca dari Firebase Console langsung kelihatan bagian mana
// yang dimaksud, tanpa perlu nebak-nebak dari isi pesan bebasnya.

enum FeedbackMenuTopic {
  beranda,
  laporanPemasukan,
  laporanPengeluaran,
  tambahPemasukan,
  tambahPengeluaran,
  kelolaKategori,
  riwayatAktivitas,
  profil,
  lainnya,
}

extension on FeedbackMenuTopic {
  String get label => switch (this) {
    FeedbackMenuTopic.beranda => 'Beranda',
    FeedbackMenuTopic.laporanPemasukan => 'Laporan Pemasukan',
    FeedbackMenuTopic.laporanPengeluaran => 'Laporan Pengeluaran',
    FeedbackMenuTopic.tambahPemasukan => 'Tambah Pemasukan',
    FeedbackMenuTopic.tambahPengeluaran => 'Tambah Pengeluaran',
    FeedbackMenuTopic.kelolaKategori => 'Kelola Kategori',
    FeedbackMenuTopic.riwayatAktivitas => 'Riwayat Aktivitas',
    FeedbackMenuTopic.profil => 'Profil',
    FeedbackMenuTopic.lainnya => 'Lainnya',
  };
}

// ─── FeedbackSheet ──────────────────────────────────────────────────────────
//
// Bottom sheet "Feedback" dari ProfileScreen — pilih menu yang dimaksud
// lalu tulis pesan bebas. Tanpa Cubit sendiri karena cuma satu aksi
// (create) yang tidak perlu dipantau widget lain, beda dengan
// Category/Transaction yang statusnya dibaca bareng-bareng oleh list &
// sheet-nya sendiri.

class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _menuNotifier = ValueNotifier<FeedbackMenuTopic?>(null);
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    _menuNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthCubit>().state.user;
    setState(() => _isSubmitting = true);
    try {
      await FeedbackService.submit(
        authorUid: user?.uid ?? '-',
        authorEmail: user?.email ?? '-',
        menu: _menuNotifier.value!.label,
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.showSuccess(context, 'Terima kasih atas masukannya!');
    } catch (e) {
      if (!mounted) return;
      AppDialog.showError(context, title: 'Gagal', message: e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Feedback', style: AppTextStyle.titleLg),
          const SizedBox(height: 4),
          const Text('Ada yang bisa gue tingkatkan dari Ngekas?', style: AppTextStyle.bodySm),
          const SizedBox(height: 20),
          _buildMenuField(),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Masukan',
            hint: 'Contoh: filter laporan agak susah dipakai...',
            type: FieldType.multiline,
            maxLines: 5,
            controller: _messageController,
            isRequired: true,
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Tulis dulu bro' : null,
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Kirim', isLoading: _isSubmitting, onPressed: _handleSubmit),
        ],
      ),
    );
  }

  Widget _buildMenuField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Menu', style: AppTextStyle.labelLg),
        const SizedBox(height: 6),
        DropdownButtonFormField2<FeedbackMenuTopic>(
          isExpanded: true,
          hint: Text('Pilih menu yang dimaksud', style: AppTextStyle.labelMd.copyWith(color: AppColors.textHint)),
          items: FeedbackMenuTopic.values
              .map(
                (topic) => DropdownItem<FeedbackMenuTopic>(
                  value: topic,
                  child: Text(topic.label, style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary)),
                ),
              )
              .toList(),
          valueListenable: _menuNotifier,
          onChanged: (value) => _menuNotifier.value = value,
          validator: (value) => value == null ? 'Pilih menu dulu' : null,
          buttonStyleData: const FormFieldButtonStyleData(padding: EdgeInsets.zero),
          menuItemStyleData: const MenuItemStyleData(useDecorationHorizontalPadding: true),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
