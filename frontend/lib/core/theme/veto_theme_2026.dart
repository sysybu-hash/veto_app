// ============================================================
//  VETO · Theme 2026 (luxuryLight)
//  Replaces VetoTheme.luxuryLight() — pixel-aligned with the HTML mockups.
//  Reference: design_mockups/2026/_veto-2026.css
// ============================================================
import 'package:flutter/material.dart';

import 'veto_tokens_2026.dart';

class VetoTheme2026 {
  VetoTheme2026._();

  /// Build the canonical light theme. Intended to replace
  /// `VetoTheme.luxuryLight()` for new code. Legacy themes are kept for
  /// backwards-compat during migration.
  static ThemeData luxuryLight() {
    const ink = VetoTokens.ink900;
    const paper = VetoTokens.paper;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      iconTheme: const IconThemeData(color: ink, size: 22),
      primaryIconTheme: const IconThemeData(color: ink, size: 22),

      colorScheme: const ColorScheme.light(
        primary: VetoTokens.navy600,
        onPrimary: Colors.white,
        secondary: VetoTokens.navy500,
        onSecondary: Colors.white,
        tertiary: VetoTokens.gold,
        onTertiary: Colors.white,
        surface: VetoTokens.surface,
        onSurface: ink,
        error: VetoTokens.emerg,
        onError: Colors.white,
        outline: VetoTokens.hairline,
        outlineVariant: VetoTokens.hairline2,
      ),

      // ── App bar (white, hairline bottom) ──────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        toolbarHeight: 56,
        shape: Border(
          bottom: BorderSide(color: VetoTokens.hairline, width: 1),
        ),
        iconTheme: IconThemeData(color: ink, size: 22),
        actionsIconTheme: IconThemeData(color: ink, size: 22),
      ),

      // ── Typography ────────────────────────────────────
      // We define textTheme through the tokens so every TextStyle in the app
      // automatically picks up the right font/size/weight/colour.
      textTheme: TextTheme(
        displayLarge:   VetoTokens.displayLg,
        displayMedium:  VetoTokens.displayMd,
        displaySmall:   VetoTokens.displaySm,
        headlineLarge:  VetoTokens.headlineLg,
        headlineMedium: VetoTokens.headlineMd,
        headlineSmall:  VetoTokens.headlineSm,
        titleLarge:     VetoTokens.titleLg,
        titleMedium:    VetoTokens.titleMd,
        titleSmall:     VetoTokens.titleSm,
        bodyLarge:      VetoTokens.bodyLg,
        bodyMedium:     VetoTokens.bodyMd,
        bodySmall:      VetoTokens.bodySm,
        labelLarge:     VetoTokens.labelLg,
        labelMedium:    VetoTokens.labelMd,
        labelSmall:     VetoTokens.bodyXs,
      ),

      // ── Cards ─────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: VetoTokens.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(VetoTokens.rLg)),
          side: BorderSide(color: VetoTokens.hairline, width: 1),
        ),
      ),

      // ── Inputs ────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink300),
        labelStyle: VetoTokens.titleSm.copyWith(color: VetoTokens.ink700),
        floatingLabelStyle: VetoTokens.bodyXs.copyWith(color: VetoTokens.navy600),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VetoTokens.hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VetoTokens.navy500, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VetoTokens.emerg, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VetoTokens.emerg, width: 1.5),
        ),
      ),

      // ── Buttons (regular = 38px / lg = 48px / sm = 32px) ─
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VetoTokens.navy600,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(0, 38),
          iconSize: 16,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: VetoTokens.labelMd,
        ).copyWith(
          // Brand shadow lives on a separate Container in mockups, but ElevatedButton
          // can render a custom shadow via the overlay. We keep elevation at 0 and
          // paint the shadow at call-site via VetoButton helpers (see widgets).
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VetoTokens.navy600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(0, 38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: VetoTokens.labelMd,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VetoTokens.navy600,
          side: const BorderSide(color: VetoTokens.navy300, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(0, 38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: VetoTokens.labelMd,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VetoTokens.navy600,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          minimumSize: const Size(0, 36),
          textStyle: VetoTokens.labelMd,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: VetoTokens.ink700,
          backgroundColor: Colors.white,
          minimumSize: const Size(38, 38),
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: VetoTokens.hairline, width: 1),
          ),
          iconSize: 16,
        ),
      ),

      // ── Dialogs ───────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(VetoTokens.rXl)),
          side: BorderSide(color: VetoTokens.hairline, width: 1),
        ),
        titleTextStyle: VetoTokens.titleLg,
        contentTextStyle: VetoTokens.bodyMd,
      ),

      // ── Bottom sheet ──────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBarrierColor: Color(0x66000000),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(VetoTokens.r2Xl)),
        ),
      ),

      // ── Snackbar ──────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VetoTokens.ink900,
        contentTextStyle: VetoTokens.bodyMd.copyWith(color: Colors.white),
        actionTextColor: VetoTokens.navy300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rMd)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ───────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: VetoTokens.hairline,
        thickness: 1,
        space: 1,
      ),

      // ── Bottom navigation (4 tabs · 72px height) ──────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 72,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => VetoTokens.bodyXs.copyWith(
            fontWeight: FontWeight.w700,
            color: s.contains(WidgetState.selected) ? VetoTokens.navy600 : VetoTokens.ink300,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 20,
            color: s.contains(WidgetState.selected) ? VetoTokens.navy600 : VetoTokens.ink300,
          ),
        ),
      ),

      // ── Chip ──────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: VetoTokens.paper2,
        selectedColor: VetoTokens.navy600,
        labelStyle: VetoTokens.labelMd.copyWith(color: VetoTokens.ink700),
        secondaryLabelStyle: VetoTokens.labelMd.copyWith(color: Colors.white),
        side: const BorderSide(color: VetoTokens.hairline, width: 1),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Switch (mockup is custom-painted, but Material default is fine) ─
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? VetoTokens.ok : VetoTokens.ink200,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── List tile ─────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: VetoTokens.ink900,
        iconColor: VetoTokens.ink700,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: VetoTokens.ink900,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: VetoTokens.ink500,
        ),
      ),

      // ── Tab bar ───────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: VetoTokens.navy600,
        unselectedLabelColor: VetoTokens.ink500,
        labelStyle: VetoTokens.labelMd,
        unselectedLabelStyle: VetoTokens.labelMd,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: VetoTokens.navy500, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // ── Tooltip ───────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: VetoTokens.ink900,
          borderRadius: BorderRadius.circular(VetoTokens.rSm),
        ),
        textStyle: VetoTokens.bodyXs.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Page transitions ──────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android:  FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:      CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS:    CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux:    FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows:  FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia:  FadeForwardsPageTransitionsBuilder(),
        },
      ),

      visualDensity: VisualDensity.standard,
    );
  }
}
