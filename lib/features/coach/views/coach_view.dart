import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/puhu_avatar.dart';
import '../../../shared/widgets/speech_bubble.dart';
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

    // AppBackground: push route'larda scaffold transparent — sarmazsak
    // önceki ekran arkadan görünür ("eski ekran kalıyor" bug'ı).
    if (report == null) {
      return const AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Puhu'),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // === Puhu asistan — maskot + konuşma balonu + soru çipleri ===
          _PuhuHeader(report: report, subjectFor: _subjectFromId),
          const SizedBox(height: 20),

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

        ],
      ),
    ));
  }
}

/// Puhu asistan başlığı — maskot, konuşma balonu ve hazır soru çipleri.
///
/// AI notu balonda typewriter ile akar; maskota dokununca espri yapar.
class _PuhuHeader extends ConsumerStatefulWidget {
  const _PuhuHeader({required this.report, required this.subjectFor});
  final CoachReport report;
  final Subject? Function(String) subjectFor;

  @override
  ConsumerState<_PuhuHeader> createState() => _PuhuHeaderState();
}

class _PuhuHeaderState extends ConsumerState<_PuhuHeader>
    with AutomaticKeepAliveClientMixin {
  // Scroll'da ekran dışına çıkınca state (balon metni) sıfırlanmasın.
  @override
  bool get wantKeepAlive => true;

  String? _bubbleText;
  bool _animateBubble = false;
  bool _loading = false;

  static const _greeting =
      'Hoo! Ben Puhu 🦉 Sana özel bir not için aşağıdaki çiplerden birine dokun.';

  static const _jokes = [
    'Hoo hoo! Çalışıyor muyuz, kaytarıyor muyuz? 👀',
    'Baykuşlar gece uçar — sen her saat net uçurursun! 🚀',
    'Bir soru daha çözersen kanat çırpacağım, söz!',
    'Gözlerim büyük ama hedeflerin daha büyük 🎯',
    'Şşşt... YKS\'ye az kaldı, ama panik baykuşlara yakışmaz 😎',
  ];

  String _buildContext(String style) {
    final weakest = widget.report.weakestSubjectIds
        .map((id) => widget.subjectFor(id)?.title ?? id)
        .join(', ');
    final strongest = widget.report.strongestSubjectIds
        .map((id) => widget.subjectFor(id)?.title ?? id)
        .join(', ');
    final today = widget.report.todayRecommendation;
    return """
En zayıf 3 ders: $weakest.
En güçlü 3 ders: $strongest.
Bugünkü öneri: ${today.title}.
İstenen tarz: $style
""";
  }

  Future<void> _ask(String style) async {
    setState(() {
      _loading = true;
      _bubbleText = 'Hmm, düşünüyorum... 🤔';
      _animateBubble = false;
    });
    final summarizer = ref.read(aiSummarizerProvider);
    final result = await summarizer.generateCoachNote(_buildContext(style));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _animateBubble = true;
      _bubbleText = result ??
          'Şu an cevap üretemedim — internetini kontrol edip tekrar dener misin?';
    });
  }

  void _tellJoke() {
    setState(() {
      _animateBubble = true;
      _bubbleText =
          _jokes[DateTime.now().millisecondsSinceEpoch % _jokes.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAlive için zorunlu
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final summarizer = ref.watch(aiSummarizerProvider);
    final isAvailable = summarizer.isAvailable;
    final remaining = ref.watch(aiRemainingTodayProvider);
    final exhausted = isAvailable && remaining == 0;

    final bubble = _bubbleText ??
        (!isAvailable
            ? 'Hoo! AI tarafım şu an kapalı — ama algoritmik önerilerim aşağıda 👇'
            : (exhausted
                ? 'Bugünlük konuşma hakkım doldu 🌙 Yarın yine buradayım!'
                : _greeting));

    final chips = <(String, String)>[
      ('✨ Günün notu', 'motive edici günlük durum özeti'),
      ('💪 Motivasyon', 'kısa, güçlü bir motivasyon konuşması'),
      ('📚 Ne çalışayım?', 'bugün hangi derse, nasıl çalışmalı — somut öneri'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PuhuAvatar(size: 92, onTap: _tellJoke),
              const SizedBox(width: 6),
              Expanded(
                child: SpeechBubble(
                  text: bubble,
                  animate: _animateBubble,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isAvailable && !exhausted)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, style) in chips)
                  ActionChip(
                    label: Text(label),
                    labelStyle: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: colorScheme.primary.withAlpha(22),
                    side: BorderSide(
                        color: colorScheme.primary.withAlpha(70)),
                    onPressed: _loading ? null : () => _ask(style),
                  ),
              ],
            ),
          if (isAvailable && remaining >= 0) ...[
            const SizedBox(height: 8),
            Text(
              'Bugün $remaining konuşma hakkı • cevaplar 24 saat hatırlanır',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
                  // Tab-shell route'larına (/timer, /home) push YAPILMAZ —
                  // Navigator key çakışmasıyla crash olur; go ile geçilir.
                  GoRouter.of(context).go(recommendation.actionRoute),
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
