// ============================================================
//  v26_call_control_bar.dart — Bottom row of circular call buttons.
//  Mirrors `.footer-controls` in 2026/communication.html.
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';

/// Visual style for a [V26CallButton].
enum V26CallButtonVariant { neutral, active, danger, success }

class V26CallButton extends StatelessWidget {
  const V26CallButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 60,
    this.iconSize = 22,
    this.variant = V26CallButtonVariant.neutral,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final V26CallButtonVariant variant;

  (Color bg, Color border, Color icon) _paint() {
    switch (variant) {
      case V26CallButtonVariant.active:
        return (
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.30),
          Colors.white,
        );
      case V26CallButtonVariant.danger:
        return (V26.emerg, V26.emerg, Colors.white);
      case V26CallButtonVariant.success:
        return (V26.ok, V26.ok, Colors.white);
      case V26CallButtonVariant.neutral:
        return (
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.18),
          Colors.white,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, bd, ic) = _paint();
    final button = InkResponse(
      onTap: onPressed,
      radius: size / 2,
      containedInkWell: true,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: bd, width: 1),
          boxShadow: variant == V26CallButtonVariant.danger
              ? [
                  BoxShadow(
                    color: V26.emerg.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : V26.shadow1,
        ),
        child: Icon(icon, color: ic, size: iconSize),
      ),
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Horizontal row of call controls with soft translucent backdrop that
/// fades into the dark stage (`linear-gradient(to bottom, transparent, navy/50)`).
class V26CallControlBar extends StatelessWidget {
  const V26CallControlBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              V26.navy900.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in children) ...[c, const SizedBox(width: 12)],
              const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
