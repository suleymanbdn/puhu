import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/feature_gate.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../exam/models/exam_profile.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../mocks/providers/mock_exam_provider.dart';
import '../../questions/providers/question_log_provider.dart';
import '../../subjects/models/subject.dart';
import '../../subjects/models/topic.dart';
import '../../subjects/providers/topic_provider.dart';
import '../../timer/providers/focus_provider.dart';

/// YKS Analiz ekranı
class StatsView extends ConsumerWidget {
  const StatsView({super.key});

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
    if (profile == null) return const SizedBox.shrink();

    final filter = _filter(profile.examType);
    final subjects = Subject.forExamType(filter);
    final topics = ref.watch(topicProvider);
    final mockNotifier = ref.read(mockExamProvider.notifier);
    final mocks = ref.watch(mockExamProvider);
    final questionNotifier = ref.read(questionLogProvider.notifier);
    ref.watch(questionLogProvider);
    final todayFocusStats = ref.watch(todayFocusStatsProvider);
    final weekFocusStats = ref.watch(weekFocusStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Analiz'),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                ? 'Aydınlık Mod'
                : 'Karanlık Mod',
            onPressed: () =>
                ref.read(themeModeNotifierProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 124),
        children: [
          // Sınava kalan + bugün
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(180),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YKS\'ye',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withAlpha(220),
                        ),
                      ),
                      Text(
                        '${profile.daysUntilExam} gün',
                        style: textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        profile.examType.title,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.school_rounded, size: 80, color: Colors.white24),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bugün özet kartları
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.timer_outlined,
                  label: 'Bugün',
                  value: _formatMinutes(todayFocusStats['minutes'] ?? 0),
                  sub: '${todayFocusStats['sessions'] ?? 0} oturum',
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.calendar_view_week,
                  label: 'Bu Hafta',
                  value: _formatMinutes(weekFocusStats['minutes'] ?? 0),
                  sub: '${weekFocusStats['sessions'] ?? 0} oturum',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.edit_note,
                  label: 'Bugün Soru',
                  value: '${questionNotifier.todayTotalQuestions}',
                  sub: '${questionNotifier.todayTotalNet.toStringAsFixed(1)} net',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.assessment_outlined,
                  label: 'Son Deneme',
                  value: mockNotifier.lastNet?.toStringAsFixed(1) ?? '—',
                  sub: 'Ort: ${mocks.isEmpty ? '—' : mockNotifier.averageNet.toStringAsFixed(1)}',
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Net gelişim grafiği (varsa)
          if (mocks.length >= 2) ...[
            _NetTrendCard(
              spots: [
                for (var i = 0; i < mocks.length; i++)
                  FlSpot(i.toDouble(), mocks[i].totalNet),
              ],
              targetNet: profile.targetNet,
            ),
            const SizedBox(height: 24),
          ],

          // Ders bazlı çalışma dağılımı
          Text('Ders Dağılımı (Toplam Çalışma)',
              style: textTheme.titleSmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          _SubjectDistributionCard(subjects: subjects, topics: topics),
          const SizedBox(height: 24),

          // Konu zayıflık analizi — premium özellik
          if (ref.watch(isPremiumProvider))
            _WeakTopicsCard(topics: topics)
          else
            const _LockedWeakTopics(),
        ],
      ),
    );
  }

  String _formatMinutes(int m) {
    if (m < 60) return '${m}dk';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}sa' : '${h}sa ${r}dk';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              )),
          Text(sub,
              style: textTheme.labelSmall?.copyWith(
                color: color.withAlpha(180),
              )),
        ],
      ),
    );
  }
}

class _NetTrendCard extends StatelessWidget {
  const _NetTrendCard({required this.spots, this.targetNet});
  final List<FlSpot> spots;
  final double? targetNet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxY = spots.map((s) => s.y).fold<double>(
          targetNet ?? 0,
          (a, b) => a > b ? a : b,
        );
    final yMax = (maxY * 1.15).ceilToDouble().clamp(10, 600).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net Gelişimi',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 2,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: yMax,
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                extraLinesData: targetNet != null
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: targetNet!,
                          color: const Color(0xFF10B981),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ])
                    : const ExtraLinesData(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary.withAlpha(60),
                          colorScheme.primary.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectDistributionCard extends StatelessWidget {
  const _SubjectDistributionCard({
    required this.subjects,
    required this.topics,
  });
  final List<Subject> subjects;
  final List<Topic> topics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final minutesBySubject = <Subject, int>{};
    for (final s in subjects) {
      minutesBySubject[s] = topics
          .where((t) => t.subjectId == s.id)
          .fold<int>(0, (sum, t) => sum + t.totalMinutes);
    }
    final total =
        minutesBySubject.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline,
                size: 40, color: colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text(
              'Henüz çalışma kaydı yok',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // En çok çalışılan ilk 6 ders
    final sorted = minutesBySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(8).where((e) => e.value > 0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: top.map((entry) {
          final ratio = entry.value / total;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(entry.key.icon, color: entry.key.color, size: 16),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: Text(
                    entry.key.title,
                    style: textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: entry.key.color.withAlpha(20),
                      color: entry.key.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: Text(
                    _formatMinutes(entry.value),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatMinutes(int m) {
    if (m < 60) return '${m}dk';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}sa' : '${h}sa ${r}dk';
  }
}

/// Ücretsiz kullanıcıya zayıf konu analizinin kilitli olduğunu gösterir.
class _LockedWeakTopics extends StatelessWidget {
  const _LockedWeakTopics();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () =>
          showPaywall(context, feature: PremiumFeature.weakTopicAnalysis),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 32, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text('Zayıf Konu Analizi',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              'Hangi konularda zayıf olduğunu gör, çalışmanı odakla — Puhu+',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeakTopicsCard extends StatelessWidget {
  const _WeakTopicsCard({required this.topics});
  final List<Topic> topics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Yanlış oranı yüksek ilk 5 konu (en az 5 soru çözülmüş olanlar arası)
    final weak = topics
        .where((t) => t.questionsSolved >= 5 && t.correctRatio < 0.6)
        .toList()
      ..sort((a, b) => a.correctRatio.compareTo(b.correctRatio));
    final top = weak.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Text('Zayıf Konular',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'En az 5 soru çözülmüş, doğru oranı %60 altı',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (top.isEmpty)
            Text(
              'Henüz yeterli veri yok 👍',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...top.map((t) {
              final subject = Subject.fromId(t.subjectId);
              final ratio = t.correctRatio;
              final color = subject?.color ?? colorScheme.primary;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              )),
                          Text(
                            '${subject?.title ?? t.subjectId} · ${t.questionsSolved} soru',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '%${(ratio * 100).toStringAsFixed(0)}',
                        style: textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
