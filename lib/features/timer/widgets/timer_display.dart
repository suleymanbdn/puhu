import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_container.dart';
import '../providers/focus_provider.dart';

/// Dairesel zamanlayıcı göstergesi
///
/// İlerleme çemberi, kalan süre ve durum etiketini gösterir.
/// Çalışırken pulse animasyonu uygular.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({
    super.key,
    required this.timerState,
    required this.pulseAnimation,
  });

  final FocusTimerState timerState;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final size =
        (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.45;

    return ScaleTransition(
      scale: pulseAnimation,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Parlayan arka plan (Glowing effect)
            Container(
              width: size - 10,
              height: size - 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: timerState.status == TimerStatus.running
                    ? [
                        BoxShadow(
                          color: timerState.focusType.color.withAlpha(100),
                          blurRadius: 50,
                          spreadRadius: pulseAnimation.value * 10,
                        ),
                        BoxShadow(
                          color: timerState.focusType.color.withAlpha(50),
                          blurRadius: 100,
                          spreadRadius: pulseAnimation.value * 20,
                        ),
                      ]
                    : [],
              ),
            ),

            // Arka plan dairesi (Glassmorphism)
            GlassContainer(
              width: size,
              height: size,
              borderRadius: BorderRadius.circular(size / 2),
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black,
              colorOpacity: 0.05,
              blur: 15,
              child: const SizedBox.expand(),
            ),

            // İlerleme çemberi
            SizedBox(
              width: size - 20,
              height: size - 20,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: timerState.progress,
                  color: timerState.focusType.color,
                  backgroundColor:
                      colorScheme.outlineVariant.withAlpha(80),
                  strokeWidth: 12,
                ),
              ),
            ),

            // İç daire: süre ve durum
            Container(
              width: size - 60,
              height: size - 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withAlpha(100) // Deep dark inside
                    : Colors.white.withAlpha(200),
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
                  // Kalan süre
                  Text(
                    timerState.formattedTime,
                    style: TextStyle(
                      fontSize: size * 0.18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: timerState.status == TimerStatus.running
                          ? timerState.focusType.color
                          : colorScheme.onSurface,
                      shadows: timerState.status == TimerStatus.running
                          ? [
                              Shadow(
                                color: timerState.focusType.color,
                                blurRadius: 10,
                              ),
                            ]
                          : [],
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
                      _statusText(timerState.status),
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

  String _statusText(TimerStatus status) {
    switch (status) {
      case TimerStatus.idle:
        return 'Hazır';
      case TimerStatus.running:
        return 'Odaklanıyor...';
      case TimerStatus.paused:
        return 'Duraklatıldı';
      case TimerStatus.completed:
        return 'Tamamlandı!';
    }
  }
}

/// Dairesel ilerleme çizici
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  const _CircularProgressPainter({
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
