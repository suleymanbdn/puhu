import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/subject.dart';
import '../models/topic.dart';
import '../providers/topic_provider.dart';

/// Bir dersin tüm konularını listeleyen ekran
class TopicListView extends ConsumerWidget {
  const TopicListView({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final subject = Subject.fromId(subjectId);
    if (subject == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Ders bulunamadı')),
      );
    }

    final topics = ref.watch(topicsForSubjectProvider(subject));
    final byStatus = <TopicStatus, List<Topic>>{
      for (final s in TopicStatus.values)
        s: topics.where((t) => t.status == s).toList(),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: subject.color.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(subject.icon, color: subject.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.title,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '${topics.length} konu',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 124),
        children: [
          // Durum özeti
          Row(
            children: TopicStatus.values.map((s) {
              final count = byStatus[s]?.length ?? 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: s.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          count.toString(),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: s.color,
                          ),
                        ),
                        Text(
                          s.title,
                          style: textTheme.labelSmall?.copyWith(
                            color: s.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Konu listesi
          ...topics.map(
            (t) => _TopicTile(topic: t, subject: subject),
          ),
        ],
      ),
    );
  }
}

class _TopicTile extends ConsumerWidget {
  const _TopicTile({required this.topic, required this.subject});
  final Topic topic;
  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showStatusSheet(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: topic.status.color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    topic.status.icon,
                    color: topic.status.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.name,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: topic.status == TopicStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: topic.status == TopicStatus.completed
                              ? colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      if (topic.totalMinutes > 0 ||
                          topic.questionsSolved > 0) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (topic.totalMinutes > 0)
                              Text(
                                '${_formatTime(topic.totalMinutes)} çalışıldı',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (topic.questionsSolved > 0)
                              Text(
                                '${topic.questionsSolved} soru • ${(topic.correctRatio * 100).toStringAsFixed(0)}% doğru',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (topic.lastStudiedAt != null)
                              Text(
                                _formatLastStudied(topic.lastStudiedAt!),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}dk';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}sa' : '${h}sa ${m}dk';
  }

  String _formatLastStudied(DateTime when) {
    final now = DateTime.now();
    final diff = now.difference(when);
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return DateFormat('d MMM', 'tr_TR').format(when);
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  topic.name,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Durumu güncelle',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                ...TopicStatus.values.map((s) {
                  final isSelected = s == topic.status;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: s.color.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(s.icon, color: s.color, size: 20),
                    ),
                    title: Text(s.title),
                    trailing: isSelected
                        ? Icon(Icons.check, color: s.color)
                        : null,
                    onTap: () {
                      ref
                          .read(topicProvider.notifier)
                          .updateStatus(topic.id, s);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
