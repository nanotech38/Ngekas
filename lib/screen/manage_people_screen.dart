import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/services/user_profile_service.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_toast.dart';

// ─── ManagePeopleScreen ─────────────────────────────────────────────────────
//
// "Kelola Orang" di ProfileScreen — owner-only (menu-nya sendiri sudah
// disembunyikan dari staff, lihat ProfileScreen). Kode undangan = uid owner
// itu sendiri (lihat UserProfileService), jadi tidak perlu layar/alur
// generate kode terpisah — cukup tampilkan uid-nya buat disalin & dibagikan.

class ManagePeopleScreen extends StatelessWidget {
  const ManagePeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    final ownerId = user?.ownerId;

    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kelola Orang')),
      child: ownerId == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInviteCodeCard(context, ownerId),
                const SizedBox(height: 24),
                const Text('Anggota Workspace', style: AppTextStyle.titleMd),
                const SizedBox(height: 12),
                StreamBuilder<List<AppUser>>(
                  stream: UserProfileService.watchWorkspaceMembers(ownerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Gagal memuat daftar anggota',
                        style: AppTextStyle.bodySm.copyWith(color: AppColors.error),
                      );
                    }

                    final members = snapshot.data ?? const <AppUser>[];
                    // Owner selalu di atas, sisanya (staff) diurutkan by email
                    // supaya urutannya stabil tiap kali list berubah.
                    final sorted = [...members]..sort((a, b) {
                      if (a.role != b.role) return a.role == UserRole.owner ? -1 : 1;
                      return a.email.compareTo(b.email);
                    });

                    return Column(
                      children: sorted
                          .map((member) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildMemberTile(context, member),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildInviteCodeCard(BuildContext context, String ownerId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Kode Undangan', style: AppTextStyle.titleSm),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bagikan kode ini ke orang yang mau kamu ajak. Minta mereka daftar akun baru di Ngekas dan masukkan kode ini saat mendaftar.',
            style: AppTextStyle.bodySm,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ownerId,
                    style: AppTextStyle.labelLg.copyWith(fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: ownerId));
                    if (context.mounted) AppToast.showSuccess(context, 'Kode disalin');
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, AppUser member) {
    final isOwner = member.role == UserRole.owner;
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
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.email,
                  style: AppTextStyle.labelLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOwner ? AppColors.secondaryContainer : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOwner ? 'Owner' : 'Staff',
                    style: AppTextStyle.labelSm.copyWith(
                      color: isOwner ? AppColors.secondary : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isOwner && !isSelf)
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
      title: 'Keluarkan ${member.email}?',
      message: 'Orang ini tidak akan bisa lagi mengakses workspace kamu.',
      confirmText: 'Keluarkan',
      cancelText: 'Batal',
      onConfirm: () => _removeMember(context, member),
    );
  }

  Future<void> _removeMember(BuildContext context, AppUser member) async {
    final actor = context.read<AuthCubit>().state.user;
    try {
      await UserProfileService.removeMember(member.uid);
      await ActivityLogService.log(
        ownerId: member.ownerId,
        actorEmail: actor?.email ?? '-',
        action: ActivityAction.deleted,
        entity: ActivityEntity.member,
        description: '${member.email} dikeluarkan dari workspace',
      );
      if (context.mounted) AppToast.showSuccess(context, '${member.email} dikeluarkan');
    } catch (e) {
      if (context.mounted) {
        AppDialog.showError(context, title: 'Gagal', message: e.toString());
      }
    }
  }
}
