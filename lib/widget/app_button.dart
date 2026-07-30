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
  final IconData? icon;
  final double height;
  final double? width;
  final double? borderRadius;
  final double? fontSize;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 52,
    this.width,
    this.borderRadius,
    this.fontSize,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    // Padding vertikal bawaan tema (elevatedButtonTheme di main.dart) diukur
    // untuk tinggi 52 — kalau height di-custom lebih kecil, padding itu tetap
    // dipaksakan tema dan bikin isi tombol kepotong. Override padding
    // vertikal jadi 0 tiap kali height/borderRadius di-custom, biar tinggi
    // konten murni diatur oleh SizedBox di luar.
    final isCustomSize = height != 52 || borderRadius != null;

    // expand:false -> lebar tidak dipaksa, tombol menyesuaikan panjang label
    // (SizedBox tanpa constraint width, ElevatedButton shrink ke kontennya).
    return SizedBox(
      width: !expand ? width : (width ?? double.infinity),
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: !isCustomSize
            ? null
            : ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: borderRadius == null
                    ? null
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius!),
                      ),
              ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : (icon == null
                  ? Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: fontSize == null
                          ? null
                          : TextStyle(fontSize: fontSize),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: fontSize == null
                                ? null
                                : TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ],
                    )),
      ),
    );
  }
}
