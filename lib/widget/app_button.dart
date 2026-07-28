import 'package:flutter/material.dart';

// ─── AppButton ──────────────────────────────────────────────────────────────
//
// Tombol aksi utama (full width, tinggi 52) yang dipakai di seluruh halaman
// supaya tampilannya selaras. Warna & bentuknya ikut elevatedButtonTheme dari
// main.dart, jadi tidak perlu di-style ulang di sini.

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
