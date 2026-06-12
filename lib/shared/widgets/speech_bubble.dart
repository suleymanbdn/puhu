import 'dart:async';

import 'package:flutter/material.dart';

/// Puhu'nun konuşma balonu — metni typewriter efektiyle yazar.
///
/// [text] değiştiğinde animasyon baştan başlar. [animate] false ise metin
/// doğrudan gösterilir (örn. cache'ten gelen eski not).
class SpeechBubble extends StatefulWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.animate = true,
    this.tailAlignment = BubbleTail.left,
  });

  final String text;
  final bool animate;
  final BubbleTail tailAlignment;

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

enum BubbleTail { left, top }

class _SpeechBubbleState extends State<SpeechBubble> {
  Timer? _timer;
  int _visibleChars = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant SpeechBubble old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  void _start() {
    _timer?.cancel();
    if (!widget.animate) {
      _visibleChars = widget.text.length;
      return;
    }
    _visibleChars = 0;
    // ~50 karakter/sn — okunaklı ama bekletmeyen hız.
    _timer = Timer.periodic(const Duration(milliseconds: 20), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        _visibleChars += 1;
        if (_visibleChars >= widget.text.length) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visible = widget.text.substring(
        0, _visibleChars.clamp(0, widget.text.length));

    return CustomPaint(
      painter: _BubblePainter(
        color: colorScheme.primary.withAlpha(26),
        borderColor: colorScheme.primary.withAlpha(70),
        tail: widget.tailAlignment,
      ),
      child: Padding(
        // Kuyruk için sol/üst tarafta ekstra boşluk.
        padding: EdgeInsets.fromLTRB(
          widget.tailAlignment == BubbleTail.left ? 22 : 14,
          widget.tailAlignment == BubbleTail.top ? 20 : 12,
          14,
          12,
        ),
        child: Text(
          visible.isEmpty ? ' ' : visible,
          style: textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({
    required this.color,
    required this.borderColor,
    required this.tail,
  });

  final Color color;
  final Color borderColor;
  final BubbleTail tail;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final bodyRect = tail == BubbleTail.left
        ? Rect.fromLTRB(10, 0, size.width, size.height)
        : Rect.fromLTRB(0, 10, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(16));

    final path = Path()..addRRect(rrect);
    // Kuyruk üçgeni — Puhu'ya bakar.
    if (tail == BubbleTail.left) {
      final cy = size.height * 0.5;
      path
        ..moveTo(10, cy - 8)
        ..lineTo(0, cy)
        ..lineTo(10, cy + 8)
        ..close();
    } else {
      final cx = size.width * 0.5;
      path
        ..moveTo(cx - 8, 10)
        ..lineTo(cx, 0)
        ..lineTo(cx + 8, 10)
        ..close();
    }

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.color != color || old.tail != tail;
}
