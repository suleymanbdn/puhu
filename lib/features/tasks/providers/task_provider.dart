import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_model.dart';
import '../models/task_enums.dart';
import '../repositories/task_repository.dart';

// =============================================================================
// STATE
// =============================================================================

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

// =============================================================================
// NOTIFIER
// =============================================================================

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
      tasks.sort((a, b) => a.date.compareTo(b.date));
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Listeyi tarihe göre sıralayan yardımcı metod
  List<Task> _sorted(List<Task> tasks) =>
      [...tasks]..sort((a, b) => a.date.compareTo(b.date));

  /// Yeni görev ekler
  Future<Task> addTask({
    required String title,
    String description = '',
    TaskCategory category = TaskCategory.personal,
    TaskPriority priority = TaskPriority.medium,
    required DateTime date,
    List<String> subtasks = const [],
  }) async {
    final task = await _repository.addTask(
      title: title,
      description: description,
      category: category,
      priority: priority,
      date: date,
      subtasks: subtasks,
    );
    state = state.copyWith(tasks: _sorted([...state.tasks, task]));
    return task;
  }

  /// Görevi günceller
  Future<void> updateTask(Task task) async {
    final updated = await _repository.updateTask(task);
    state = state.copyWith(
      tasks: _sorted(
        state.tasks.map((t) => t.id == updated.id ? updated : t).toList(),
      ),
    );
  }

  /// Görevin tamamlanma durumunu değiştirir
  Future<void> toggleCompletion(String id) async {
    final updated = await _repository.toggleTaskCompletion(id);
    state = state.copyWith(
      tasks: _sorted(
        state.tasks.map((t) => t.id == updated.id ? updated : t).toList(),
      ),
    );
  }

  /// Görevi siler
  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != id).toList(),
    );
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

// =============================================================================
// PROVIDERS
// =============================================================================

/// Task repository provider — HiveTaskRepository inject eder
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return HiveTaskRepository();
});

/// Task listesi provider
final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskListNotifier(repository);
});

// =============================================================================
// FILTER PROVIDERS — view'dan çıkarıldı, buraya taşındı
// =============================================================================

/// Görev filtre seçenekleri
enum TaskFilter { all, today, upcoming, completed, overdue }

/// Seçili durum filtresi provider'ı
final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);



/// Filtrelenmiş görevler provider'ı
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);

  var tasks = taskState.tasks;


  // Ana filtre
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  switch (filter) {
    case TaskFilter.all:
      break;
    case TaskFilter.today:
      tasks = tasks.where((t) {
        final taskDate = DateTime(t.date.year, t.date.month, t.date.day);
        return taskDate == today;
      }).toList();
      break;
    case TaskFilter.upcoming:
      tasks = tasks.where((t) {
        final taskDate = DateTime(t.date.year, t.date.month, t.date.day);
        return taskDate.isAfter(today) && !t.isCompleted;
      }).toList();
      break;
    case TaskFilter.completed:
      tasks = tasks.where((t) => t.isCompleted).toList();
      break;
    case TaskFilter.overdue:
      tasks = tasks.where((t) {
        final taskDate = DateTime(t.date.year, t.date.month, t.date.day);
        return taskDate.isBefore(today) && !t.isCompleted;
      }).toList();
      break;
  }

  // Sıralama: Önce tamamlanmamışlar, sonra tarihe göre
  tasks.sort((a, b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }
    return a.date.compareTo(b.date);
  });

  return tasks;
});

// =============================================================================
// CALENDAR PROVIDERS
// =============================================================================

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
    events.putIfAbsent(date, () => []).add(task);
  }

  return events;
});

/// İstatistikler provider'ı
final taskStatisticsProvider = Provider((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getStatistics();
});
