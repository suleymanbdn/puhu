import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exam/models/exam_profile.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../subjects/models/subject.dart';
import '../../subjects/models/topic.dart';
import '../../subjects/providers/topic_provider.dart';
import '../providers/focus_provider.dart';

/// YKS Ders + Konu seçici
///
/// Sadece Çalışma modunda görünür ve timer idle iken etkileşilebilir.
/// Üstte yatay scroll ders chip'leri, altta seçilen ders için "konu seç" satırı.
class TimerCategorySelector extends ConsumerWidget {
  const TimerCategorySelector({super.key});

  ExamTypeFilter _filter(ExamType t) {
    switch (t) {
      case ExamType.tyt:
        return ExamTypeFilter.tyt;
      case ExamType.sayisal:
        return ExamTypeFilter.sayisal;
      case ExamType.esitAgirlik:
        return ExamTypeFilter.esitAgirlik;
      case ExamType.sozel:
        return ExamTypeFilter.sozel;
      case ExamType.dil:
        return ExamTypeFilter.dil;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timerState = ref.watch(focusTimerProvider);
    final profile = ref.watch(examProfileProvider);
    if (profile == null) return const SizedBox.shrink();

    final subjects = Subject.forExamType(_filter(profile.examType));
    final selectedSubject = timerState.subjectId != null
        ? Subject.fromId(timerState.subjectId!)
        : null;
    final selectedTopic = timerState.topicId != null
        ? ref.watch(topicProvider).where((t) => t.id == timerState.topicId!).firstOrNull
        : null;

    final isInteractive = timerState.status == TimerStatus.idle;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ders',
            style: textTheme.labelSmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          // Ders chip'leri (yatay scroll)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = subjects[i];
                final isSelected = s == selectedSubject;
                return GestureDetector(
                  onTap: isInteractive
                      ? () => ref
                          .read(focusTimerProvider.notifier)
                          .setSubject(s.id)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? s.color
                          : colorScheme.surfaceContainerHighest.withAlpha(100),
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(s.icon,
                            size: 16,
                            color: isSelected ? Colors.white : s.color),
                        const SizedBox(width: 6),
                        Text(
                          s.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Konu seç (ders seçilmişse)
          if (selectedSubject != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: isInteractive
                  ? () => _pickTopic(context, ref, selectedSubject)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedTopic?.name ?? 'Konu seç (opsiyonel)',
                        style: textTheme.bodySmall?.copyWith(
                          color: selectedTopic != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                          fontWeight: selectedTopic != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selectedTopic != null && isInteractive)
                      InkWell(
                        onTap: () => ref
                            .read(focusTimerProvider.notifier)
                            .setTopic(null),
                        child: Icon(Icons.close,
                            size: 16, color: colorScheme.onSurfaceVariant),
                      )
                    else
                      Icon(Icons.expand_more,
                          size: 18, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _pickTopic(BuildContext context, WidgetRef ref, Subject subject) {
    final topics = ref.read(topicsForSubjectProvider(subject));
    if (topics.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(subject.icon, color: subject.color),
                    const SizedBox(width: 10),
                    Text(
                      '${subject.title} - Konu Seç',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: topics.length,
                  itemBuilder: (_, i) {
                    final t = topics[i];
                    return _TopicListItem(
                      topic: t,
                      onTap: () {
                        ref
                            .read(focusTimerProvider.notifier)
                            .setTopic(t.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicListItem extends StatelessWidget {
  const _TopicListItem({required this.topic, required this.onTap});
  final Topic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: topic.status.color.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(topic.status.icon, color: topic.status.color, size: 16),
      ),
      title: Text(topic.name),
      subtitle: topic.totalMinutes > 0
          ? Text('${topic.totalMinutes} dk çalışıldı')
          : null,
      onTap: onTap,
    );
  }
}
