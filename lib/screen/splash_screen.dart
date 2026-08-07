import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/splash/splash_cubit.dart';
import 'package:ngekas/const/app_rc_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/screen/home_screen.dart';
import 'package:ngekas/screen/login_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/template/base_template.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic));

    _logoController.forward().then((_) {
      if (mounted) {
        context.read<SplashCubit>().initialize(loadProfile: () => context.read<AuthCubit>().loadCurrentProfile());
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state.rc == rcSuccess) {
          // Profil (kalau isLoggedIn) sudah selesai dimuat di dalam
          // SplashCubit.initialize sebelum state ini di-emit, jadi
          // state.user di AuthCubit sudah siap saat HomeScreen tampil.
          Future.delayed(const Duration(milliseconds: 600), () {
            if (state.isLoggedIn) {
              NavigationService.get().pushAndRemoveAll(const HomeScreen());
            } else {
              NavigationService.get().pushAndRemoveAll(const LoginScreen());
            }
          });
        }
      },
      child: BaseTemplate(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _buildLogo(),
            const SizedBox(height: 40),
            _buildProgressSection(),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoOpacity,
      child: SlideTransition(
        position: _logoSlide,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset('assets/logo/icon_app.png', width: 96, height: 96),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ngekas',
              style: TextStyle(
                fontSize: AppFontSize.xl7,
                fontWeight: AppFontWeight.extraBold,
                color: Colors.white,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Catatan Pemasukan & Pengeluaran',
              style: TextStyle(
                fontSize: AppFontSize.md,
                fontWeight: AppFontWeight.regular,
                color: Colors.white.withValues(alpha: 0.75),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return BlocBuilder<SplashCubit, SplashState>(
      builder: (context, state) {
        final isError = state.rc == rcError;

        if (!isError) {
          return const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white, strokeCap: StrokeCap.round),
          );
        }

        final message = state.message.isNotEmpty ? state.message : 'Terjadi kesalahan';

        return Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 32),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: AppFontWeight.medium,
                color: Color(0xFFFCA5A5),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.read<SplashCubit>().initialize(
                loadProfile: () => context.read<AuthCubit>().loadCurrentProfile(),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(color: Colors.white, fontWeight: AppFontWeight.semiBold, fontSize: AppFontSize.sm),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
