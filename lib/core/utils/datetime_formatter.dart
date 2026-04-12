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
    final d = date ?? DateTime.now();
    return "${d.day} ${monthsId[d.month - 1]} ${d.year}";
  }

  static String formatDateTime(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
