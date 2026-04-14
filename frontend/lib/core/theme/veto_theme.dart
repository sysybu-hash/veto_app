// ============================================================
//  veto_theme.dart — VETO Design System
//  Professional · Legal · Deep Navy & Gold
// ============================================================

import 'package:flutter/material.dart';

class VetoColors {
  VetoColors._();

  // ── Base ───────────────────────────────────────────────────
  static const Color background    = Color(0xFF07101C);
  static const Color surface       = Color(0xFF0C1827);
  static const Color surfaceHigh   = Color(0xFF121F32);
  static const Color surfaceGlass  = Color(0x1AC9A050);

  // ── Accent (legal gold) ────────────────────────────────────
  static const Color accent        = Color(0xFFC9A050);
  static const Color accentDark    = Color(0xFF8B6B1A);
  static const Color accentGlow    = Color(0x40C9A050);

  // ── Gold palette ───────────────────────────────────────────
  static const Color goldLight     = Color(0xFFE2C070);
  static const Color goldDim       = Color(0xFF9A7830);
  static const Color goldSoft      = Color(0x20C9A050);

  // ── VETO (emergency red) ───────────────────────────────────
  static const Color vetoRed       = Color(0xFFFF1744);
  static const Color vetoRedDeep   = Color(0xFFD50000);
  static const Color vetoRedGlow   = Color(0x60FF1744);
  static const Color vetoRedSoft   = Color(0x20FF1744);

  // ── Text ───────────────────────────────────────────────────
  static const Color white         = Color(0xFFF0E8D5);
  static const Color silver        = Color(0xFFA8A090);
  static const Color silverLight   = Color(0xFFC8C0A8);
  static const Color silverDim     = Color(0xFF7A7260);
  static const Color textMuted     = Color(0xFF5A5445);

  // ── Status ─────────────────────────────────────────────────
  static const Color success       = Color(0xFF2ECC71);
  static const Color warning       = Color(0xFFF39C12);
  static const Color error         = Color(0xFFE74C3C);
  static const Color online        = Color(0xFF2ECC71);

  // ── Border ─────────────────────────────────────────────────
  static const Color border        = Color(0x30C9A050);
  static const Color borderLight   = Color(0x50C9A050);
  static const Color divider       = Color(0x18C9A050);
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

class VetoDecorations {
  VetoDecorations._();

  static BoxDecoration gradientBg() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF07101C), Color(0xFF0C1827)],
      ),
    );
  }

  static BoxDecoration surfaceCard({double radius = 16}) {
    return BoxDecoration(
      color: VetoColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: VetoColors.border),
    );
  }

  static List<BoxShadow> accentGlow({double intensity = 1.0}) {
    return [
      BoxShadow(
        color: VetoColors.accent.withOpacity(0.3 * intensity),
        blurRadius: 20 * intensity,
        spreadRadius: 2 * intensity,
      ),
    ];
  }
  
  /// Create a gold glow effect for elevated elements
  static List<BoxShadow> vetoGlow({double intensity = 1.0}) {
    return [
      BoxShadow(
        color: VetoColors.accent.withOpacity(0.3 * intensity),
        blurRadius: 20 * intensity,
        spreadRadius: 4 * intensity,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: VetoColors.accent.withOpacity(0.15 * intensity),
        blurRadius: 40 * intensity,
        spreadRadius: 8 * intensity,
        offset: const Offset(0, 8),
      ),
    ];
  }
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
        backgroundColor: Color(0xFF07101C),
        foregroundColor: Color(0xFFF0E8D5),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFC9A050),
          letterSpacing: 2.0,
        ),
      ),

      // ── Text ────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontFamily: 'Heebo', fontSize: 57, fontWeight: FontWeight.w700, color: Color(0xFFF0E8D5), letterSpacing: -0.5),
        displayMedium:  TextStyle(fontFamily: 'Heebo', fontSize: 45, fontWeight: FontWeight.w700, color: Color(0xFFF0E8D5)),
        displaySmall:   TextStyle(fontFamily: 'Heebo', fontSize: 36, fontWeight: FontWeight.w600, color: Color(0xFFF0E8D5)),
        headlineLarge:  TextStyle(fontFamily: 'Heebo', fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFFC9A050), letterSpacing: 0.5),
        headlineMedium: TextStyle(fontFamily: 'Heebo', fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFFF0E8D5)),
        headlineSmall:  TextStyle(fontFamily: 'Heebo', fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFF0E8D5)),
        titleLarge:     TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF0E8D5), letterSpacing: 0.3),
        titleMedium:    TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFF0E8D5)),
        titleSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFC8C0A8)),
        bodyLarge:      TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFF0E8D5)),
        bodyMedium:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFA8A090)),
        bodySmall:      TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF7A7260)),
        labelLarge:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF0E8D5), letterSpacing: 0.8),
        labelMedium:    TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFA8A090)),
        labelSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF5A5445)),
      ),

      // ── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: VetoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: VetoColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        shadowColor: VetoColors.accent,
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
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: VetoColors.surfaceHigh,
        contentTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 14,
          color: VetoColors.white,
        ),
      ),
    );
  }
}
