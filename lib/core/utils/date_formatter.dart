import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String formatShortDay(DateTime dateTime) {
    return DateFormat('E').format(dateTime);
  }

  static String formatMonthYear(DateTime dateTime) {
    return DateFormat('MMMM yyyy').format(dateTime);
  }
}
