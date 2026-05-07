import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/task_model.dart';
import '../models/task_enums.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_bottom_sheet.dart';

/// Filtre seçenekleri
enum TaskFilter { all, today, upcoming, completed, overdue }

/// Seçili filtre provider'ı
final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

/// Seçili kategoriye göre filtre provider'ı
final categoryFilterProvider = StateProvider<TaskCategory?>((ref) => null);

/// Filtrelenmiş görevler provider'ı
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);
  final categoryFilter = ref.watch(categoryFilterProvider);

  var tasks = taskState.tasks;

  // Kategori filtresi
  if (categoryFilter != null) {
    tasks = tasks.where((t) => t.category == categoryFilter).toList();
  }

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

/// Görevler ana ekranı
class TasksView extends ConsumerWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final taskState = ref.watch(taskListProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final currentFilter = ref.watch(taskFilterProvider);
    final categoryFilter = ref.watch(categoryFilterProvider);

    // İstatistikler
    final totalTasks = taskState.tasks.length;
    final completedTasks = taskState.tasks.where((t) => t.isCompleted).length;
    final overdueTasks = ref.read(taskListProvider.notifier).overdueTasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                ? 'Light Mode'
                : 'Dark Mode',
            onPressed: () {
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            },
          ),
          // Kategori filtresi
          PopupMenuButton<TaskCategory?>(
            icon: Badge(
              isLabelVisible: categoryFilter != null,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Category Filter',
            onSelected: (category) {
              ref.read(categoryFilterProvider.notifier).state = category;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: categoryFilter == null
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'All',
                      style: TextStyle(
                        fontWeight: categoryFilter == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...TaskCategory.values.map((category) {
                final isSelected = categoryFilter == category;
                return PopupMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(category.icon, color: category.color),
                      const SizedBox(width: 12),
                      Text(
                        category.title,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      body: taskState.isLoading
          ? const LoadingWidget(message: 'Loading tasks...')
          : Column(
              children: [
                // Özet kartları
                if (totalTasks > 0) _buildSummaryCards(
                  context,
                  colorScheme,
                  textTheme,
                  totalTasks,
                  completedTasks,
                  overdueTasks,
                ),

                // Filtre çipleri
                _buildFilterChips(context, ref, currentFilter, colorScheme),

                // Görev listesi
                Expanded(
                  child: filteredTasks.isEmpty
                      ? _buildEmptyState(currentFilter, ref)
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 100),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            return TaskCard(
                              task: filteredTasks[index],
                              showDate: currentFilter != TaskFilter.today,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddTaskBottomSheet.show(context),
        tooltip: 'New Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    int total,
    int completed,
    int overdue,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Toplam
          Expanded(
            child: _SummaryCard(
              title: 'Total',
              value: total.toString(),
              icon: Icons.list_alt,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Done',
              value: completed.toString(),
              icon: Icons.check_circle_outline,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          if (overdue > 0)
            Expanded(
              child: _SummaryCard(
                title: 'Overdue',
                value: overdue.toString(),
                icon: Icons.warning_amber_outlined,
                color: colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    TaskFilter currentFilter,
    ColorScheme colorScheme,
  ) {
    final filters = [
      (TaskFilter.all, 'All', Icons.list),
      (TaskFilter.today, 'Today', Icons.today),
      (TaskFilter.upcoming, 'Upcoming', Icons.event),
      (TaskFilter.completed, 'Done', Icons.check_circle),
      (TaskFilter.overdue, 'Overdue', Icons.warning_amber),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: filters.map((item) {
          final (filter, label, icon) = item;
          final isSelected = currentFilter == filter;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () {
              ref.read(taskFilterProvider.notifier).state = filter;
            },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest.withAlpha(100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
              icon,
              size: 18,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(TaskFilter filter, WidgetRef ref) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case TaskFilter.all:
        title = 'No tasks yet';
        subtitle = 'Add a new task to get started';
        icon = Icons.task_alt;
        break;
      case TaskFilter.today:
        title = 'No tasks for today';
        subtitle = 'Add a task for today';
        icon = Icons.today;
        break;
      case TaskFilter.upcoming:
        title = 'No upcoming tasks';
        subtitle = 'Plan tasks for the future';
        icon = Icons.event;
        break;
      case TaskFilter.completed:
        title = 'No completed tasks';
        subtitle = 'Start completing your tasks';
        icon = Icons.check_circle;
        break;
      case TaskFilter.overdue:
        title = 'No overdue tasks';
        subtitle = 'Great! All tasks are on time';
        icon = Icons.celebration;
        break;
    }

    return EmptyStateWidget(
      icon: icon,
      title: title,
      subtitle: filter == TaskFilter.overdue 
          ? subtitle 
          : 'Tap + to add a new task',
    );
  }
}

/// Özet kartı widget'ı
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
