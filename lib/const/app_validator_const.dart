// ─── AppValidator ───────────────────────────────────────────────────────────
//
// Kumpulan validator untuk AppTextField yang dipakai bersama di seluruh
// halaman (bukan cuma login), supaya aturan validasi tidak diduplikasi
// per-screen.

class AppValidator {
  AppValidator._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi';
    }
    if (value != password) {
      return 'Konfirmasi kata sandi tidak sama';
    }
    return null;
  }
}
