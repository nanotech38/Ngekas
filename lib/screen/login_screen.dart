import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/const/app_validator_const.dart';
import 'package:ngekas/logic/login_logic.dart';
import 'package:ngekas/screen/home_screen.dart';
import 'package:ngekas/screen/register_screen.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    LoginLogic.handleLogin(
      context: context,
      formKey: _formKey,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
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
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            size: 38,
            color: Colors.white,
          ),
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
          'Masuk untuk mulai mencatat penjualanmu',
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
              const SizedBox(height: 28),
              AppTextField(
                label: 'Email',
                hint: 'Masukan Email',
                type: FieldType.email,
                controller: _emailController,
                focusNode: _emailFocus,
                isRequired: true,
                showRequiredMark: false,
                validator: AppValidator.email,
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: arahkan ke halaman lupa kata sandi
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Lupa Kata Sandi?',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      fontWeight: AppFontWeight.semiBold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('atau', style: AppTextStyle.bodySm),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun? ',
                      style: AppTextStyle.bodyMd,
                    ),
                    GestureDetector(
                      onTap: () =>
                          NavigationService.get().push(const RegisterScreen()),
                      child: const Text(
                        'Daftar Sekarang',
                        style: TextStyle(
                          fontSize: AppFontSize.md,
                          fontWeight: AppFontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
