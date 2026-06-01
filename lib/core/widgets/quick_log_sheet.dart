import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/exam/models/exam_profile.dart';
import '../../features/exam/providers/exam_profile_provider.dart';
import '../../features/questions/providers/question_log_provider.dart';
import '../../features/subjects/models/subject.dart';
import '../services/feature_gate.dart';
import '../theme/app_colors.dart';

/// Hızlı soru kaydı bottom-sheet.
///
/// Tek modal'da: ders chip seçer → doğru/yanlış/boş stepper'larını
/// ayarlar → kaydet. Tab değiştirmeden, mevcut ekrandan çıkmadan log.
///
/// Premium limiti dolduysa paywall'a yönlendirir.
Future<void> showQuickLogSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _QuickLogSheet(),
      );
    },
  );
}

class _QuickLogSheet extends ConsumerStatefulWidget {
  const _QuickLogSheet();

  @override
  ConsumerState<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<_QuickLogSheet> {
  Subject? _selected;
  int _correct = 0;
  int _wrong = 0;
  int _blank = 0;
  bool _saving = false;

  ExamTypeFilter _filter(ExamType t) {
    switch (t) {
      case ExamType.tyt:
        return ExamTypeFilter.tyt;
      case ExamType.sayisal:
        return ExamTypeFilter.sayisal;
      case ExamType.esitAgirlik:
        return ExamTypeFilter.esitAgirlik;
      case ExamType.sozel:
        return ExamTypeFilter.sozel;
      case ExamType.dil:
        return ExamTypeFilter.dil;
    }
  }

  double get _net => (_correct - _wrong / 4).clamp(0, double.infinity);
  int get _total => _correct + _wrong + _blank;

  Future<void> _save() async {
    final subject = _selected;
    if (subject == null || _total == 0) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(questionLogProvider.notifier).addLog(
            subjectId: subject.id,
            correct: _correct,
            wrong: _wrong,
            blank: _blank,
          );
      if (mounted) {
        navigator.maybePop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${subject.title} • ${_net.toStringAsFixed(2)} net kaydedildi',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        HapticFeedback.lightImpact();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(examProfileProvider);
    final canAdd = ref.watch(canAddQuestionLogProvider);
    final remaining = ref.watch(remainingQuestionLogsProvider);

    if (profile == null) return const SizedBox.shrink();

    if (!canAdd) {
      return _LimitReached(remaining: remaining);
    }

    final subjects = Subject.forExamType(_filter(profile.examType));
    final canSave = _selected != null && _total > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          // Header
          Row(
            children: [
              Icon(Icons.add_chart_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Hızlı Soru Kaydı',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subject chips (yatay scroll)
          Text(
            'Ders',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final s = subjects[i];
                final selected = _selected == s;
                return ChoiceChip(
                  label: Text(s.title),
                  avatar: Icon(s.icon, size: 16, color: selected ? Colors.white : s.color),
                  selected: selected,
                  onSelected: (_) => setState(() => _selected = s),
                  selectedColor: s.color,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.subtleOf(s.color),
                  side: BorderSide(
                    color: selected ? s.color : AppColors.softOf(s.color),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Stepper'lar
          Row(
            children: [
              Expanded(
                child: _NumStepper(
                  label: 'Doğru',
                  value: _correct,
                  color: AppColors.success,
                  onChanged: (v) => setState(() => _correct = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumStepper(
                  label: 'Yanlış',
                  value: _wrong,
                  color: AppColors.danger,
                  onChanged: (v) => setState(() => _wrong = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumStepper(
                  label: 'Boş',
                  value: _blank,
                  color: AppColors.streakInactive,
                  onChanged: (v) => setState(() => _blank = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Toplam + net
          if (_total > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.subtleOf(colorScheme.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate_outlined,
                      size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Toplam $_total soru',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_net.toStringAsFixed(2)} net',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          if (_total > 0) const SizedBox(height: 14),

          // Kaydet
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (canSave && !_saving) ? _save : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(
                      canSave ? 'Kaydet' : 'Ders ve soru sayısını seç',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek satır numerik stepper — büyük rakam, ±2 buton.
class _NumStepper extends StatelessWidget {
  const _NumStepper({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.subtleOf(color),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softOf(color), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: textTheme.displaySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StepperBtn(
                icon: Icons.remove,
                color: color,
                onTap: value > 0 ? () => onChanged(value - 1) : null,
              ),
              _StepperBtn(
                icon: Icons.add,
                color: color,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn(
      {required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.subtleOf(color)
              : AppColors.softOf(color),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? color.withAlpha(120) : color,
        ),
      ),
    );
  }
}

/// Limit dolduğunda gösterilen panel — Puhu+ promosyonu.
class _LimitReached extends StatelessWidget {
  const _LimitReached({required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Icon(Icons.lock_outline, size: 40, color: AppColors.premium),
          const SizedBox(height: 12),
          Text(
            'Günlük limit doldu',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Ücretsiz planda günde belirli sayıda kayıt hakkın var '
            '(kalan: $remaining). Sınırsız soru günlüğü için Puhu+\'a geç.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Puhu+\'a Geç'),
              onPressed: () {
                Navigator.of(context).pop();
                showPaywall(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
