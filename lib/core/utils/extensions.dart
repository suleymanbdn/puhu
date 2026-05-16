import 'package:flutter/material.dart';

/// String extension'ları
extension StringExtension on String {
  /// İlk harfi büyük yapar
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Boş veya sadece boşluk karakterlerinden mi oluşuyor
  bool get isBlank => trim().isEmpty;

  /// Boş değil ve içerik var mı
  bool get isNotBlank => trim().isNotEmpty;
}

/// DateTime extension'ları
extension DateTimeExtension on DateTime {
  /// Sadece tarih kısmını alır (saat bilgisi sıfırlanır)
  DateTime get dateOnly => DateTime(year, month, day);

  /// Aynı gün mü kontrol eder
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Geçmiş mi kontrol eder
  bool get isPast => isBefore(DateTime.now());

  /// Gelecek mi kontrol eder
  bool get isFuture => isAfter(DateTime.now());
}

/// BuildContext extension'ları
extension ContextExtension on BuildContext {
  /// Theme'e kolay erişim
  ThemeData get theme => Theme.of(this);

  /// ColorScheme'e kolay erişim
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// TextTheme'e kolay erişim
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// MediaQuery'ye kolay erişim
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Ekran boyutlarına kolay erişim
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Ekran genişliğine kolay erişim
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Ekran yüksekliğine kolay erişim
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Snackbar gösterimi
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// List extension'ları
extension ListExtension<T> on List<T> {
  /// Güvenli indeks erişimi
  T? safeGet(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}


