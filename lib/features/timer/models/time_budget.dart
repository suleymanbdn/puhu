import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../subjects/models/subject.dart';

part 'time_budget.g.dart';

/// Zaman bütçesi modeli - Haftalık hedefler
@HiveType(typeId: 6)
class TimeBudget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryName;

  @HiveField(2)
  final int targetMinutesPerWeek;

  @HiveField(3)
  int spentMinutes;

  @HiveField(4)
  final DateTime weekStartDate;

  @HiveField(5)
  final Color? customColor;

  @HiveField(6)
  final IconData? customIcon;

  TimeBudget({
    required this.id,
    required this.categoryName,
    required this.targetMinutesPerWeek,
    this.spentMinutes = 0,
    required this.weekStartDate,
    this.customColor,
    this.customIcon,
  });

  /// Hedef saat cinsinden
  double get targetHours => targetMinutesPerWeek / 60;

  /// Harcanan saat cinsinden
  double get spentHours => spentMinutes / 60;

  /// Kalan dakika
  int get remainingMinutes => (targetMinutesPerWeek - spentMinutes).clamp(0, targetMinutesPerWeek);

  /// Kalan saat
  double get remainingHours => remainingMinutes / 60;

  /// İlerleme yüzdesi (0-1)
  double get progress {
    if (targetMinutesPerWeek == 0) return 0;
    return (spentMinutes / targetMinutesPerWeek).clamp(0.0, 1.0);
  }

  /// Hedef aşıldı mı?
  bool get isOverBudget => spentMinutes > targetMinutesPerWeek;

  /// Hedef tamamlandı mı?
  bool get isCompleted => spentMinutes >= targetMinutesPerWeek;

  /// Subject (categoryName aslında Subject.id)
  Subject? get subject => Subject.fromId(categoryName);

  /// Kategori rengi (Subject'ten)
  Color get color {
    if (customColor != null) return customColor!;
    return subject?.color ?? const Color(0xFF6366F1);
  }

  /// Kategori ikonu (Subject'ten)
  IconData get icon {
    if (customIcon != null) return customIcon!;
    return subject?.icon ?? Icons.timer_outlined;
  }

  /// Görüntülenecek isim (Subject.title varsa onu döndür)
  String get displayName => subject?.title ?? categoryName;

  TimeBudget copyWith({
    String? id,
    String? categoryName,
    int? targetMinutesPerWeek,
    int? spentMinutes,
    DateTime? weekStartDate,
    Color? customColor,
    IconData? customIcon,
  }) {
    return TimeBudget(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      targetMinutesPerWeek: targetMinutesPerWeek ?? this.targetMinutesPerWeek,
      spentMinutes: spentMinutes ?? this.spentMinutes,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      customColor: customColor ?? this.customColor,
      customIcon: customIcon ?? this.customIcon,
    );
  }
}

/// YKS dersleri için varsayılan haftalık zaman bütçeleri
///
/// Dersin soru sayısına göre proportionel olarak hedef saat ataması yapar.
/// Toplam hedef ~30 saat/hafta (4-5 saat/gün) varsayılıdır; kullanıcı
/// onboarding sonrasında ayarlayabilir.
class DefaultBudgets {
  /// Bir sınav tipi için ders bütçeleri oluşturur
  static List<TimeBudget> forExamType(
    ExamTypeFilter examType,
    DateTime weekStart, {
    double weeklyTotalHours = 30,
  }) {
    final subjects = Subject.forExamType(examType);
    if (subjects.isEmpty) return [];

    final totalQuestions =
        subjects.fold<int>(0, (sum, s) => sum + s.questionCount);
    final totalMinutes = (weeklyTotalHours * 60).round();

    return subjects.map((s) {
      // Soru sayısı oranında dakika tahsis et, minimum 60 dk
      final share = totalQuestions == 0
          ? totalMinutes ~/ subjects.length
          : (totalMinutes * s.questionCount / totalQuestions).round();
      final allocated = share < 60 ? 60 : share;
      return TimeBudget(
        id: '${s.id}_budget',
        categoryName: s.id,
        targetMinutesPerWeek: allocated,
        weekStartDate: weekStart,
      );
    }).toList();
  }
}


