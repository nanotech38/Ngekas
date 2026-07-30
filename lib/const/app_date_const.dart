// ─── AppDate ────────────────────────────────────────────────────────────────
//
// Util format tanggal singkat (dd MMM yyyy) tanpa perlu tambah dependency intl
// — dipakai di layar Laporan (list, filter, form tambah entri).

class AppDate {
  AppDate._();

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const _weekdayNamesShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  static String format(DateTime date) =>
      '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

  static String weekdayShort(DateTime date) => _weekdayNamesShort[date.weekday - 1];

  // Dipakai Riwayat Aktivitas — butuh jam kejadian, bukan cuma tanggal.
  static String formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${format(date)} $hour:$minute';
  }
}
