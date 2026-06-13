import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../exam/models/exam_profile.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../subjects/models/subject.dart';
import '../providers/mistake_provider.dart';
import '../services/mistake_image_service.dart';

/// Hata Sepeti'ne yeni hata eklemek için bottom sheet.
Future<bool> showAddMistakeSheet(BuildContext context, {Subject? prefilled}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
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
  String? _imagePath;
  bool _saving = false;
  bool _picking = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final path = await pickMistakeImage(source);
      if (path != null && mounted) setState(() => _imagePath = path);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

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
    if (subject == null) return;
    var title = _titleCtl.text.trim();
    // Foto eklendiyse başlık zorunlu değil — soru fotoğrafı zaten içeriği taşır.
    if (title.isEmpty) {
      if (_imagePath == null) return;
      title = '${subject.title} sorusu';
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await ref.read(mistakeProvider.notifier).add(
            subjectId: subject.id,
            title: title,
            note: _noteCtl.text.trim().isEmpty ? null : _noteCtl.text.trim(),
            imagePath: _imagePath,
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
    // Ders seçili + (başlık girilmiş VEYA soru fotoğrafı eklenmiş).
    final canSave = _selected != null &&
        (_titleCtl.text.trim().isNotEmpty || _imagePath != null);

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
            'Yanlış sorunun fotoğrafını çek ya da kısaca yaz — birkaç gün sonra '
            'tekrar görür, kalıcılaştırırsın.',
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
          const SizedBox(height: 16),

          // Soru fotoğrafı — eklenirse tekrarda "soru" olarak gösterilir.
          if (_imagePath != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(MistakeImages.mistakeImagePath(_imagePath)!),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 160,
                      color: colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      iconSize: 20,
                      tooltip: 'Fotoğrafı kaldır',
                      onPressed: () {
                        final old = _imagePath;
                        setState(() => _imagePath = null);
                        deleteMistakeImage(old);
                      },
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Fotoğraf çek'),
                    onPressed:
                        _picking ? null : () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Galeriden'),
                    onPressed:
                        _picking ? null : () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(
                canSave
                    ? 'Hata sepetine ekle'
                    : (_selected == null
                        ? 'Önce bir ders seç'
                        : 'Başlık yaz ya da foto ekle'),
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
