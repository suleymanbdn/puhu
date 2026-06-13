import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/quick_log_sheet.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../subjects/models/subject.dart';
import '../models/question_log.dart';
import '../providers/question_log_provider.dart';

/// Soru çözüm günlüğü ekranı
class QuestionLogView extends ConsumerWidget {
  const QuestionLogView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(examProfileProvider);
    final logs = ref.watch(questionLogProvider);
    final notifier = ref.read(questionLogProvider.notifier);

    if (profile == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Soru Çözüm'),
        actions: [
          IconButton(
            tooltip: 'Denemeler',
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () => context.push('/mocks'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 140 + MediaQuery.of(context).padding.bottom),
        children: [
          // Bugün özeti
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withAlpha(30),
                  colorScheme.primary.withAlpha(10),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bugün',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        '${notifier.todayTotalQuestions} soru',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${notifier.todayTotalNet.toStringAsFixed(2)} net',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.show_chart,
                    size: 60,
                    color: colorScheme.primary.withAlpha(60)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Geçmiş',
            style: textTheme.titleSmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.edit_note_rounded,
                      size: 56, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'İlk sorunu kaydet',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Çözdüğün soruları dersine göre günlüğe ekle — '
                    'günlük net\'in, ilerlemen ve zayıf konuların burada '
                    'somutlaşır.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: () => showQuickLogSheet(context),
                    icon: const Icon(Icons.add_chart_rounded),
                    label: const Text('Hemen başla'),
                  ),
                ],
              ),
            )
          else
            ...logs.map((log) => _LogTile(log: log)),
        ],
      ),
      // Yüzen cam nav bar'ı (≈ alt 92px) geçecek kadar kaldır — fazlası FAB'ı
      // ekran ortasına itiyordu. Hit-test için Transform değil Padding.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
            bottom: 24 + MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton.extended(
          shape: const StadiumBorder(),
          onPressed: () => showQuickLogSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Soru Ekle'),
        ),
      ),
    );
  }
}

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.log});
  final QuestionLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subject = Subject.fromId(log.subjectId);
    final color = subject?.color ?? colorScheme.primary;
    final title = subject?.title ?? log.subjectId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(log.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) =>
            ref.read(questionLogProvider.notifier).deleteLog(log.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(subject?.icon ?? Icons.book_outlined,
                    color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      '${log.correct}D • ${log.wrong}Y • ${log.blank}B  ·  ${DateFormat('d MMM HH:mm', 'tr_TR').format(log.date)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${log.net.toStringAsFixed(1)} net',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
