// ============================================================
//  v26_call_stage.dart — Dark full-bleed scaffold used by every
//  call state (incoming, connecting, voice, video). Mirrors the
//  `.call-stage` gradient from 2026/communication.html.
// ============================================================

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
    final body = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [V26.ink900, V26.navy800, Color(0xFF05070E)],
        ),
      ),
      child: child,
    );
    final withDir = textDirection == null
        ? body
        : Directionality(textDirection: textDirection!, child: body);
    return Scaffold(
      backgroundColor: V26.ink900,
      body: withDir,
    );
  }
}

/// "VETO" shield pill (reused by the top bar).
class V26CallShieldBadge extends StatelessWidget {
  const V26CallShieldBadge({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: V26.navy800.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(V26.rSm),
        border: Border.all(color: V26.gold.withValues(alpha: 0.35)),
        boxShadow: V26.shadow1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, color: V26.gold, size: 14),
          const SizedBox(width: 5),
          Text(
            'VETO',
            style: TextStyle(
              fontFamily: V26.serif,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.95),
              letterSpacing: 1.2,
            ),
          ),
        ],
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
