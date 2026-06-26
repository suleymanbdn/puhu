import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/focus_session.dart';
import '../providers/focus_provider.dart';
import '../widgets/focus_completion_dialog.dart';

import '../widgets/timer_category_selector.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_display.dart';
import '../widgets/timer_mode_selector.dart';

/// Odak modu ekranı — minimal zamanlayıcı
class TimerView extends ConsumerStatefulWidget {
  const TimerView({super.key});

  @override
  ConsumerState<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends ConsumerState<TimerView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onStateChange(FocusTimerState? prev, FocusTimerState next) {
    if (next.status == TimerStatus.running) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController
        ..stop()
        ..reset();
    }
    // Tamamlama dialogu yalnızca ÇALIŞMA oturumu tamamlandığında ve bu geçiş
    // BİR KEZ yaşandığında açılır (mola tamamlanınca dialog yok). Mükerrer
    // dialog ve mola/çalışma yarışı böyle önlenir.
    final justCompletedWork = prev?.status != TimerStatus.completed &&
        next.status == TimerStatus.completed &&
        next.focusType == FocusType.work;
    if (justCompletedWork) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showDialog(next);
      });
    }
  }

  Future<void> _showDialog(FocusTimerState state) async {
    await FocusCompletionDialog.show(
      context,
      elapsedMinutes: state.elapsedMinutes,
      focusType: state.focusType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timerState = ref.watch(focusTimerProvider);
    final todayStats = ref.watch(todayFocusStatsProvider);

    ref.listen<FocusTimerState>(
        focusTimerProvider, (prev, next) => _onStateChange(prev, next));

    return Scaffold(
      backgroundColor: timerState.status == TimerStatus.running
          ? timerState.focusType.color.withAlpha(10)
          : Colors.transparent,
      appBar: AppBar(
        title: const Text('Odak'),
        actions: [
          // Bugünün özeti
          if (todayStats['minutes'] as int > 0)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${todayStats['minutes']}dk',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Mod seçimi
              const TimerModeSelector(),

              // Çalışma modunda ders/konu seçimi — oturum derse bağlansın.
              if (timerState.focusType == FocusType.work) ...[
                const SizedBox(height: 16),
                const TimerCategorySelector(),
              ],

              const Spacer(),

              // Zamanlayıcı
              TimerDisplay(
                timerState: timerState,
                pulseAnimation: _pulseAnimation,
              ),

              const Spacer(),

              // Kontrol butonları
              TimerControls(timerState: timerState),

              // Yüzen cam nav bar'ın (≈92px) arkasında kalmasın (SafeArea zaten
              // home-indicator inset'ini ekliyor).
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
