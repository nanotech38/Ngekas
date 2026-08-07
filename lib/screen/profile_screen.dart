import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/home_logic.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/screen/activity_log_screen.dart';
import 'package:ngekas/screen/feedback_sheet.dart';
import 'package:ngekas/screen/manage_people_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_dialog.dart';

// ─── ProfileScreen ──────────────────────────────────────────────────────────
//
// Tab "Profil" di bottom nav HomeScreen — info akun (email, role) plus
// pintasan ke Riwayat Aktivitas & tombol keluar (dipindah dari AppBar Home
// yang lama, sekarang lewat dialog konfirmasi biar tidak kepencet tidak
// sengaja).

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;

    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildUserCard(user),
          const SizedBox(height: 20),
          _buildMenuTile(
            icon: Icons.history_rounded,
            label: 'Riwayat Aktivitas',
            onTap: () => NavigationService.get().push(const ActivityLogScreen()),
          ),
          _buildMenuTile(
            icon: Icons.feedback_rounded,
            label: 'Feedback',
            onTap: () => AppBottomSheet.show(context, builder: (_) => const FeedbackSheet()),
          ),
          if (user?.role == UserRole.owner)
            _buildMenuTile(
              icon: Icons.group_rounded,
              label: 'Kelola Orang',
              onTap: () => NavigationService.get().push(const ManagePeopleScreen()),
            ),
          _buildMenuTile(
            icon: Icons.settings_rounded,
            label: 'Pengaturan',
            onTap: () => HomeLogic.comingSoon(context, 'Pengaturan'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Keluar', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    AppDialog.show(
      context,
      type: AppDialogType.warning,
      title: 'Keluar?',
      message: 'Kamu akan keluar dari akun ini.',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      onConfirm: () => HomeLogic.handleLogout(context),
    );
  }

  Widget _buildUserCard(AppUser? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.email ?? '-', style: AppTextStyle.titleSm, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(user?.role == UserRole.owner ? 'Owner' : 'Staff', style: AppTextStyle.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: AppTextStyle.labelLg)),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
