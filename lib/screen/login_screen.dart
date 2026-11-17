import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/const/app_validator_const.dart';
import 'package:ngekas/logic/login_logic.dart';
import 'package:ngekas/screen/home_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final AnimationController _animController;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerOpacity = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    LoginLogic.handleLogin(
      context: context,
      formKey: _formKey,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _fillDemoAccount(String username) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = 'admin123';
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.loginSuccess) {
          NavigationService.get().pushAndRemoveAll(const HomeScreen());
        } else if (state.status == AuthStatus.error) {
          AppDialog.showError(
            context,
            title: 'Gagal Masuk',
            message: state.errorMessage,
          );
        }
      },
      child: BaseTemplate(
        child: Column(
          children: [
            const SizedBox(height: 24),
            FadeTransition(opacity: _headerOpacity, child: _buildHeader()),
            const SizedBox(height: 28),
            Expanded(
              child: SlideTransition(
                position: _cardSlide,
                child: FadeTransition(
                  opacity: _headerOpacity,
                  child: _buildFormCard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset('assets/logo/icon_app.png', width: 72, height: 72),
        ),
        const SizedBox(height: 16),
        const Text(
          'Selamat Datang',
          style: TextStyle(
            fontSize: AppFontSize.xl4,
            fontWeight: AppFontWeight.extraBold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Masuk untuk mulai berjualan & kelola stok barang',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppFontSize.md,
            fontWeight: AppFontWeight.regular,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoAccountInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Text(
                'Akun demo · kata sandi admin123',
                style: AppTextStyle.labelMd.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildDemoChip('admin', 'Admin', Icons.admin_panel_settings_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _buildDemoChip('kasir', 'Kasir', Icons.point_of_sale_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoChip(String username, String label, IconData icon) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _fillDemoAccount(username),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyle.labelMd),
                    Text(username, style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Masuk ke Akun', style: AppTextStyle.titleLg),
              const SizedBox(height: 6),
              const Text(
                'Silakan masuk dengan akun yang sudah terdaftar',
                style: AppTextStyle.bodySm,
              ),
              const SizedBox(height: 16),
              _buildDemoAccountInfo(),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Username',
                hint: 'Masukkan username',
                prefixIcon: Icons.person_outline_rounded,
                controller: _usernameController,
                focusNode: _usernameFocus,
                isRequired: true,
                showRequiredMark: false,
                validator: AppValidator.username,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Kata Sandi',
                hint: 'Masukkan kata sandi',
                type: FieldType.password,
                controller: _passwordController,
                focusNode: _passwordFocus,
                isRequired: true,
                showRequiredMark: false,
                validator: AppValidator.password,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 28),
              BlocSelector<AuthCubit, AuthState, bool>(
                selector: (state) => state.status == AuthStatus.loading,
                builder: (context, isLoading) {
                  return AppButton(
                    label: 'Masuk',
                    isLoading: isLoading,
                    onPressed: _handleLogin,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
