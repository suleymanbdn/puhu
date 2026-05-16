import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/glass_container.dart';
import '../../timer/models/time_budget.dart';
import '../../timer/providers/focus_provider.dart';

/// Zaman bütçesi kartı - Progress bar grubu
class TimeBudgetCard extends ConsumerWidget {
  const TimeBudgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final budgetState = ref.watch(timeBudgetProvider);
    final budgets = budgetState.budgets;

    if (budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Toplam hesapla
    final totalTarget = budgets.fold<double>(0, (sum, b) => sum + b.targetHours);
    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.spentHours);
    final overallProgress = totalTarget > 0 ? (totalSpent / totalTarget) : 0.0;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zaman Bütçesi',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${totalSpent.toStringAsFixed(1)} / ${totalTarget.toStringAsFixed(0)} saat',
                      style: textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              // Genel ilerleme
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: overallProgress.clamp(0.0, 1.0),
                      backgroundColor: colorScheme.outline,
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation(
                        overallProgress >= 1.0
                            ? const Color(0xFF10B981)
                            : colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${(overallProgress * 100).round()}%',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Kategori bütçeleri
          ...budgets.map((budget) => _BudgetProgressItem(budget: budget)),
        ],
      ),
    );
  }
}

/// Tekil bütçe ilerleme öğesi
class _BudgetProgressItem extends StatelessWidget {
  const _BudgetProgressItem({required this.budget});

  final TimeBudget budget;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isOverBudget = budget.isOverBudget;
    final isCompleted = budget.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: Kategori ve süre bilgisi
          Row(
            children: [
              // Kategori ikonu
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: budget.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  budget.icon,
                  color: budget.color,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              // Kategori adı
              Expanded(
                child: Text(
                  budget.categoryName,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Süre bilgisi
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${budget.spentHours.toStringAsFixed(1)} / ${budget.targetHours.toStringAsFixed(0)}s',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOverBudget
                          ? colorScheme.error
                          : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          Stack(
            children: [
              // Arka plan
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // İlerleme
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                height: 6,
                width: MediaQuery.of(context).size.width *
                    0.65 *
                    budget.progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? colorScheme.error
                      : isCompleted
                          ? const Color(0xFF10B981)
                          : budget.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kompakt zaman bütçesi widget'ı (Ana sayfa için)
class TimeBudgetCompact extends ConsumerWidget {
  const TimeBudgetCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final budgetState = ref.watch(timeBudgetProvider);
    final budgets = budgetState.budgets;

    if (budgets.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Zaman Bütçesi',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mini progress bars
          Row(
            children: budgets.take(4).map((budget) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              value: budget.progress.clamp(0.0, 1.0),
                              backgroundColor: colorScheme.outline,
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(
                                budget.isCompleted
                                    ? const Color(0xFF10B981)
                                    : budget.color,
                              ),
                            ),
                          ),
                          Icon(
                            budget.icon,
                            size: 14,
                            color: budget.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${budget.spentHours.toStringAsFixed(0)}s',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
