import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../exam/models/exam_profile.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../subjects/models/subject.dart';
import '../providers/mistake_provider.dart';

/// Hata Sepeti'ne yeni hata eklemek için bottom sheet.
Future<bool> showAddMistakeSheet(BuildContext context, {Subject? prefilled}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddMistakeSheet(prefilledSubject: prefilled),
      );
    },
  );
  return result ?? false;
}

class _AddMistakeSheet extends ConsumerStatefulWidget {
  const _AddMistakeSheet({this.prefilledSubject});
  final Subject? prefilledSubject;

  @override
  ConsumerState<_AddMistakeSheet> createState() => _AddMistakeSheetState();
}

class _AddMistakeSheetState extends ConsumerState<_AddMistakeSheet> {
  Subject? _selected;
  final _titleCtl = TextEditingController();
  final _noteCtl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.prefilledSubject;
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

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

  Future<void> _save() async {
    final subject = _selected;
    final title = _titleCtl.text.trim();
    if (subject == null || title.isEmpty) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await ref.read(mistakeProvider.notifier).add(
            subjectId: subject.id,
            title: title,
            note: _noteCtl.text.trim().isEmpty ? null : _noteCtl.text.trim(),
          );
      HapticFeedback.lightImpact();
      if (mounted) navigator.pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(examProfileProvider);
    if (profile == null) return const SizedBox.shrink();

    final subjects = Subject.forExamType(_filter(profile.examType));
    final canSave = _selected != null && _titleCtl.text.trim().isNotEmpty;

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
              const Icon(Icons.bookmark_add_rounded, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                'Hata Sepeti\'ne Ekle',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Yaptığın yanlışı kısaca yaz — birkaç gün sonra tekrar görür, '
            'kalıcılaştırırsın.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
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
                  avatar: Icon(s.icon,
                      size: 16, color: selected ? Colors.white : s.color),
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
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtl,
            decoration: InputDecoration(
              labelText: 'Konu / soru başlığı',
              hintText: 'Örn: Trigonometri özdeşliği, paragrafta ana fikir',
              prefixIcon: const Icon(Icons.title_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Not (opsiyonel)',
              hintText: 'Neyi karıştırdın? Doğrusu neydi?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(
                canSave ? 'Hata sepetine ekle' : 'Ders ve başlık gir',
              ),
              onPressed: (canSave && !_saving) ? _save : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: textTheme.titleMedium?.copyWith(
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
