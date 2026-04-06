import 'package:flutter/material.dart';
// google_fonts import removed — Heebo is loaded via index.html CSS link

class VetoPalette {
  // ── Light backgrounds (page / card / form areas) ──────────────
  static const Color bg       = Color(0xFFF1F5F9); // slate-100  — page background
  static const Color surface  = Color(0xFFFFFFFF); // white      — cards & panels
  static const Color surface2 = Color(0xFFF8FAFC); // slate-50   — elevated card
  static const Color border   = Color(0xFFE2E8F0); // slate-200  — light border

  // ── Dark panel colors (hero sections, headers, splash) ────────
  static const Color darkBg      = Color(0xFF060C17); // near-black
  static const Color darkSurface = Color(0xFF0C1526); // deep dark card
  static const Color darkBorder  = Color(0xFF182336); // dark subtle border

  // ── Semantics — unchanged ─────────────────────────────────────
  static const Color primary   = Color(0xFF3B82F6); // blue-500  — trust, actions
  static const Color emergency = Color(0xFFEF4444); // red-500   — danger, SOS
  static const Color success   = Color(0xFF22C55E); // green-500 — OK, available
  static const Color warning   = Color(0xFFF59E0B); // amber-500 — caution
  static const Color info      = Color(0xFF60A5FA); // blue-400  — neutral info

  // ── Text (for light backgrounds) ──────────────────────────────
  static const Color text       = Color(0xFF0F172A); // slate-900 — primary text
  static const Color textMuted  = Color(0xFF475569); // slate-600 — secondary text
  static const Color textSubtle = Color(0xFF94A3B8); // slate-400 — placeholder

  // ── Legacy aliases kept so existing code compiles ─────────────
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
  // Deep navy for headers + dark hero panels — gives the "mixed" feel
  static const Color _navBg  = Color(0xFF0F172A); // slate-900
  static const Color _navFg  = Colors.white;

  static ThemeData dark() {
    final base = ThemeData.light(useMaterial3: true);

    final tt = base.textTheme.apply(
      fontFamily: 'Heebo',
    ).apply(
      bodyColor: VetoPalette.text,
      displayColor: VetoPalette.text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: VetoPalette.bg,
      colorScheme: const ColorScheme.light(
        primary: VetoPalette.primary,
        secondary: VetoPalette.info,
        surface: VetoPalette.surface,
        error: VetoPalette.emergency,
        onSurface: VetoPalette.text,
        onPrimary: Colors.white,
      ),
      textTheme: tt,
      appBarTheme: const AppBarTheme(
        backgroundColor: _navBg,
        foregroundColor: _navFg,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Heebo',
          color: _navFg,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _navFg),
        actionsIconTheme: IconThemeData(color: _navFg),
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
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VetoPalette.text,
          side: const BorderSide(color: VetoPalette.border),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w500),
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
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
