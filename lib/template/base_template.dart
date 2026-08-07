import 'package:flutter/material.dart';

// ─── BaseTemplate ───────────────────────────────────────────────────────────
//
// Scaffold bersama dipakai di SEMUA halaman biar behaviour dasarnya (SafeArea,
// resizeToAvoidBottomInset, dst) selalu konsisten — halaman cukup kirim
// AppBar/FAB/bottomNavigationBar/backgroundColor lewat parameter, tidak perlu
// bikin Scaffold sendiri-sendiri.
//
// Dua mode background:
// - `backgroundColor` diisi (mis. AppColors.background) -> halaman konten
//   biasa (Beranda, Laporan, Kategori, Profil, dll), background solid.
// - `backgroundColor` dibiarkan null (default) -> body pakai gradient teal
//   full-bleed, dipakai Splash/Login/Register yang tanpa AppBar.

class BaseTemplate extends StatelessWidget {
  const BaseTemplate({
    super.key,
    required this.child,
    this.appBar,
    this.backgroundColor,
    this.gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF134E4A),
        Color(0xFF0F766E),
        Color(0xFF0D9488),
      ],
      stops: [0.0, 0.5, 1.0],
    ),
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Gradient gradient;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool? resizeToAvoidBottomInset;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    // backgroundColor null berarti belum ada halaman konten solid yang minta
    // -> fallback ke gradient (perilaku lama, dipakai Splash/Login/Register).
    final useGradient = backgroundColor == null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: useGradient ? BoxDecoration(gradient: gradient) : null,
        child: SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: child),
      ),
    );
  }
}
