import 'package:intl/intl.dart';

/// Tarih işlemleri için yardımcı sınıf
class AppDateUtils {
  AppDateUtils._();

  /// Tarihi "14 Aralık 2025" formatında döndürür
  static String formatDateFull(DateTime date) {
    return DateFormat('d MMMM yyyy', 'en_US').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('d MMM', 'en_US').format(date);
  }

  /// Saati "14:30" formatında döndürür
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Tarihi "14.12.2025" formatında döndürür
  static String formatDateNumeric(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Dakikayı "1s 30dk" formatına çevirir
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  /// Bugün mü kontrol eder
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Yarın mı kontrol eder
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Günün başlangıcını döndürür
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Günün sonunu döndürür
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Haftanın başlangıcını döndürür (Pazartesi)
  static DateTime startOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysToSubtract)));
  }

  /// Ayın başlangıcını döndürür
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
}

