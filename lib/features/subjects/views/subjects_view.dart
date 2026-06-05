import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../exam/providers/exam_profile_provider.dart';
import '../../exam/models/exam_profile.dart';
import '../../questions/providers/question_log_provider.dart';
import '../../timer/providers/focus_provider.dart';
import '../models/subject.dart';
import '../providers/topic_provider.dart';

/// Tüm derslerin listelendiği ana ekran
class SubjectsView extends ConsumerWidget {
  const SubjectsView({super.key});

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
    final profile = ref.watch(examProfileProvider);

    if (profile == null) {
      return const SizedBox.shrink();
    }

    final subjects = Subject.forExamType(_filter(profile.examType));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Dersler'),
        actions: [
          if (profile.daysUntilExam >= 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${profile.daysUntilExam} gün',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 140 + MediaQuery.of(context).padding.bottom),
        itemCount: subjects.length,
        itemBuilder: (context, i) {
          final subject = subjects[i];
          return _SubjectCard(subject: subject);
        },
      ),
    );
  }
}

class _SubjectCard extends ConsumerWidget {
  const _SubjectCard({required this.subject});
  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final topics = ref.watch(topicsForSubjectProvider(subject));
    final completion = ref.watch(subjectCompletionProvider(subject));
    final budgets = ref.watch(timeBudgetProvider).budgets;
    final budgetMinutes = budgets
        .where((b) => b.categoryName == subject.id)
        .fold<int>(0, (sum, b) => sum + b.targetMinutesPerWeek);
    final totalMinutes =
        topics.fold<int>(0, (sum, t) => sum + t.totalMinutes);
    // ignore: avoid_dynamic_calls
    ref.watch(questionLogProvider);
    final totalNet =
        ref.read(questionLogProvider.notifier).netForSubject(subject);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/subject/${subject.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: subject.color.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(subject.icon, color: subject.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${subject.examPart} • ${subject.questionCount} soru • ${topics.length} konu',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 14),
                // Konu tamamlanma çubuğu
                Row(
                  children: [
                    Text(
                      '${(completion * 100).toStringAsFixed(0)}%',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: subject.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completion,
                          minHeight: 6,
                          backgroundColor: subject.color.withAlpha(30),
                          color: subject.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stat satırı
                Row(
                  children: [
                    _Stat(
                      icon: Icons.access_time,
                      label: _formatHours(totalMinutes),
                      sub: 'çalışıldı',
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                    _Stat(
                      icon: Icons.flag_outlined,
                      label: '${(budgetMinutes / 60).toStringAsFixed(1)}sa',
                      sub: 'haftalık',
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const Spacer(),
                    if (totalNet > 0)
                      _Stat(
                        icon: Icons.show_chart,
                        label: totalNet.toStringAsFixed(1),
                        sub: 'net',
                        color: const Color(0xFF10B981),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatHours(int minutes) {
    if (minutes < 60) return '${minutes}dk';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}sa' : '${h}sa ${m}dk';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          sub,
          style: textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
