// ============================================================
//  veto_theme.dart — VETO Design System
//  Luxury · Minimalist · Deep Navy & Silver
// ============================================================

import 'package:flutter/material.dart';

class VetoColors {
  VetoColors._();

  // ── Base ───────────────────────────────────────────────────
  static const Color background    = Color(0xFF050D1A);
  static const Color surface       = Color(0xFF0A1628);
  static const Color surfaceHigh   = Color(0xFF0F1F38);
  static const Color surfaceGlass  = Color(0x1A4E9BFF);

  // ── Accent (electric blue) ─────────────────────────────────
  static const Color accent        = Color(0xFF4E9BFF);
  static const Color accentDark    = Color(0xFF1A5CCC);
  static const Color accentGlow    = Color(0x404E9BFF);

  // ── VETO (emergency red) ───────────────────────────────────
  static const Color vetoRed       = Color(0xFFFF1744);
  static const Color vetoRedDeep   = Color(0xFFD50000);
  static const Color vetoRedGlow   = Color(0x60FF1744);
  static const Color vetoRedSoft   = Color(0x20FF1744);

  // ── Text ───────────────────────────────────────────────────
  static const Color white         = Color(0xFFF8FAFF);
  static const Color silver        = Color(0xFFB0BEC5);
  static const Color silverLight   = Color(0xFFCFD8DC);
  static const Color silverDim     = Color(0xFF78909C);
  static const Color textMuted     = Color(0xFF546E7A);

  // ── Status ─────────────────────────────────────────────────
  static const Color success       = Color(0xFF00E676);
  static const Color warning       = Color(0xFFFFD600);
  static const Color error         = Color(0xFFFF5252);
  static const Color online        = Color(0xFF00E676);

  // ── Border ─────────────────────────────────────────────────
  static const Color border        = Color(0x264E9BFF);
  static const Color borderLight   = Color(0x404E9BFF);
  static const Color divider       = Color(0x1AFFFFFF);
}

// ══════════════════════════════════════════════════════════════
//  VetoPalette — Full backward-compatibility alias for VetoColors
//  Maps every legacy property name used across old screens.
// ══════════════════════════════════════════════════════════════
class VetoPalette {
  VetoPalette._();

  // ── Core ───────────────────────────────────────────────────
  static const Color background    = VetoColors.background;
  /// Alias: main background
  static const Color bg            = VetoColors.background;
  /// Alias: slightly elevated surface (darker)
  static const Color darkBg        = VetoColors.surfaceHigh;
  static const Color surface       = VetoColors.surface;
  /// Alias: secondary surface
  static const Color surface2      = VetoColors.surfaceHigh;

  // ── Accent ─────────────────────────────────────────────────
  static const Color accent        = VetoColors.accent;
  /// Alias: primary action color
  static const Color primary       = VetoColors.accent;
  /// Alias: info color (teal/cyan variant)
  static const Color info          = Color(0xFF00BCD4);
  /// Alias: cyan
  static const Color cyan          = Color(0xFF00BCD4);
  /// Alias: coral / orange
  static const Color coral         = Color(0xFFFF6E40);

  // ── Emergency ──────────────────────────────────────────────
  static const Color vetoRed       = VetoColors.vetoRed;
  /// Alias: emergency alert color
  static const Color emergency     = VetoColors.vetoRed;

  // ── Status ─────────────────────────────────────────────────
  static const Color success       = VetoColors.success;
  static const Color warning       = VetoColors.warning;
  static const Color error         = VetoColors.error;

  // ── Text ───────────────────────────────────────────────────
  static const Color white         = VetoColors.white;
  /// Alias: primary text
  static const Color text          = VetoColors.white;
  static const Color silver        = VetoColors.silver;
  /// Alias: muted text
  static const Color textMuted     = VetoColors.silver;
  /// Alias: subtle / de-emphasized text
  static const Color textSubtle    = VetoColors.silverDim;

  // ── Borders ────────────────────────────────────────────────
  static const Color border        = VetoColors.border;
  /// Alias: darker/stronger border
  static const Color darkBorder    = VetoColors.borderLight;
}

class VetoTheme {
  VetoTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VetoColors.background,
      colorScheme: const ColorScheme.dark(
        brightness:  Brightness.dark,
        primary:     VetoColors.accent,
        onPrimary:   VetoColors.white,
        secondary:   VetoColors.accentDark,
        onSecondary: VetoColors.white,
        surface:     VetoColors.surface,
        onSurface:   VetoColors.white,
        error:       VetoColors.error,
        onError:     VetoColors.white,
      ),
      fontFamily: 'Heebo',

      // ── App Bar ─────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: VetoColors.background,
        foregroundColor: VetoColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: VetoColors.white,
          letterSpacing: 1.2,
        ),
      ),

      // ── Text ────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontFamily: 'Heebo', fontSize: 57, fontWeight: FontWeight.w700, color: VetoColors.white, letterSpacing: -0.5),
        displayMedium:  TextStyle(fontFamily: 'Heebo', fontSize: 45, fontWeight: FontWeight.w700, color: VetoColors.white),
        displaySmall:   TextStyle(fontFamily: 'Heebo', fontSize: 36, fontWeight: FontWeight.w600, color: VetoColors.white),
        headlineLarge:  TextStyle(fontFamily: 'Heebo', fontSize: 32, fontWeight: FontWeight.w700, color: VetoColors.white),
        headlineMedium: TextStyle(fontFamily: 'Heebo', fontSize: 28, fontWeight: FontWeight.w600, color: VetoColors.white),
        headlineSmall:  TextStyle(fontFamily: 'Heebo', fontSize: 24, fontWeight: FontWeight.w600, color: VetoColors.white),
        titleLarge:     TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w600, color: VetoColors.white),
        titleMedium:    TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w500, color: VetoColors.white),
        titleSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w500, color: VetoColors.silverLight),
        bodyLarge:      TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w400, color: VetoColors.white),
        bodyMedium:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w400, color: VetoColors.silver),
        bodySmall:      TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w400, color: VetoColors.silverDim),
        labelLarge:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: VetoColors.white, letterSpacing: 0.5),
        labelMedium:    TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w500, color: VetoColors.silver),
        labelSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w400, color: VetoColors.textMuted),
      ),

      // ── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: VetoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: VetoColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VetoColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.silverDim, fontSize: 14),
        floatingLabelStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.accent, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VetoColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VetoColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VetoColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VetoColors.error, width: 1.5),
        ),
      ),

      // ── Buttons ─────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VetoColors.accent,
          foregroundColor: VetoColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VetoColors.accent,
          side: const BorderSide(color: VetoColors.accent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VetoColors.accent,
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: VetoColors.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VetoColors.border, width: 1),
        ),
        titleTextStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w600, color: VetoColors.white),
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14, color: VetoColors.silver),
      ),

      // ── Bottom Sheet ────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VetoColors.surface,
        modalBarrierColor: Color(0xCC050D1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ── Snack Bar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VetoColors.surfaceHigh,
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Misc ────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(color: VetoColors.divider, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: VetoColors.surfaceHigh,
        selectedColor: VetoColors.accentGlow,
        labelStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.silver, fontSize: 13),
        side: const BorderSide(color: VetoColors.border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? VetoColors.accent : VetoColors.silverDim),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? VetoColors.accentGlow : VetoColors.surfaceHigh),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: VetoColors.white,
        iconColor: VetoColors.silver,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

// ── Decoration Helpers ──────────────────────────────────────

class VetoDecorations {
  VetoDecorations._();

  static BoxDecoration glassCard({double radius = 16, double opacity = 0.08}) =>
      BoxDecoration(
        color: Color.fromRGBO(78, 155, 255, opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: VetoColors.border, width: 1),
      );

  static BoxDecoration surfaceCard({double radius = 16}) => BoxDecoration(
        color: VetoColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: VetoColors.border, width: 1),
      );

  static BoxDecoration gradientBg() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050D1A), Color(0xFF071626), Color(0xFF050D1A)],
          stops: [0.0, 0.5, 1.0],
        ),
      );

  static List<BoxShadow> vetoGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: VetoColors.vetoRedGlow.withOpacity(0.6 * intensity),
          blurRadius: 40 * intensity,
          spreadRadius: 4 * intensity,
        ),
        BoxShadow(
          color: VetoColors.vetoRed.withOpacity(0.2 * intensity),
          blurRadius: 80 * intensity,
          spreadRadius: 10 * intensity,
        ),
      ];

  static List<BoxShadow> accentGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: VetoColors.accentGlow.withOpacity(0.6 * intensity),
          blurRadius: 30 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];
}
