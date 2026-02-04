import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../models/task_model.dart';
import '../models/task_enums.dart';

/// Task CRUD işlemlerini yöneten repository sınıfı
/// 
/// Bu sınıf, görevlerin Hive veritabanında saklanması,
/// güncellenmesi, silinmesi ve sorgulanması işlemlerini gerçekleştirir.
class TaskRepository {
  TaskRepository._();

  static TaskRepository? _instance;

  /// Singleton instance
  static TaskRepository get instance {
    _instance ??= TaskRepository._();
    return _instance!;
  }

  /// UUID generator
  final _uuid = const Uuid();

  /// Tasks box'a erişim
  Box<Task> get _tasksBox => Hive.box<Task>(AppConstants.tasksBox);

  // ============================================================
  // CREATE
  // ============================================================

  /// Yeni görev ekler
  Future<Task> addTask({
    required String title,
    String description = '',
    TaskCategory category = TaskCategory.personal,
    TaskPriority priority = TaskPriority.medium,
    required DateTime date,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      category: category,
      priority: priority,
      date: date,
    );

    await _tasksBox.put(task.id, task);
    return task;
  }

  // ============================================================
  // READ
  // ============================================================

  /// Tüm görevleri getirir
  List<Task> getAllTasks() {
    return _tasksBox.values.toList();
  }

  /// ID'ye göre görev getirir
  Task? getTaskById(String id) {
    return _tasksBox.get(id);
  }

  /// Belirli bir tarihe ait görevleri getirir
  List<Task> getTasksByDate(DateTime date) {
    return _tasksBox.values.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
  }

  /// Bugünün görevlerini getirir
  List<Task> getTodayTasks() {
    return getTasksByDate(DateTime.now());
  }

  /// Tamamlanmamış görevleri getirir
  List<Task> getIncompleteTasks() {
    return _tasksBox.values.where((task) => !task.isCompleted).toList();
  }

  /// Tamamlanmış görevleri getirir
  List<Task> getCompletedTasks() {
    return _tasksBox.values.where((task) => task.isCompleted).toList();
  }

  /// Kategoriye göre görevleri getirir
  List<Task> getTasksByCategory(TaskCategory category) {
    return _tasksBox.values.where((task) => task.category == category).toList();
  }

  /// Önceliğe göre görevleri getirir
  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasksBox.values.where((task) => task.priority == priority).toList();
  }

  /// Tarih aralığına göre görevleri getirir
  List<Task> getTasksByDateRange(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return _tasksBox.values.where((task) {
      return task.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          task.date.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();
  }

  /// Gecikmiş görevleri getirir
  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _tasksBox.values.where((task) {
      return !task.isCompleted && task.date.isBefore(today);
    }).toList();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// Görevi günceller
  Future<Task> updateTask(Task task) async {
    final updatedTask = task.copyWith(updatedAt: DateTime.now());
    await _tasksBox.put(task.id, updatedTask);
    return updatedTask;
  }

  /// Görevin tamamlanma durumunu değiştirir
  Future<Task> toggleTaskCompletion(String id) async {
    final task = _tasksBox.get(id);
    if (task == null) {
      throw Exception('Görev bulunamadı: $id');
    }

    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );

    await _tasksBox.put(id, updatedTask);
    return updatedTask;
  }

  /// Göreve süre ekler
  Future<Task> addDuration(String id, int minutes) async {
    final task = _tasksBox.get(id);
    if (task == null) {
      throw Exception('Görev bulunamadı: $id');
    }

    final updatedTask = task.copyWith(
      durationSpent: task.durationSpent + minutes,
      updatedAt: DateTime.now(),
    );

    await _tasksBox.put(id, updatedTask);
    return updatedTask;
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Görevi siler
  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  /// Tüm görevleri siler
  Future<void> deleteAllTasks() async {
    await _tasksBox.clear();
  }

  /// Tamamlanmış görevleri siler
  Future<void> deleteCompletedTasks() async {
    final completedTasks = getCompletedTasks();
    for (final task in completedTasks) {
      await _tasksBox.delete(task.id);
    }
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Görev istatistiklerini hesaplar
  TaskStatistics getStatistics() {
    final allTasks = getAllTasks();
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();
    final overdueTasks = getOverdueTasks();

    int totalDuration = 0;
    for (final task in allTasks) {
      totalDuration += task.durationSpent;
    }

    return TaskStatistics(
      totalTasks: allTasks.length,
      completedTasks: completedTasks.length,
      pendingTasks: allTasks.length - completedTasks.length,
      overdueTasks: overdueTasks.length,
      totalDurationSpent: totalDuration,
    );
  }

  /// Hive box stream'i - değişiklikleri dinlemek için
  Stream<BoxEvent> watchTasks() {
    return _tasksBox.watch();
  }
}

/// Görev istatistikleri modeli
class TaskStatistics {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final int totalDurationSpent;

  const TaskStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.totalDurationSpent,
  });

  /// Tamamlanma oranı (0-100 arası)
  double get completionRate {
    if (totalTasks == 0) return 0;
    return (completedTasks / totalTasks) * 100;
  }
}


