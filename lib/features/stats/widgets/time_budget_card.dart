import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Time Budget',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${totalSpent.toStringAsFixed(1)} / ${totalTarget.toStringAsFixed(0)}h',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Genel ilerleme
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: overallProgress.clamp(0.0, 1.0),
                        backgroundColor: colorScheme.outlineVariant,
                        strokeWidth: 5,
                        valueColor: AlwaysStoppedAnimation(
                          overallProgress >= 1.0
                              ? const Color(0xFF10B981)
                              : colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${(overallProgress * 100).round()}%',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
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
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              // Kategori adı
              Expanded(
                child: Text(
                  budget.categoryName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Süre bilgisi
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${budget.spentHours.toStringAsFixed(1)} / ${budget.targetHours.toStringAsFixed(0)}h',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOverBudget
                          ? colorScheme.error
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    isCompleted
                        ? 'Goal reached! ✓'
                        : 'Remaining: ${budget.remainingHours.toStringAsFixed(1)}h',
                    style: textTheme.labelSmall?.copyWith(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : colorScheme.onSurfaceVariant,
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
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // İlerleme
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                height: 8,
                width: MediaQuery.of(context).size.width *
                    0.65 *
                    budget.progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOverBudget
                        ? [
                            colorScheme.error,
                            colorScheme.error.withAlpha(180),
                          ]
                        : isCompleted
                            ? [
                                const Color(0xFF10B981),
                                const Color(0xFF10B981).withAlpha(180),
                              ]
                            : [
                                budget.color,
                                budget.color.withAlpha(180),
                              ],
                  ),
                  borderRadius: BorderRadius.circular(4),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withAlpha(80),
            colorScheme.secondaryContainer.withAlpha(60),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Time Budget',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
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
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              value: budget.progress.clamp(0.0, 1.0),
                              backgroundColor:
                                  colorScheme.outlineVariant.withAlpha(100),
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation(
                                budget.isCompleted
                                    ? const Color(0xFF10B981)
                                    : budget.color,
                              ),
                            ),
                          ),
                          Icon(
                            budget.icon,
                            size: 16,
                            color: budget.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${budget.spentHours.toStringAsFixed(0)}h',
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
