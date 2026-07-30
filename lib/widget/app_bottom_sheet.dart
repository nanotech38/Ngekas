import 'package:flutter/material.dart';
import 'package:ngekas/const/app_theme_const.dart';

// ─── AppBottomSheet ─────────────────────────────────────────────────────────
//
// Wrapper showModalBottomSheet supaya tampilannya (rounded top, drag handle,
// padding, SafeArea) konsisten di semua halaman — konten spesifik tiap
// halaman cukup dikirim lewat parameter `builder`. Dibungkus SafeArea(top:
// false) supaya konten tidak kepotong system UI (gesture bar/home indicator)
// di bagian bawah layar.

class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              builder(context),
            ],
          ),
        ),
      ),
    );
  }
}
