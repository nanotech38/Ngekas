import 'package:flutter/material.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/widget/app_button.dart';

// ─── AppDialog ──────────────────────────────────────────────────────────────
//
// Dialog konfirmasi/notifikasi dengan 3 varian visual: sukses, warning/info,
// error. Dipanggil lewat method statis (AppDialog.showSuccess/showWarning/
// showError, atau AppDialog.show untuk kontrol penuh), bukan langsung
// showDialog manual, supaya tampilannya selaras di seluruh halaman.

enum AppDialogType { success, warning, error }

class _DialogVisual {
  final IconData icon;
  final Color color;
  final Color background;

  const _DialogVisual({
    required this.icon,
    required this.color,
    required this.background,
  });
}

class AppDialog extends StatelessWidget {
  final AppDialogType type;
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback? onConfirm;
  final String? cancelText;
  final VoidCallback? onCancel;

  const AppDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.confirmText = 'OK',
    this.onConfirm,
    this.cancelText,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required AppDialogType type,
    required String title,
    required String message,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
    String? cancelText,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AppDialog(
        type: type,
        title: title,
        message: message,
        confirmText: confirmText,
        onConfirm: onConfirm,
        cancelText: cancelText,
        onCancel: onCancel,
      ),
    );
  }

  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) => show(
    context,
    type: AppDialogType.success,
    title: title,
    message: message,
    confirmText: confirmText,
    onConfirm: onConfirm,
  );

  static Future<void> showWarning(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) => show(
    context,
    type: AppDialogType.warning,
    title: title,
    message: message,
    confirmText: confirmText,
    onConfirm: onConfirm,
  );

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) => show(
    context,
    type: AppDialogType.error,
    title: title,
    message: message,
    confirmText: confirmText,
    onConfirm: onConfirm,
  );

  _DialogVisual get _visual {
    switch (type) {
      case AppDialogType.success:
        return const _DialogVisual(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          background: AppColors.successLight,
        );
      case AppDialogType.warning:
        return const _DialogVisual(
          icon: Icons.info_rounded,
          color: AppColors.warning,
          background: AppColors.warningLight,
        );
      case AppDialogType.error:
        return const _DialogVisual(
          icon: Icons.error_rounded,
          color: AppColors.error,
          background: AppColors.errorLight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: visual.background,
                shape: BoxShape.circle,
              ),
              child: Icon(visual.icon, color: visual.color, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle.titleLg,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyMd,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onCancel?.call();
                        },
                        child: Text(cancelText!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: AppButton(
                    label: confirmText,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
