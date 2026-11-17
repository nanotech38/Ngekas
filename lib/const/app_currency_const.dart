class AppCurrency {
  AppCurrency._();

  static String format(int amount) => 'Rp${formatDigits(amount)}';

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
