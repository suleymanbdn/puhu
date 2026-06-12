import 'package:flutter/material.dart';

/// Shell dışında push edilen ekranların arka planı.
///
/// Shell ekranları MainScaffold'un gradient'i üzerinde şeffaf durur; ancak
/// standalone (push edilen) ekranların kendi opak arka planı olmazsa geçiş
/// animasyonu sırasında arkadaki ekran görünür. Bu widget aynı gradient'i sağlar.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E1B4B),
                  Color(0xFF000000),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
              ),
      ),
      child: child,
    );
  }
}
