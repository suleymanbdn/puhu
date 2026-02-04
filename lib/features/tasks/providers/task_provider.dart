import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: unused_import
import '../../../core/constants/app_constants.dart';
import '../models/task_model.dart';
import '../models/task_enums.dart';
import '../repositories/task_repository.dart';

/// Task listesi state'i
class TaskListState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  TaskListState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Task listesi notifier
class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskRepository _repository;

  TaskListNotifier(this._repository) : super(const TaskListState()) {
    loadTasks();
  }

  /// Tüm görevleri yükler
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true);
    try {
      final tasks = _repository.getAllTasks();
      // Tarihe göre sırala (en yakın önce)
      tasks.sort((a, b) => a.date.compareTo(b.date));
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Yeni görev ekler
  Future<Task> addTask({
    required String title,
    String description = '',
    TaskCategory category = TaskCategory.personal,
    TaskPriority priority = TaskPriority.medium,
    required DateTime date,
  }) async {
    final task = await _repository.addTask(
      title: title,
      description: description,
      category: category,
      priority: priority,
      date: date,
    );
    await loadTasks();
    return task;
  }

  /// Görevi günceller
  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    await loadTasks();
  }

  /// Görevin tamamlanma durumunu değiştirir
  Future<void> toggleCompletion(String id) async {
    await _repository.toggleTaskCompletion(id);
    await loadTasks();
  }

  /// Görevi siler
  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    await loadTasks();
  }

  /// Belirli bir tarihteki görevleri getirir
  List<Task> getTasksForDate(DateTime date) {
    return state.tasks.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
  }

  /// Bugünün görevlerini getirir
  List<Task> get todayTasks {
    final now = DateTime.now();
    return getTasksForDate(now);
  }

  /// Tamamlanmamış görevleri getirir
  List<Task> get incompleteTasks {
    return state.tasks.where((task) => !task.isCompleted).toList();
  }

  /// Gecikmiş görevleri getirir
  List<Task> get overdueTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.tasks.where((task) {
      return !task.isCompleted && task.date.isBefore(today);
    }).toList();
  }
}

/// Task repository provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository.instance;
});

/// Task listesi provider
final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskListNotifier(repository);
});

/// Seçili tarih provider'ı
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Seçili tarihteki görevler provider'ı
final tasksForSelectedDateProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskListProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  
  return taskState.tasks.where((task) {
    return task.date.year == selectedDate.year &&
        task.date.month == selectedDate.month &&
        task.date.day == selectedDate.day;
  }).toList()
    ..sort((a, b) {
      // Önce tamamlanmamışlar, sonra önceliğe göre
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return b.priority.index.compareTo(a.priority.index);
    });
});

/// Takvimde görev olan günler (event marker için)
final taskDatesProvider = Provider<Map<DateTime, List<Task>>>((ref) {
  final taskState = ref.watch(taskListProvider);
  final Map<DateTime, List<Task>> events = {};
  
  for (final task in taskState.tasks) {
    final date = DateTime(task.date.year, task.date.month, task.date.day);
    if (events[date] == null) {
      events[date] = [];
    }
    events[date]!.add(task);
  }
  
  return events;
});

/// İstatistikler provider'ı
final taskStatisticsProvider = Provider((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getStatistics();
});

