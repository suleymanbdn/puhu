import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../tasks/models/task_enums.dart';

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

  /// Kategori rengi
  Color get color {
    if (customColor != null) return customColor!;
    
    // TaskCategory'den renk al
    try {
      final category = TaskCategory.values.firstWhere(
        (c) => c.title == categoryName || c.name == categoryName.toLowerCase(),
      );
      return category.color;
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  /// Kategori ikonu
  IconData get icon {
    if (customIcon != null) return customIcon!;
    
    try {
      final category = TaskCategory.values.firstWhere(
        (c) => c.title == categoryName || c.name == categoryName.toLowerCase(),
      );
      return category.icon;
    } catch (_) {
      return Icons.timer_outlined;
    }
  }

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

/// Varsayılan kategori bütçeleri
class DefaultBudgets {
  static List<TimeBudget> createDefaults(DateTime weekStart) {
    return [
      TimeBudget(
        id: 'work_budget',
        categoryName: 'İş',
        targetMinutesPerWeek: 30 * 60, // 30 saat
        weekStartDate: weekStart,
      ),
      TimeBudget(
        id: 'study_budget',
        categoryName: 'Eğitim',
        targetMinutesPerWeek: 10 * 60, // 10 saat
        weekStartDate: weekStart,
      ),
      TimeBudget(
        id: 'personal_budget',
        categoryName: 'Kişisel',
        targetMinutesPerWeek: 5 * 60, // 5 saat
        weekStartDate: weekStart,
      ),
      TimeBudget(
        id: 'health_budget',
        categoryName: 'Sağlık',
        targetMinutesPerWeek: 7 * 60, // 7 saat
        weekStartDate: weekStart,
      ),
    ];
  }
}


