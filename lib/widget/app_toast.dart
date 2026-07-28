import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ngekas/const/app_theme_const.dart';

// ─── AppToast ───────────────────────────────────────────────────────────────
//
// Notifikasi sekilas (auto-hilang, tidak perlu di-dismiss user) — beda dengan
// AppDialog yang dipakai khusus untuk error/konfirmasi yang wajib dibaca user.
// Dipasang lewat Overlay root MaterialApp, jadi tetap muncul walau layar
// pemanggilnya langsung di-pop/diganti (mis. sukses registrasi lalu pindah
// ke HomeScreen).

enum AppToastType { success, warning, error }

class _ToastVisual {
  final IconData icon;
  final Color color;

  const _ToastVisual({required this.icon, required this.color});
}

class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.success,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlayState = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismissed: () => entry.remove(),
      ),
    );
    overlayState.insert(entry);
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) => show(
    context,
    message: message,
    type: AppToastType.success,
    duration: duration,
  );

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) => show(
    context,
    message: message,
    type: AppToastType.warning,
    duration: duration,
  );

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) => show(
    context,
    message: message,
    type: AppToastType.error,
    duration: duration,
  );
}

class _AppToastWidget extends StatefulWidget {
  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _AppToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  _ToastVisual get _visual {
    switch (widget.type) {
      case AppToastType.success:
        return const _ToastVisual(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        );
      case AppToastType.warning:
        return const _ToastVisual(
          icon: Icons.info_rounded,
          color: AppColors.warning,
        );
      case AppToastType.error:
        return const _ToastVisual(
          icon: Icons.error_rounded,
          color: AppColors.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;

    return Positioned(
      left: 24,
      right: 24,
      // Jarak dari bawah layar. Makin besar angkanya, makin naik ke atas
      // posisi toast-nya.
      bottom: MediaQuery.of(context).padding.bottom + 48,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(visual.icon, color: visual.color, size: 22),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.md,
                        fontWeight: AppFontWeight.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
