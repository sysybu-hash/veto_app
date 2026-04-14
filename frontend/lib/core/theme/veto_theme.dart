// ============================================================
//  veto_theme.dart — VETO Design System
//  Professional · Legal · Deep Navy & Gold
// ============================================================

import 'package:flutter/material.dart';

class VetoColors {
  VetoColors._();

  // ── Base (bright luxury — warm ivory & paper) ──────────────
  static const Color background    = Color(0xFFFBF9F5);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceHigh   = Color(0xFFF3EEE6);
  static const Color surfaceGlass  = Color(0x14B8941E);

  // ── Accent (antique gold on light) ─────────────────────────
  static const Color accent        = Color(0xFFB8941E);
  static const Color accentDark    = Color(0xFF8A6F14);
  static const Color accentGlow    = Color(0x33C9A050);

  // ── Gold palette ───────────────────────────────────────────
  static const Color goldLight     = Color(0xFFD4AF37);
  static const Color goldDim       = Color(0xFF9A7830);
  static const Color goldSoft      = Color(0x18C9A050);

  // ── VETO (emergency red) ───────────────────────────────────
  static const Color vetoRed       = Color(0xFFE53935);
  static const Color vetoRedDeep   = Color(0xFFC62828);
  static const Color vetoRedGlow   = Color(0x45E53935);
  static const Color vetoRedSoft   = Color(0x18E53935);

  // ── Text (ink on light — names kept for compatibility) ───
  static const Color white         = Color(0xFF1C1814);
  static const Color silver        = Color(0xFF5E5A52);
  static const Color silverLight   = Color(0xFF7A756C);
  static const Color silverDim     = Color(0xFF9A948A);
  static const Color textMuted     = Color(0xFF8A847A);

  // ── Status ─────────────────────────────────────────────────
  static const Color success       = Color(0xFF1E8E4F);
  static const Color warning       = Color(0xFFC87F0A);
  static const Color error         = Color(0xFFC62828);
  static const Color online        = Color(0xFF1E8E4F);

  // ── Border ─────────────────────────────────────────────────
  static const Color border        = Color(0x33B8941E);
  static const Color borderLight   = Color(0x55C9A050);
  static const Color divider       = Color(0x22B8941E);
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

  /// Bright luxury theme — warm paper, gold accents, ink typography.
  static ThemeData luxuryLight() {
    const ink = VetoColors.white;
    const paper = VetoColors.background;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paper,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: VetoColors.accent,
        onPrimary: Colors.white,
        secondary: VetoColors.accentDark,
        onSecondary: Colors.white,
        surface: VetoColors.surface,
        onSurface: ink,
        error: VetoColors.error,
        onError: Colors.white,
      ),
      fontFamily: 'Heebo',
      // Web + Heebo: some glyphs (e.g. rare punctuation / mixed scripts) need a
      // broad Hebrew-capable fallback — avoids "Could not find Noto" warnings.
      fontFamilyFallback: const [
        'Noto Sans Hebrew',
        'Noto Sans',
        'Arial',
        'sans-serif',
      ],

      appBarTheme: const AppBarTheme(
        backgroundColor: VetoColors.surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: VetoColors.accent,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: ink),
      ),

      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontFamily: 'Heebo', fontSize: 57, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5),
        displayMedium:  TextStyle(fontFamily: 'Heebo', fontSize: 45, fontWeight: FontWeight.w700, color: ink),
        displaySmall:   TextStyle(fontFamily: 'Heebo', fontSize: 36, fontWeight: FontWeight.w600, color: ink),
        headlineLarge:  TextStyle(fontFamily: 'Heebo', fontSize: 32, fontWeight: FontWeight.w700, color: VetoColors.accent, letterSpacing: 0.4),
        headlineMedium: TextStyle(fontFamily: 'Heebo', fontSize: 28, fontWeight: FontWeight.w600, color: ink),
        headlineSmall:  TextStyle(fontFamily: 'Heebo', fontSize: 24, fontWeight: FontWeight.w600, color: ink),
        titleLarge:     TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w600, color: ink, letterSpacing: 0.2),
        titleMedium:    TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w500, color: ink),
        titleSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: VetoColors.silver),
        bodyLarge:      TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w600, color: ink, height: 1.35),
        bodyMedium:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: ink, height: 1.4),
        bodySmall:      TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600, color: VetoColors.silver, height: 1.35),
        labelLarge:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w700, color: ink, letterSpacing: 0.6),
        labelMedium:    TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600, color: VetoColors.silver),
        labelSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w600, color: VetoColors.silver),
      ),

      cardTheme: CardThemeData(
        color: VetoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: VetoColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x14000000),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VetoColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.silver, fontSize: 14),
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

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VetoColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: const Color(0x22000000),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VetoColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VetoColors.accentDark,
          side: const BorderSide(color: VetoColors.accent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VetoColors.accentDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(48, 40),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ink,
          iconSize: 22,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.all(10),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: VetoColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VetoColors.border, width: 1),
        ),
        titleTextStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w600, color: ink),
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14, color: VetoColors.silver),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VetoColors.surface,
        modalBarrierColor: Color(0x66000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2824),
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', color: Color(0xFFF5F0E8), fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(color: VetoColors.divider, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VetoColors.surface,
        indicatorColor: VetoColors.accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? VetoColors.accent : VetoColors.silver,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VetoColors.surfaceHigh,
        selectedColor: VetoColors.goldSoft,
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
        textColor: ink,
        iconColor: VetoColors.silver,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  /// @deprecated Use [luxuryLight] — kept for short-term compatibility.
  static ThemeData dark() => luxuryLight();
}

// ── Decoration Helpers ──────────────────────────────────────

class VetoDecorations {
  VetoDecorations._();

  static BoxDecoration glassCard({double radius = 16, double opacity = 0.08}) =>
      BoxDecoration(
        color: Color.fromRGBO(201, 160, 80, opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: VetoColors.border, width: 1),
      );

  static BoxDecoration surfaceCard({double radius = 16}) => BoxDecoration(
        color: VetoColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: VetoColors.border, width: 1),
      );

  static BoxDecoration goldCard({double radius = 12}) => BoxDecoration(
        color: VetoColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: VetoColors.accent.withValues(alpha:0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: VetoColors.accent.withValues(alpha:0.06),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      );

  static BoxDecoration gradientBg() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF9F5), Color(0xFFF5EFE6), Color(0xFFFBF9F5)],
          stops: [0.0, 0.5, 1.0],
        ),
      );

  static BoxDecoration legalHeaderBg() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF3EEE6)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x40B8941E), width: 1),
        ),
      );

  static List<BoxShadow> vetoGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: VetoColors.vetoRedGlow.withValues(alpha:0.6 * intensity),
          blurRadius: 40 * intensity,
          spreadRadius: 4 * intensity,
        ),
        BoxShadow(
          color: VetoColors.vetoRed.withValues(alpha:0.2 * intensity),
          blurRadius: 80 * intensity,
          spreadRadius: 10 * intensity,
        ),
      ];

  static List<BoxShadow> accentGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: VetoColors.accentGlow.withValues(alpha:0.6 * intensity),
          blurRadius: 30 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  static List<BoxShadow> goldGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: VetoColors.accent.withValues(alpha:0.25 * intensity),
          blurRadius: 24 * intensity,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: VetoColors.accent.withValues(alpha:0.1 * intensity),
          blurRadius: 48 * intensity,
          spreadRadius: 4 * intensity,
        ),
      ];
}
