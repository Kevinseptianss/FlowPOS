class DatetimeFormatter {
  static DateTime get now => DateTime.now();

  static List<String> monthsId = [
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

  static String formatDateYear(DateTime? date) {
    final d = (date ?? DateTime.now()).toLocal();
    return "${d.day} ${monthsId[d.month - 1]} ${d.year}";
  }

  static String formatIndonesian(DateTime date, {bool includeTime = false}) {
    final localDate = date.toLocal();
    final timeStr = includeTime 
      ? " • ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}" 
      : "";
    return "${localDate.day} ${monthsId[localDate.month - 1]} ${localDate.year}$timeStr";
  }

  static String formatDateTime(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
