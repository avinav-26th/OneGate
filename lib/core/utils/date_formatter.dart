import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeOnlyFormat = DateFormat('hh:mm a');
  static final DateFormat _dateOnlyFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  // date and time formatting helpers
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

  // parse string timestamps or epoch numbers
  static DateTime? fromIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed != null) return parsed.toLocal();
    final millis = int.tryParse(iso);
    if (millis != null) {
      if (millis > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
      } else {
        return DateTime.fromMillisecondsSinceEpoch(millis * 1000).toLocal();
      }
    }
    return null;
  }

  static bool isToday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final now = DateTime.now();
    final local = dateTime.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  static bool isYesterday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final local = dateTime.toLocal();
    return local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
  }

  static bool isThisWeek(DateTime? dateTime) {
    if (dateTime == null) return false;
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final diff = now.difference(local).inDays;
    return diff >= 0 && diff <= 7;
  }

  static bool isThisMonth(DateTime? dateTime) {
    if (dateTime == null) return false;
    final now = DateTime.now();
    final local = dateTime.toLocal();
    return local.year == now.year && local.month == now.month;
  }

  // groups dates into buckets for list headers
  static String getDateGroup(DateTime? dateTime) {
    if (dateTime == null) return 'Older';
    if (isToday(dateTime)) return 'Today';
    if (isYesterday(dateTime)) return 'Yesterday';
    if (isThisWeek(dateTime)) return 'This Week';
    if (isThisMonth(dateTime)) return 'This Month';
    return _monthYearFormat.format(dateTime.toLocal());
  }
}
