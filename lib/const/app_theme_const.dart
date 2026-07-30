import 'package:flutter/material.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Primary — Teal
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryContainer = Color(0xFFCCFBF1);

  // Secondary — Amber
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondaryContainer = Color(0xFFFEF3C7);

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Border
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = primary;

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFFCBD5E1);
  static const Color textDisabled = Color(0xFF94A3B8);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Income & Expense — khusus catatan penjualan
  static const Color income = Color(0xFF16A34A);
  static const Color incomeBackground = Color(0xFFDCFCE7);
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseBackground = Color(0xFFFEE2E2);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
  static const Color divider = Color(0xFFE2E8F0);
  static const Color overlay = Color(0x80000000);
}

// ─── Font Sizes ───────────────────────────────────────────────────────────────

class AppFontSize {
  AppFontSize._();

  static const double xs = 11.0;
  static const double sm = 12.0;
  static const double base = 13.0;
  static const double md = 14.0;
  static const double lg = 15.0;
  static const double xl = 16.0;
  static const double xl2 = 18.0;
  static const double xl3 = 20.0;
  static const double xl4 = 22.0;
  static const double xl5 = 24.0;
  static const double xl6 = 28.0;
  static const double xl7 = 32.0;
}

// ─── Font Weights ─────────────────────────────────────────────────────────────

class AppFontWeight {
  AppFontWeight._();

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
}

// ─── Text Styles ──────────────────────────────────────────────────────────────

class AppTextStyle {
  AppTextStyle._();

  // Heading
  static const TextStyle h1 = TextStyle(
    fontSize: AppFontSize.xl7,
    fontWeight: AppFontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: AppFontSize.xl6,
    fontWeight: AppFontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: AppFontSize.xl5,
    fontWeight: AppFontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: AppFontSize.xl4,
    fontWeight: AppFontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Title
  static const TextStyle titleLg = TextStyle(
    fontSize: AppFontSize.xl2,
    fontWeight: AppFontWeight.semiBold,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleMd = TextStyle(
    fontSize: AppFontSize.xl,
    fontWeight: AppFontWeight.semiBold,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleSm = TextStyle(
    fontSize: AppFontSize.lg,
    fontWeight: AppFontWeight.semiBold,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontSize: AppFontSize.lg,
    fontWeight: AppFontWeight.regular,
    color: AppColors.textSecondary,
  );
  static const TextStyle bodyMd = TextStyle(
    fontSize: AppFontSize.md,
    fontWeight: AppFontWeight.regular,
    color: AppColors.textSecondary,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: AppFontSize.base,
    fontWeight: AppFontWeight.regular,
    color: AppColors.textMuted,
  );

  // Label
  static const TextStyle labelLg = TextStyle(
    fontSize: AppFontSize.base,
    fontWeight: AppFontWeight.semiBold,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );
  static const TextStyle labelMd = TextStyle(
    fontSize: AppFontSize.sm,
    fontWeight: AppFontWeight.semiBold,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );
  static const TextStyle labelSm = TextStyle(
    fontSize: AppFontSize.xs,
    fontWeight: AppFontWeight.medium,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  // Currency — khusus angka nominal
  static const TextStyle currencyLg = TextStyle(
    fontSize: AppFontSize.xl5,
    fontWeight: AppFontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );
  static const TextStyle currencyMd = TextStyle(
    fontSize: AppFontSize.xl2,
    fontWeight: AppFontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle currencySm = TextStyle(
    fontSize: AppFontSize.lg,
    fontWeight: AppFontWeight.semiBold,
    color: AppColors.textPrimary,
  );
}
