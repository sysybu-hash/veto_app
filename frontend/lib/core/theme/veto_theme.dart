// ============================================================
//  veto_theme.dart — VETO 2026 Design System
//  Light · Navy / Gold / Paper · Frank Ruhl Libre + Heebo
//  Aligns with repo-root `2026/_veto-2026.css` + Flutter tokens in veto_2026.dart
// ============================================================

import 'package:flutter/material.dart';

import 'veto_2026.dart';

// ── 2026 palette (exposed via the legacy VetoColors API) ──
class VetoColors {
  VetoColors._();

  // ── Background layers ─────────────────────────────────
  static const Color background    = V26.paper;
  static const Color surface       = V26.surface;
  static const Color surfaceHigh   = V26.paper2;
  static const Color surfaceGlass  = V26.surface;

  static const Color surfaceMint     = Color(0x14264975);
  static const Color surfaceSky      = Color(0x142E69E7);
  static const Color surfaceLavender = Color(0x14B8895C);

  // ── Brand: Navy primary ───────────────────────────────
  static const Color accent        = V26.navy600;
  static const Color accentDark    = V26.navy800;
  static const Color accentGlow    = Color(0x40264975);

  static const Color accentSky     = V26.navy500;
  static const Color accentViolet  = V26.gold;
  static const Color accentCoral   = V26.emerg;
  static const Color accentTeal    = V26.navy400;

  // ── Gold accent (2026) ────────────────────────────────
  static const Color goldLight     = V26.gold;
  static const Color goldDim       = V26.goldDeep;
  static const Color goldSoft      = V26.goldSoft;

  // ── Emergency red ─────────────────────────────────────
  static const Color vetoRed       = V26.emerg;
  static const Color vetoRedDeep   = V26.emerg2;
  static const Color vetoRedGlow   = Color(0x55D6243A);
  static const Color vetoRedSoft   = V26.emergBg;

  // ── Text — ink ladder on light paper ──────────────────
  static const Color white         = Color(0xFFFFFFFF);
  static const Color inkDark       = V26.ink900;
  static const Color inkMedium     = V26.ink700;
  static const Color inkLight      = V26.ink500;
  static const Color inkFaint      = V26.ink300;
  static const Color silver        = V26.ink500;
  static const Color silverLight   = V26.ink300;
  static const Color silverDim     = V26.ink200;
  static const Color textMuted     = V26.ink500;

  // ── Status ────────────────────────────────────────────
  static const Color success       = V26.ok;
  static const Color warning       = V26.warn;
  static const Color error         = V26.emerg;
  static const Color online        = V26.ok;

  // ── Border / divider ──────────────────────────────────
  static const Color border        = V26.hairline;
  static const Color borderLight   = V26.paper2;
  static const Color divider       = V26.hairline;
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
  static const Color cyan          = Color(0xFF2DD4BF);
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
  static const Color text          = VetoColors.inkDark;
  static const Color silver        = VetoColors.silver;
  static const Color textMuted     = VetoColors.textMuted;
  static const Color textSubtle    = VetoColors.inkFaint;

  static const Color border        = VetoColors.border;
  static const Color darkBorder    = VetoColors.borderLight;
}

class VetoTheme {
  VetoTheme._();

  /// 2026 light luxury theme — Navy / Gold / Paper with serif headlines.
  static ThemeData luxury2026() => luxuryLight();

  static ThemeData luxuryLight() {
    const ink = VetoColors.inkDark;
    const paper = VetoColors.background;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paper,
      primaryIconTheme: const IconThemeData(color: ink, size: 22),
      iconTheme: const IconThemeData(color: ink, size: 22),
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: VetoColors.accent,       // Navy 600
        onPrimary: Colors.white,
        secondary: V26.gold,
        onSecondary: Colors.white,
        tertiary: V26.navy500,
        onTertiary: Colors.white,
        surface: VetoColors.surface,
        onSurface: ink,
        error: VetoColors.error,
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: V26.surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(color: V26.hairline, width: 1),
        ),
        titleTextStyle: TextStyle(
          fontFamily: V26.serif,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: ink,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: V26.ink700),
      ),

      textTheme: const TextTheme(
        // Headlines: Frank Ruhl Libre (serif)
        displayLarge:   TextStyle(fontFamily: V26.serif, fontSize: 57, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.8, height: 1.05),
        displayMedium:  TextStyle(fontFamily: V26.serif, fontSize: 45, fontWeight: FontWeight.w700, color: ink, height: 1.1),
        displaySmall:   TextStyle(fontFamily: V26.serif, fontSize: 36, fontWeight: FontWeight.w700, color: ink, height: 1.15),
        headlineLarge:  TextStyle(fontFamily: V26.serif, fontSize: 32, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.3, height: 1.15),
        headlineMedium: TextStyle(fontFamily: V26.serif, fontSize: 26, fontWeight: FontWeight.w700, color: ink, height: 1.2),
        headlineSmall:  TextStyle(fontFamily: V26.serif, fontSize: 22, fontWeight: FontWeight.w700, color: ink, height: 1.2),
        titleLarge:     TextStyle(fontFamily: V26.serif, fontSize: 20, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.2, height: 1.25),
        // Body + labels: Heebo
        titleMedium:    TextStyle(fontFamily: V26.sans, fontSize: 15, fontWeight: FontWeight.w700, color: ink),
        titleSmall:     TextStyle(fontFamily: V26.sans, fontSize: 13, fontWeight: FontWeight.w700, color: V26.ink700),
        bodyLarge:      TextStyle(fontFamily: V26.sans, fontSize: 15, fontWeight: FontWeight.w500, color: ink, height: 1.5),
        bodyMedium:     TextStyle(fontFamily: V26.sans, fontSize: 13.5, fontWeight: FontWeight.w500, color: V26.ink700, height: 1.55),
        bodySmall:      TextStyle(fontFamily: V26.sans, fontSize: 12, fontWeight: FontWeight.w500, color: V26.ink500, height: 1.5),
        labelLarge:     TextStyle(fontFamily: V26.sans, fontSize: 13, fontWeight: FontWeight.w700, color: ink, letterSpacing: 0.2),
        labelMedium:    TextStyle(fontFamily: V26.sans, fontSize: 12, fontWeight: FontWeight.w700, color: V26.ink700),
        labelSmall:     TextStyle(fontFamily: V26.sans, fontSize: 11, fontWeight: FontWeight.w700, color: V26.ink500, letterSpacing: 1.5),
      ),

      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: VetoColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.inkFaint, fontSize: 14),
        labelStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.inkLight, fontSize: 14),
        floatingLabelStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.accent, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VetoColors.border, width: 1),
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
          foregroundColor: Colors.white,
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
          foregroundColor: Colors.white,
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
          foregroundColor: VetoColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(48, 40),
          iconSize: 22,
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: VetoColors.inkDark,
          iconSize: 22,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.all(10),
        ),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: VetoColors.border, width: 1),
        ),
        titleTextStyle: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w700, color: VetoColors.inkDark),
        contentTextStyle: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: VetoColors.inkLight),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        modalBarrierColor: Color(0x44000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A2340),
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(color: VetoColors.divider, thickness: 1, space: 1),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xEEFFFFFF),
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: VetoColors.accent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w700, color: VetoColors.inkDark),
        ),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? VetoColors.accent : VetoColors.inkLight,
            size: 24,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEF2FF),
        selectedColor: VetoColors.accent.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.inkMedium, fontSize: 13),
        side: const BorderSide(color: VetoColors.border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? VetoColors.accent : const Color(0xFFCDD5E0)),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? VetoColors.accentGlow : const Color(0xFFE8EDF8)),
      ),

      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: VetoColors.inkDark,
        iconColor: VetoColors.accent,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  /// Legacy `glassDark()` API — now returns the 2026 light theme.
  /// Every screen/test that referenced this function automatically picks
  /// up the Navy/Gold/Paper system.
  static ThemeData glassDark() => luxuryLight();

  /// Legacy private path kept only to preserve imports; no longer used.
  // ignore: unused_element
  static ThemeData _legacyGlassDark() {
    const on = V26.ink900;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: V26.paper,
      primaryIconTheme: const IconThemeData(color: on, size: 24),
      iconTheme: const IconThemeData(color: on, size: 24),
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: V26.navy600,
        onPrimary: Colors.white,
        secondary: V26.navy500,
        onSecondary: Colors.white,
        tertiary: V26.gold,
        onTertiary: Colors.white,
        surface: V26.surface,
        onSurface: V26.ink900,
        error: Color(0xFFF87171),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0x18FFFFFF),
        foregroundColor: on,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: on,
          letterSpacing: 0.4,
        ),
        iconTheme: IconThemeData(color: on),
      ),
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontFamily: 'Heebo', fontSize: 57, fontWeight: FontWeight.w700, color: on, letterSpacing: -0.5),
        displayMedium:  TextStyle(fontFamily: 'Heebo', fontSize: 45, fontWeight: FontWeight.w700, color: on),
        displaySmall:   TextStyle(fontFamily: 'Heebo', fontSize: 36, fontWeight: FontWeight.w600, color: on),
        headlineLarge:  TextStyle(fontFamily: 'Heebo', fontSize: 32, fontWeight: FontWeight.w800, color: on, letterSpacing: 0.3),
        headlineMedium: TextStyle(fontFamily: 'Heebo', fontSize: 28, fontWeight: FontWeight.w600, color: on),
        headlineSmall:  TextStyle(fontFamily: 'Heebo', fontSize: 24, fontWeight: FontWeight.w600, color: on),
        titleLarge:     TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w600, color: on, letterSpacing: 0.2),
        titleMedium:    TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w500, color: on),
        titleSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
        bodyLarge:      TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w500, color: on, height: 1.35),
        bodyMedium:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFE2E8F0), height: 1.4),
        bodySmall:      TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8), height: 1.35),
        labelLarge:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w700, color: on, letterSpacing: 0.6),
        labelMedium:    TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
        labelSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
      ),
      cardTheme: CardThemeData(
        color: V26.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x18FFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(fontFamily: 'Heebo', color: Color(0xFF64748B), fontSize: 14),
        labelStyle: const TextStyle(fontFamily: 'Heebo', color: Color(0xFF94A3B8), fontSize: 14),
        floatingLabelStyle: const TextStyle(fontFamily: 'Heebo', color: V26.navy600, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: V26.navy600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: V26.navy700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF334155),
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: V26.navy600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: on,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: V26.navy600,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: on,
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.all(8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: V26.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.16), width: 1),
        ),
        titleTextStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w800, color: on),
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14, color: Color(0xFFCBD5E1)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: V26.surface,
        modalBarrierColor: Colors.black.withValues(alpha: 0.55),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: V26.surface,
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', color: on, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08), thickness: 1),
      popupMenuTheme: const PopupMenuThemeData(
        color: V26.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(fontFamily: 'Heebo', color: V26.ink900, fontSize: 14),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(V26.surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0x18FFFFFF),
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: V26.navy600.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1)),
        ),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? V26.navy600 : const Color(0xFF64748B),
            size: 24,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? V26.navy600 : const Color(0xFF475569)),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? V26.navy600.withValues(alpha: 0.35) : const Color(0xFF1E293B)),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: on,
        iconColor: V26.navy600,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final p in TargetPlatform.values) p: const ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData dark() => glassDark();
}

// ── Decoration Helpers ──────────────────────────────────────

class VetoDecorations {
  VetoDecorations._();

  /// Light glass card — white semi-transparent with light border and soft shadow
  static BoxDecoration glassCard({double radius = 16, double opacity = 0.88}) =>
      BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: VetoColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: VetoColors.accent.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration surfaceCard({double radius = 16}) => BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE2E8F8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration goldCard({double radius = 12}) => BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: VetoColors.accent.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: VetoColors.accent.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      );

  /// Light background — slate paper
  static BoxDecoration gradientBg() => const BoxDecoration(
        color: VetoColors.background,
      );

  static BoxDecoration legalHeaderBg() => BoxDecoration(
        color: const Color(0xEEFFFFFF),
        border: Border(
          bottom: BorderSide(
            color: VetoColors.accent.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      );

  /// Red SOS glow — bright red on white background
  static List<BoxShadow> vetoGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: const Color(0xFFFF3B3B).withValues(alpha: 0.45 * intensity),
          blurRadius: 40 * intensity,
          spreadRadius: 4 * intensity,
        ),
        BoxShadow(
          color: const Color(0xFFFF3B3B).withValues(alpha: 0.20 * intensity),
          blurRadius: 80 * intensity,
          spreadRadius: 12 * intensity,
        ),
      ];

  static List<BoxShadow> accentGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: VetoColors.accent.withValues(alpha: 0.35 * intensity),
          blurRadius: 24 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  static List<BoxShadow> goldGlow({double intensity = 1.0}) => [
        BoxShadow(
          color: VetoColors.accent.withValues(alpha: 0.15 * intensity),
          blurRadius: 22 * intensity,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: VetoColors.accentSky.withValues(alpha: 0.10 * intensity),
          blurRadius: 40 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  /// 2026 Light 3D panel with deep soft shadows and smooth curves
  static BoxDecoration light3DPanel({double radius = 24, Color? color}) =>
      BoxDecoration(
        color: color ?? const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x33B4C6E4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1A30).withValues(alpha: 0.05),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF90A4AE).withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// 2026 3D SOS Orb with rich gradients and volumetric shadows
  static BoxDecoration light3DOrb({bool active = false}) => BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? [const Color(0xFFFF6B6B), const Color(0xFFFF3B3B), const Color(0xFFB91C1C)]
              : [const Color(0xFFFF9494), const Color(0xFFFF4D4D), const Color(0xFFD92D2D)],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B3B).withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 16),
          ),
        ],
      );
}
