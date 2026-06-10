import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../subjects/models/subject.dart';
import '../models/study_plan.dart';
import '../providers/ai_provider.dart';
import '../providers/coach_provider.dart';

const _weekdayShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// Algoritmik koç ekranı — Bugün önerisi + haftalık plan + zayıf/güçlü dersler.
class CoachView extends ConsumerWidget {
  const CoachView({super.key});

  Subject? _subjectFromId(String id) {
    for (final s in Subject.values) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(coachReportProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (report == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Koç'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.subtleOf(AppColors.focus),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Algoritmik',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.focus,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 140 + MediaQuery.of(context).padding.bottom),
        children: [
          // === Bugün önerisi hero ===
          _TodayHero(
            recommendation: report.todayRecommendation,
            subjectFor: _subjectFromId,
          ),
          const SizedBox(height: 20),

          // === En zayıf 3 ders ===
          Text(
            'Bu hafta en çok dikkat',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...report.subjectScores.take(3).map(
                (s) => _SubjectScoreTile(
                  score: s,
                  subject: _subjectFromId(s.subjectId),
                  emphasis: true,
                ),
              ),

          const SizedBox(height: 20),

          // === Haftalık plan ===
          Text(
            'Haftalık plan önerisi',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _WeeklyPlanGrid(
            plan: report.weeklyPlan,
            subjectFor: _subjectFromId,
          ),

          const SizedBox(height: 20),

          // === Güçlü 3 (mevcut güç noktaları) ===
          if (report.strongestSubjectIds.isNotEmpty) ...[
            Text(
              'Güçlü olduğun alanlar',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...report.subjectScores.reversed.take(3).map(
                  (s) => _SubjectScoreTile(
                    score: s,
                    subject: _subjectFromId(s.subjectId),
                    emphasis: false,
                  ),
                ),
          ],

          const SizedBox(height: 20),

          // === AI Koç Notu — opsiyonel (BYOK gerekli) ===
          _AiCoachNoteSection(report: report, subjectFor: _subjectFromId),
        ],
      ),
    );
  }
}

/// AI tarafından üretilen koç notu kartı. Key yoksa "Settings'ten bağla"
/// promo gösterir; key varsa "Üret" butonu + sonuç metni.
class _AiCoachNoteSection extends ConsumerStatefulWidget {
  const _AiCoachNoteSection({required this.report, required this.subjectFor});
  final CoachReport report;
  final Subject? Function(String) subjectFor;

  @override
  ConsumerState<_AiCoachNoteSection> createState() =>
      _AiCoachNoteSectionState();
}

class _AiCoachNoteSectionState extends ConsumerState<_AiCoachNoteSection> {
  String? _note;
  bool _loading = false;
  String? _error;

  String _buildContext() {
    final weakest = widget.report.weakestSubjectIds
        .map((id) => widget.subjectFor(id)?.title ?? id)
        .join(', ');
    final strongest = widget.report.strongestSubjectIds
        .map((id) => widget.subjectFor(id)?.title ?? id)
        .join(', ');
    final today = widget.report.todayRecommendation;
    return '''
En zayıf 3 ders: $weakest.
En güçlü 3 ders: $strongest.
Bugünkü öneri: ${today.title}.
Bugün üretilecek mesaj: kullanıcıya bu durumu özetleyen, motive edici,
samimi 2-3 cümle.
''';
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final summarizer = ref.read(aiSummarizerProvider);
    final result = await summarizer.generateCoachNote(_buildContext());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _note = result;
      if (result == null) {
        _error = 'Üretim başarısız — key geçerli mi, internet var mı?';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final summarizer = ref.watch(aiSummarizerProvider);
    final isAvailable = summarizer.isAvailable;
    final remaining = ref.watch(aiRemainingTodayProvider);
    final isBundledExhausted = isAvailable && remaining == 0;

    if (!isAvailable) {
      // Promo: key yoksa
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.subtleOf(AppColors.focus),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.softOf(AppColors.focus)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.focus, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI koç notu (ücretsiz)',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.focus,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kendi ücretsiz Gemini key\'ini Ayarlar > Yapay Zeka\'dan '
              'bağlarsan, koç bugünkü durumun için kişisel bir not üretir. '
              'Key cihazında kalır.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Ayarlardan bağla'),
                onPressed: () =>
                    GoRouter.of(context).push('/settings'),
              ),
            ),
          ],
        ),
      );
    }

    // Key var
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softOf(AppColors.focus)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.focus, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Koç Notu',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    summarizer.providerName,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (remaining >= 0)
                    Text(
                      'Bugün $remaining hak',
                      style: textTheme.labelSmall?.copyWith(
                        color: isBundledExhausted
                            ? AppColors.danger
                            : AppColors.focus,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2.5)),
            )
          else if (_note != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.subtleOf(AppColors.focus),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _note!,
                style: textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.subtleOf(AppColors.danger),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                ),
              ),
            )
          else
            Text(
              'Bugünün durumu için sana özel bir motivasyon notu üret.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(_note == null
                  ? Icons.auto_awesome_rounded
                  : Icons.refresh_rounded),
              label: Text(isBundledExhausted
                  ? 'Bugünkü hak doldu — yarın yeniden'
                  : (_note == null ? 'Not üret' : 'Yeniden üret')),
              onPressed: (_loading || isBundledExhausted) ? null : _generate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.focus,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cevap 24 saat cihazında cache\'lenir — gereksiz çağrı yapmaz.',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bugünkü öneri hero kartı.
class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.recommendation, required this.subjectFor});

  final TodayRecommendation recommendation;
  final Subject? Function(String) subjectFor;

  Color _color(BuildContext context) {
    switch (recommendation.kind) {
      case RecommendationKind.reviewMistakes:
        return AppColors.danger;
      case RecommendationKind.startStreak:
        return AppColors.streak;
      case RecommendationKind.focusWeakest:
        return AppColors.focus;
      case RecommendationKind.maintain:
        return AppColors.success;
    }
  }

  IconData _icon() {
    switch (recommendation.kind) {
      case RecommendationKind.reviewMistakes:
        return Icons.replay_circle_filled_rounded;
      case RecommendationKind.startStreak:
        return Icons.local_fire_department_rounded;
      case RecommendationKind.focusWeakest:
        return Icons.center_focus_strong_rounded;
      case RecommendationKind.maintain:
        return Icons.verified_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _color(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(60),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon(), color: Colors.white, size: 28),
              ),
              const SizedBox(width: 10),
              Text(
                'Bugün önerin',
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white.withAlpha(220),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            recommendation.title,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(230),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(
                recommendation.mistakeReview
                    ? Icons.replay_rounded
                    : Icons.play_arrow_rounded,
                color: color,
              ),
              label: Text(
                recommendation.minutes > 0
                    ? '${recommendation.minutes} dk başla'
                    : 'Devam et',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () =>
                  GoRouter.of(context).push(recommendation.actionRoute),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectScoreTile extends StatelessWidget {
  const _SubjectScoreTile({
    required this.score,
    required this.subject,
    required this.emphasis,
  });

  final SubjectScore score;
  final Subject? subject;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = subject?.color ?? colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emphasis
              ? AppColors.softOf(color)
              : colorScheme.outlineVariant.withAlpha(80),
          width: emphasis ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.subtleOf(color),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(subject?.icon ?? Icons.school_outlined,
                    color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subject?.title ?? score.subjectId,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${score.totalScore.toStringAsFixed(0)}/100',
                style: textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score.totalScore / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.subtleOf(color),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          // Mini breakdown
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _Chip(
                label: 'Net: ${score.recentNet.toStringAsFixed(1)}',
                color: AppColors.success,
              ),
              _Chip(
                label:
                    'Tamamlama: %${(score.completionRatio * 100).toStringAsFixed(0)}',
                color: AppColors.focus,
              ),
              if (score.pendingMistakes > 0)
                _Chip(
                  label: '${score.pendingMistakes} hata',
                  color: AppColors.danger,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.subtleOf(color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Haftalık plan — 7 gün × atanan dersler grid'i.
class _WeeklyPlanGrid extends StatelessWidget {
  const _WeeklyPlanGrid({required this.plan, required this.subjectFor});

  final WeeklyPlan plan;
  final Subject? Function(String) subjectFor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now().weekday;

    return Column(
      children: [
        for (var day = 1; day <= 7; day++) ...[
          _DayRow(
            day: day,
            isToday: day == today,
            allocations: plan.allocations[day] ?? const [],
            subjectFor: subjectFor,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          if (day < 7)
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withAlpha(40),
            ),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.isToday,
    required this.allocations,
    required this.subjectFor,
    required this.colorScheme,
    required this.textTheme,
  });

  final int day;
  final bool isToday;
  final List<DayAllocation> allocations;
  final Subject? Function(String) subjectFor;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final dayName = _weekdayShort[day - 1];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.subtleOf(colorScheme.primary)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isToday
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                if (isToday)
                  Text(
                    'BUGÜN',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: allocations.isEmpty
                ? Text(
                    'Boş — yine de bir konuya bak 🙂',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: allocations.map((a) {
                      final s = subjectFor(a.subjectId);
                      final c = s?.color ?? colorScheme.primary;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.subtleOf(c),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.softOf(c)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s?.icon ?? Icons.school_outlined,
                                color: c, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${s?.title ?? a.subjectId} · ${a.minutes}dk',
                              style: textTheme.labelSmall?.copyWith(
                                color: c,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
