// ============================================================
//  veto_theme.dart — VETO Design System
//  Bright fintech / “Swiss-clean + color” — teal primary, airy surfaces
// ============================================================

import 'package:flutter/material.dart';

class VetoColors {
  VetoColors._();

  // ── Base (airy ice + white — post-login app shell) ──────────
  static const Color background    = Color(0xFFE8F4FC);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceHigh   = Color(0xFFF0F9FF);
  static const Color surfaceGlass  = Color(0x140D9488);

  /// Tinted card backs (rotate for variety in custom layouts)
  static const Color surfaceMint     = Color(0xFFECFDF5);
  static const Color surfaceSky    = Color(0xFFF0F9FF);
  static const Color surfaceLavender = Color(0xFFF5F3FF);

  // ── Brand (teal primary) ───────────────────────────────────
  static const Color accent        = Color(0xFF0D9488);
  static const Color accentDark    = Color(0xFF0F7668);
  static const Color accentGlow    = Color(0x330D9488);

  /// Extra hues for icons / secondary CTAs (mockup: sky, violet, coral)
  static const Color accentSky     = Color(0xFF0284C7);
  static const Color accentViolet  = Color(0xFF6366F1);
  static const Color accentCoral   = Color(0xFFF97316);

  // ── Legacy “gold” names (code still references) → cool tones
  static const Color goldLight     = Color(0xFF22D3EE);
  static const Color goldDim       = Color(0xFF0369A1);
  static const Color goldSoft      = Color(0x1A0D9488);

  // ── VETO (emergency red) ───────────────────────────────────
  static const Color vetoRed       = Color(0xFFE53935);
  static const Color vetoRedDeep   = Color(0xFFC62828);
  static const Color vetoRedGlow   = Color(0x45E53935);
  static const Color vetoRedSoft   = Color(0x18E53935);

  // ── Text — darker ink on light (high contrast) ─────────────
  static const Color white         = Color(0xFF0F172A);
  static const Color silver        = Color(0xFF475569);
  static const Color silverLight   = Color(0xFF64748B);
  static const Color silverDim     = Color(0xFF94A3B8);
  static const Color textMuted     = Color(0xFF64748B);

  // ── Status ─────────────────────────────────────────────────
  static const Color success       = Color(0xFF059669);
  static const Color warning       = Color(0xFFD97706);
  static const Color error         = Color(0xFFDC2626);
  static const Color online        = Color(0xFF059669);

  // ── Border / divider (cool slate) ─────────────────────────
  static const Color border        = Color(0xFFCBD5E1);
  static const Color borderLight   = Color(0xFF94A3B8);
  static const Color divider       = Color(0xFFE2E8F0);
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
  /// Legacy name: light tinted surface (not a dark chrome bar).
  static const Color darkBg        = VetoColors.surfaceHigh;
  static const Color surface       = VetoColors.surface;
  /// Alias: secondary surface
  static const Color surface2      = VetoColors.surfaceHigh;

  // ── Accent ─────────────────────────────────────────────────
  static const Color accent        = VetoColors.accent;
  /// Alias: primary action color
  static const Color primary       = VetoColors.accent;
  /// Sky blue secondary accent (icons, highlights)
  static const Color accentSky     = VetoColors.accentSky;
  /// Alias: info / sky accent
  static const Color info          = VetoColors.accentSky;
  /// Alias: cyan
  static const Color cyan          = Color(0xFF06B6D4);
  /// Alias: coral (secondary warm CTA)
  static const Color coral         = VetoColors.accentCoral;

  /// Tinted surfaces for cards / sections
  static const Color surfaceMint     = VetoColors.surfaceMint;
  static const Color surfaceSkyTint  = VetoColors.surfaceSky;
  static const Color surfaceLavender = VetoColors.surfaceLavender;
  static const Color violet          = VetoColors.accentViolet;

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

  /// App theme — bright icy shell, teal primary, dark type, soft colorful chips.
  static ThemeData luxuryLight() {
    const ink = VetoColors.white;
    const paper = VetoColors.background;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paper,
      // Default icon color/size (AppBar uses appBarTheme.iconTheme).
      primaryIconTheme: const IconThemeData(color: ink, size: 24),
      iconTheme: const IconThemeData(color: ink, size: 24),
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: VetoColors.accent,
        onPrimary: Colors.white,
        secondary: VetoColors.accentSky,
        onSecondary: Colors.white,
        tertiary: VetoColors.accentViolet,
        onTertiary: Colors.white,
        surface: VetoColors.surface,
        onSurface: ink,
        error: VetoColors.error,
        onError: Colors.white,
      ),
      // Never set ThemeData.fontFamily / fontFamilyFallback here. On Flutter Web
      // those values merge into Icon's TextStyle and replace MaterialIcons with
      // Heebo → blank squares site-wide. Hebrew uses explicit fontFamily on each
      // entry in [textTheme] and in input/button themes below.

      appBarTheme: AppBarTheme(
        backgroundColor: VetoColors.surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x140D9488),
        surfaceTintColor: const Color(0x0D0D9488),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF0D9488), width: 2),
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

      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontFamily: 'Heebo', fontSize: 57, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5),
        displayMedium:  TextStyle(fontFamily: 'Heebo', fontSize: 45, fontWeight: FontWeight.w700, color: ink),
        displaySmall:   TextStyle(fontFamily: 'Heebo', fontSize: 36, fontWeight: FontWeight.w600, color: ink),
        headlineLarge:  TextStyle(fontFamily: 'Heebo', fontSize: 32, fontWeight: FontWeight.w800, color: ink, letterSpacing: 0.2),
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
        elevation: 0.5,
        shadowColor: const Color(0x120F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: VetoColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
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
          borderSide: const BorderSide(color: VetoColors.accentSky, width: 2),
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
          iconSize: 22,
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
          iconSize: 22,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VetoColors.accentDark,
          side: const BorderSide(color: VetoColors.accent, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          iconSize: 22,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w600),
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
        backgroundColor: Color(0xFF1E293B),
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', color: Color(0xFFF8FAFC), fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(color: VetoColors.divider, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VetoColors.surface,
        elevation: 3,
        shadowColor: const Color(0x140D9488),
        indicatorColor: const Color(0xFFCCFBF1),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w700),
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
        backgroundColor: VetoColors.surfaceSky,
        selectedColor: const Color(0xFFCCFBF1),
        labelStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.silver, fontSize: 13),
        side: const BorderSide(color: VetoColors.border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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

  static BoxDecoration glassCard({double radius = 16, double opacity = 0.6}) =>
      BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration surfaceCard({double radius = 16}) => BoxDecoration(
        color: VetoColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration goldCard({double radius = 12}) => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: VetoColors.accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: VetoColors.accentGlow.withValues(alpha: 0.25),
            blurRadius: 14,
            spreadRadius: 0,
          ),
        ],
      );

  static BoxDecoration gradientBg() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0F2FE), // Light sky blue
            Color(0xFFF0FDF4), // Light mint
            Color(0xFFFFFFFF), // White
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      );

  static BoxDecoration legalHeaderBg() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF0F9FF)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x660D9488), width: 2),
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
          color: VetoColors.accent.withValues(alpha: 0.22 * intensity),
          blurRadius: 22 * intensity,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: VetoColors.accentSky.withValues(alpha: 0.12 * intensity),
          blurRadius: 40 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];
}
