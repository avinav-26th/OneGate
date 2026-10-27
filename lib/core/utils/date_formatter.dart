import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeOnlyFormat = DateFormat('hh:mm a');
  static final DateFormat _dateOnlyFormat = DateFormat('dd MMM yyyy');

  static String formatDisplay(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _displayFormat.format(dateTime.toLocal());
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _timeOnlyFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateOnlyFormat.format(dateTime.toLocal());
  }

  static String toIso(DateTime dateTime) {
    return dateTime.toLocal().toIso8601String();
  }

  static DateTime? fromIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    return parsed?.toLocal();
  }

  static bool isToday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final now = DateTime.now();
    final local = dateTime.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }
}
