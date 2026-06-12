import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Puhu maskotu — uygulamanın AI asistanının yüzü.
///
/// Tamamen kodla çizilir (CustomPaint): göz kırpma, süzülme (idle float),
/// dokununca sallanma ve kutlama zıplaması gibi gerçek animasyonlar yapar.
/// İleride Rive rigged karaktere geçilirse yalnızca bu widget'ın içi
/// değişir — kullanan ekranlar aynı kalır.
///
/// [celebrate] true verilirse sürekli zıplar (oturum sonu kutlaması).
class PuhuAvatar extends StatefulWidget {
  const PuhuAvatar({
    super.key,
    this.size = 96,
    this.celebrate = false,
    this.onTap,
  });

  final double size;
  final bool celebrate;
  final VoidCallback? onTap;

  @override
  State<PuhuAvatar> createState() => _PuhuAvatarState();
}

class _PuhuAvatarState extends State<PuhuAvatar>
    with TickerProviderStateMixin {
  // Idle süzülme — yavaş sinüs.
  late final AnimationController _float;
  // Göz kırpma — kısa, rastgele aralıklarla tetiklenir.
  late final AnimationController _blink;
  // Dokunma tepkisi — kısa sallanma.
  late final AnimationController _wiggle;
  // Kutlama — squash & stretch zıplama.
  late final AnimationController _jump;

  Timer? _blinkTimer;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _jump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scheduleBlink();
    if (widget.celebrate) _jump.repeat();
  }

  @override
  void didUpdateWidget(covariant PuhuAvatar old) {
    super.didUpdateWidget(old);
    if (widget.celebrate && !old.celebrate) {
      _jump.repeat();
    } else if (!widget.celebrate && old.celebrate) {
      _jump
        ..stop()
        ..value = 0;
    }
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2500 + _rng.nextInt(3500)),
      () async {
        if (!mounted) return;
        await _blink.forward();
        await _blink.reverse();
        // Bazen çift kırpar — daha canlı durur.
        if (_rng.nextInt(4) == 0 && mounted) {
          await _blink.forward();
          await _blink.reverse();
        }
        if (mounted) _scheduleBlink();
      },
    );
  }

  void _handleTap() {
    _wiggle
      ..value = 0
      ..forward();
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _float.dispose();
    _blink.dispose();
    _wiggle.dispose();
    _jump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_float, _blink, _wiggle, _jump]),
        builder: (context, _) {
          // Süzülme: yukarı-aşağı ±4% boyut.
          final floatDy =
              math.sin(_float.value * 2 * math.pi) * widget.size * 0.04;
          // Sallanma: sönümlü sinüs.
          final wiggleAngle = math.sin(_wiggle.value * math.pi * 3) *
              (1 - _wiggle.value) *
              0.12;
          // Zıplama: parabolik yükselme + inişte squash.
          final t = _jump.value;
          final jumpDy = -math.sin(t * math.pi) * widget.size * 0.22;
          final squash = 1 - math.sin(t * math.pi * 2).clamp(-1, 0) * 0.08;

          return Transform.translate(
            offset: Offset(0, floatDy + jumpDy),
            child: Transform.rotate(
              angle: wiggleAngle,
              child: Transform.scale(
                scaleY: squash,
                scaleX: 2 - squash,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _PuhuPainter(blink: _blink.value),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Baykuşu çizen painter. Oranlar app icon'daki Puhu'dan alındı.
class _PuhuPainter extends CustomPainter {
  _PuhuPainter({required this.blink});

  /// 0 = gözler açık, 1 = tamamen kapalı.
  final double blink;

  // İmza renkleri — app icon paleti.
  static const _body = Color(0xFF6F76F8); // Açık mor gövde
  static const _bodyDark = Color(0xFF5A5FE0); // Sağ yüz gölgesi
  static const _ear = Color(0xFF4A4ECC); // Kulak üçgenleri
  static const _eyeYellow = Color(0xFFFFC93C); // Dev göz
  static const _pupil = Color(0xFF1A1B2E);
  static const _beak = Color(0xFFFF9F1C);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ---- Kulaklar (üçgen tüyler) ----
    final earPaint = Paint()..color = _ear;
    final leftEar = Path()
      ..moveTo(w * 0.16, h * 0.30)
      ..quadraticBezierTo(w * 0.10, h * 0.06, w * 0.30, h * 0.14)
      ..lineTo(w * 0.38, h * 0.22)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.84, h * 0.30)
      ..quadraticBezierTo(w * 0.90, h * 0.06, w * 0.70, h * 0.14)
      ..lineTo(w * 0.62, h * 0.22)
      ..close();
    canvas.drawPath(leftEar, earPaint);
    canvas.drawPath(rightEar, earPaint);

    // ---- Kafa/gövde — yumuşak oval (yuvarlak yüz) ----
    final head = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, h * 0.54),
        width: w * 0.76,
        height: h * 0.80,
      ));
    canvas.drawPath(head, Paint()..color = _body);
    // Sağ yarı gölge — icon'daki iki tonlu yüz.
    canvas.save();
    canvas.clipPath(head);
    canvas.drawRect(
      Rect.fromLTRB(cx, 0, w, h),
      Paint()..color = _bodyDark.withAlpha(140),
    );
    canvas.restore();

    // ---- Gözler ----
    final eyeR = w * 0.21;
    final eyeY = h * 0.46;
    final leftEyeC = Offset(w * 0.32, eyeY);
    final rightEyeC = Offset(w * 0.68, eyeY);

    final eyePaint = Paint()..color = _eyeYellow;
    canvas.drawCircle(leftEyeC, eyeR, eyePaint);
    canvas.drawCircle(rightEyeC, eyeR, eyePaint);

    // Pupiller + parıltı (blink'te gizlenir).
    if (blink < 0.95) {
      final pupilPaint = Paint()..color = _pupil;
      final pupilR = eyeR * 0.42;
      canvas.drawCircle(leftEyeC, pupilR, pupilPaint);
      canvas.drawCircle(rightEyeC, pupilR, pupilPaint);
      final glint = Paint()..color = Colors.white;
      canvas.drawCircle(
          leftEyeC.translate(-pupilR * 0.35, -pupilR * 0.35),
          pupilR * 0.32,
          glint);
      canvas.drawCircle(
          rightEyeC.translate(-pupilR * 0.35, -pupilR * 0.35),
          pupilR * 0.32,
          glint);
    }

    // Göz kapakları — üstten inen gövde renginde yay.
    if (blink > 0) {
      final lidPaint = Paint()..color = _body;
      final lidH = eyeR * 2 * blink;
      for (final c in [leftEyeC, rightEyeC]) {
        canvas.save();
        canvas.clipPath(
            Path()..addOval(Rect.fromCircle(center: c, radius: eyeR + 0.5)));
        canvas.drawRect(
          Rect.fromLTWH(c.dx - eyeR - 1, c.dy - eyeR - 1, eyeR * 2 + 2, lidH),
          lidPaint,
        );
        canvas.restore();
      }
    }

    // ---- Gaga ----
    final beak = Path()
      ..moveTo(cx - w * 0.05, h * 0.56)
      ..lineTo(cx + w * 0.05, h * 0.56)
      ..lineTo(cx, h * 0.68)
      ..close();
    canvas.drawPath(beak, Paint()..color = _beak);

    // ---- Gülümseme ----
    final smile = Paint()
      ..color = _ear
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx - w * 0.10, h * 0.74),
          width: w * 0.09,
          height: h * 0.05),
      0.3,
      2.0,
      false,
      smile,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx + w * 0.10, h * 0.74),
          width: w * 0.09,
          height: h * 0.05),
      0.85,
      2.0,
      false,
      smile,
    );
  }

  @override
  bool shouldRepaint(_PuhuPainter old) => old.blink != blink;
}
