class DatetimeFormatter {
  static DateTime get now => DateTime.now();

  static List<String> month = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String formatDateYear([DateTime? date]) {
    if (date == null) {
      return "${month[now.month - 1]} ${now.year}";
    }

    return "${month[date.month - 1]} ${date.year}";
  }
}
