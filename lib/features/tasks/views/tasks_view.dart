import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/glass_container.dart';

import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_bottom_sheet.dart';

/// Görevler ekranı — 21st.dev stili Bento Dashboard
class TasksView extends ConsumerWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskListProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final currentFilter = ref.watch(taskFilterProvider);

    final total = taskState.tasks.length;
    final completed = taskState.tasks.where((t) => t.isCompleted).length;
    final overdue = ref.read(taskListProvider.notifier).overdueTasks.length;

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Ana İçerik
          taskState.isLoading
              ? const LoadingWidget(message: 'Yükleniyor...')
              : CustomScrollView(
                  slivers: [
                    // Dinamik Başlık (Sliver)
                    const _SliverGreetingHeader(),

                    // Bento Grid İstatistikleri
                    if (total > 0)
                      SliverToBoxAdapter(
                        child: _BentoSummaryGrid(
                          total: total,
                          completed: completed,
                          overdue: overdue,
                        ),
                      ),

                    // Filtreleme (Sticky Pill Tabs)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyFilterDelegate(
                        child: _LiquidFilterTabs(current: currentFilter),
                      ),
                    ),

                    // Görev Listesi
                    if (filteredTasks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: _EmptyState(filter: currentFilter)),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 8, bottom: 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => TaskCard(
                              task: filteredTasks[i],
                              showDate: currentFilter != TaskFilter.today,
                            ),
                            childCount: filteredTasks.length,
                          ),
                        ),
                      ),
                  ],
                ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 180),
        child: FloatingActionButton(
          onPressed: () => AddTaskBottomSheet.show(context),
          tooltip: 'Yeni Görev',
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

/// Göz alıcı başlık kısmı
class _SliverGreetingHeader extends ConsumerWidget {
  const _SliverGreetingHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    final textTheme = Theme.of(context).textTheme;

    final quotes = [
      'Günü planla, zamanı yönet ⚡️',
      'Zaman en değerli hazinendir ⏳',
      'Bugün ne başarıyoruz? 🎯',
      'Odağını koru, hedefine ulaş 🚀',
      'Gelecek bugün başlar 🌱',
      'Anı yakala, erteleme 💪',
      'Her saniye yeni bir fırsat ⏱️',
    ];
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final greeting = quotes[dayOfYear % quotes.length];

    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          greeting,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            themeMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
          onPressed: () =>
              ref.read(themeModeNotifierProvider.notifier).toggleTheme(),
        ),

        const SizedBox(width: 8),
      ],
    );
  }
}

/// Bento Grid formatında istatistikler
class _BentoSummaryGrid extends StatelessWidget {
  const _BentoSummaryGrid({
    required this.total,
    required this.completed,
    required this.overdue,
  });

  final int total;
  final int completed;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Sol Büyük Kare (Progress)
          Expanded(
            flex: 5,
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Günlük\nİlerleme',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: colorScheme.outline.withAlpha(50),
                            valueColor: AlwaysStoppedAnimation(
                              progress >= 1.0
                                  ? const Color(0xFF10B981)
                                  : colorScheme.primary,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Text(
                              '${(progress * 100).round()}%',
                              style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sağ Taraf (İki ufak dikdörtgen)
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // Tamamlanan
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(40),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$completed',
                              style: textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text('Biten',
                              style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Gecikmiş
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: colorScheme.error.withAlpha(40),
                            shape: BoxShape.circle),
                        child: Icon(Icons.warning_rounded,
                            color: colorScheme.error, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$overdue',
                              style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: overdue > 0
                                      ? colorScheme.error
                                      : null)),
                          Text('Geciken',
                              style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Akışkan pill (hap) şekilli filtre sekmeleri
class _LiquidFilterTabs extends ConsumerWidget {
  const _LiquidFilterTabs({required this.current});
  final TaskFilter current;

  static const _tabs = [
    (TaskFilter.all, 'Tümü'),
    (TaskFilter.today, 'Bugün'),
    (TaskFilter.upcoming, 'Yaklaşan'),
    (TaskFilter.completed, 'Bitti'),
    (TaskFilter.overdue, 'Gecikmiş'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 60,
      alignment: Alignment.center,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (filter, label) = _tabs[i];
          final isSelected = current == filter;

          return GestureDetector(
            onTap: () => ref.read(taskFilterProvider.notifier).state = filter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 20 : 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest.withAlpha(150),
                borderRadius: BorderRadius.circular(30),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: colorScheme.primary.withAlpha(100),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: textTheme.labelMedium!.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(label),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Sticky Header Delegate (Bulanık arka plan)
class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  _StickyFilterDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 60.0;
  @override
  double get maxExtent => 60.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: isDark ? Colors.black.withAlpha(100) : Colors.white.withAlpha(100),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyFilterDelegate oldDelegate) =>
      oldDelegate.child != child;
}


/// Boş durum
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    final data = switch (filter) {
      TaskFilter.all => (
          Icons.check_circle_outline_rounded,
          'Görev yok',
          '+ butonuyla ilk görevini ekle'
        ),
      TaskFilter.today => (
          Icons.today_rounded,
          'Bugün görev yok',
          'Bugün için bir şeyler planla'
        ),
      TaskFilter.upcoming => (
          Icons.event_rounded,
          'Yaklaşan görev yok',
          'Gelecek için görev ekle'
        ),
      TaskFilter.completed => (
          Icons.done_all_rounded,
          'Tamamlanan yok',
          'Görevlerini tamamlamaya başla'
        ),
      TaskFilter.overdue => (
          Icons.celebration_rounded,
          'Gecikmiş yok!',
          'Tüm görevlerin zamanında 🎉'
        ),
    };

    return EmptyStateWidget(
      icon: data.$1,
      title: data.$2,
      subtitle: data.$3,
    );
  }
}
