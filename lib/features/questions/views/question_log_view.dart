import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/feature_gate.dart';
import '../../exam/models/exam_profile.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../subjects/models/subject.dart';
import '../models/question_log.dart';
import '../providers/question_log_provider.dart';

/// Soru çözüm günlüğü ekranı
class QuestionLogView extends ConsumerWidget {
  const QuestionLogView({super.key});

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
    final logs = ref.watch(questionLogProvider);
    final notifier = ref.read(questionLogProvider.notifier);
    final canAdd = ref.watch(canAddQuestionLogProvider);
    final remaining = ref.watch(remainingQuestionLogsProvider);

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
          if (remaining < 9999) ...[
            const SizedBox(height: 12),
            _RemainingBanner(remaining: remaining),
          ],
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
                    onPressed: canAdd
                        ? () async {
                            // Soru ekleme bottom sheet'ini açan utility
                            // import edemediği için bu ekranda zaten "+"
                            // butonu mevcut (alt FAB); ipucu olarak göster.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Sağ alttaki + butonuna basarak başla'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : null,
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
      floatingActionButton: Transform.translate(
        offset: Offset(0, -(96 + MediaQuery.of(context).padding.bottom)),
        child: FloatingActionButton.extended(
          shape: const StadiumBorder(),
          onPressed: () {
            if (canAdd) {
              _AddLogSheet.show(context, examType: _filter(profile.examType));
            } else {
              showPaywall(context,
                  feature: PremiumFeature.unlimitedQuestionLog);
            }
          },
          icon: Icon(canAdd ? Icons.add : Icons.lock_outline),
          label: Text(canAdd ? 'Soru Ekle' : 'Puhu+ ile Sınırsız'),
        ),
      ),
    );
  }
}

/// Ücretsiz kullanıcıya kalan günlük soru kaydı hakkını gösteren bant.
class _RemainingBanner extends StatelessWidget {
  const _RemainingBanner({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEmpty = remaining <= 0;
    final color = isEmpty ? colorScheme.error : colorScheme.primary;

    return InkWell(
      onTap: isEmpty
          ? () => showPaywall(context,
              feature: PremiumFeature.unlimitedQuestionLog)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(isEmpty ? Icons.lock_outline : Icons.bolt_outlined,
                size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEmpty
                    ? 'Günlük ücretsiz limit doldu. Puhu+ ile sınırsız kayıt.'
                    : 'Bugün $remaining ücretsiz kayıt hakkın kaldı.',
                style: textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
            if (isEmpty)
              Icon(Icons.chevron_right, size: 18, color: color),
          ],
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

class _AddLogSheet extends ConsumerStatefulWidget {
  const _AddLogSheet({required this.examType});
  final ExamTypeFilter examType;

  static Future<void> show(BuildContext context,
      {required ExamTypeFilter examType}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddLogSheet(examType: examType),
    );
  }

  @override
  ConsumerState<_AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends ConsumerState<_AddLogSheet> {
  Subject? _subject;
  int _correct = 0;
  int _wrong = 0;
  int _blank = 0;
  bool _saving = false;

  double get _net => _correct - (_wrong / 4);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subjects = Subject.forExamType(widget.examType);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Soru Çözüm Kaydı',
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Ders seçici
              Text('Ders',
                  style: textTheme.labelMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((s) {
                  final selected = s == _subject;
                  return InkWell(
                    onTap: () => setState(() => _subject = s),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? s.color.withAlpha(40)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected ? s.color : colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.icon, size: 16, color: s.color),
                          const SizedBox(width: 6),
                          Text(
                            s.title,
                            style: textTheme.labelMedium?.copyWith(
                              color: selected
                                  ? s.color
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Sayaçlar
              _Counter(
                label: 'Doğru',
                value: _correct,
                color: const Color(0xFF10B981),
                onChanged: (v) => setState(() => _correct = v),
              ),
              const SizedBox(height: 12),
              _Counter(
                label: 'Yanlış',
                value: _wrong,
                color: const Color(0xFFEF4444),
                onChanged: (v) => setState(() => _wrong = v),
              ),
              const SizedBox(height: 12),
              _Counter(
                label: 'Boş',
                value: _blank,
                color: const Color(0xFF6B7280),
                onChanged: (v) => setState(() => _blank = v),
              ),
              const SizedBox(height: 20),

              // Net
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calculate_outlined, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text('Net',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      _net.toStringAsFixed(2),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_subject == null ||
                          _saving ||
                          (_correct + _wrong + _blank) == 0)
                      ? null
                      : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_subject == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(questionLogProvider.notifier).addLog(
            subjectId: _subject!.id,
            correct: _correct,
            wrong: _wrong,
            blank: _blank,
          );
      HapticFeedback.lightImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const Spacer(),
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
            color: color,
          ),
        ],
      ),
    );
  }
}
