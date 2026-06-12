import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../coach/providers/ai_provider.dart';
import '../../mistakes/views/add_mistake_sheet.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../providers/topic_provider.dart';
import '../../../shared/widgets/app_background.dart';

/// Bir dersin tüm konularını listeleyen ekran
class TopicListView extends ConsumerWidget {
  const TopicListView({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final subject = Subject.fromId(subjectId);
    if (subject == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Ders bulunamadı')),
      );
    }

    final topics = ref.watch(topicsForSubjectProvider(subject));
    final byStatus = <TopicStatus, List<Topic>>{
      for (final s in TopicStatus.values)
        s: topics.where((t) => t.status == s).toList(),
    };

    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: subject.color.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(subject.icon, color: subject.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.title,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '${topics.length} konu',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 124),
        children: [
          // Durum özeti
          Row(
            children: TopicStatus.values.map((s) {
              final count = byStatus[s]?.length ?? 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: s.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          count.toString(),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: s.color,
                          ),
                        ),
                        Text(
                          s.title,
                          style: textTheme.labelSmall?.copyWith(
                            color: s.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Konu listesi
          ...topics.map(
            (t) => _TopicTile(topic: t, subject: subject),
          ),
        ],
      ),
    ));
  }
}

class _TopicTile extends ConsumerWidget {
  const _TopicTile({required this.topic, required this.subject});
  final Topic topic;
  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showStatusSheet(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: topic.status.color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    topic.status.icon,
                    color: topic.status.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.name,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: topic.status == TopicStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: topic.status == TopicStatus.completed
                              ? colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      if (topic.totalMinutes > 0 ||
                          topic.questionsSolved > 0) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (topic.totalMinutes > 0)
                              Text(
                                '${_formatTime(topic.totalMinutes)} çalışıldı',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (topic.questionsSolved > 0)
                              Text(
                                '${topic.questionsSolved} soru • ${(topic.correctRatio * 100).toStringAsFixed(0)}% doğru',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (topic.lastStudiedAt != null)
                              Text(
                                _formatLastStudied(topic.lastStudiedAt!),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}dk';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}sa' : '${h}sa ${m}dk';
  }

  String _formatLastStudied(DateTime when) {
    final now = DateTime.now();
    final diff = now.difference(when);
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return DateFormat('d MMM', 'tr_TR').format(when);
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  topic.name,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subject.title,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                // Hızlı eylemler
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text('AI Özet'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAiSummary(context, ref);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const Text('Hataya at'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          showAddMistakeSheet(context, prefilled: subject);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Theme.of(ctx).colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  'Durumu güncelle',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                ...TopicStatus.values.map((s) {
                  final isSelected = s == topic.status;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: s.color.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(s.icon, color: s.color, size: 20),
                    ),
                    title: Text(s.title),
                    trailing: isSelected
                        ? Icon(Icons.check, color: s.color)
                        : null,
                    onTap: () {
                      ref
                          .read(topicProvider.notifier)
                          .updateStatus(topic.id, s);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// AI ile konu özetini gösteren modal.
  ///
  /// Eğer AI yapılandırılmadıysa Settings'e yönlendiren promo gösterir.
  /// Yapılandırılmışsa loading → cache veya canlı çağrı → metin.
  void _showAiSummary(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
        shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AiTopicSummarySheet(
        subjectTitle: subject.title,
        topicName: topic.name,
      ),
    );
  }
}

/// AI konu özeti bottom sheet.
class _AiTopicSummarySheet extends ConsumerStatefulWidget {
  const _AiTopicSummarySheet({
    required this.subjectTitle,
    required this.topicName,
  });
  final String subjectTitle;
  final String topicName;

  @override
  ConsumerState<_AiTopicSummarySheet> createState() =>
      _AiTopicSummarySheetState();
}

class _AiTopicSummarySheetState
    extends ConsumerState<_AiTopicSummarySheet> {
  String? _summary;
  bool _loading = false;
  String? _error;
  bool _started = false;

  Future<void> _load() async {
    setState(() {
      _started = true;
      _loading = true;
      _error = null;
    });
    final summarizer = ref.read(aiSummarizerProvider);
    final result = await summarizer.summarizeTopic(
      subjectTitle: widget.subjectTitle,
      topicName: widget.topicName,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _summary = result;
      if (result == null) {
        _error = 'Özet üretilemedi — key geçerli mi, internet var mı?';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final summarizer = ref.watch(aiSummarizerProvider);
    final isAvailable = summarizer.isAvailable;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.focus, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.topicName,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${widget.subjectTitle} • AI özeti',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isAvailable) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.subtleOf(AppColors.focus),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI yapılandırılmadı',
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kendi ücretsiz Gemini key\'ini Ayarlar\'dan bağlarsan '
                    'konunun kısa AI özetini burada görürsün. Key 30 gün '
                    'cihazda cache\'lenir, ek istek yapmaz.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Ayarlardan bağla'),
                onPressed: () {
                  Navigator.of(context).pop();
                  GoRouter.of(context).push('/settings');
                },
              ),
            ),
          ] else if (!_started) ...[
            Text(
              'Bu konuyu kısaca özetleyip 3 madde formül/kavram istersen '
              'aşağıdaki butona bas. Aynı konu için 30 gün cache\'lenir.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Özeti üret'),
                onPressed: _load,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.focus,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ] else if (_loading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2.5)),
            ),
          ] else if (_summary != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.subtleOf(AppColors.focus),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _summary!,
                style: textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${summarizer.providerName} ile üretildi · 30 gün cache.',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.subtleOf(AppColors.danger),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.danger),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar dene'),
                onPressed: _load,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
