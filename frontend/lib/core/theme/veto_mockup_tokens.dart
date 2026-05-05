// ============================================================
//  veto_mockup_tokens.dart — Mockup-driven light luxury tokens
//  See docs/DESIGN_SYSTEM_MOCKUP.md
// ============================================================

import 'package:flutter/material.dart';

abstract final class VetoMockup {
  static const Color pageBackground = Color(0xFFF7F5F0);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color primaryCta = Color(0xFFB91C3C);
  static const Color primaryCtaDeep = Color(0xFF7A1E2E);
  static const Color primaryCtaDark = Color(0xFF8C1530);
  static const Color inkMuted = Color(0xFF6B7280);
  static const Color emerg = Color(0xFFD6243A);
  static const Color ok = Color(0xFF2E7D32);
  static const Color warn = Color(0xFFB87514);
  static const Color softCard = Color(0xFFF8F4F1);
  static const Color hairline = Color(0xFFE8E4DC);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkSecondary = Color(0xFF4A5568);
  static const Color metricBlue = Color(0xFF2563EB);
  static const Color metricPurple = Color(0xFF7C3AED);
  static const double radiusCard = 18;
  static const double radiusPill = 999;
  static const double radiusButton = 14;

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ];
}
