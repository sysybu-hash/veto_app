// Splash-stage widgets — pixel-aligned with `2026/splash.html` + gradients.

import 'package:flutter/material.dart';

import 'veto_2026.dart';

/// Full-screen splash background: dual radial glows on [V26.paper] (light variant).
class V26SplashStage extends StatelessWidget {
  final Widget child;
  final bool dark;

  const V26SplashStage({
    super.key,
    required this.child,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return ColoredBox(
        color: V26.ink900,
        child: CustomPaint(
          painter: _SplashDarkPainter(),
          child: child,
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: V26.paper),
        CustomPaint(painter: _SplashLightPainter(), child: child),
      ],
    );
  }
}

class _SplashLightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _rad(
      canvas,
      Offset(w * 0.5, h * 0.30),
      450,
      const Color(0xFFE8F0FB),
      0.65,
    );
    _rad(
      canvas,
      Offset(w * 0.5, h * 0.90),
      350,
      const Color(0xFFF0E9DE),
      0.60,
    );
  }

  void _rad(Canvas canvas, Offset c, double r, Color rgb, double fadeStop) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          rgb.withValues(alpha: 1),
          rgb.withValues(alpha: 0),
        ],
        stops: [0, fadeStop],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashDarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _rad(canvas, Offset(w * 0.5, h * 0.30), 450,
        const Color(0xFF2E69E7).withValues(alpha: 0.18), 0.60);
    _rad(canvas, Offset(w * 0.5, h * 0.80), 400,
        Colors.black.withValues(alpha: 0.40), 0.60);
  }

  void _rad(Canvas canvas, Offset c, double r, Color col, double fadeStop) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [col, col.withValues(alpha: 0)],
        stops: [0, fadeStop],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Crest 120×120 · r30 · “V” 64px — matches `.crest-xl` (light gradient).
class V26SplashCrest extends StatelessWidget {
  final bool dark;
  const V26SplashCrest({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final gradient = dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E69E7), Color(0xFF5B8BF0)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [V26.navy700, V26.navy500],
          );
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: dark
            ? const [
                BoxShadow(
                  color: Color(0x732E69E7),
                  blurRadius: 64,
                  offset: Offset(0, 24),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x4D264975),
                  blurRadius: 50,
                  offset: Offset(0, 20),
                ),
              ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'V',
        style: TextStyle(
          fontFamily: V26.serif,
          fontWeight: FontWeight.w900,
          fontSize: 64,
          color: Colors.white,
          letterSpacing: 2.4,
          height: 1,
        ),
      ),
    );
  }
}

/// Three dots — same timing as `splash.html` @keyframes `sp` (1.2s, stagger 0.2s).
class V26SplashDots extends StatefulWidget {
  final bool dark;
  const V26SplashDots({super.key, this.dark = false});

  @override
  State<V26SplashDots> createState() => _V26SplashDotsState();
}

class _V26SplashDotsState extends State<V26SplashDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// CSS: peak opacity at 40%, low at 0/80/100%; translateY -4px at peak.
  double _opacity(double phase) {
    final t = (_c.value + phase) % 1.0;
    double o;
    if (t < 0.40) {
      o = 0.25 + 0.75 * (t / 0.40);
    } else if (t < 0.80) {
      o = 1.0 - 0.75 * ((t - 0.40) / 0.40);
    } else {
      o = 0.25;
    }
    return o.clamp(0.25, 1.0);
  }

  double _dy(double phase) {
    final t = (_c.value + phase) % 1.0;
    if (t < 0.40) {
      return -4 * (t / 0.40);
    }
    if (t < 0.80) {
      return -4 * (1 - (t - 0.40) / 0.40);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.dark ? const Color(0xFF5B8BF0) : V26.navy500;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = i * (0.2 / 1.2);
            return Padding(
              padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 6),
              child: Transform.translate(
                offset: Offset(0, _dy(phase)),
                child: Opacity(
                  opacity: _opacity(phase),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Mini SOS orb + caption — matches `.mini-orb` / `.mini-stat` in `2026/landing.html`.
class V26LandingMiniDevice extends StatelessWidget {
  final String sosLabel;
  final Widget caption;
  const V26LandingMiniDevice({
    super.key,
    this.sosLabel = 'SOS',
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.maxWidth * 0.78;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _MiniGlowPainter(),
                  ),
                ),
              ),
              SizedBox(
                width: side,
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: V26.ink900,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x381B1830),
                          blurRadius: 80,
                          offset: Offset(0, 30),
                        ),
                        BoxShadow(
                          color: Color(0x1A1B1830),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: V26.paper,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MiniOrb(label: sosLabel),
                          const SizedBox(height: 14),
                          DefaultTextStyle.merge(
                            style: const TextStyle(
                              fontFamily: V26.sans,
                              fontSize: 11,
                              color: V26.ink500,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            child: caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.42;
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x1A2E69E7),
          Colors.transparent,
        ],
        stops: [0, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniOrb extends StatelessWidget {
  final String label;
  const _MiniOrb({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.35),
          radius: 1.2,
          colors: [
            Color(0xFFFF8492),
            Color(0xFFE5354C),
            Color(0xFFB81B30),
          ],
          stops: [0, 0.38, 0.78],
        ),
        boxShadow: [
          ...V26.shadowEmerg,
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.5),
                    radius: 0.65,
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, 2),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: V26.serif,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 5.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
