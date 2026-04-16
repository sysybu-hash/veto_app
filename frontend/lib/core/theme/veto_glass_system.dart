// ============================================================
//  veto_glass_system.dart — Dark glassmorphism (mockup-aligned)
//  Fluid aurora background, blur panels, neon cyan/blue accents
// ============================================================

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Design tokens for dark glass UI (LEXIGUARD / LegalAid style references).
class VetoGlassTokens {
  VetoGlassTokens._();

  static const Color bgBase = Color(0xFF06101C);
  static const Color bgDeep = Color(0xFF030A12);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);

  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonBlue = Color(0xFF007BFF);
  static const Color accentSoft = Color(0xFF38BDF8);
  static const Color violetGlow = Color(0xFF8B5CF6);

  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassFillStrong = Color(0x22FFFFFF);
  static const Color glassBorder = Color(0x28FFFFFF);
  static const Color glassBorderBright = Color(0x40FFFFFF);

  static const LinearGradient neonButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), Color(0xFF007BFF)],
  );

  static const LinearGradient specularTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x35FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.35],
  );

  static double blurSigma = 18;

  /// Frosted pill / card shell (use inside [ClipRRect]).
  static BoxDecoration glassPanel({
    double radius = 24,
    Color? fill,
    Color? borderColor,
    List<BoxShadow>? glow,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: fill ?? glassFill,
        border: Border.all(color: borderColor ?? glassBorder, width: 1),
        boxShadow: glow ??
            [
              BoxShadow(
                color: neonBlue.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
      );
}

/// Global fluid background: deep base + soft teal / sky / violet blobs.
class VetoFluidBackgroundPainter extends CustomPainter {
  const VetoFluidBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final base = Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF07182A),
        Color(0xFF06101C),
        Color(0xFF0A1E32),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), base);

    _blob(canvas, Offset(w * 0.82, h * 0.05), w * 0.48, const Color(0xFF00B4D8), 0.28);
    _blob(canvas, Offset(w * 0.12, h * 0.12), w * 0.52, const Color(0xFF4DB6AC), 0.22);
    _blob(canvas, Offset(w * 0.08, h * 0.58), w * 0.48, const Color(0xFF7C6FED), 0.18);
    _blob(canvas, Offset(w * 0.88, h * 0.72), w * 0.42, const Color(0xFF2196F3), 0.16);

    // Subtle bokeh specks
    final rnd = Paint()..color = Colors.white.withValues(alpha: 0.04);
    for (var i = 0; i < 28; i++) {
      final x = (i * 97.0 + w * 0.03) % w;
      final y = (i * 53.0 + h * 0.11) % h;
      canvas.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.6, rnd);
    }
  }

  void _blob(Canvas canvas, Offset center, double radius, Color color, double alpha) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full-screen fluid aurora behind your content (matches app-wide glass shell).
class VetoGlassAuroraBackground extends StatelessWidget {
  final Widget child;

  const VetoGlassAuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: VetoFluidBackgroundPainter()),
        ),
        child,
      ],
    );
  }
}

/// Clip + backdrop blur + optional gradient rim.
class VetoGlassBlur extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double sigma;
  final Color? fill;
  final Color? borderColor;

  const VetoGlassBlur({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.sigma = 18,
    this.fill,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill ?? VetoGlassTokens.glassFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? VetoGlassTokens.glassBorder,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
