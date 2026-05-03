import 'package:flutter/material.dart';

import 'veto_2026.dart';
import 'veto_theme.dart';

/// Plain light paper backdrop (2026).
class FutureBackdrop extends StatelessWidget {
  final Widget child;

  const FutureBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: V26.paper, child: child);
  }
}

/// Clean surface card with border and subtle shadow.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: V26.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: V26.hairline),
        boxShadow: V26.shadow1,
      ),
      child: child,
    );
  }
}

/// Status pill / badge.
class NeonBadge extends StatelessWidget {
  final String label;
  final Color color;

  const NeonBadge({
    super.key,
    required this.label,
    this.color = VetoPalette.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}