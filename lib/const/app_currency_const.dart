// ─── AppCurrency ────────────────────────────────────────────────────────────
//
// Util format nominal ke Rupiah (Rp1.234.567) tanpa perlu tambah dependency
// intl — dipakai di Laporan (list, form tambah entri) & ringkasan Home.

class AppCurrency {
  AppCurrency._();

  static String format(int amount) => 'Rp${formatDigits(amount)}';

  // Grup ribuan tanpa prefix "Rp" — dipakai buat prefill AppTextField
  // currency (mis. form edit laporan) yang butuh angkanya saja.
  static String formatDigits(int amount) {
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromRight = digits.length - i;
      buffer.write(digits[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }
}
