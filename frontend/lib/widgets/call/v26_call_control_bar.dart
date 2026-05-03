// ============================================================
//  v26_call_control_bar.dart — Bottom row of circular call buttons.
//  Mirrors `.footer-controls` in 2026/communication.html.
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import 'v26_call_stage.dart';

/// Visual style for a [V26CallButton].
enum V26CallButtonVariant { neutral, active, danger, success, goldOutline }

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
          V26.gold.withValues(alpha: 0.18),
          V26.gold.withValues(alpha: 0.72),
          V26.goldSoft,
        );
      case V26CallButtonVariant.danger:
        return (V26.callDangerRed, V26.callDangerRed, Colors.white);
      case V26CallButtonVariant.success:
        return (V26.ok, V26.ok, Colors.white);
      case V26CallButtonVariant.goldOutline:
        return (
          Colors.white.withValues(alpha: 0.08),
          V26.gold.withValues(alpha: 0.68),
          V26.goldSoft,
        );
      case V26CallButtonVariant.neutral:
        return (
          Colors.white.withValues(alpha: 0.06),
          V26.gold.withValues(alpha: 0.42),
          V26.goldSoft,
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
                    color: V26.callDangerRed.withValues(alpha: 0.45),
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
    final hasDanger = children.isNotEmpty &&
        children.last is V26CallButton &&
        (children.last as V26CallButton).variant == V26CallButtonVariant.danger;
    final leading =
        hasDanger ? children.take(children.length - 1).toList() : children;
    final danger = hasDanger ? children.last : null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: V26CallGlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: V26.callRadiusPanel,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final buttonSize = compact ? 48.0 : 56.0;
              final dangerSize = compact ? 62.0 : 72.0;
              Widget normalize(Widget child) {
                if (child is V26CallButton) {
                  return V26CallButton(
                    icon: child.icon,
                    onPressed: child.onPressed,
                    tooltip: child.tooltip,
                    size: child.variant == V26CallButtonVariant.danger
                        ? dangerSize
                        : buttonSize,
                    iconSize:
                        child.variant == V26CallButtonVariant.danger ? 28 : 23,
                    variant: child.variant == V26CallButtonVariant.neutral
                        ? V26CallButtonVariant.goldOutline
                        : child.variant,
                  );
                }
                return child;
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final c in leading) ...[
                            normalize(c),
                            SizedBox(width: compact ? 10 : 14),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (danger != null) ...[
                    Container(
                      width: 1,
                      height: 42,
                      margin:
                          EdgeInsets.symmetric(horizontal: compact ? 10 : 18),
                      color: V26.gold.withValues(alpha: 0.55),
                    ),
                    normalize(danger),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
