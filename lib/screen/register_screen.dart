import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/const/app_validator_const.dart';
import 'package:ngekas/logic/register_logic.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_button.dart';
import 'package:ngekas/widget/app_dialog.dart';
import 'package:ngekas/widget/app_text_field.dart';
import 'package:ngekas/widget/app_toast.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _inviteCodeFocus = FocusNode();

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
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _inviteCodeFocus.dispose();
    super.dispose();
  }

  void _handleRegister() {
    RegisterLogic.handleRegister(
      context: context,
      formKey: _formKey,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      inviteCode: _inviteCodeController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.registerSuccess) {
          AppToast.showSuccess(context, 'Registrasi berhasil! Silakan masuk.');
          NavigationService.get().pop();
        } else if (state.status == AuthStatus.error) {
          AppDialog.showError(
            context,
            title: 'Gagal Daftar',
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
            Icons.person_add_alt_1_rounded,
            size: 38,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Buat Akun Baru',
          style: TextStyle(
            fontSize: AppFontSize.xl4,
            fontWeight: AppFontWeight.extraBold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Daftar untuk mulai mencatat pemasukan & pengeluaranmu',
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
              const Text('Daftar Akun', style: AppTextStyle.titleLg),
              const SizedBox(height: 6),
              const Text(
                'Isi data di bawah untuk membuat akun baru',
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
                showRequiredMark: true,
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
                showRequiredMark: true,
                validator: AppValidator.password,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_confirmPasswordFocus),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Konfirmasi Kata Sandi',
                hint: 'Ulangi kata sandi',
                type: FieldType.password,
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                isRequired: true,
                showRequiredMark: true,
                validator: (value) => AppValidator.confirmPassword(
                  value,
                  _passwordController.text,
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_inviteCodeFocus),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Kode Undangan',
                hint: 'Punya kode dari pemilik workspace?',
                controller: _inviteCodeController,
                focusNode: _inviteCodeFocus,
                isRequired: false,
                showRequiredMark: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleRegister(),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kosongkan kalau kamu mau daftar sebagai pemilik workspace baru. Isi kalau diajak gabung ke workspace orang lain.',
                style: AppTextStyle.bodySm,
              ),
              const SizedBox(height: 24),
              // Cuma rebuild saat status loading berubah, bukan tiap emit AuthState.
              BlocSelector<AuthCubit, AuthState, bool>(
                selector: (state) => state.status == AuthStatus.loading,
                builder: (context, isLoading) {
                  return AppButton(
                    label: 'Daftar',
                    isLoading: isLoading,
                    onPressed: _handleRegister,
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: AppTextStyle.bodyMd,
                    ),
                    GestureDetector(
                      onTap: () => NavigationService.get().pop(),
                      child: const Text(
                        'Masuk',
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
