import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/focus_session.dart';
import '../providers/focus_provider.dart';
import '../widgets/focus_completion_dialog.dart';

/// Zamanlayıcı kontrol butonları (Sıfırla / Başlat-Duraklat-Devam / Bitir)
class TimerControls extends ConsumerWidget {
  const TimerControls({super.key, required this.timerState});

  final FocusTimerState timerState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Sıfırla butonu
          if (timerState.status != TimerStatus.idle)
            _ControlButton(
              icon: Icons.refresh,
              label: 'Sıfırla',
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(focusTimerProvider.notifier).reset();
              },
              color: colorScheme.onSurfaceVariant,
            ),

          // Ana buton
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
              label: 'Bitir',
              onPressed: () {
                HapticFeedback.mediumImpact();
                FocusCompletionDialog.show(
                  context,
                  elapsedMinutes: timerState.elapsedMinutes,
                  focusType: timerState.focusType,
                );
              },
              color: colorScheme.error,
            ),
        ],
      ),
    );
  }
}

/// Yardımcı kontrol butonu (Sıfırla / Bitir)
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

/// Ana kontrol butonu (Başlat / Duraklat / Devam / Tekrar)
class _MainControlButton extends StatefulWidget {
  const _MainControlButton({
    required this.status,
    required this.focusType,
    required this.onPressed,
  });

  final TimerStatus status;
  final FocusType focusType;
  final VoidCallback onPressed;

  @override
  State<_MainControlButton> createState() => _MainControlButtonState();
}

class _MainControlButtonState extends State<_MainControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.status == TimerStatus.running) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _MainControlButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      if (widget.status == TimerStatus.running) {
        _controller.repeat(reverse: true);
      } else {
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (IconData, String) _iconAndLabel() {
    switch (widget.status) {
      case TimerStatus.idle:
        return (Icons.play_arrow_rounded, 'Başlat');
      case TimerStatus.running:
        return (Icons.pause_rounded, 'Duraklat');
      case TimerStatus.paused:
        return (Icons.play_arrow_rounded, 'Devam');
      case TimerStatus.completed:
        return (Icons.refresh_rounded, 'Tekrar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _iconAndLabel();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Nefes alma (breathing) efekti için scale ve parlama değerleri
            final scale = 1.0 + (_controller.value * 0.06); 
            final glowOpacity = 100 + (_controller.value * 120).toInt();

            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.focusType.color,
                      widget.focusType.color.withAlpha(200),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    // Dış parlama (Neon glow)
                    BoxShadow(
                      color: widget.focusType.color.withAlpha(glowOpacity),
                      blurRadius: 20 + (_controller.value * 10),
                      spreadRadius: 2 + (_controller.value * 6),
                      offset: const Offset(0, 4),
                    ),
                    // İç sınır çizgisi (21st.dev glass effect)
                    BoxShadow(
                      color: Colors.white.withAlpha(100),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 0),
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: widget.onPressed,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Icon(icon, key: ValueKey(icon), color: Colors.white, size: 32),
                  ),
                  padding: const EdgeInsets.all(18),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            label,
            key: ValueKey(label),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: widget.focusType.color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
        ),
      ],
    );
  }
}
