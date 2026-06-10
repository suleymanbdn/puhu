import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/feature_gate.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/quick_log_sheet.dart';
import '../../coach/models/study_plan.dart';
import '../../coach/providers/coach_provider.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../mistakes/providers/mistake_provider.dart';
import '../../mocks/providers/mock_exam_provider.dart';
import '../../questions/providers/question_log_provider.dart';
import '../../streak/providers/streak_freeze_provider.dart';
import '../../streak/providers/streak_provider.dart';
import '../../timer/providers/focus_provider.dart';
import '../../whats_new/views/whats_new_sheet.dart';

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

    // İlk açılışta (versiyon değişmişse) "Bu sürümde yeni" sheet'ini göster.
    // Idempotent: sheet kendi içinde lastSeenVersion kontrolü yapar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) maybeShowWhatsNewSheet(context);
    });

    final dailyTargetMin = (profile.dailyTargetHours * 60).round();
    final todayMin = today['minutes'] ?? 0;
    final dailyProgress =
        dailyTargetMin == 0 ? 0.0 : (todayMin / dailyTargetMin).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Bottom nav FAB'i kapatıyor — Padding ile tab bar'ın üstüne al.
      // (Transform.translate KULLANMA: görseli taşır ama hit-test alanı
      // Scaffold sınırı dışında kalır, buton tıklanamaz olur.)
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
            bottom: 72 + MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton.extended(
          shape: const StadiumBorder(),
          onPressed: () => showQuickLogSheet(context),
          icon: const Icon(Icons.add_chart_rounded),
          label: const Text('Soru Ekle'),
        ),
      ),
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

          // === ÜST FOLD: Algoritmik koç bugün önerisi ===
          const _CoachTodayCard(),
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
          const SizedBox(height: 16),

          // Hata Sepeti tanıtım / bekleyen sayısı
          const _MistakeBucketCard(),
          const SizedBox(height: 24),

          // Motivasyon
          _MotivationCard(
            streak: streak.currentStreak,
            studiedToday: streak.studiedToday,
            todayMin: todayMin,
            targetMin: dailyTargetMin,
          ),

          // Puhu+ tanıtım kartı — yalnızca trigger anlarında (her zaman değil)
          if (!isPremium) ...[
            Builder(builder: (_) {
              final trigger = _premiumTrigger(
                streak: streak,
                daysUntilExam: profile.daysUntilExam,
              );
              if (trigger == null) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 16),
                  _PremiumPromoCard(trigger: trigger),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Puhu+ promo kartı için trigger nedeni.
///
/// Bu kart artık her zaman değil, yalnızca aşağıdaki anlardan biri
/// gerçekleştiğinde gösterilir; mesaj o ana göre özelleşir.
enum _PromoTrigger {
  /// 7, 30 veya 100 günlük streak milestone.
  streakMilestone,

  /// Sınava ≤ 30 gün kaldı — aciliyet.
  examUrgency,
}

/// Hangi trigger şu an aktif? (Hiçbiri yoksa null → kart gösterilmez.)
_PromoTrigger? _premiumTrigger({
  required StreakStats streak,
  required int daysUntilExam,
}) {
  if (daysUntilExam > 0 && daysUntilExam <= 30) {
    return _PromoTrigger.examUrgency;
  }
  if (const {7, 30, 100}.contains(streak.currentStreak)) {
    return _PromoTrigger.streakMilestone;
  }
  return null;
}

/// Anasayfada gösterilen Puhu+ tanıtım kartı — bağlama duyarlı mesaj.
class _PremiumPromoCard extends StatelessWidget {
  const _PremiumPromoCard({required this.trigger});
  final _PromoTrigger trigger;

  String get _title {
    switch (trigger) {
      case _PromoTrigger.streakMilestone:
        return '🔥 Streak\'in patladı — Puhu+ ile hızını koru';
      case _PromoTrigger.examUrgency:
        return '⏰ Sınav yakın — son kulvar için tam destek';
    }
  }

  String get _subtitle {
    switch (trigger) {
      case _PromoTrigger.streakMilestone:
        return 'Tüm deneme geçmişi, zayıf konu analizi ve 5 streak '
            'freeze/ay';
      case _PromoTrigger.examUrgency:
        return 'Tüm deneme geçmişi, zayıf konu analizi ve gelişmiş '
            'grafikler';
    }
  }

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
                    _title,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
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
/// üst fold'da tek satır, tam genişlik, büyük rakam + ateş ikonu +
/// Streak Freeze etkileşimleri (sağ üstte kalan token, dün kurtarma CTA).
class _StreakHero extends ConsumerWidget {
  const _StreakHero({required this.streak});
  final StreakStats streak;

  Future<void> _useFreeze(BuildContext context, WidgetRef ref) async {
    final isPremium = ref.read(isPremiumProvider);
    final yesterday =
        DateTime.now().subtract(const Duration(days: 1));
    final ok = await ref
        .read(streakFreezeProvider.notifier)
        .freezeDay(yesterday, isPremium: isPremium);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.shield_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Streak korundu — ${streak.streakIfYesterdayFrozen} güne yükseldi',
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final remainingFreeze = ref.watch(remainingFreezeTokensProvider);
    final maxFreeze = ref.watch(maxFreezeTokensProvider);

    final color = streak.studiedToday
        ? AppColors.streak
        : AppColors.streakInactive;
    final subtitle = streak.studiedToday
        ? 'Bugün çalıştın — devam et!'
        : (streak.currentStreak > 0
            ? '15 dakika yeter — serin bugün de sürsün ✨'
            : 'Bugün küçük bir adım at — yeni seri başlasın 💪');

    final showFreezeCta = streak.canFreezeYesterday;
    final hasFreezeToken = remainingFreeze > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.subtleOf(color),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softOf(color), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
              // Freeze token rozeti — her zaman görünür (kullanıcı varlığını bilsin)
              Tooltip(
                message: 'Bu ay kalan streak freeze (donma): '
                    '$remainingFreeze / $maxFreeze',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.softOf(AppColors.focus),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded,
                          color: AppColors.focus, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$remainingFreeze',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.focus,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Dünü kurtar CTA — yalnızca anlamlıysa göster
          if (showFreezeCta) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.softOf(AppColors.focus),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: AppColors.focus, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasFreezeToken
                              ? 'Dünü kurtar → streak\'i ${streak.streakIfYesterdayFrozen} güne yükselt'
                              : 'Dün kaçtı — ama bugün yeni bir başlangıç 💪',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: hasFreezeToken
                        ? FilledButton.tonalIcon(
                            icon: const Icon(Icons.shield_rounded),
                            label: Text('Freeze kullan (kalan: '
                                '${remainingFreeze - 1}/$maxFreeze)'),
                            onPressed: () => _useFreeze(context, ref),
                          )
                        : FilledButton.tonalIcon(
                            icon: const Icon(Icons.timer_outlined),
                            label: const Text(
                                '15 dk çalış — bugünü kazan'),
                            onPressed: () => context.go('/timer'),
                          ),
                  ),
                ],
              ),
            ),
          ],
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

/// Anasayfada Hata Sepeti'ne erişim kartı.
///
/// Bekleyen hata varsa "X hata tekrar bekliyor" + canlı CTA gösterir;
/// yoksa sade tanıtım: "Yanlışlarını sepete at, aralıklı tekrarla unutma."
class _MistakeBucketCard extends ConsumerWidget {
  const _MistakeBucketCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingMistakeCountProvider);
    final active = ref.watch(activeMistakeCountProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final showPending = pending > 0;
    final color = showPending ? AppColors.danger : AppColors.focus;

    return InkWell(
      onTap: () => context.push('/mistakes'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.subtleOf(color),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.softOf(color), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.softOf(color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                showPending
                    ? Icons.replay_circle_filled_rounded
                    : Icons.bookmark_outline_rounded,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showPending
                        ? '$pending hata tekrar bekliyor'
                        : 'Hata Sepeti',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.strongOf(color),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    showPending
                        ? 'Aralıklı tekrar seansını başlat'
                        : (active > 0
                            ? '$active aktif hata — gün geldikçe tekrar gör'
                            : 'Yanlışlarını sepete at, aralıklı tekrarla unutma'),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.strongOf(color)),
          ],
        ),
      ),
    );
  }
}

/// Anasayfada koç bugün önerisi kartı.
///
/// Algoritmik koç [todayRecommendationProvider]'dan gelen öneriyi gösterir;
/// tap edince ya doğrudan aksiyon route'una gider (timer / mistake review
/// vb.) ya da uzun basışla /coach detay sayfasına götürür.
class _CoachTodayCard extends ConsumerWidget {
  const _CoachTodayCard();

  Color _color(TodayRecommendation r) {
    switch (r.kind) {
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

  IconData _icon(TodayRecommendation r) {
    switch (r.kind) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(todayRecommendationProvider);
    final textTheme = Theme.of(context).textTheme;
    if (rec == null) {
      return SizedBox(
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
      );
    }

    final color = _color(rec);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(rec.actionRoute),
      onLongPress: () => context.push('/coach'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withAlpha(180)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon(rec), color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: Colors.white.withAlpha(220), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'KOÇ ÖNERİSİ',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white.withAlpha(220),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rec.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              rec.mistakeReview
                  ? Icons.replay_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
