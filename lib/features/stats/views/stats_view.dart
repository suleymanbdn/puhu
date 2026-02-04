import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../timer/providers/focus_provider.dart';
import '../widgets/time_budget_card.dart';

/// İstatistikler ekranı
class StatsView extends ConsumerWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final taskState = ref.watch(taskListProvider);
    final focusHistory = ref.watch(focusHistoryProvider);
    final todayStats = ref.watch(todayFocusStatsProvider);

    // Görev istatistikleri
    final totalTasks = taskState.tasks.length;
    final completedTasks = taskState.tasks.where((t) => t.isCompleted).length;
    final overdueTasks = taskState.tasks
        .where((t) => !t.isCompleted && t.isOverdue)
        .length;

    // Odak istatistikleri
    final todayFocusMinutes = todayStats['minutes'] as int;
    final todaySessions = todayStats['sessions'] as int;

    // Bu haftanın odak süresi
    final weekFocusMinutes = ref.read(focusHistoryProvider.notifier).weekTotalMinutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        actions: [
          // Tema değiştirme butonu
          IconButton(
            icon: Icon(
              ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                ? 'Aydınlık Mod'
                : 'Karanlık Mod',
            onPressed: () {
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet kartları - Görevler
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Görev Özeti',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Toplam',
                    value: totalTasks.toString(),
                    icon: Icons.list_alt,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Tamamlandı',
                    value: completedTasks.toString(),
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Gecikmiş',
                    value: overdueTasks.toString(),
                    icon: Icons.warning_amber_outlined,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),

            const SizedBox(height: 24),

            // Odak Modu İstatistikleri
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Odak Modu',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: _FocusStatCard(
                    title: 'Bugün',
                    minutes: todayFocusMinutes,
                    sessions: todaySessions,
                    color: colorScheme.primary,
                    icon: Icons.today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FocusStatCard(
                    title: 'Bu Hafta',
                    minutes: weekFocusMinutes,
                    sessions: ref.read(focusHistoryProvider.notifier).thisWeekSessions.length,
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.date_range,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),

            const SizedBox(height: 24),

            // Zaman Bütçesi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Zaman Bütçesi',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const TimeBudgetCard(),

            const SizedBox(height: 24),

            // Tamamlanma oranı
            _CompletionRateCard(
              completed: completedTasks,
              total: totalTasks,
            ),

            const SizedBox(height: 24),

            // Son odak oturumları
            if (focusHistory.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Son Odak Oturumları',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${focusHistory.length} oturum',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...focusHistory.take(5).map((session) => _FocusSessionItem(
                    session: session,
                  )),
            ],

            // Motivasyon mesajı
            if (completedTasks > 0 || todayFocusMinutes > 0)
              _MotivationCard(
                completedTasks: completedTasks,
                focusMinutes: todayFocusMinutes,
              ),
          ],
        ),
      ),
    );
  }
}

/// İstatistik kartı widget'ı
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Odak modu istatistik kartı
class _FocusStatCard extends StatelessWidget {
  const _FocusStatCard({
    required this.title,
    required this.minutes,
    required this.sessions,
    required this.color,
    required this.icon,
  });

  final String title;
  final int minutes;
  final int sessions;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final timeStr = hours > 0 ? '${hours}s ${mins}dk' : '${mins}dk';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withAlpha(25),
            color.withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            timeStr,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$sessions oturum',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tamamlanma oranı kartı
class _CompletionRateCard extends StatelessWidget {
  const _CompletionRateCard({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final rate = total > 0 ? (completed / total) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Tamamlanma Oranı',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(rate * 100).round()}%',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rate >= 0.7
                      ? const Color(0xFF10B981)
                      : rate >= 0.4
                          ? const Color(0xFFF59E0B)
                          : colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 10,
                width: MediaQuery.of(context).size.width * 0.85 * rate,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      rate >= 0.7
                          ? const Color(0xFF10B981)
                          : rate >= 0.4
                              ? const Color(0xFFF59E0B)
                              : colorScheme.error,
                      rate >= 0.7
                          ? const Color(0xFF10B981).withAlpha(180)
                          : rate >= 0.4
                              ? const Color(0xFFF59E0B).withAlpha(180)
                              : colorScheme.error.withAlpha(180),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Odak oturumu öğesi
class _FocusSessionItem extends StatelessWidget {
  const _FocusSessionItem({required this.session});

  final dynamic session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: session.type.color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              session.type == session.type
                  ? Icons.work_outline
                  : Icons.coffee_outlined,
              color: session.type.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.type.title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${session.actualMinutes}dk odaklanma',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (session.mood != null)
            Text(
              session.mood!.emoji,
              style: const TextStyle(fontSize: 24),
            ),
        ],
      ),
    );
  }
}

/// Motivasyon kartı
class _MotivationCard extends StatelessWidget {
  const _MotivationCard({
    required this.completedTasks,
    required this.focusMinutes,
  });

  final int completedTasks;
  final int focusMinutes;

  String get _message {
    if (focusMinutes >= 120 && completedTasks >= 5) {
      return '🌟 İnanılmaz bir gün geçiriyorsun! Enerjin ve odağın muhteşem!';
    } else if (focusMinutes >= 60 || completedTasks >= 3) {
      return '💪 Harika gidiyorsun! Hedeflerine doğru kararlı adımlarla ilerliyorsun.';
    } else if (focusMinutes > 0 || completedTasks > 0) {
      return '🎯 İyi bir başlangıç! Her adım seni hedefine yaklaştırıyor.';
    }
    return '🚀 Bugün harika şeyler başarabilirsin! Başlamak için bir görev seç.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withAlpha(100),
            colorScheme.tertiaryContainer.withAlpha(80),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _message,
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
