import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/notification_service.dart';
import '../../exam/models/exam_profile.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../subjects/models/subject.dart';
import '../../subjects/providers/topic_provider.dart';
import '../../timer/providers/focus_provider.dart';

/// Onboarding — 3 adımlı kurulum sihirbazı
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _pageController = PageController();
  int _currentStep = 0;

  ExamType? _selectedExamType;
  DateTime _examDate = _defaultYksDate();
  double _dailyHours = 4.0;
  final _universityController = TextEditingController();
  final _departmentController = TextEditingController();
  final _targetNetController = TextEditingController();

  bool _saving = false;

  /// Bir sonraki YKS için varsayılan tarih (Haziran ortası)
  static DateTime _defaultYksDate() {
    final now = DateTime.now();
    var year = now.year;
    final june15 = DateTime(year, 6, 15);
    if (now.isAfter(june15)) year += 1;
    return DateTime(year, 6, 20);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _targetNetController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    if (_selectedExamType == null) return;

    setState(() => _saving = true);

    final profile = ExamProfile(
      examType: _selectedExamType!,
      examDate: _examDate,
      dailyTargetHours: _dailyHours,
      targetUniversity: _universityController.text.trim().isEmpty
          ? null
          : _universityController.text.trim(),
      targetDepartment: _departmentController.text.trim().isEmpty
          ? null
          : _departmentController.text.trim(),
      targetNet: double.tryParse(_targetNetController.text.replaceAll(',', '.')),
    );

    try {
      await ref.read(examProfileProvider.notifier).save(profile);
      // Konuları otomatik oluştur
      await ref
          .read(topicProvider.notifier)
          .ensureTopicsForExamType(_examTypeToFilter(_selectedExamType!));
      // Time budget'ları yeniden oluştur
      await ref.read(timeBudgetProvider.notifier).initializeForExamType();

      // Bildirimleri planla
      await NotificationService.instance.scheduleExamReminders(_examDate);
      await NotificationService.instance.scheduleDailyReminder();
      await NotificationService.instance.scheduleStreakBreakReminder();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  ExamTypeFilter _examTypeToFilter(ExamType type) {
    switch (type) {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: List.generate(3, (i) {
                  final isActive = i <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildExamTypeStep(),
                  _buildScheduleStep(),
                  _buildTargetStep(),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _back,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Geri'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving || !_canProceed() ? null : _next,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_currentStep == 2 ? 'Tamamla' : 'Devam'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) return _selectedExamType != null;
    return true;
  }

  // =================== STEP 1: Exam Type ===================
  Widget _buildExamTypeStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selam, ben Puhu 🦉',
              style: textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'YKS yolculuğunda yanındayım. Hangi alanda hazırlanıyorsun?',
            style: textTheme.bodyLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'TYT dersleri her alana otomatik dahildir. '
                    'Alanını seç — TYT + alan derslerin birlikte hazırlanır.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...ExamType.values.map((type) {
            final isSelected = type == _selectedExamType;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedExamType = type),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? type.color.withAlpha(26)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? type.color : colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: type.color.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(type.icon, color: type.color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type.description,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: type.color),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // =================== STEP 2: Schedule ===================
  Widget _buildScheduleStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Programını ayarlayalım ⏰',
              style: textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Sınav tarihin ve günlük çalışma hedefin neyi olsun?',
            style: textTheme.bodyLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Sınav tarihi
          Text('Sınav Tarihi',
              style: textTheme.titleSmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _examDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null) setState(() => _examDate = picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('d MMMM yyyy, EEEE', 'tr_TR')
                              .format(_examDate),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sınava ${_examDate.difference(DateTime.now()).inDays} gün',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Günlük hedef
          Row(
            children: [
              Text('Günlük Çalışma Hedefi',
                  style: textTheme.titleSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text(
                '${_dailyHours.toStringAsFixed(1)} saat',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _dailyHours,
            min: 1,
            max: 12,
            divisions: 22,
            label: '${_dailyHours.toStringAsFixed(1)} saat',
            onChanged: (v) => setState(() => _dailyHours = v),
          ),
          Text(
            'Haftada toplam ${(_dailyHours * 7).toStringAsFixed(0)} saat',
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // =================== STEP 3: Target ===================
  Widget _buildTargetStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hedefin nedir? 🎯',
              style: textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Bunlar opsiyonel — sonra ayarlardan değiştirebilirsin.',
            style: textTheme.bodyLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _universityController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Hedef Üniversite',
              hintText: 'Örn: Boğaziçi, ODTÜ, Hacettepe',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _departmentController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Hedef Bölüm',
              hintText: 'Örn: Bilgisayar Mühendisliği',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _targetNetController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Hedef Net (opsiyonel)',
              hintText: 'Örn: 95',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tamamla butonuna bastığında ${_selectedExamType != null ? Subject.forExamType(_examTypeToFilter(_selectedExamType!)).length : 0} ders ve onlara ait konular otomatik oluşturulacak.',
                    style: textTheme.bodySmall,
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
