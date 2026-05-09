import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../subjects/models/subject.dart';
import '../../subjects/providers/topic_provider.dart';
import '../models/focus_session.dart';
import '../providers/focus_provider.dart';

/// Odak oturumu tamamlama dialogu
class FocusCompletionDialog extends ConsumerStatefulWidget {
  const FocusCompletionDialog({
    super.key,
    required this.elapsedMinutes,
    required this.focusType,
  });

  final int elapsedMinutes;
  final FocusType focusType;

  static Future<FocusSession?> show(
    BuildContext context, {
    required int elapsedMinutes,
    required FocusType focusType,
  }) {
    return showDialog<FocusSession>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FocusCompletionDialog(
        elapsedMinutes: elapsedMinutes,
        focusType: focusType,
      ),
    );
  }

  @override
  ConsumerState<FocusCompletionDialog> createState() =>
      _FocusCompletionDialogState();
}

class _FocusCompletionDialogState extends ConsumerState<FocusCompletionDialog>
    with SingleTickerProviderStateMixin {
  FocusMood? _selectedMood;
  final _noteController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedMood == null) return;

    setState(() => _isLoading = true);

    // completeSession() içinde reset() çağrılıp state temizleneceğinden
    // YKS subject/topic bilgilerini ÖNCE okuyoruz
    final timerState = ref.read(focusTimerProvider);
    final subjectId = timerState.subjectId;
    final topicId = timerState.topicId;
    // Subject seçilmediyse fallback olarak eski category sistemini kullan
    final budgetKey = subjectId ?? timerState.category?.title;

    try {
      final session = await ref.read(focusTimerProvider.notifier).completeSession(
            _selectedMood!,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );

      // Sadece çalışma oturumlarında bütçe ve konu güncellenir
      if (widget.focusType == FocusType.work && widget.elapsedMinutes > 0) {
        // 1) Time budget'a süre ekle
        if (budgetKey != null) {
          await ref
              .read(timeBudgetProvider.notifier)
              .addTimeToCategory(budgetKey, widget.elapsedMinutes);
        }
        // 2) YKS Topic'e süre ekle (lastStudiedAt + status güncellenir)
        if (topicId != null) {
          await ref
              .read(topicProvider.notifier)
              .addStudyTime(topicId, widget.elapsedMinutes);

          // 3) Spaced repetition tekrar bildirimleri planla
          final topic = ref
              .read(topicProvider)
              .where((t) => t.id == topicId)
              .firstOrNull;
          if (topic != null) {
            final subject = Subject.fromId(topic.subjectId);
            await NotificationService.instance.scheduleTopicReview(
              topicId: topic.id,
              topicName: topic.name,
              subjectTitle: subject?.title ?? topic.subjectId,
              studiedAt: DateTime.now(),
            );
          }
        }
      }

      // Focus history'yi güncelle
      ref.read(focusHistoryProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context, session);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başarı ikonu
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.focusType.color,
                      widget.focusType.color.withAlpha(180),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.focusType.color.withAlpha(100),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Başlık
              Text(
                'Harika İş! 🎉',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Süre bilgisi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.elapsedMinutes} dakika ${widget.focusType.title.toLowerCase()}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Mood seçimi başlığı
              Text(
                'Nasıl hissediyorsun?',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Mood butonları
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: FocusMood.values.map((mood) {
                  final isSelected = _selectedMood == mood;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? mood.color.withAlpha(30)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? mood.color
                              : colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            mood.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mood.title,
                            style: textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? mood.color
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Not alanı (opsiyonel)
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Not ekle (opsiyonel)',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(100),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedMood == null || _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),

              // İptal butonu
              TextButton(
                onPressed: () {
                  ref.read(focusTimerProvider.notifier).cancel();
                  Navigator.pop(context);
                },
                child: Text(
                  'Kaydetmeden Geç',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


