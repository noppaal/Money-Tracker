import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _fullDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final DateFormat _shortDate = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _timeOnly = DateFormat('HH:mm', 'id_ID');

  /// Formats date to user-friendly group header
  /// e.g. "Hari Ini (27 Okt 2026)", "Kemarin (26 Okt 2026)" or "Minggu, 25 Okt 2026"
  static String formatGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Hari Ini, ${DateFormat('d MMM yyyy', 'id_ID').format(date)}';
    } else if (target == yesterday) {
      return 'Kemarin, ${DateFormat('d MMM yyyy', 'id_ID').format(date)}';
    } else {
      return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
    }
  }

  static String formatShort(DateTime date) => _shortDate.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);
  static String formatTime(DateTime date) => _timeOnly.format(date);

  /// Returns remaining days in the given month, including today
  static int getRemainingDaysInMonth(DateTime date) {
    final now = DateTime.now();
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    if (date.year == now.year && date.month == now.month) {
      return (daysInMonth - now.day + 1).clamp(1, daysInMonth);
    }
    return daysInMonth;
  }
}
