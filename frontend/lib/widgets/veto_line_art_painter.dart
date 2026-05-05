// ============================================================
//  Subtle background line art (park / city) — Pango-class
// ============================================================

import 'package:flutter/material.dart';

import '../core/theme/veto_mockup_tokens.dart';

class VetoLineArtBackground extends StatelessWidget {
  const VetoLineArtBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _LineArtPainter()),
        ),
        child,
      ],
    );
  }
}

class _LineArtPainter extends CustomPainter {
  const _LineArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = VetoMockup.hairline.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Ground curve
    canvas.drawPath(
      Path()..quadraticBezierTo(w * 0.35, h * 0.72, w, h * 0.68),
      p,
    );

    // Trees (simple circles + trunk)
    void tree(double x, double y, double scale) {
      canvas.drawCircle(Offset(x, y), 18 * scale, p);
      canvas.drawLine(Offset(x, y + 18 * scale), Offset(x, y + 42 * scale), p);
    }

    tree(w * 0.12, h * 0.42, 1);
    tree(w * 0.22, h * 0.48, 0.85);
    tree(w * 0.88, h * 0.38, 1.1);

    // Sun / bird dots
    canvas.drawCircle(Offset(w * 0.75, h * 0.18), 22, p);
    final fill = Paint()
      ..color = VetoMockup.hairline.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.62, h * 0.22), 3, fill);
    canvas.drawCircle(Offset(w * 0.58, h * 0.2), 2.5, fill);
    canvas.drawCircle(Offset(w * 0.54, h * 0.22), 2, fill);

    // Traffic light pole
    canvas.drawLine(Offset(w * 0.42, h * 0.35), Offset(w * 0.42, h * 0.62), p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.42, h * 0.32), width: 14, height: 36),
        const Radius.circular(4),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
