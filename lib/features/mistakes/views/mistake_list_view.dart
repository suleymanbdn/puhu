import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_background.dart';
import '../../subjects/models/subject.dart';
import '../models/mistake.dart';
import '../providers/mistake_provider.dart';
import 'add_mistake_sheet.dart';

/// Hata Sepeti ana ekran — bekleyen, gelecek, mastered tab'ları.
class MistakeListView extends ConsumerWidget {
  const MistakeListView({super.key});

  Subject? _subjectFromId(String id) {
    for (final s in Subject.values) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final all = ref.watch(mistakeProvider);
    final pending = ref.watch(pendingMistakesProvider);
    final upcoming = ref
        .watch(activeMistakesProvider)
        .where((m) => !m.isPending)
        .toList();
    final mastered = all.where((m) => m.mastered).toList();

    // AppBackground: push route — sarmazsak önceki ekran arkadan görünür.
    return AppBackground(
        child: DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Hata Sepeti'),
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: [
              _Tab(label: 'Bugün', count: pending.length),
              _Tab(label: 'Sıradakiler', count: upcoming.length),
              _Tab(label: 'Öğrenildi', count: mastered.length),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showAddMistakeSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Hata Ekle'),
        ),
        body: TabBarView(
          children: [
            _MistakeList(
              mistakes: pending,
              emptyTitle: 'Bugün tekrar yok 🎉',
              emptySubtitle:
                  'Sepetin bugün boş. Yeni bir hata ekleyebilir veya '
                  'sıradakileri inceleyebilirsin.',
              subjectFor: _subjectFromId,
              showReviewCta: pending.isNotEmpty,
              onReview: () => context.push('/mistakes/review'),
            ),
            _MistakeList(
              mistakes: upcoming,
              emptyTitle: 'Sırada bekleyen yok',
              emptySubtitle:
                  'Hata eklediğinde aralıklı tekrar programı burada '
                  'görünür.',
              subjectFor: _subjectFromId,
            ),
            _MistakeList(
              mistakes: mastered,
              emptyTitle: 'Henüz öğrenilen yok',
              emptySubtitle:
                  'Bir hatayı birkaç kez "Biliyorum" geçince burada '
                  'birikecek.',
              subjectFor: _subjectFromId,
            ),
          ],
        ),
      ),
    ));
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.subtleOf(Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MistakeList extends ConsumerWidget {
  const _MistakeList({
    required this.mistakes,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.subjectFor,
    this.showReviewCta = false,
    this.onReview,
  });

  final List<Mistake> mistakes;
  final String emptyTitle;
  final String emptySubtitle;
  final Subject? Function(String) subjectFor;
  final bool showReviewCta;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (mistakes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  size: 64, color: colorScheme.outlineVariant),
              const SizedBox(height: 14),
              Text(
                emptyTitle,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (showReviewCta && onReview != null) ...[
          _ReviewCta(count: mistakes.length, onTap: onReview!),
          const SizedBox(height: 14),
        ],
        ...mistakes.map((m) => _MistakeTile(
              mistake: m,
              subject: subjectFor(m.subjectId),
            )),
      ],
    );
  }
}

class _ReviewCta extends StatelessWidget {
  const _ReviewCta({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.focus, AppColors.premium],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.replay_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count hata tekrar bekliyor',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aralıklı tekrar seansını başlat',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _MistakeTile extends ConsumerWidget {
  const _MistakeTile({required this.mistake, required this.subject});
  final Mistake mistake;
  final Subject? subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = subject?.color ?? colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softOf(color), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.subtleOf(color),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(subject?.icon ?? Icons.school_outlined,
                color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (subject != null)
                      Text(
                        subject!.title,
                        style: textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (mistake.mastered) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.subtleOf(AppColors.success),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ÖĞRENİLDİ',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mistake.title,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (mistake.note != null && mistake.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    mistake.note!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule_outlined,
                        size: 13, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      mistake.mastered
                          ? 'Öğrenildi'
                          : 'Sonraki tekrar: ${DateFormat('d MMM', 'tr_TR').format(mistake.nextReviewAt)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (mistake.wrongCount > 0)
                      Text(
                        '${mistake.wrongCount}× yanlış',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: colorScheme.onSurfaceVariant, size: 18),
            itemBuilder: (_) => [
              if (!mistake.mastered)
                const PopupMenuItem(
                    value: 'mastered',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Öğrenildi işaretle'),
                      ],
                    )),
              if (mistake.mastered)
                const PopupMenuItem(
                    value: 'unmaster',
                    child: Row(
                      children: [
                        Icon(Icons.replay_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Aktif et'),
                      ],
                    )),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Sil', style: TextStyle(color: AppColors.danger)),
                    ],
                  )),
            ],
            onSelected: (v) async {
              final notifier = ref.read(mistakeProvider.notifier);
              switch (v) {
                case 'mastered':
                  await notifier.markMastered(mistake.id);
                case 'unmaster':
                  await notifier.unmaster(mistake.id);
                case 'delete':
                  await notifier.delete(mistake.id);
              }
            },
          ),
        ],
      ),
    );
  }
}
