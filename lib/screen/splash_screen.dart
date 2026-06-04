import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/splash/splash_cubit.dart';
import 'package:ngekas/const/app_rc_const.dart';
import 'package:ngekas/const/app_theme_const.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _logoController.forward().then((_) {
      if (mounted) context.read<SplashCubit>().initialize();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _animateProgress(double target) {
    final current = _progressAnimation.value;
    _progressAnimation = Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state.inLoading) {
          _animateProgress(state.progress);
        }
        if (state.rc == rcSuccess) {
          _animateProgress(1.0);
          Future.delayed(const Duration(milliseconds: 600), () {
            // TODO: ganti dengan halaman utama setelah dibuat
            // NavigationService.get().pushAndRemoveAll(const HomeScreen());
          });
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF134E4A),
                Color(0xFF0F766E),
                Color(0xFF0D9488),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                _buildLogo(),
                const Spacer(flex: 3),
                _buildProgressSection(),
                const SizedBox(height: 48),
              ],
            ),
          ),
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
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 52,
                color: Colors.white,
              ),
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
              'Catatan Penjualan Usahamu',
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
        final message = state.message.isNotEmpty
            ? state.message
            : 'Memulai...';

        return Column(
          children: [
            _buildCircularProgress(isError: isError),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                message,
                key: ValueKey(message),
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: AppFontWeight.medium,
                  color: isError
                      ? const Color(0xFFFCA5A5)
                      : Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (isError) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.read<SplashCubit>().initialize(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: AppFontWeight.semiBold,
                      fontSize: AppFontSize.sm,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCircularProgress({required bool isError}) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, _) {
        final progress = _progressAnimation.value;
        final percent = (progress * 100).toInt();

        return SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 5,
                  color: Colors.white.withValues(alpha: 0.15),
                  strokeCap: StrokeCap.round,
                ),
              ),
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  color: isError ? const Color(0xFFFCA5A5) : Colors.white,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: AppFontSize.xl,
                  fontWeight: AppFontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
