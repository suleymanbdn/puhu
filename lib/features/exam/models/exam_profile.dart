import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'exam_profile.g.dart';

/// YKS sınav türü (kullanıcının hedefi)
@HiveType(typeId: 9)
enum ExamType {
  /// Sadece TYT (önlisans hedefi)
  @HiveField(0)
  tyt,

  /// TYT + AYT Sayısal (Mat-Fen)
  @HiveField(1)
  sayisal,

  /// TYT + AYT Eşit Ağırlık
  @HiveField(2)
  esitAgirlik,

  /// TYT + AYT Sözel
  @HiveField(3)
  sozel,

  /// TYT + YDT (Yabancı Dil)
  @HiveField(4)
  dil;

  String get title {
    switch (this) {
      case ExamType.tyt:
        return 'TYT (Önlisans)';
      case ExamType.sayisal:
        return 'Sayısal (SAY)';
      case ExamType.esitAgirlik:
        return 'Eşit Ağırlık (EA)';
      case ExamType.sozel:
        return 'Sözel (SÖZ)';
      case ExamType.dil:
        return 'Dil (DİL)';
    }
  }

  String get description {
    switch (this) {
      case ExamType.tyt:
        return 'Sadece TYT • 2 yıllık önlisans';
      case ExamType.sayisal:
        return 'TYT + AYT • Mühendislik, Tıp, Fen';
      case ExamType.esitAgirlik:
        return 'TYT + AYT • Hukuk, Psikoloji, İşletme';
      case ExamType.sozel:
        return 'TYT + AYT • Edebiyat, Tarih, Sosyoloji';
      case ExamType.dil:
        return 'TYT + YDT • İngilizce, Almanca, Fransızca';
    }
  }

  IconData get icon {
    switch (this) {
      case ExamType.tyt:
        return Icons.school_outlined;
      case ExamType.sayisal:
        return Icons.calculate_outlined;
      case ExamType.esitAgirlik:
        return Icons.balance_outlined;
      case ExamType.sozel:
        return Icons.menu_book_outlined;
      case ExamType.dil:
        return Icons.language_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ExamType.tyt:
        return const Color(0xFF6366F1);
      case ExamType.sayisal:
        return const Color(0xFF3B82F6);
      case ExamType.esitAgirlik:
        return const Color(0xFFF59E0B);
      case ExamType.sozel:
        return const Color(0xFFEF4444);
      case ExamType.dil:
        return const Color(0xFFEC4899);
    }
  }
}

/// Kullanıcının YKS profili
///
/// Onboarding'de oluşturulur. Tek instance — `box.get('current')` ile erişilir.
@HiveType(typeId: 10)
class ExamProfile extends HiveObject {
  /// Hive box'ta kullanılan sabit anahtar
  static const String boxKey = 'current';

  @HiveField(0)
  final ExamType examType;

  @HiveField(1)
  final String? targetUniversity;

  @HiveField(2)
  final String? targetDepartment;

  /// Hedef toplam net (tahmini)
  @HiveField(3)
  final double? targetNet;

  /// Sınav tarihi (kullanıcı veya sabit YKS tarihi)
  @HiveField(4)
  final DateTime examDate;

  /// Günlük çalışma hedefi (saat)
  @HiveField(5)
  final double dailyTargetHours;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  ExamProfile({
    required this.examType,
    this.targetUniversity,
    this.targetDepartment,
    this.targetNet,
    required this.examDate,
    this.dailyTargetHours = 4.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Sınava kalan gün sayısı
  int get daysUntilExam {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exam = DateTime(examDate.year, examDate.month, examDate.day);
    return exam.difference(today).inDays;
  }

  /// Haftalık çalışma hedefi (saat)
  double get weeklyTargetHours => dailyTargetHours * 7;

  ExamProfile copyWith({
    ExamType? examType,
    String? targetUniversity,
    String? targetDepartment,
    double? targetNet,
    DateTime? examDate,
    double? dailyTargetHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamProfile(
      examType: examType ?? this.examType,
      targetUniversity: targetUniversity ?? this.targetUniversity,
      targetDepartment: targetDepartment ?? this.targetDepartment,
      targetNet: targetNet ?? this.targetNet,
      examDate: examDate ?? this.examDate,
      dailyTargetHours: dailyTargetHours ?? this.dailyTargetHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
