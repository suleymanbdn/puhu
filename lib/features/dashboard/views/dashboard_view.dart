import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/feature_gate.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/quick_log_sheet.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../mocks/providers/mock_exam_provider.dart';
import '../../questions/providers/question_log_provider.dart';
import '../../streak/providers/streak_provider.dart';
import '../../timer/providers/focus_provider.dart';

/// Anasayfa
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(examProfileProvider);
    final streak = ref.watch(streakProvider);
    final today = ref.watch(todayFocusStatsProvider);
    final qNotifier = ref.read(questionLogProvider.notifier);
    ref.watch(questionLogProvider);
    final mocks = ref.watch(mockExamProvider);
    final mockNotifier = ref.read(mockExamProvider.notifier);
    final isPremium = ref.watch(isPremiumProvider);

    if (profile == null) return const SizedBox.shrink();

    final dailyTargetMin = (profile.dailyTargetHours * 60).round();
    final todayMin = today['minutes'] ?? 0;
    final dailyProgress =
        dailyTargetMin == 0 ? 0.0 : (todayMin / dailyTargetMin).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickLogSheet(context),
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('Soru Ekle'),
      ),
      // Bottom nav var → FAB'i biraz yukarı al, üstte kalmasın.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: const Text('Anasayfa'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 140 + MediaQuery.of(context).padding.bottom),
        children: [
          // Sınav countdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  profile.examType.color,
                  profile.examType.color.withAlpha(150),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(profile.examType.icon, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      profile.examType.title,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${profile.daysUntilExam}',
                      style: textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'gün kaldı',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white.withAlpha(220),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMMM yyyy, EEEE', 'tr_TR')
                      .format(profile.examDate),
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // === ÜST FOLD: Streak hero (ana metrik) ===
          _StreakHero(streak: streak),
          const SizedBox(height: 12),

          // === ÜST FOLD: Bugün başla CTA ===
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/timer'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Bugün çalışmaya başla'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // === ALT FOLD: Detaylı istatistikler ===
          Row(
            children: [
              Expanded(
                child: _DailyProgressCard(
                  todayMin: todayMin,
                  targetMin: dailyTargetMin,
                  progress: dailyProgress,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.edit_note,
                  label: 'Bugün',
                  value: '${qNotifier.todayTotalQuestions} soru',
                  sub: '${qNotifier.todayTotalNet.toStringAsFixed(1)} net',
                  color: AppColors.quickAction,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.assessment_outlined,
                  label: 'Son Deneme',
                  value: mockNotifier.lastNet?.toStringAsFixed(1) ?? '—',
                  sub: profile.targetNet != null
                      ? 'Hedef: ${profile.targetNet!.toStringAsFixed(0)}'
                      : (mocks.isEmpty
                          ? 'Deneme ekle'
                          : 'Ort: ${mockNotifier.averageNet.toStringAsFixed(1)}'),
                  color: AppColors.mockExam,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.menu_book_outlined,
                  label: 'Dersler',
                  color: AppColors.study,
                  onTap: () => context.go('/subjects'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.bar_chart,
                  label: 'Analiz',
                  color: AppColors.insight,
                  onTap: () => context.go('/stats'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.calendar_month_outlined,
                  label: 'Takvim',
                  color: colorScheme.primary,
                  onTap: () => context.go('/calendar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Motivasyon
          _MotivationCard(
            streak: streak.currentStreak,
            studiedToday: streak.studiedToday,
            todayMin: todayMin,
            targetMin: dailyTargetMin,
          ),

          // Puhu+ tanıtım kartı (premium olmayanlar için)
          if (!isPremium) ...[
            const SizedBox(height: 16),
            const _PremiumPromoCard(),
          ],
        ],
      ),
    );
  }
}

/// Anasayfada gösterilen Puhu+ tanıtım kartı.
class _PremiumPromoCard extends StatelessWidget {
  const _PremiumPromoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: () => showPaywall(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puhu+ ile potansiyelini aç',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sınırsız soru günlüğü, tüm deneme geçmişi ve zayıf '
                    'konu analizi',
                    style: textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withAlpha(220)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Anasayfa "ana metrik" — streak'i hero olarak gösterir.
///
/// Tasarım kararı: streak YKS öğrencisi için günlük temasın motorudur;
/// üst fold'da tek satır, tam genişlik, büyük rakam + ateş ikonu.
class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.streak});
  final StreakStats streak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = streak.studiedToday
        ? AppColors.streak
        : AppColors.streakInactive;
    final subtitle = streak.studiedToday
        ? 'Bugün çalıştın — devam et!'
        : (streak.currentStreak > 0
            ? 'Bugün çalışmayı unutma — streak\'i kaybetme'
            : 'İlk gününü başlat 🔥');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.subtleOf(color),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softOf(color), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softOf(color),
              shape: BoxShape.circle,
            ),
            child: Icon(
              streak.studiedToday
                  ? Icons.local_fire_department
                  : Icons.local_fire_department_outlined,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      streak.currentStreak.toString(),
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'gün streak',
                        style: textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.strongOf(color),
                  ),
                ),
                if (streak.longestStreak > streak.currentStreak) ...[
                  const SizedBox(height: 2),
                  Text(
                    'En uzun: ${streak.longestStreak} gün',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.mediumOf(color),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({
    required this.todayMin,
    required this.targetMin,
    required this.progress,
  });

  final int todayMin;
  final int targetMin;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = progress >= 1.0
        ? const Color(0xFF10B981)
        : colorScheme.primary;

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
              Icon(Icons.flag_outlined, color: color, size: 18),
              const SizedBox(width: 6),
              Text('Günlük Hedef',
                  style: textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_format(todayMin)} / ${_format(targetMin)}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withAlpha(40),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _format(int m) {
    if (m < 60) return '${m}dk';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}sa' : '${h}sa ${r}dk';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            sub,
            style: textTheme.labelSmall?.copyWith(color: color.withAlpha(180)),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({
    required this.streak,
    required this.studiedToday,
    required this.todayMin,
    required this.targetMin,
  });

  final int streak;
  final bool studiedToday;
  final int todayMin;
  final int targetMin;

  String get _message {
    if (todayMin >= targetMin && targetMin > 0) {
      return '🎯 Bugünün hedefini aştın! Puhu bile şaşırdı 🦉';
    }
    if (streak >= 7 && studiedToday) {
      return '🔥 $streak günlük muhteşem bir seri! Tüy bırakma 🦉';
    }
    if (streak > 0 && !studiedToday) {
      return '⚡ Puhu seni bekliyor — kısa bir Pomodoro yeter.';
    }
    if (todayMin > 0) {
      return '💪 Güzel başlangıç! Hedefe yaklaşıyorsun.';
    }
    return '🦉 Puhu ile harika bir gün — ilk Pomodoro\'yu başlat.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withAlpha(40)),
      ),
      child: Text(
        _message,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
