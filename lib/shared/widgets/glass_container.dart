import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10.0,
    this.borderOpacity = 0.2,
    this.colorOpacity = 0.1,
    this.color,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double borderOpacity;
  final double colorOpacity;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseColor = color ?? (isDark ? Colors.white : Colors.white);
    final br = borderRadius ?? BorderRadius.circular(16);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // Hafif dış gölge
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: colorOpacity),
              borderRadius: br,
              border: Border.all(
                color: baseColor.withValues(alpha: borderOpacity),
                width: 1.5, // Daha belirgin cam kenarı
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor.withValues(alpha: (colorOpacity + 0.05).clamp(0.0, 1.0)),
                  baseColor.withValues(alpha: (colorOpacity - 0.05).clamp(0.0, 1.0)),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
