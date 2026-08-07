import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/home_logic.dart';
import 'package:ngekas/screen/category_screen.dart';
import 'package:ngekas/screen/home/home_tab.dart';
import 'package:ngekas/screen/home/laporan_tab.dart';
import 'package:ngekas/screen/login_screen.dart';
import 'package:ngekas/screen/profile_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _tabs = [HomeTab(), LaporanTab(), CategoryScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final showAddTransactionFab = _index == 0 || _index == 1;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.loggedOut) {
          NavigationService.get().pushAndRemoveAll(const LoginScreen());
        } else if (state.status == AuthStatus.error) {
          AppDialog.showError(context, title: 'Gagal Keluar', message: state.errorMessage);
        }
      },
      child: BaseTemplate(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        safeAreaTop: false,
        safeAreaBottom: false,
        floatingActionButton: showAddTransactionFab
            ? FloatingActionButton(
                heroTag: 'home_add_transaction_fab',
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                onPressed: () => HomeLogic.openReportPicker(context),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: showAddTransactionFab ? const CircularNotchedRectangle() : null,
          notchMargin: 8,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_rounded, label: 'Beranda', index: 0),
                _buildNavItem(icon: Icons.receipt_long_rounded, label: 'Laporan', index: 1),
                const SizedBox(width: 56),
                _buildNavItem(icon: Icons.category_rounded, label: 'Kategori', index: 2),
                _buildNavItem(icon: Icons.person_rounded, label: 'Profil', index: 3),
              ],
            ),
          ),
        ),
        child: IndexedStack(index: _index, children: _tabs),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final selected = _index == index;
    final color = selected ? AppColors.primary : AppColors.textDisabled;

    return InkWell(
      onTap: () => setState(() => _index = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyle.labelSm.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
