import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../tasks/models/task_enums.dart';
import '../models/focus_session.dart';
import '../providers/focus_provider.dart';
import '../widgets/focus_completion_dialog.dart';

/// Pomodoro / Odak Modu Ekranı
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
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTimerStateChange(FocusTimerState state) {
    if (state.status == TimerStatus.running) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Tamamlandığında dialog göster
    if (state.status == TimerStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCompletionDialog(state);
      });
    }
  }

  Future<void> _showCompletionDialog(FocusTimerState state) async {
    HapticFeedback.heavyImpact();
    
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

    // State değişikliklerini dinle
    ref.listen<FocusTimerState>(focusTimerProvider, (previous, next) {
      _handleTimerStateChange(next);
    });

    return Scaffold(
      backgroundColor: timerState.status == TimerStatus.running
          ? timerState.focusType.color.withAlpha(15)
          : null,
      appBar: AppBar(
        title: const Text('Focus Mode'),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                ? 'Light Mode'
                : 'Dark Mode',
            onPressed: () {
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            },
          ),
          // Bugünün istatistikleri
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(100),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${todayStats['minutes']}m',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Mod seçimi
            _buildModeSelector(colorScheme, textTheme, timerState),

              const Spacer(flex: 1),

            // Ana zamanlayıcı
            _buildTimer(colorScheme, textTheme, timerState),

              const Spacer(flex: 1),

            // Kategori seçimi
            if (timerState.focusType == FocusType.work)
              _buildCategorySelector(colorScheme, textTheme, timerState),

              if (timerState.focusType == FocusType.work)
                const SizedBox(height: 12),

            // Kontrol butonları
            _buildControls(colorScheme, timerState),

              const SizedBox(height: 8),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(
    ColorScheme colorScheme,
    TextTheme textTheme,
    FocusTimerState timerState,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: FocusType.values.map((type) {
          final isSelected = timerState.focusType == type;
          return Expanded(
            child: GestureDetector(
              onTap: timerState.status == TimerStatus.idle
                  ? () => ref.read(focusTimerProvider.notifier).setFocusType(type)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? type.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: type.color.withAlpha(60),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type == FocusType.work
                          ? Icons.work_outline
                          : type == FocusType.shortBreak
                              ? Icons.coffee_outlined
                              : Icons.weekend_outlined,
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.title,
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimer(
    ColorScheme colorScheme,
    TextTheme textTheme,
    FocusTimerState timerState,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Daha küçük ekranlar için daha küçük timer
    final size = (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.45;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arka plan dairesi
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest.withAlpha(50),
              ),
            ),

            // İlerleme çemberi
            SizedBox(
              width: size - 20,
              height: size - 20,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: timerState.progress,
                  color: timerState.focusType.color,
                  backgroundColor: colorScheme.outlineVariant.withAlpha(80),
                  strokeWidth: 12,
                ),
              ),
            ),

            // İç daire ve içerik
            Container(
              width: size - 60,
              height: size - 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(20),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Süre
                  Text(
                    timerState.formattedTime,
                    style: TextStyle(
                      fontSize: size * 0.18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                      color: timerState.status == TimerStatus.running
                          ? timerState.focusType.color
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Durum etiketi
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: timerState.focusType.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(timerState.status),
                      style: textTheme.labelMedium?.copyWith(
                        color: timerState.focusType.color,
                        fontWeight: FontWeight.w600,
                      ),
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

  String _getStatusText(TimerStatus status) {
    switch (status) {
      case TimerStatus.idle:
        return 'Ready';
      case TimerStatus.running:
        return 'Focusing...';
      case TimerStatus.paused:
        return 'Paused';
      case TimerStatus.completed:
        return 'Done!';
    }
  }

  Widget _buildCategorySelector(
    ColorScheme colorScheme,
    TextTheme textTheme,
    FocusTimerState timerState,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Category',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: TaskCategory.values.map((category) {
              final isSelected = timerState.category == category;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: timerState.status == TimerStatus.idle
                        ? () {
                          ref
                              .read(focusTimerProvider.notifier)
                              .setCategory(category);
                      }
                    : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? category.color
                            : colorScheme.surfaceContainerHighest.withAlpha(100),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: colorScheme.outlineVariant,
                                width: 1,
                              ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                  category.icon,
                  size: 16,
                  color: isSelected ? Colors.white : category.color,
                ),
                          const SizedBox(height: 2),
                          Text(
                            category.title,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ColorScheme colorScheme, FocusTimerState timerState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Sıfırla butonu
          if (timerState.status != TimerStatus.idle)
            _ControlButton(
              icon: Icons.refresh,
              label: 'Reset',
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(focusTimerProvider.notifier).reset();
              },
              color: colorScheme.onSurfaceVariant,
            ),

          // Ana buton (Başlat/Duraklat/Devam)
          _MainControlButton(
            status: timerState.status,
            focusType: timerState.focusType,
            onPressed: () {
              HapticFeedback.mediumImpact();
              final notifier = ref.read(focusTimerProvider.notifier);
              switch (timerState.status) {
                case TimerStatus.idle:
                  notifier.start();
                  break;
                case TimerStatus.running:
                  notifier.pause();
                  break;
                case TimerStatus.paused:
                  notifier.resume();
                  break;
                case TimerStatus.completed:
                  notifier.reset();
                  break;
              }
            },
          ),

          // Erken bitir butonu
          if (timerState.status == TimerStatus.running ||
              timerState.status == TimerStatus.paused)
            _ControlButton(
              icon: Icons.stop,
              label: 'Finish',
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showCompletionDialog(timerState);
              },
              color: colorScheme.error,
            ),
        ],
      ),
    );
  }
}

/// Kontrol butonu
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: 20),
          style: IconButton.styleFrom(
            side: BorderSide(color: color.withAlpha(80)),
            padding: const EdgeInsets.all(10),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

/// Ana kontrol butonu
class _MainControlButton extends StatelessWidget {
  const _MainControlButton({
    required this.status,
    required this.focusType,
    required this.onPressed,
  });

  final TimerStatus status;
  final FocusType focusType;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;

    switch (status) {
      case TimerStatus.idle:
        icon = Icons.play_arrow;
        label = 'Start';
        break;
      case TimerStatus.running:
        icon = Icons.pause;
        label = 'Pause';
        break;
      case TimerStatus.paused:
        icon = Icons.play_arrow;
        label = 'Resume';
        break;
      case TimerStatus.completed:
        icon = Icons.refresh;
        label = 'Restart';
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                focusType.color,
                focusType.color.withAlpha(200),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: focusType.color.withAlpha(100),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 28),
            padding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: focusType.color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Dairesel ilerleme çizici
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Arka plan çemberi
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // İlerleme çemberi
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
