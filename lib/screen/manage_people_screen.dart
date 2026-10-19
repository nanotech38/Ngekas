import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/const/app_validator_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/services/user_profile_service.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_text_field.dart';
import 'package:ngekas/widget/app_toast.dart';

// ─── ManagePeopleScreen ─────────────────────────────────────────────────────
//
// "Kelola Pengguna" di ProfileScreen — admin-only (menu-nya sudah
// disembunyikan dari kasir). Tidak ada pendaftaran mandiri: akun kasir baru
// dibuat admin lewat tombol "Tambah Kasir" di sini. Juga menampilkan daftar
// akun terdaftar dan tombol keluarkan akun kasir.

class ManagePeopleScreen extends StatelessWidget {
  const ManagePeopleScreen({super.key});

  void _openAddKasir(BuildContext context) {
    AppBottomSheet.show(context, builder: (_) => const _AddKasirSheet());
  }

  @override
  Widget build(BuildContext context) {
    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kelola Pengguna')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppButton(label: 'Tambah Kasir', icon: Icons.person_add_alt_1_rounded, onPressed: () => _openAddKasir(context)),
          const SizedBox(height: 24),
          const Text('Pengguna Terdaftar', style: AppTextStyle.titleMd),
          const SizedBox(height: 12),
          StreamBuilder<List<AppUser>>(
            stream: UserProfileService.watchMembers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Admin selalu di atas, sisanya diurutkan by username supaya
              // urutannya stabil tiap kali list berubah.
              final sorted = [...snapshot.data!]
                ..sort((a, b) {
                  if (a.role != b.role) return a.isAdmin ? -1 : 1;
                  return a.username.compareTo(b.username);
                });

              return Column(
                children: sorted
                    .map(
                      (member) =>
                          Padding(padding: const EdgeInsets.only(bottom: 10), child: _buildMemberTile(context, member)),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, AppUser member) {
    final currentUser = context.read<AuthCubit>().state.user;
    final isSelf = member.uid == currentUser?.uid;

    return Container(
      padding: const EdgeInsets.all(14),
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
            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: Icon(
              member.isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSelf ? '${member.name} (kamu)' : member.name,
                  style: AppTextStyle.labelLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: member.isAdmin ? AppColors.secondaryContainer : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member.role.label,
                        style: AppTextStyle.labelSm.copyWith(
                          color: member.isAdmin ? AppColors.secondary : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('@${member.username}', style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          if (!member.isAdmin && !isSelf)
            IconButton(
              tooltip: 'Keluarkan',
              icon: const Icon(Icons.person_remove_rounded, color: AppColors.error),
              onPressed: () => _confirmRemove(context, member),
            ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, AppUser member) {
    AppDialog.show(
      context,
      type: AppDialogType.warning,
      title: 'Keluarkan ${member.name}?',
      message: 'Akun @${member.username} tidak akan bisa masuk lagi.',
      confirmText: 'Keluarkan',
      cancelText: 'Batal',
      onConfirm: () => _removeMember(context, member),
    );
  }

  Future<void> _removeMember(BuildContext context, AppUser member) async {
    try {
      await UserProfileService.removeMember(member.uid);
      await ActivityLogService.log(
        action: ActivityAction.deleted,
        entity: ActivityEntity.member,
        subject: member.name,
        details: [ActivityDetail('Username', '@${member.username}'), ActivityDetail('Peran', member.role.label)],
        description: '@${member.username} dikeluarkan dari toko',
      );
      if (context.mounted) AppToast.showSuccess(context, '${member.name} dikeluarkan');
    } catch (e) {
      if (context.mounted) AppDialog.showError(context, title: 'Gagal', message: e.toString());
    }
  }
}

// ─── _AddKasirSheet ─────────────────────────────────────────────────────────
//
// Form admin untuk membuat akun kasir baru: nama, username, kata sandi.
// Setelah dibuat, kasir langsung bisa login pakai username & kata sandi itu.

class _AddKasirSheet extends StatefulWidget {
  const _AddKasirSheet();

  @override
  State<_AddKasirSheet> createState() => _AddKasirSheetState();
}

class _AddKasirSheetState extends State<_AddKasirSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final user = await UserProfileService.createKasir(
        name: _nameController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
      await ActivityLogService.log(
        action: ActivityAction.created,
        entity: ActivityEntity.member,
        subject: user.name,
        details: [ActivityDetail('Username', '@${user.username}'), ActivityDetail('Peran', user.role.label)],
        description: '@${user.username} (${user.name}) dibuat sebagai kasir',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.showSuccess(context, 'Akun kasir @${user.username} dibuat');
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
          const Text('Tambah Kasir', style: AppTextStyle.titleLg),
          const SizedBox(height: 4),
          const Text('Kasir bisa langsung masuk pakai username & kata sandi ini.', style: AppTextStyle.bodySm),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Nama',
            hint: 'Contoh: Budi',
            prefixIcon: Icons.badge_outlined,
            controller: _nameController,
            isRequired: true,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Username',
            hint: 'Contoh: budi',
            prefixIcon: Icons.person_outline_rounded,
            controller: _usernameController,
            isRequired: true,
            validator: AppValidator.username,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Kata Sandi',
            hint: 'Minimal 6 karakter',
            type: FieldType.password,
            controller: _passwordController,
            isRequired: true,
            validator: AppValidator.password,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSave(),
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Buat Akun Kasir', isLoading: _isSubmitting, onPressed: _handleSave),
        ],
      ),
    );
  }
}
