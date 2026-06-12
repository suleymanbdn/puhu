import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'focus_session.g.dart';

/// Kullanıcının odak oturumu sonrası hissi
@HiveType(typeId: 3)
enum FocusMood {
  @HiveField(0)
  happy,

  @HiveField(1)
  neutral,

  @HiveField(2)
  stressed;

  String get title {
    switch (this) {
      case FocusMood.happy:
        return 'Mutlu';
      case FocusMood.neutral:
        return 'Nötr';
      case FocusMood.stressed:
        return 'Stresli';
    }
  }

  String get emoji {
    switch (this) {
      case FocusMood.happy:
        return '😊';
      case FocusMood.neutral:
        return '😐';
      case FocusMood.stressed:
        return '😫';
    }
  }

  Color get color {
    switch (this) {
      case FocusMood.happy:
        return const Color(0xFF10B981);
      case FocusMood.neutral:
        return const Color(0xFFF59E0B);
      case FocusMood.stressed:
        return const Color(0xFFEF4444);
    }
  }
}

/// Odak oturumu tipi
@HiveType(typeId: 4)
enum FocusType {
  @HiveField(0)
  work,

  @HiveField(1)
  shortBreak,

  @HiveField(2)
  longBreak;

  String get title {
    switch (this) {
      case FocusType.work:
        return 'Çalışma';
      case FocusType.shortBreak:
        return 'Kısa Ara';
      case FocusType.longBreak:
        return 'Uzun Ara';
    }
  }

  int get defaultMinutes {
    switch (this) {
      case FocusType.work:
        return 25;
      case FocusType.shortBreak:
        return 5;
      case FocusType.longBreak:
        return 15;
    }
  }

  Color get color {
    switch (this) {
      case FocusType.work:
        // Marka imza rengi (dark theme primary ile aynı neon cyan)
        return const Color(0xFF00F0FF);
      case FocusType.shortBreak:
        return const Color(0xFF0EA5E9);
      case FocusType.longBreak:
        return const Color(0xFF8B5CF6);
    }
  }
}

/// Odak oturumu modeli
@HiveType(typeId: 5)
class FocusSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final FocusType type;

  @HiveField(2)
  final int plannedMinutes;

  @HiveField(3)
  final int actualMinutes;

  @HiveField(4)
  final FocusMood? mood;

  @HiveField(5)
  final DateTime startTime;

  @HiveField(6)
  final DateTime? endTime;

  @HiveField(7)
  final String? taskId;

  @HiveField(8)
  final String? categoryName;

  @HiveField(9)
  final String? note;

  FocusSession({
    required this.id,
    required this.type,
    required this.plannedMinutes,
    required this.actualMinutes,
    this.mood,
    required this.startTime,
    this.endTime,
    this.taskId,
    this.categoryName,
    this.note,
  });

  FocusSession copyWith({
    String? id,
    FocusType? type,
    int? plannedMinutes,
    int? actualMinutes,
    FocusMood? mood,
    DateTime? startTime,
    DateTime? endTime,
    String? taskId,
    String? categoryName,
    String? note,
  }) {
    return FocusSession(
      id: id ?? this.id,
      type: type ?? this.type,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      mood: mood ?? this.mood,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      taskId: taskId ?? this.taskId,
      categoryName: categoryName ?? this.categoryName,
      note: note ?? this.note,
    );
  }

  /// Oturum tamamlandı mı?
  bool get isCompleted => endTime != null;

  /// Tamamlanma yüzdesi
  double get completionRate {
    if (plannedMinutes == 0) return 0;
    return (actualMinutes / plannedMinutes).clamp(0.0, 1.0);
  }
}
