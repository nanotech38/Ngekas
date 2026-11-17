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

  static const _monthNamesLong = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const _weekdayNamesShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  static String format(DateTime date) =>
      '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

  static String weekdayShort(DateTime date) => _weekdayNamesShort[date.weekday - 1];

  static String monthYear(DateTime date) => '${_monthNamesLong[date.month - 1]} ${date.year}';

  static String formatDateTime(DateTime date) => '${format(date)} ${time(date)}';

  static String time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  static String weekdayDate(DateTime date) => '${weekdayShort(date)}, ${format(date)}';
}
