// ============================================================
//  v26_call_stage.dart — Dark full-bleed scaffold used by every
//  call state (incoming, connecting, voice, video). Mirrors the
//  VETO Bold navy/gold call mockups.
// ============================================================

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';

/// Scaffold with the 2026 dark navy gradient. Children fill it top-to-bottom.
class V26CallStage extends StatelessWidget {
  const V26CallStage({
    super.key,
    required this.child,
    this.textDirection,
  });

  final Widget child;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final body = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [V26.callBgTop, V26.callBgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
              child: CustomPaint(painter: _V26CallNoisePainter())),
          child,
        ],
      ),
    );
    final withDir = textDirection == null
        ? body
        : Directionality(textDirection: textDirection!, child: body);
    return Scaffold(
      backgroundColor: V26.callBgBottom,
      body: withDir,
    );
  }
}

class _V26CallNoisePainter extends CustomPainter {
  const _V26CallNoisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()..color = V26.gold.withValues(alpha: 0.035);
    final navy = Paint()..color = Colors.white.withValues(alpha: 0.015);
    for (var i = 0; i < 72; i++) {
      final x = ((i * 37) % 101) / 100 * size.width;
      final y = ((i * 61) % 103) / 100 * size.height;
      canvas.drawCircle(
          Offset(x, y), i.isEven ? 0.65 : 0.45, i.isEven ? gold : navy);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "VETO" shield pill (reused by the top bar).
class V26CallShieldBadge extends StatelessWidget {
  const V26CallShieldBadge({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(V26.rSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: V26.gold, size: compact ? 18 : 22),
          const SizedBox(width: 5),
          Text(
            'VETO',
            style: TextStyle(
              fontFamily: V26.serif,
              fontSize: compact ? 16 : 22,
              fontWeight: FontWeight.w800,
              color: V26.gold,
              letterSpacing: compact ? 1.6 : 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

class V26CallGlassPanel extends StatelessWidget {
  const V26CallGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = V26.callRadiusPanel,
    this.borderColor = V26.callGoldHair,
    this.backgroundColor = V26.callGlass,
    this.blurSigma = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color borderColor;
  final Color backgroundColor;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small pill used by top-bar overlays (timer, REC, quality chip).
class V26CallPill extends StatelessWidget {
  const V26CallPill({
    super.key,
    required this.child,
    this.background,
    this.border,
  });
  final Widget child;
  final Color? background;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? V26.navy900.withValues(alpha: 0.72);
    final bd = border ?? Colors.white.withValues(alpha: 0.16);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(V26.rPill),
        border: Border.all(color: bd),
      ),
      child: child,
    );
  }
}
