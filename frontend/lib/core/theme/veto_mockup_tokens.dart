// ============================================================
//  veto_mockup_tokens.dart — Pango-class consumer UI (May 2026)
//  Primary blue, light surfaces, rounded UI. See docs/DESIGN_SYSTEM_MOCKUP.md
// ============================================================

import 'package:flutter/material.dart';

abstract final class VetoMockup {
  /// Off-white / cool gray page (Pango-like)
  static const Color pageBackground = Color(0xFFF4F6FA);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  /// Primary brand / CTA (reference ~#2B65EC)
  static const Color primaryCta = Color(0xFF2B65EC);
  static const Color primaryCtaDeep = Color(0xFF1E4CAD);
  static const Color primaryCtaDark = Color(0xFF153D99);
  /// Light drawer / panel tint
  static const Color drawerTint = Color(0xFFE8F1FF);
  static const Color drawerHeader = Color(0xFF0E2A5A);
  static const Color inkMuted = Color(0xFF6B7280);
  /// Emergency / destructive (unchanged semantics)
  static const Color emerg = Color(0xFFD6243A);
  static const Color ok = Color(0xFF2E7D32);
  static const Color warn = Color(0xFFB87514);
  static const Color softCard = Color(0xFFEEF2F8);
  static const Color hairline = Color(0xFFE2E8EF);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkSecondary = Color(0xFF4A5568);
  static const Color metricBlue = Color(0xFF2563EB);
  static const Color metricPurple = Color(0xFF7C3AED);
  /// Service wheel accent disks (icons on colored circles)
  static const Color wheelRed = Color(0xFFFF4D4D);
  static const Color wheelTeal = Color(0xFF40B5AD);
  static const Color wheelOrange = Color(0xFFFF9F43);
  static const Color wheelYellow = Color(0xFFFFD43B);
  static const Color wheelSky = Color(0xFF74C0FC);

  static const double radiusCard = 24;
  static const double radiusPill = 999;
  static const double radiusButton = 16;

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 28,
          offset: Offset(0, 10),
        ),
      ];

  /// Primary CTA glow (mobile hero button)
  static List<BoxShadow> get primaryGlow => const [
        BoxShadow(
          color: Color(0x552B65EC),
          blurRadius: 24,
          spreadRadius: 0,
          offset: Offset(0, 8),
        ),
      ];
}
