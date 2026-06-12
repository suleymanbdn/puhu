import 'package:flutter/material.dart';

import '../../../shared/widgets/app_background.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../subjects/models/subject.dart';
import '../models/mistake.dart';
import '../providers/mistake_provider.dart';

/// Hata Sepeti tekrar oturumu — bekleyen hataları kart kart gösterir.
///
/// Akış: not gizli başlar → kullanıcı "Cevabı göster"e basar → "Biliyorum"
/// veya "Yine yanlış" geçişi seçer → sonraki karta atlanır.
class MistakeReviewView extends ConsumerStatefulWidget {
  const MistakeReviewView({super.key});

  @override
  ConsumerState<MistakeReviewView> createState() => _MistakeReviewViewState();
}

class _MistakeReviewViewState extends ConsumerState<MistakeReviewView> {
  late List<Mistake> _queue;
  int _index = 0;
  bool _revealed = false;
  int _correct = 0;
  int _wrong = 0;

  @override
  void initState() {
    super.initState();
    // Snapshot'i bir kez al — kullanıcı işaretledikçe queue'da değişiklik olmasın.
    _queue = List.of(ref.read(pendingMistakesProvider));
  }

  Subject? _subjectFromId(String id) {
    for (final s in Subject.values) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> _onCorrect() async {
    HapticFeedback.lightImpact();
    await ref.read(mistakeProvider.notifier).markCorrect(_queue[_index].id);
    setState(() {
      _correct++;
      _index++;
      _revealed = false;
    });
  }

  Future<void> _onWrong() async {
    HapticFeedback.heavyImpact();
    await ref.read(mistakeProvider.notifier).markWrong(_queue[_index].id);
    setState(() {
      _wrong++;
      _index++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_queue.isEmpty) {
      return AppBackground(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Tekrar')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration_outlined,
                    size: 80, color: AppColors.success),
                const SizedBox(height: 16),
                Text('Bugün tekrar yok 🎉',
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Bekleyen hatan yok. Yeni eklediklerini gün sonu '
                  'görmeye başlarsın.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Geri dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    }

    if (_index >= _queue.length) {
      return _CompletionScreen(
        total: _queue.length,
        correct: _correct,
        wrong: _wrong,
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    final m = _queue[_index];
    final subject = _subjectFromId(m.subjectId);
    final color = subject?.color ?? colorScheme.primary;

    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Tekrar — ${_index + 1}/${_queue.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // İlerleme barı
              LinearProgressIndicator(
                value: _index / _queue.length,
                backgroundColor: AppColors.subtleOf(color),
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
              // Kart
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(m.id),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppColors.softOf(color), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.subtleOf(color),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                subject?.icon ?? Icons.school_outlined,
                                color: color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (subject != null)
                              Text(
                                subject.title,
                                style: textTheme.titleMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          m.title,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        if (m.note != null && m.note!.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 220),
                            firstChild: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.subtleOf(color),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_off_outlined,
                                      size: 18, color: color),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Notu görmek için "Cevabı göster"',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.strongOf(color),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            secondChild: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.subtleOf(AppColors.success),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notun:',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    m.note!,
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            crossFadeState: _revealed
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.repeat_rounded,
                                size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              'Aralık: ${Mistake.intervals[m.intervalIndex]} gün',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            if (m.correctStreak > 0)
                              Text(
                                '✓ ${m.correctStreak}',
                                style: textTheme.labelMedium?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            if (m.wrongCount > 0) ...[
                              const SizedBox(width: 10),
                              Text(
                                '✗ ${m.wrongCount}',
                                style: textTheme.labelMedium?.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!_revealed && (m.note != null && m.note!.isNotEmpty))
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() => _revealed = true),
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Cevabı göster'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _onWrong,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Yine yanlış'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _onCorrect,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Biliyorum'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    required this.total,
    required this.correct,
    required this.wrong,
    required this.onClose,
  });

  final int total;
  final int correct;
  final int wrong;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pct = total == 0 ? 0.0 : correct / total;

    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pct >= 0.8
                    ? Icons.emoji_events_rounded
                    : Icons.bolt_rounded,
                size: 88,
                color: pct >= 0.8 ? AppColors.warning : colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                pct >= 0.8 ? 'Mükemmel oturum!' : 'Tamamlandı',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '$correct doğru · $wrong yanlış · $total toplam',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Bitir'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
