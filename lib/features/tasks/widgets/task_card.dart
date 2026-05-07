import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

/// Modern görev kartı widget'ı
class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.showDate = false,
  });

  final Task task;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.onError,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(taskListProvider.notifier).deleteTask(task.id);
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: task.isCompleted
                  ? colorScheme.outlineVariant
                  : colorScheme.outline.withAlpha(100),
              width: 1,
            ),
            boxShadow: [
              if (!task.isCompleted)
                BoxShadow(
                  color: colorScheme.shadow.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Öncelik renk şeridi
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? colorScheme.outlineVariant
                        : task.priority.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                // İçerik
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Üst satır: Başlık ve Kategori
                        Row(
                          children: [
                            // Kategori ikonu
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: task.category.color.withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                task.category.icon,
                                size: 16,
                                color: task.category.color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Başlık
                            Expanded(
                              child: Text(
                                task.title,
                                style: textTheme.titleMedium?.copyWith(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.isCompleted
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Açıklama (varsa)
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            task.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Alt satır: Tarih ve etiketler
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Tarih (opsiyonel)
                            if (showDate) ...[
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: task.isOverdue
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(task.date),
                                style: textTheme.labelSmall?.copyWith(
                                  color: task.isOverdue
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: task.isOverdue
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            // Öncelik etiketi
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: task.priority.color.withAlpha(26),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    task.priority.icon,
                                    size: 12,
                                    color: task.priority.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.priority.title,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: task.priority.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Harcanan süre (varsa)
                            if (task.durationSpent > 0) ...[
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppDateUtils.formatDuration(task.durationSpent),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Checkbox
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) {
                        ref.read(taskListProvider.notifier).toggleCompletion(task.id);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return AppDateUtils.formatDateShort(date);
    }
  }
}


