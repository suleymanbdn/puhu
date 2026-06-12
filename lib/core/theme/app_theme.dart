import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uygulama teması — Sade, modern, Inter tipografisi
class AppTheme {
  AppTheme._();

  // ===========================================================================
  // PALETTE
  // ===========================================================================

  // Light palette
  static const Color _primaryL = Color(0xFF6366F1); // Indigo 500
  static const Color _bgL = Color(0xFFF5F7FA);
  static const Color _surfaceL = Color(0xFFFFFFFF);
  static const Color _onSurfaceL = Color(0xFF111827); // Gray 900
  static const Color _subtleL = Color(0xFF6B7280); // Gray 500
  static const Color _borderL = Color(0xFFE5E7EB); // Gray 200
  static const Color _primaryContainerL = Color(0xFFEEF2FF); // Indigo 50

  // Dark palette - VIBRANT & NEON
  static const Color _primaryD = Color(0xFF00F0FF); // Neon Cyan
  static const Color _bgD = Color(0xFF050511); // Deep dark blue/black
  /// Bottom sheet'ler için OPAK koyu yüzey — _surfaceD2 transparent olduğu
  /// için sheet'lerde kullanılamaz (arka içerik içinden görünür).
  static const Color _sheetD = Color(0xFF12132A);
  static const Color _surfaceD = Colors.transparent; // For glassmorphism
  static const Color _surfaceD2 = Colors.transparent; // For glassmorphism
  static const Color _onSurfaceD = Color(0xFFF8FAFC);
  static const Color _subtleD = Color(0xFF94A3B8);
  static const Color _borderD = Color(0x33FFFFFF); // Semi-transparent white
  static const Color _primaryContainerD = Color(0x2200F0FF);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // ===========================================================================
  // TEXT THEME
  // ===========================================================================

  static TextTheme _buildTextTheme(Color textColor, Color subtleColor) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 57, fontWeight: FontWeight.w300, color: textColor, letterSpacing: -0.25),
      displayMedium: GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.w300, color: textColor),
      displaySmall: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w400, color: textColor),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.3),
      headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.2),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.2),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: subtleColor),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: subtleColor, letterSpacing: 0.3),
    );
  }

  // ===========================================================================
  // LIGHT THEME
  // ===========================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: _buildTextTheme(_onSurfaceL, _subtleL),
      colorScheme: const ColorScheme.light(
        primary: _primaryL,
        onPrimary: Colors.white,
        primaryContainer: _primaryContainerL,
        onPrimaryContainer: Color(0xFF312E81),
        secondary: Color(0xFF8B5CF6),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFF5F3FF),
        onSecondaryContainer: Color(0xFF5B21B6),
        tertiary: Color(0xFF06B6D4),
        onTertiary: Colors.white,
        error: danger,
        onError: Colors.white,
        errorContainer: Color(0xFFFEF2F2),
        surface: _surfaceL,
        onSurface: _onSurfaceL,
        onSurfaceVariant: _subtleL,
        outline: _borderL,
        outlineVariant: Color(0xFFF3F4F6),
        surfaceContainerHighest: Color(0xFFF9FAFB),
        surfaceContainerHigh: Color(0xFFF3F4F6),
        surfaceContainer: _surfaceL,
        shadow: Color(0xFF000000),
      ),
      scaffoldBackgroundColor: _bgL,
      appBarTheme: AppBarTheme(
        // Transparent: gövde gradient'i (AppBackground) bar arkasından da
        // aksın — düz blok renk temayla kopukluk yaratıyordu.
        backgroundColor: Colors.transparent,
        foregroundColor: _onSurfaceL,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _onSurfaceL,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: _onSurfaceL, size: 22),
      ),
      cardTheme: CardThemeData(
        color: _surfaceL,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _borderL, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceL,
        indicatorColor: _primaryContainerL,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primaryL, size: 22);
          }
          return const IconThemeData(color: _subtleL, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _primaryL);
          }
          return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _subtleL);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryL,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryL,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryL,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: _borderL, width: 1.5),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryL,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _bgL,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderL)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderL)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryL, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: danger)),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: _subtleL),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: _subtleL),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? _primaryL : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: _borderL, width: 1.5),
      ),
      dividerTheme: const DividerThemeData(color: _borderL, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: _bgL,
        selectedColor: _primaryContainerL,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceL),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: _borderL),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surfaceL,
        modalBackgroundColor: _surfaceL,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceL,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _onSurfaceL),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: _subtleL),
      ),
    );
  }

  // ===========================================================================
  // DARK THEME
  // ===========================================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: _buildTextTheme(_onSurfaceD, _subtleD),
      colorScheme: const ColorScheme.dark(
        primary: _primaryD,
        onPrimary: Color(0xFF000000),
        primaryContainer: _primaryContainerD,
        onPrimaryContainer: _primaryD,
        secondary: Color(0xFFB026FF), // Neon Purple
        onSecondary: Colors.white,
        secondaryContainer: Color(0x22B026FF),
        onSecondaryContainer: Color(0xFFE9D5FF),
        tertiary: Color(0xFFFF007F), // Neon Pink
        onTertiary: Colors.white,
        error: Color(0xFFFF453A),
        onError: Colors.white,
        errorContainer: Color(0x33FF453A),
        surface: _surfaceD2,
        onSurface: _onSurfaceD,
        onSurfaceVariant: _subtleD,
        outline: _borderD,
        outlineVariant: Color(0x11FFFFFF),
        surfaceContainerHighest: Color(0x11FFFFFF),
        surfaceContainerHigh: Color(0x08FFFFFF),
        surfaceContainer: _surfaceD2,
        shadow: Color(0xFF000000),
      ),
      scaffoldBackgroundColor: _bgD,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _onSurfaceD,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _onSurfaceD,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: _onSurfaceD, size: 22),
      ),
      cardTheme: CardThemeData(
        color: _surfaceD2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _borderD, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent, // Glass effect will handle bg
        indicatorColor: _primaryContainerD,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primaryD, size: 24);
          }
          return const IconThemeData(color: _subtleD, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _primaryD);
          }
          return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _subtleD);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryD,
        foregroundColor: Color(0xFF1E1B4B),
        elevation: 0,
        shape: CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryD,
          foregroundColor: const Color(0xFF1E1B4B),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryD,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: _borderD, width: 1.5),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryD,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceD,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderD)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderD)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryD, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFC8181))),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: _subtleD),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: _subtleD),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? _primaryD : Colors.transparent),
        checkColor: WidgetStateProperty.all(const Color(0xFF1E1B4B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: _borderD, width: 1.5),
      ),
      dividerTheme: const DividerThemeData(color: _borderD, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceD,
        selectedColor: _primaryContainerD,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: _borderD),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _sheetD,
        modalBackgroundColor: _sheetD,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceD2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _onSurfaceD),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: _subtleD),
      ),
    );
  }
}
