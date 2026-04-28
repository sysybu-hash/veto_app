// ============================================================
//  veto_glass_system.dart — Dark glassmorphism (VETO v4)
//  Deep ink base, mint–indigo aurora, frosted panels
// ============================================================

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Design tokens for dark glass UI — single source for screens + painters.
class VetoGlassTokens {
  VetoGlassTokens._();

  static const Color bgBase = Color(0xFF0A0E17);
  static const Color bgDeep = Color(0xFF05070D);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);

  /// Primary accent (mint–teal). Kept name [neonCyan] for stable call sites.
  static const Color neonCyan = Color(0xFF5EEAD4);
  static const Color neonBlue = Color(0xFF6366F1);
  static const Color accentSoft = Color(0xFF2DD4BF);
  static const Color violetGlow = Color(0xFFA78BFA);

  static const Color glassFill = Color(0x12FFFFFF);
  static const Color glassFillStrong = Color(0x1EFFFFFF);
  static const Color glassBorder = Color(0x24FFFFFF);
  static const Color glassBorderBright = Color(0x3AFFFFFF);

  /// Dialogs, modals, bottom sheets (aligned with glassDark theme)
  static const Color sheetPanel = Color(0xE6161F2E);
  /// [DropdownButton] / popup surfaces on dark UI
  static const Color menuPanel = Color(0xFF151B2C);
  /// Text/icons on neon / gradient buttons
  static const Color onNeon = Color(0xFF071018);

  static const LinearGradient neonButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5EEAD4), Color(0xFF6366F1)],
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
        Color(0xFF0D1526),
        Color(0xFF0A0E17),
        Color(0xFF111827),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), base);

    _blob(canvas, Offset(w * 0.82, h * 0.05), w * 0.48, const Color(0xFF2DD4BF), 0.26);
    _blob(canvas, Offset(w * 0.12, h * 0.12), w * 0.52, const Color(0xFF34D399), 0.20);
    _blob(canvas, Offset(w * 0.08, h * 0.58), w * 0.48, const Color(0xFF818CF8), 0.17);
    _blob(canvas, Offset(w * 0.88, h * 0.72), w * 0.42, const Color(0xFF6366F1), 0.14);
    _blob(canvas, Offset(w * 0.48, h * 0.88), w * 0.55, const Color(0xFFA78BFA), 0.22);
    _blob(canvas, Offset(w * 0.25, h * 0.42), w * 0.38, const Color(0xFF5EEAD4), 0.16);
    _blob(canvas, Offset(w * 0.62, h * 0.18), w * 0.32, const Color(0xFF22D3EE), 0.10);

    // Subtle bokeh specks
    final rnd = Paint()..color = Colors.white.withValues(alpha: 0.055);
    for (var i = 0; i < 40; i++) {
      final x = (i * 97.0 + w * 0.03) % w;
      final y = (i * 53.0 + h * 0.11) % h;
      canvas.drawCircle(Offset(x, y), 0.8 + (i % 4) * 0.7, rnd);
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

/// Slow-moving cyan / violet wash for presentation “aurora” depth (on top of [VetoFluidBackgroundPainter]).
class VetoAuroraMotionPainter extends CustomPainter {
  final double phase;
  const VetoAuroraMotionPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = phase * 2 * math.pi;
    final c1 = Offset(
      w * (0.52 + 0.11 * math.sin(t * 0.65)),
      h * (0.28 + 0.1 * math.cos(t * 0.48)),
    );
    final c2 = Offset(
      w * (0.18 + 0.12 * math.cos(t * 0.82)),
      h * (0.72 + 0.08 * math.sin(t * 0.55)),
    );
    _wash(canvas, c1, w * 0.62, const Color(0xFF5EEAD4), 0.09);
    _wash(canvas, c2, w * 0.48, const Color(0xFFA78BFA), 0.075);
  }

  void _wash(Canvas canvas, Offset c, double r, Color col, double a) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [col.withValues(alpha: a), col.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant VetoAuroraMotionPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// Abstract “tactical map” for lawyer dashboard: dark basemap + glowing cyan pins.
class VetoCommandMapPainter extends CustomPainter {
  const VetoCommandMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F1729),
          Color(0xFF0A0E17),
          Color(0xFF131C2E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), base);

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (var x = 0.0; x < w; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (var y = 0.0; y < h; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    // “Routes”
    final route = Paint()
      ..color = VetoGlassTokens.neonCyan.withValues(alpha: 0.10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.35, h * 0.45, w * 0.72, h * 0.55)
      ..quadraticBezierTo(w * 0.9, h * 0.62, w, h * 0.38);
    canvas.drawPath(path, route);

    void pin(Offset c) {
      final g = Paint()
        ..shader = RadialGradient(
          colors: [
            VetoGlassTokens.neonCyan.withValues(alpha: 0.45),
            VetoGlassTokens.neonCyan.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: 22));
      canvas.drawCircle(c, 22, g);
      canvas.drawCircle(
        c,
        5,
        Paint()..color = VetoGlassTokens.neonCyan,
      );
      canvas.drawCircle(
        c,
        8,
        Paint()
          ..color = VetoGlassTokens.neonCyan.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    pin(Offset(w * 0.22, h * 0.38));
    pin(Offset(w * 0.55, h * 0.52));
    pin(Offset(w * 0.78, h * 0.32));
    pin(Offset(w * 0.42, h * 0.72));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rounded “command center” map strip for the lawyer console.
class VetoCommandMapPanel extends StatelessWidget {
  final double height;
  const VetoCommandMapPanel({super.key, this.height = 170});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: const CustomPaint(painter: VetoCommandMapPainter()),
      ),
    );
  }
}

/// Full-screen fluid aurora behind your content (matches app-wide glass shell).
class VetoGlassAuroraBackground extends StatefulWidget {
  final Widget child;

  const VetoGlassAuroraBackground({super.key, required this.child});

  @override
  State<VetoGlassAuroraBackground> createState() => _VetoGlassAuroraBackgroundState();
}

class _VetoGlassAuroraBackgroundState extends State<VetoGlassAuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _aurora;

  @override
  void initState() {
    super.initState();
    _aurora = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _aurora.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: VetoFluidBackgroundPainter()),
        ),
        if (!reduceMotion && !kIsWeb)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _aurora,
                builder: (_, __) => CustomPaint(
                  painter: VetoAuroraMotionPainter(phase: _aurora.value),
                ),
              ),
            ),
          ),
        widget.child,
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
