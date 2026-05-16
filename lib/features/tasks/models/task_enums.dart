import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'task_enums.g.dart';

/// Görev kategorisi
@HiveType(typeId: 1)
enum TaskCategory {
  @HiveField(0)
  work,

  @HiveField(1)
  personal,

  @HiveField(2)
  study,

  @HiveField(3)
  health;

  /// Kategori başlığı
  String get title {
    switch (this) {
      case TaskCategory.work:
        return 'İş';
      case TaskCategory.personal:
        return 'Kişisel';
      case TaskCategory.study:
        return 'Eğitim';
      case TaskCategory.health:
        return 'Sağlık';
    }
  }

  /// Kategori ikonu
  IconData get icon {
    switch (this) {
      case TaskCategory.work:
        return Icons.work_outline;
      case TaskCategory.personal:
        return Icons.person_outline;
      case TaskCategory.study:
        return Icons.school_outlined;
      case TaskCategory.health:
        return Icons.favorite_outline;
    }
  }

  /// Kategori rengi
  Color get color {
    switch (this) {
      case TaskCategory.work:
        return const Color(0xFF6366F1); // Indigo
      case TaskCategory.personal:
        return const Color(0xFF8B5CF6); // Purple
      case TaskCategory.study:
        return const Color(0xFF0EA5E9); // Sky Blue
      case TaskCategory.health:
        return const Color(0xFF10B981); // Emerald
    }
  }
}

/// Görev önceliği
@HiveType(typeId: 2)
enum TaskPriority {
  @HiveField(0)
  low,

  @HiveField(1)
  medium,

  @HiveField(2)
  high;

  /// Öncelik başlığı
  String get title {
    switch (this) {
      case TaskPriority.low:
        return 'Düşük';
      case TaskPriority.medium:
        return 'Orta';
      case TaskPriority.high:
        return 'Yüksek';
    }
  }

  /// Öncelik rengi
  Color get color {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFF6B7280); // Gray
      case TaskPriority.medium:
        return const Color(0xFFF59E0B); // Amber
      case TaskPriority.high:
        return const Color(0xFFEF4444); // Red
    }
  }

  /// Öncelik ikonu
  IconData get icon {
    switch (this) {
      case TaskPriority.low:
        return Icons.arrow_downward;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.arrow_upward;
    }
  }
}


