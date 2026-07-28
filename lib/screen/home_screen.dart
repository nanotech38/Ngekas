import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/home_logic.dart';
import 'package:ngekas/models/app_user.dart';
import 'package:ngekas/screen/login_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/widget/app_dialog.dart';

// ─── HomeScreen ─────────────────────────────────────────────────────────────
//
// Placeholder minimal supaya alur register/login/auto-login/logout bisa
// dites end-to-end. Konten sebenarnya (catatan penjualan) menyusul — menu
// di bawah ini masih hardcode, belum diarahkan ke halaman sungguhan.

class _MenuItem {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label});
}

const _menus = [
  _MenuItem(icon: Icons.receipt_long_rounded, label: 'Transaksi'),
  _MenuItem(icon: Icons.category_rounded, label: 'Kategori'),
  _MenuItem(icon: Icons.bar_chart_rounded, label: 'Laporan'),
  _MenuItem(icon: Icons.group_rounded, label: 'Staff'),
  _MenuItem(icon: Icons.settings_rounded, label: 'Pengaturan'),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.loggedOut) {
          NavigationService.get().pushAndRemoveAll(const LoginScreen());
        } else if (state.status == AuthStatus.error) {
          AppDialog.showError(
            context,
            title: 'Gagal Keluar',
            message: state.errorMessage,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Beranda'),
          actions: [
            IconButton(
              tooltip: 'Keluar',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => HomeLogic.handleLogout(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) => _buildUserCard(state.user),
              ),
              const SizedBox(height: 24),
              const Text('Menu', style: AppTextStyle.titleMd),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _menus.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) => _buildMenuItem(_menus[index]),
              ),
            ],
          ),
        ),
      ),
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
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email ?? '-',
                  style: AppTextStyle.titleSm,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.role == UserRole.owner ? 'Owner' : 'Staff',
                  style: AppTextStyle.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem menu) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: arahkan ke halaman ${menu.label}
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(menu.icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                menu.label,
                style: AppTextStyle.labelMd,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
