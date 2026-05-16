import 'package:hive_flutter/hive_flutter.dart';
import 'task_enums.dart';

part 'task_model.g.dart';

/// Görev modeli
/// 
/// Bu sınıf bir görevi temsil eder ve Hive veritabanında saklanabilir.
@HiveType(typeId: 0)
class Task extends HiveObject {
  /// Benzersiz görev kimliği
  @HiveField(0)
  final String id;

  /// Görev başlığı
  @HiveField(1)
  String title;

  /// Görev açıklaması
  @HiveField(2)
  String description;

  /// Görev kategorisi
  @HiveField(3)
  TaskCategory category;

  /// Görev önceliği
  @HiveField(4)
  TaskPriority priority;

  /// Görev tarihi
  @HiveField(5)
  DateTime date;

  /// Görev tamamlandı mı
  @HiveField(6)
  bool isCompleted;

  /// Göreve harcanan süre (dakika cinsinden)
  @HiveField(7)
  int durationSpent;

  /// Alt görevler (Checklist)
  @HiveField(8)
  List<String> subtasks;

  /// Oluşturulma tarihi
  @HiveField(9)
  final DateTime createdAt;

  /// Güncellenme tarihi
  @HiveField(10)
  DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.category = TaskCategory.personal,
    this.priority = TaskPriority.medium,
    required this.date,
    this.isCompleted = false,
    this.durationSpent = 0,
    this.subtasks = const [],
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Kopyalama metodu - güncellemeler için kullanılır
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? date,
    bool? isCompleted,
    int? durationSpent,
    List<String>? subtasks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      durationSpent: durationSpent ?? this.durationSpent,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Görevin geçmiş olup olmadığını kontrol eder
  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Görevin bugüne ait olup olmadığını kontrol eder
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, category: $category, '
        'priority: $priority, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}


