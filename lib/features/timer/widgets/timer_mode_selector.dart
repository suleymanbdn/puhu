import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/focus_session.dart';
import '../providers/focus_provider.dart';

/// Zamanlayıcı mod seçimi (Çalışma / Kısa Ara / Uzun Ara)
class TimerModeSelector extends ConsumerWidget {
  const TimerModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timerState = ref.watch(focusTimerProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        // Primary tonu — gri şerit koyu gradient'in canlılığını öldürüyordu.
        color: colorScheme.primary.withAlpha(28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: FocusType.values.map((type) {
          final isSelected = timerState.focusType == type;
          return Expanded(
            child: GestureDetector(
              onTap: timerState.status == TimerStatus.idle
                  ? () =>
                      ref.read(focusTimerProvider.notifier).setFocusType(type)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? type.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: type.color.withAlpha(60),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconFor(type),
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.title,
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(FocusType type) {
    switch (type) {
      case FocusType.work:
        return Icons.work_outline;
      case FocusType.shortBreak:
        return Icons.coffee_outlined;
      case FocusType.longBreak:
        return Icons.weekend_outlined;
    }
  }
}
