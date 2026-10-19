import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/home_logic.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/screen/activity_log_screen.dart';
import 'package:ngekas/screen/category_screen.dart';
import 'package:ngekas/screen/manage_people_screen.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_dialog.dart';

// ─── ProfileScreen ──────────────────────────────────────────────────────────
//
// Tab "Profil" — info akun (nama, username, role) plus pintasan ke Riwayat
// Aktivitas, Kategori Barang, Kelola Pengguna (admin), Pengaturan & tombol
// keluar (lewat dialog konfirmasi biar tidak kepencet tidak sengaja).

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;

    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          _buildUserCard(user),
          const SizedBox(height: 20),
          _buildMenuTile(
            icon: Icons.history_rounded,
            label: 'Riwayat Aktivitas',
            onTap: () => NavigationService.get().push(const ActivityLogScreen()),
          ),
          _buildMenuTile(
            icon: Icons.category_outlined,
            label: 'Kategori Barang',
            onTap: () => NavigationService.get().push(const CategoryScreen()),
          ),
          if (user?.isAdmin ?? false)
            _buildMenuTile(
              icon: Icons.group_rounded,
              label: 'Kelola Pengguna',
              onTap: () => NavigationService.get().push(const ManagePeopleScreen()),
            ),
          _buildMenuTile(
            icon: Icons.settings_rounded,
            label: 'Pengaturan',
            onTap: () => HomeLogic.comingSoon(context, 'Pengaturan'),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode demo: semua data tersimpan sementara dan akan kembali seperti awal saat aplikasi ditutup.',
                    style: AppTextStyle.labelSm.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
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
            child: Icon(
              user?.isAdmin ?? false ? Icons.admin_panel_settings_outlined : Icons.point_of_sale_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? '-', style: AppTextStyle.titleSm, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '@${user?.username ?? '-'} · ${user?.role.label ?? '-'} · ${DatabaseService.storeName}',
                  style: AppTextStyle.bodySm,
                  overflow: TextOverflow.ellipsis,
                ),
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
