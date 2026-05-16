import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';

import '../providers/focus_provider.dart';
import '../widgets/focus_completion_dialog.dart';

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

  void _onStateChange(FocusTimerState state) {
    if (state.status == TimerStatus.running) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController
        ..stop()
        ..reset();
    }
    if (state.status == TimerStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDialog(state));
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

    ref.listen<FocusTimerState>(focusTimerProvider, (_, next) => _onStateChange(next));

    return Scaffold(
      backgroundColor: timerState.status == TimerStatus.running
          ? timerState.focusType.color.withAlpha(10)
          : Colors.transparent,
      appBar: AppBar(
        title: const Text('Odak'),
        actions: [
          // Tema
          IconButton(
            icon: Icon(
              ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 20,
            ),
            onPressed: () =>
                ref.read(themeModeNotifierProvider.notifier).toggleTheme(),
          ),
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

              const Spacer(),

              // Zamanlayıcı
              TimerDisplay(
                timerState: timerState,
                pulseAnimation: _pulseAnimation,
              ),

              const Spacer(),



              // Kontrol butonları
              TimerControls(timerState: timerState),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
