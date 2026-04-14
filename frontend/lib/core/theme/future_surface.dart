import 'package:flutter/material.dart';

import 'veto_theme.dart';

/// Plain dark background — replaced aurora/grid backdrop with clean solid.
class FutureBackdrop extends StatelessWidget {
  final Widget child;

  const FutureBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: VetoPalette.bg, child: child);
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
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
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