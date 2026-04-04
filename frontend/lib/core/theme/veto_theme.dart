import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VetoPalette {
  // Backgrounds
  static const Color bg       = Color(0xFF0F172A); // slate-900
  static const Color surface  = Color(0xFF1E293B); // slate-800
  static const Color surface2 = Color(0xFF263348); // elevated card
  static const Color border   = Color(0xFF334155); // slate-700

  // Semantics
  static const Color primary   = Color(0xFF3B82F6); // blue-500  — trust, actions
  static const Color emergency = Color(0xFFEF4444); // red-500   — danger, SOS
  static const Color success   = Color(0xFF22C55E); // green-500 — OK, available
  static const Color warning   = Color(0xFFF59E0B); // amber-500 — caution
  static const Color info      = Color(0xFF60A5FA); // blue-400  — neutral info

  // Text
  static const Color text       = Color(0xFFF8FAFC); // slate-50
  static const Color textMuted  = Color(0xFF94A3B8); // slate-400
  static const Color textSubtle = Color(0xFF64748B); // slate-500

  // Legacy aliases kept so existing code compiles without change
  static const Color ink    = bg;
  static const Color panel  = surface;
  static const Color cloud  = text;
  static const Color cyan   = primary;
  static const Color violet = Color(0xFF818CF8); // indigo-400
  static const Color mint   = success;
  static const Color coral  = emergency;
  static const Color amber  = warning;
  static const Color steel  = surface2;
}

class VetoTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    final tt = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: VetoPalette.text,
      displayColor: VetoPalette.text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: VetoPalette.bg,
      colorScheme: const ColorScheme.dark(
        primary: VetoPalette.primary,
        secondary: VetoPalette.info,
        surface: VetoPalette.surface,
        error: VetoPalette.emergency,
      ),
      textTheme: tt,
      appBarTheme: AppBarTheme(
        backgroundColor: VetoPalette.surface,
        foregroundColor: VetoPalette.text,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: VetoPalette.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: VetoPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: VetoPalette.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: VetoPalette.primary,
          disabledBackgroundColor: const Color(0xFF2D3952),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VetoPalette.text,
          side: const BorderSide(color: VetoPalette.border),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VetoPalette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: VetoPalette.textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: VetoPalette.textSubtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VetoPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VetoPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VetoPalette.primary, width: 1.5),
        ),
      ),
      dividerColor: VetoPalette.border,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? VetoPalette.primary
                : VetoPalette.textSubtle),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? VetoPalette.primary.withValues(alpha: 0.3)
                : VetoPalette.border),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VetoPalette.surface2,
        contentTextStyle: const TextStyle(color: VetoPalette.text, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
