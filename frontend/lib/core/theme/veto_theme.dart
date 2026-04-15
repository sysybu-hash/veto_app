// ============================================================
//  veto_theme.dart — VETO Design System v2
//  Aurora Glassmorphism — dark frosted glass, glowing orbs,
//  teal/cyan/sky aurora background, luminous white typography
// ============================================================

import 'package:flutter/material.dart';

// ── Aurora palette ────────────────────────────────────────
class VetoColors {
  VetoColors._();

  // ── Background layers ─────────────────────────────────
  static const Color background    = Color(0xFF0A1628);   // deep navy
  static const Color surface       = Color(0xFF0D1F3C);   // dark navy card
  static const Color surfaceHigh   = Color(0xFF112240);   // slightly lighter
  static const Color surfaceGlass  = Color(0x1AFFFFFF);   // white 10%

  static const Color surfaceMint     = Color(0x1200E5CC);
  static const Color surfaceSky      = Color(0x1238BDF8);
  static const Color surfaceLavender = Color(0x12A78BFA);

  // ── Brand teal/cyan ───────────────────────────────────
  static const Color accent        = Color(0xFF00E5CC);   // bright teal
  static const Color accentDark    = Color(0xFF00B4A0);
  static const Color accentGlow    = Color(0x4000E5CC);

  static const Color accentSky     = Color(0xFF38BDF8);   // sky blue
  static const Color accentViolet  = Color(0xFFA78BFA);   // soft violet
  static const Color accentCoral   = Color(0xFFFF6B6B);   // coral red

  // ── Legacy "gold" names ───────────────────────────────
  static const Color goldLight     = Color(0xFF00E5CC);
  static const Color goldDim       = Color(0xFF0369A1);
  static const Color goldSoft      = Color(0x1A00E5CC);

  // ── Emergency red ─────────────────────────────────────
  static const Color vetoRed       = Color(0xFFFF4B4B);
  static const Color vetoRedDeep   = Color(0xFFE03030);
  static const Color vetoRedGlow   = Color(0x66FF4B4B);
  static const Color vetoRedSoft   = Color(0x22FF4B4B);

  // ── Text — white on dark ───────────────────────────────
  static const Color white         = Color(0xFFFFFFFF);
  static const Color silver        = Color(0xFFB0C4D8);
  static const Color silverLight   = Color(0xFF8AA4BE);
  static const Color silverDim     = Color(0xFF5E7A99);
  static const Color textMuted     = Color(0xFF8AA4BE);

  // ── Status ────────────────────────────────────────────
  static const Color success       = Color(0xFF00E5CC);
  static const Color warning       = Color(0xFFFFBB33);
  static const Color error         = Color(0xFFFF4B4B);
  static const Color online        = Color(0xFF00E5CC);

  // ── Border / divider ──────────────────────────────────
  static const Color border        = Color(0x33FFFFFF);
  static const Color borderLight   = Color(0x55FFFFFF);
  static const Color divider       = Color(0x1AFFFFFF);
}

// ══════════════════════════════════════════════════════════
//  VetoPalette — backward-compat alias
// ══════════════════════════════════════════════════════════
class VetoPalette {
  VetoPalette._();

  static const Color background    = VetoColors.background;
  static const Color bg            = VetoColors.background;
  static const Color darkBg        = VetoColors.surfaceHigh;
  static const Color surface       = VetoColors.surface;
  static const Color surface2      = VetoColors.surfaceHigh;

  static const Color accent        = VetoColors.accent;
  static const Color primary       = VetoColors.accent;
  static const Color accentSky     = VetoColors.accentSky;
  static const Color info          = VetoColors.accentSky;
  static const Color cyan          = Color(0xFF06B6D4);
  static const Color coral         = VetoColors.accentCoral;

  static const Color surfaceMint     = VetoColors.surfaceMint;
  static const Color surfaceSkyTint  = VetoColors.surfaceSky;
  static const Color surfaceLavender = VetoColors.surfaceLavender;
  static const Color violet          = VetoColors.accentViolet;

  static const Color vetoRed       = VetoColors.vetoRed;
  static const Color emergency     = VetoColors.vetoRed;

  static const Color success       = VetoColors.success;
  static const Color warning       = VetoColors.warning;
  static const Color error         = VetoColors.error;

  static const Color white         = VetoColors.white;
  static const Color text          = VetoColors.white;
  static const Color silver        = VetoColors.silver;
  static const Color textMuted     = VetoColors.silver;
  static const Color textSubtle    = VetoColors.silverDim;

  static const Color border        = VetoColors.border;
  static const Color darkBorder    = VetoColors.borderLight;
}

class VetoTheme {
  VetoTheme._();

  static ThemeData luxuryLight() {
    const ink = VetoColors.white;
    const paper = VetoColors.background;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: paper,
      primaryIconTheme: const IconThemeData(color: ink, size: 24),
      iconTheme: const IconThemeData(color: ink, size: 24),
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: VetoColors.accent,
        onPrimary: Color(0xFF0A1628),
        secondary: VetoColors.accentSky,
        onSecondary: Color(0xFF0A1628),
        tertiary: VetoColors.accentViolet,
        onTertiary: Colors.white,
        surface: VetoColors.surface,
        onSurface: ink,
        error: VetoColors.error,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xCC0D1F3C),
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: VetoColors.accent.withValues(alpha: 0.3), width: 1),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Heebo',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: ink),
      ),

      textTheme: TextTheme(
        displayLarge:   const TextStyle(fontFamily: 'Heebo', fontSize: 57, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5),
        displayMedium:  const TextStyle(fontFamily: 'Heebo', fontSize: 45, fontWeight: FontWeight.w700, color: ink),
        displaySmall:   const TextStyle(fontFamily: 'Heebo', fontSize: 36, fontWeight: FontWeight.w600, color: ink),
        headlineLarge:  const TextStyle(fontFamily: 'Heebo', fontSize: 32, fontWeight: FontWeight.w800, color: ink, letterSpacing: 0.2),
        headlineMedium: const TextStyle(fontFamily: 'Heebo', fontSize: 28, fontWeight: FontWeight.w600, color: ink),
        headlineSmall:  const TextStyle(fontFamily: 'Heebo', fontSize: 24, fontWeight: FontWeight.w600, color: ink),
        titleLarge:     const TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w600, color: ink, letterSpacing: 0.2),
        titleMedium:    const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w500, color: ink),
        titleSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: VetoColors.silver),
        bodyLarge:      const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w600, color: ink, height: 1.35),
        bodyMedium:     const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: ink, height: 1.4),
        bodySmall:      TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600, color: VetoColors.silver, height: 1.35),
        labelLarge:     const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w700, color: ink, letterSpacing: 0.6),
        labelMedium:    TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600, color: VetoColors.silver),
        labelSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w600, color: VetoColors.silver),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xCC0D1F3C),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1AFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(fontFamily: 'Heebo', color: VetoColors.silverDim, fontSize: 14),
        labelStyle: TextStyle(fontFamily: 'Heebo', color: VetoColors.silver, fontSize: 14),
        floatingLabelStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.accent, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VetoColors.accent, width: 2),
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
          foregroundColor: const Color(0xFF0A1628),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          minimumSize: const Size(48, 48),
          iconSize: 22,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VetoColors.accent,
          foregroundColor: const Color(0xFF0A1628),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          iconSize: 22,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VetoColors.accent,
          side: const BorderSide(color: VetoColors.accent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          iconSize: 22,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VetoColors.accentSky,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(48, 40),
          iconSize: 22,
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
        backgroundColor: const Color(0xF00D1F3C),
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        titleTextStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w700, color: ink),
        contentTextStyle: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: VetoColors.silver),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xF00D1F3C),
        modalBarrierColor: Color(0x88000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A2F4E),
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.1), thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xDD0D1F3C),
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: VetoColors.accent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? VetoColors.accent : VetoColors.silverDim,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x1AFFFFFF),
        selectedColor: VetoColors.accent.withValues(alpha: 0.25),
        labelStyle: TextStyle(fontFamily: 'Heebo', color: VetoColors.silver, fontSize: 13),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? VetoColors.accent : VetoColors.silverDim),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? VetoColors.accentGlow : const Color(0x1AFFFFFF)),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: Colors.white,
        iconColor: VetoColors.accent,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  static ThemeData dark() => luxuryLight();
}

// ── Decoration Helpers ──────────────────────────────────────

class VetoDecorations {
  VetoDecorations._();

  /// True dark glass card — semi-transparent dark with white border
  static BoxDecoration glassCard({double radius = 16, double opacity = 0.6}) =>
      BoxDecoration(
        color: Color.fromRGBO(13, 31, 60, opacity * 0.85),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF00E5CC).withValues(alpha: 0.04),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      );

  static BoxDecoration surfaceCard({double radius = 16}) => BoxDecoration(
        color: const Color(0xCC0D1F3C),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration goldCard({double radius = 12}) => BoxDecoration(
        color: const Color(0xCC0D1F3C),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF00E5CC).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5CC).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      );

  /// Aurora radial gradient background — blue/teal/purple blobs on deep navy
  static BoxDecoration gradientBg() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1628), // deep navy
            Color(0xFF0D1F3C), // navy
            Color(0xFF0A1628), // deep navy
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      );

  static BoxDecoration legalHeaderBg() => BoxDecoration(
        color: const Color(0xCC0D1F3C),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF00E5CC).withValues(alpha: 0.3), width: 1),
        ),
      );

  static List<BoxShadow> vetoGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: const Color(0xFFFF4B4B).withValues(alpha: 0.5 * intensity),
          blurRadius: 40 * intensity,
          spreadRadius: 4 * intensity,
        ),
        BoxShadow(
          color: const Color(0xFFFF4B4B).withValues(alpha: 0.25 * intensity),
          blurRadius: 80 * intensity,
          spreadRadius: 12 * intensity,
        ),
      ];

  static List<BoxShadow> accentGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: const Color(0xFF00E5CC).withValues(alpha: 0.5 * intensity),
          blurRadius: 30 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  static List<BoxShadow> goldGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: const Color(0xFF00E5CC).withValues(alpha: 0.2 * intensity),
          blurRadius: 22 * intensity,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.12 * intensity),
          blurRadius: 40 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];
}
