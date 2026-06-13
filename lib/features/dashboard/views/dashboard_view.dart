import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/feature_gate.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/quick_log_sheet.dart';
import '../../coach/models/study_plan.dart';
import '../../coach/providers/coach_provider.dart';
import '../../coach/widgets/recommendation_starter.dart';
import '../../exam/models/exam_profile.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../mistakes/providers/mistake_provider.dart';
import '../../questions/providers/question_log_provider.dart';
import '../../streak/providers/streak_freeze_provider.dart';
import '../../streak/providers/streak_provider.dart';
import '../../timer/providers/focus_provider.dart';
import '../../../shared/widgets/puhu_avatar.dart';
import '../../../shared/widgets/speech_bubble.dart';

/// Anasayfa — koç merkezli.
///
/// Üstte ince durum şeridi (geri sayım + streak), ardından AI koç notu ve
/// bugünkü öneri hero'su. Detaylı istatistik/ikincil kartlar aşağıda. Amaç:
/// öğrenci açınca "şimdi ne yapayım" sorusuna tek net cevap görsün.
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  static String _formatMin(int m) {
    if (m < 60) return '${m}dk';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}sa' : '${h}sa ${r}dk';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(examProfileProvider);
    final streak = ref.watch(streakProvider);
    final today = ref.watch(todayFocusStatsProvider);
    final qNotifier = ref.read(questionLogProvider.notifier);
    ref.watch(questionLogProvider);
    final isPremium = ref.watch(isPremiumProvider);

    if (profile == null) return const SizedBox.shrink();

    final dailyTargetMin = (profile.dailyTargetHours * 60).round();
    final todayMin = today['minutes'] ?? 0;
    final dailyProgress =
        dailyTargetMin == 0 ? 0.0 : (todayMin / dailyTargetMin).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
          // İnce üst şerit: geri sayım + streak (ikincil bilgi).
          _TopStrip(profile: profile, streak: streak),
          const SizedBox(height: 14),

          // AI koç notu — uygulamanın yüzü (maskot + kişisel mesaj).
          const _CoachNoteCard(),
          const SizedBox(height: 14),

          // Bugünkü öneri hero — günün tek net işi.
          const _TodayHeroCard(),
          const SizedBox(height: 12),

          // Dünü kurtar (freeze) — yalnızca anlamlıysa.
          if (streak.canFreezeYesterday) ...[
            _FreezeCtaCard(streak: streak),
            const SizedBox(height: 12),
          ],

          // Hızlı eylemler: soru ekle + haftalık plan.
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showQuickLogSheet(context),
                  icon: const Icon(Icons.add_chart_rounded),
                  label: const Text('Soru Ekle'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/coach'),
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Haftalık plan'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // === Bugün — tek kart: hedef + soru/net (eşit iki sütun) ===
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_outlined,
                              color: colorScheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Text('Günlük Hedef',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatMin(todayMin)} / ${_formatMin(dailyTargetMin)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: dailyProgress,
                          minHeight: 6,
                          backgroundColor: colorScheme.primary.withAlpha(30),
                          color: dailyProgress >= 1.0
                              ? AppColors.success
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: colorScheme.outlineVariant.withAlpha(80),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note,
                              color: AppColors.quickAction, size: 18),
                          const SizedBox(width: 6),
                          Text('Bugün',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${qNotifier.todayTotalQuestions} soru',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${qNotifier.todayTotalNet.toStringAsFixed(1)} net',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Hata Sepeti tanıtım / bekleyen sayısı
          const _MistakeBucketCard(),

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

/// İnce üst şerit — geri sayım + streak'i kompakt iki çip olarak gösterir.
///
/// Eski tasarımda bunlar ekranın yarısını kaplayan iki büyük karttı; koç
/// merkezli düzende ikincil bilgiye indirgendiler.
class _TopStrip extends StatelessWidget {
  const _TopStrip({required this.profile, required this.streak});

  final ExamProfile profile;
  final StreakStats streak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final examColor = profile.examType.color;
    final streakColor =
        streak.studiedToday ? AppColors.streak : AppColors.streakInactive;

    Widget chip({
      required IconData icon,
      required Color color,
      required String value,
      required String label,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.subtleOf(color),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.softOf(color), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.strongOf(color),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          icon: profile.examType.icon,
          color: examColor,
          value: '${profile.daysUntilExam} gün',
          label: '${profile.examType.title} • sınava kaldı',
        ),
        const SizedBox(width: 10),
        chip(
          icon: streak.studiedToday
              ? Icons.local_fire_department
              : Icons.local_fire_department_outlined,
          color: streakColor,
          value: '${streak.currentStreak} gün',
          label: streak.studiedToday ? 'streak • bugün ✓' : 'streak',
        ),
      ],
    );
  }
}

/// AI koç notu kartı — maskot + kişisel günlük mesaj.
///
/// [coachNoteProvider] AI metnini üretir (günde ~1 gerçek çağrı, cache'li).
/// AI yoksa/yüklenirken bugünkü öneri başlığına düşer. Tap → /coach detay.
class _CoachNoteCard extends ConsumerWidget {
  const _CoachNoteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final noteAsync = ref.watch(coachNoteProvider);

    // AI notu yokken hero'daki öneriyi tekrarlamamak için ona yönlendiren
    // nötr bir selam göster.
    const fallback = 'Bugünün planını senin için çıkardım — aşağıda 👇';
    final note = noteAsync.asData?.value;
    final hasNote = note != null && note.isNotEmpty;
    final text = hasNote ? note : fallback;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/coach'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const PuhuAvatar(size: 76),
              const SizedBox(width: 4),
              Expanded(
                child: SpeechBubble(
                  text: text,
                  animate: hasNote,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _recColor(RecommendationKind kind) {
  switch (kind) {
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

IconData _recIcon(RecommendationKind kind) {
  switch (kind) {
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

/// Bugünkü öneri hero'su — günün tek net işi + Başla butonu.
class _TodayHeroCard extends ConsumerWidget {
  const _TodayHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final rec = ref.watch(todayRecommendationProvider);

    // Rapor henüz hazır değilse basit bir başlangıç çağrısı göster.
    if (rec == null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => context.go('/timer'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Bugün çalışmaya başla'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final color = _recColor(rec.kind);

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
                child: Icon(_recIcon(rec.kind), color: Colors.white, size: 28),
              ),
              const SizedBox(width: 10),
              Text(
                'Bugün yap',
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white.withAlpha(220),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            rec.title,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rec.subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(230),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(
                rec.mistakeReview
                    ? Icons.replay_rounded
                    : Icons.play_arrow_rounded,
                color: color,
              ),
              label: Text(
                rec.minutes > 0 ? '${rec.minutes} dk başla' : 'Devam et',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
              // Pomodoro dayatma — kullanıcıya nasıl çalışacağını sor.
              onPressed: () => startRecommendation(context, rec),
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

/// "Dünü kurtar" freeze CTA — streak kaçtıysa kurtarma kartı.
///
/// Eski [_StreakHero]'dan çıkarıldı: streak artık üst şeritte kompakt çip,
/// ama freeze (donma) ile dünü kurtarma işlevi retention için korundu.
class _FreezeCtaCard extends ConsumerWidget {
  const _FreezeCtaCard({required this.streak});
  final StreakStats streak;

  Future<void> _useFreeze(BuildContext context, WidgetRef ref) async {
    final isPremium = ref.read(isPremiumProvider);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
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
    final hasFreezeToken = remainingFreeze > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softOf(AppColors.focus)),
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
                    label: const Text('15 dk çalış — bugünü kazan'),
                    onPressed: () => context.go('/timer'),
                  ),
          ),
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
