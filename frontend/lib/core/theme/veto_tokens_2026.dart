// ============================================================
//  VETO · Design Tokens 2026
//  Source of truth — matches design_mockups/2026/_veto-2026.css 1:1.
//  Do NOT modify colors/sizes here without updating the CSS first.
// ============================================================
//
// Usage:
//   import 'package:veto/core/theme/veto_tokens_2026.dart';
//   color: VetoTokens.navy600
//   borderRadius: BorderRadius.circular(VetoTokens.rLg)
//   boxShadow: VetoTokens.shadow1
//   style: VetoTokens.serif(28, FontWeight.w700)
//
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VetoTokens {
  VetoTokens._();

  // ─── Brand · Navy ladder ───────────────────────────────
  static const Color navy900 = Color(0xFF0E1F37);
  static const Color navy800 = Color(0xFF13284A);
  static const Color navy700 = Color(0xFF1B3A66);
  /// Primary brand colour (Pango-inspired).
  static const Color navy600 = Color(0xFF264975);
  static const Color navy500 = Color(0xFF2E69E7);
  static const Color navy400 = Color(0xFF5B8BF0);
  static const Color navy300 = Color(0xFF83B7F8);
  static const Color navy200 = Color(0xFFB6D2FB);
  static const Color navy100 = Color(0xFFD4F1F7);

  // ─── Accent · Gold (sparing — ≤ 3 occurrences per screen) ─
  static const Color gold      = Color(0xFFB8895C);
  static const Color goldSoft  = Color(0xFFE9D9C2);
  static const Color goldDeep  = Color(0xFF8C6235);

  // ─── Surfaces ──────────────────────────────────────────
  static const Color paper     = Color(0xFFF6F8FB);
  static const Color paper2    = Color(0xFFEEF2F8);
  static const Color paper3    = Color(0xFFE5EBF4);
  static const Color surface   = Color(0xFFFFFFFF);
  static const Color surface2  = Color(0xFFFBFCFE);

  // ─── Lines ─────────────────────────────────────────────
  static const Color hairline       = Color(0xFFE2E8F0);
  static const Color hairline2      = Color(0xFFCBD5E1);
  static const Color hairlineStrong = Color(0xFF94A3B8);

  // ─── Ink (text) ────────────────────────────────────────
  static const Color ink900 = Color(0xFF0B1830);
  static const Color ink800 = Color(0xFF162646);
  static const Color ink700 = Color(0xFF27374D);
  static const Color ink500 = Color(0xFF4A5A75);
  static const Color ink300 = Color(0xFF7A8AA5);
  static const Color ink200 = Color(0xFFA6B3C8);

  // ─── Status ────────────────────────────────────────────
  static const Color emerg       = Color(0xFFD6243A);
  static const Color emerg2      = Color(0xFFB81B30);
  static const Color emergSoft   = Color(0xFFFBE7EA);
  static const Color emergBg     = Color(0xFFFFF5F1);
  static const Color emergBorder = Color(0xFFF8D6CB);
  static const Color ok          = Color(0xFF2BA374);
  static const Color okSoft      = Color(0xFFDDF2E9);
  static const Color warn        = Color(0xFFC58B12);
  static const Color warnSoft    = Color(0xFFFBEFD3);
  static const Color info        = Color(0xFF2E69E7); // = navy500
  static const Color infoSoft    = Color(0xFFDCE7FB);

  // ─── Spacing ───────────────────────────────────────────
  static const double s1  = 4;
  static const double s2  = 8;
  static const double s3  = 12;
  static const double s4  = 16;
  static const double s5  = 20;
  static const double s6  = 24;
  static const double s8  = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  // ─── Radius ────────────────────────────────────────────
  static const double rXs   = 6;
  static const double rSm   = 8;
  static const double rMd   = 12;
  static const double rLg   = 16;
  static const double rXl   = 22;
  static const double r2Xl  = 28;
  static const double rPill = 999;

  // ─── Shadows ───────────────────────────────────────────
  /// Standard card shadow.
  static const List<BoxShadow> shadow1 = [
    BoxShadow(color: Color(0x0A0B1830), blurRadius: 2,  offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0B1830), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Hero / modal shadow.
  static const List<BoxShadow> shadow2 = [
    BoxShadow(color: Color(0x0D0B1830), blurRadius: 4,  offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A0B1830), blurRadius: 48, offset: Offset(0, 18)),
  ];

  /// Dropdown / popup shadow.
  static const List<BoxShadow> shadow3 = [
    BoxShadow(color: Color(0x0F0B1830), blurRadius: 8,  offset: Offset(0, 4)),
    BoxShadow(color: Color(0x240B1830), blurRadius: 72, offset: Offset(0, 28)),
  ];

  /// SOS orb only.
  static const List<BoxShadow> shadowEmerg = [
    BoxShadow(color: Color(0x47D6243A), blurRadius: 40, offset: Offset(0, 12)),
  ];

  /// Primary CTA.
  static const List<BoxShadow> shadowBrand = [
    BoxShadow(color: Color(0x4D264975), blurRadius: 16, offset: Offset(0, 6)),
  ];

  // ─── Motion ────────────────────────────────────────────
  static const Curve ease = Cubic(.4, 0, .2, 1);
  static const Duration durFast   = Duration(milliseconds: 120);
  static const Duration durBase   = Duration(milliseconds: 200);
  static const Duration durMedium = Duration(milliseconds: 300);
  static const Duration durSlow   = Duration(milliseconds: 500);
  static const Duration pulseRing = Duration(milliseconds: 3200);

  // ─── Typography ────────────────────────────────────────
  // Frank Ruhl Libre (serif, Hebrew-aware) loaded via google_fonts.
  // Heebo loaded as native asset via pubspec (kept from legacy).

  /// Serif headline. Use for h1-h4 and display text.
  /// Falls back to Times New Roman / Georgia.
  static TextStyle serif(double size, FontWeight weight, {
    Color color = ink900,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.frankRuhlLibre(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Sans body. Use for everything that isn't a heading.
  static TextStyle sans(double size, FontWeight weight, {
    Color color = ink900,
    double height = 1.5,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: 'Heebo',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ─── Standard text styles (mockup-aligned) ─────────────
  static TextStyle get displayLg  => serif(57, FontWeight.w700, height: 1.05, letterSpacing: -0.5);
  static TextStyle get displayMd  => serif(45, FontWeight.w700, height: 1.10, letterSpacing: -0.3);
  static TextStyle get displaySm  => serif(36, FontWeight.w600, height: 1.15, letterSpacing: -0.2);
  static TextStyle get headlineLg => serif(32, FontWeight.w800, height: 1.20, letterSpacing:  0.2);
  static TextStyle get headlineMd => serif(28, FontWeight.w700, height: 1.25);
  static TextStyle get headlineSm => serif(24, FontWeight.w700, height: 1.30);
  static TextStyle get titleLg    => serif(20, FontWeight.w700, height: 1.30, letterSpacing: 0.2);
  static TextStyle get titleMd    => sans (16, FontWeight.w600, height: 1.40);
  static TextStyle get titleSm    => sans (14, FontWeight.w600, height: 1.40);
  static TextStyle get bodyLg     => sans (16, FontWeight.w500, height: 1.65, color: ink500);
  static TextStyle get bodyMd     => sans (14, FontWeight.w500, height: 1.50, color: ink700);
  static TextStyle get bodySm     => sans (13, FontWeight.w500, height: 1.55, color: ink500);
  static TextStyle get bodyXs     => sans (11, FontWeight.w500, height: 1.40, color: ink500);
  static TextStyle get labelLg    => sans (14, FontWeight.w700, height: 1.20, letterSpacing: 0.6);
  static TextStyle get labelMd    => sans (13, FontWeight.w700, height: 1.20, letterSpacing: 0.4);

  /// Eyebrow / kicker — small caps style. UPPERCASE the string yourself.
  static TextStyle get kicker     => sans (11, FontWeight.w800, color: navy600, letterSpacing: 1.98); // 0.18em ≈ 1.98 at 11px

  // ─── Helper decorations ────────────────────────────────
  /// Standard card decoration (white, hairline border, radius lg, shadow1).
  static BoxDecoration cardDecoration({double radius = rLg, Color color = surface}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: hairline, width: 1),
        boxShadow: shadow1,
      );

  /// Hero / lift card (heavier shadow).
  static BoxDecoration liftCardDecoration({double radius = r2Xl}) =>
      BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: hairline, width: 1),
        boxShadow: shadow2,
      );

  /// Brand crest gradient (135deg navy-700 → navy-500).
  static LinearGradient get crestGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [navy700, navy500],
      );

  /// SOS orb radial gradient.
  static RadialGradient get sosOrbGradient => const RadialGradient(
        center: Alignment(-0.4, -0.5),
        radius: 0.85,
        colors: [Color(0xFFFF8492), Color(0xFFE5354C), Color(0xFFB81B30)],
        stops: [0.0, 0.38, 0.78],
      );

  /// Page ambient background (paper + 2 radial tints).
  /// Apply via Container(decoration: BoxDecoration(...)) wrapping Scaffold body
  /// or use directly inside CustomPaint for performance-critical surfaces.
  static BoxDecoration ambientPageDecoration() => const BoxDecoration(
        color: paper,
        gradient: RadialGradient(
          center: Alignment(0.9, -1.1),
          radius: 1.0,
          colors: [Color(0x66E8F0FB), Color(0x00E8F0FB)],
        ),
      );
}
