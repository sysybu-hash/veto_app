// ============================================================
//  veto_theme.dart — VETO Design System v4
//  Light: crisp slate paper + teal/indigo brand
//  Dark: ink base + mint/indigo glass (see VetoGlassTokens)
// ============================================================

import 'package:flutter/material.dart';

import 'veto_glass_system.dart';

// ── Light mode palette ────────────────────────────────────
class VetoColors {
  VetoColors._();

  // ── Background layers ─────────────────────────────────
  static const Color background    = Color(0xFFF8FAFC);   // slate paper
  static const Color surface       = Color(0xFFFFFFFF);   // pure white card
  static const Color surfaceHigh   = Color(0xFFF1F5F9);   // subtle lift
  static const Color surfaceGlass  = Color(0xE6FFFFFF);   // frosted white

  static const Color surfaceMint     = Color(0x142DD4BF);
  static const Color surfaceSky      = Color(0x146366F1);
  static const Color surfaceLavender = Color(0x14A78BFA);

  // ── Brand (teal + indigo) ─────────────────────────────
  static const Color accent        = Color(0xFF0D9488);   // teal-600 primary
  static const Color accentDark    = Color(0xFF0F766E);
  static const Color accentGlow    = Color(0x400D9488);

  static const Color accentSky     = Color(0xFF6366F1);   // indigo-500
  static const Color accentViolet  = Color(0xFF8B5CF6);
  static const Color accentCoral   = Color(0xFFFF6B6B);
  static const Color accentTeal    = Color(0xFF14B8A6);

  // ── Legacy "gold" names (remapped to brand teal) ─────
  static const Color goldLight     = Color(0xFF0D9488);
  static const Color goldDim       = Color(0xFF0F766E);
  static const Color goldSoft      = Color(0x1A0D9488);

  // ── Emergency red ─────────────────────────────────────
  static const Color vetoRed       = Color(0xFFFF3B3B);
  static const Color vetoRedDeep   = Color(0xFFE02020);
  static const Color vetoRedGlow   = Color(0x55FF3B3B);
  static const Color vetoRedSoft   = Color(0x15FF3B3B);

  // ── Text — dark on light ───────────────────────────────
  static const Color white         = Color(0xFFFFFFFF);
  static const Color inkDark       = Color(0xFF1A2340);   // primary text
  static const Color inkMedium     = Color(0xFF3A4A6B);   // secondary text
  static const Color inkLight      = Color(0xFF5A6A88);   // muted text
  static const Color inkFaint      = Color(0xFF8A9AB8);   // placeholder
  static const Color silver        = Color(0xFF5A6A88);   // compat alias
  static const Color silverLight   = Color(0xFF8A9AB8);
  static const Color silverDim     = Color(0xFFAABAD8);
  static const Color textMuted     = Color(0xFF5A6A88);

  // ── Status ────────────────────────────────────────────
  static const Color success       = Color(0xFF22C55E);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color error         = Color(0xFFFF3B3B);
  static const Color online        = Color(0xFF22C55E);

  // ── Border / divider ──────────────────────────────────
  static const Color border        = Color(0xFFE2E8F0);
  static const Color borderLight   = Color(0xFFF1F5F9);
  static const Color divider       = Color(0xFFE2E8F0);
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

  static ThemeData luxuryLight() {
    const ink = VetoColors.inkDark;
    const paper = VetoColors.background;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paper,
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

      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xEEFFFFFF),
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: VetoColors.accent.withValues(alpha: 0.15),
            width: 1,
          ),
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
        titleSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: VetoColors.inkMedium),
        bodyLarge:      TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w600, color: ink, height: 1.35),
        bodyMedium:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w500, color: ink, height: 1.4),
        bodySmall:      TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w500, color: VetoColors.inkLight, height: 1.35),
        labelLarge:     TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w700, color: ink, letterSpacing: 0.6),
        labelMedium:    TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600, color: VetoColors.inkMedium),
        labelSmall:     TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w600, color: VetoColors.inkLight),
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

  /// Dark glass — typography on ink base + mint/indigo accents.
  static ThemeData glassDark() {
    const on = VetoGlassTokens.textPrimary;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VetoGlassTokens.bgBase,
      primaryIconTheme: const IconThemeData(color: on, size: 24),
      iconTheme: const IconThemeData(color: on, size: 24),
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: VetoGlassTokens.neonCyan,
        onPrimary: VetoGlassTokens.onNeon,
        secondary: VetoGlassTokens.neonBlue,
        onSecondary: Colors.white,
        tertiary: VetoGlassTokens.violetGlow,
        onTertiary: VetoGlassTokens.onNeon,
        surface: VetoGlassTokens.glassFill,
        onSurface: VetoGlassTokens.textPrimary,
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
        color: VetoGlassTokens.glassFill,
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
        floatingLabelStyle: const TextStyle(fontFamily: 'Heebo', color: VetoGlassTokens.neonCyan, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VetoGlassTokens.neonCyan, width: 1.5),
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
          backgroundColor: VetoGlassTokens.accentSoft,
          foregroundColor: VetoGlassTokens.onNeon,
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
          backgroundColor: VetoGlassTokens.neonCyan,
          foregroundColor: VetoGlassTokens.onNeon,
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
          foregroundColor: VetoGlassTokens.neonCyan,
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
        backgroundColor: VetoGlassTokens.sheetPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.16), width: 1),
        ),
        titleTextStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.w800, color: on),
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14, color: Color(0xFFCBD5E1)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: VetoGlassTokens.sheetPanel,
        modalBarrierColor: Colors.black.withValues(alpha: 0.55),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VetoGlassTokens.menuPanel,
        contentTextStyle: const TextStyle(fontFamily: 'Heebo', color: on, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08), thickness: 1),
      popupMenuTheme: const PopupMenuThemeData(
        color: VetoGlassTokens.menuPanel,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(fontFamily: 'Heebo', color: VetoGlassTokens.textPrimary, fontSize: 14),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(VetoGlassTokens.menuPanel),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0x18FFFFFF),
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: VetoGlassTokens.neonCyan.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1)),
        ),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? VetoGlassTokens.neonCyan : const Color(0xFF64748B),
            size: 24,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? VetoGlassTokens.neonCyan : const Color(0xFF475569)),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? VetoGlassTokens.neonCyan.withValues(alpha: 0.35) : const Color(0xFF1E293B)),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: on,
        iconColor: VetoGlassTokens.neonCyan,
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
}
