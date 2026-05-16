import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/glass_container.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

/// Sade, modern görev kartı
class TaskCard extends ConsumerStatefulWidget {
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
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final onTap = widget.onTap;
    final showDate = widget.showDate;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: colorScheme.error, size: 22),
      ),
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) =>
          ref.read(taskListProvider.notifier).deleteTask(widget.task.id),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: widget.task.isCompleted ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              onTap?.call();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              child: Row(
            children: [
              // Sol renk şeridi — öncelik göstergesi
              _PriorityBar(task: task),

              // İçerik
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık satırı
                      Row(
                        children: [
                          // Kategori noktası

                          const SizedBox(width: 8),
                          // Başlık
                          Expanded(
                            child: Text(
                              task.title,
                              style: textTheme.bodyMedium?.copyWith(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor:
                                    colorScheme.onSurfaceVariant,
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

                      // Açıklama
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            task.description,
                            style: textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],

                      // Meta satırı
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Row(
                          children: [
                            // Tarih
                            if (showDate) ...[
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: task.isOverdue && !task.isCompleted
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _dateLabel(task.date),
                                style: textTheme.labelSmall?.copyWith(
                                  color: task.isOverdue && !task.isCompleted
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight:
                                      task.isOverdue && !task.isCompleted
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],

                            // Kategori
                            Text(
                              task.category.title,
                              style: textTheme.labelSmall?.copyWith(
                                color: task.isCompleted
                                    ? colorScheme.onSurfaceVariant
                                    : task.category.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            // Alt görevler
                            if (task.subtasks.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Icon(Icons.checklist_rounded,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Text(
                                '${task.subtasks.length}',
                                style: textTheme.labelSmall,
                              ),
                            ],

                            const Spacer(),

                            // Harcanan süre
                            if (task.durationSpent > 0) ...[
                              Icon(Icons.timer_rounded,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Text(
                                AppDateUtils.formatDuration(task.durationSpent),
                                style: textTheme.labelSmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Checkbox
              _TaskCheckbox(task: task),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Sil'),
        content: Text('"${widget.task.title}" silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Bugün';
    if (d == today.add(const Duration(days: 1))) return 'Yarın';
    if (d == today.subtract(const Duration(days: 1))) return 'Dün';
    return AppDateUtils.formatDateShort(date);
  }
}

/// Sol öncelik şeridi
class _PriorityBar extends StatelessWidget {
  const _PriorityBar({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 60,
      margin: const EdgeInsets.only(left: 1),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.transparent : task.priority.color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        ),
      ),
    );
  }
}

/// Checkbox bileşeni
class _TaskCheckbox extends ConsumerWidget {
  const _TaskCheckbox({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 48,
      child: Checkbox(
        value: task.isCompleted,
        onChanged: (_) =>
            ref.read(taskListProvider.notifier).toggleCompletion(task.id),
        shape: const CircleBorder(),
      ),
    );
  }
}
