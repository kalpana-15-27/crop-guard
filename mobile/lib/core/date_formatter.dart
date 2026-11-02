/// Core Date and Time Formatting Utilities for CropGuard AI
///
/// Correctly parses UTC ISO8601 and SQL timestamps from backend/Supabase
/// and formats them to the device's local timezone (e.g. IST) using a 24-hour clock.
class AppDateFormatter {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Parses a UTC timestamp string or DateTime object into the device's local DateTime.
  ///
  /// Guarantees that timestamps lacking explicit timezone designators from backend/SQL
  /// are treated as UTC before converting to local time.
  static DateTime parseUtcToLocal(dynamic input) {
    if (input == null) return DateTime.now();
    if (input is DateTime) {
      return input.isUtc ? input.toLocal() : input;
    }
    if (input is String) {
      String str = input.trim();
      if (str.isEmpty) return DateTime.now();
      // If the string lacks 'Z' or offset (+HH:mm/-HH:mm), append 'Z' so it is parsed as UTC
      if (!str.endsWith('Z') && !RegExp(r'[+-]\d{2}(:?\d{2})?$').hasMatch(str)) {
        str = '${str.replaceAll(' ', 'T')}Z';
      }
      try {
        final parsed = DateTime.parse(str);
        return parsed.toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Formats a DateTime to consistent 'dd MMM yyyy, HH:mm' (e.g. '02 Nov 2026, 10:34')
  /// using the 24-hour clock format without AM/PM.
  static String formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _months[local.month - 1];
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  /// Formats a DateTime to 24-hour time 'HH:mm' (e.g. '10:34') without AM/PM.
  static String formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formats a DateTime to date only 'dd MMM yyyy' (e.g. '02 Nov 2026').
  static String formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _months[local.month - 1];
    final year = local.year.toString();
    return '$day $month $year';
  }
}
