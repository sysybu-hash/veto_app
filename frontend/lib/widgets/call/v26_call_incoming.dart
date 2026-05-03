// ============================================================
//  v26_call_incoming.dart — Lawyer-side incoming call screen.
//  Mirrors the "Incoming (lawyer side)" mockup in 2026/communication.html.
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import 'call_i18n.dart';
import 'v26_call_control_bar.dart';
import 'v26_call_stage.dart';

class V26CallIncoming extends StatelessWidget {
  const V26CallIncoming({
    super.key,
    required this.language,
    required this.callerName,
    required this.caseSummary,
    this.specialization,
    this.distanceLabel,
    required this.onAccept,
    required this.onDecline,
    this.onChatFirst,
  });

  final String language;
  final String callerName;
  final String caseSummary;
  final String? specialization;
  final String? distanceLabel;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onChatFirst;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 52),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: V26CallGlassPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: V26.emerg.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(V26.rPill),
                    border: Border.all(color: V26.emerg.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _BlinkDot(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          CallI18n.incomingBadge.t(language),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFB6BD),
                            fontFamily: V26.sans,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  callerName.trim().isEmpty
                      ? CallI18n.incomingUnknown.t(language)
                      : callerName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: V26.serif,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (specialization != null || distanceLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (specialization != null && specialization!.isNotEmpty)
                        specialization!,
                      if (distanceLabel != null && distanceLabel!.isNotEmpty)
                        distanceLabel!,
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: V26.navy300,
                      fontFamily: V26.sans,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (caseSummary.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(V26.rLg),
                      border: Border.all(color: V26.callGoldHairSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CallI18n.incomingCaseDetails.t(language),
                          style: const TextStyle(
                            color: V26.navy200,
                            fontFamily: V26.sans,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          caseSummary,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: V26.sans,
                            fontSize: 13.5,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _PulsingSos(),
        const Spacer(),
        V26CallControlBar(
          children: [
            V26CallButton(
              icon: Icons.close_rounded,
              variant: V26CallButtonVariant.goldOutline,
              size: 60,
              tooltip: CallI18n.incomingDecline.t(language),
              onPressed: onDecline,
            ),
            if (onChatFirst != null)
              V26CallButton(
                icon: Icons.chat_bubble_outline_rounded,
                variant: V26CallButtonVariant.goldOutline,
                size: 60,
                tooltip: CallI18n.incomingChatFirst.t(language),
                onPressed: onChatFirst,
              ),
            V26CallButton(
              icon: Icons.call_rounded,
              variant: V26CallButtonVariant.success,
              size: 80,
              iconSize: 30,
              tooltip: CallI18n.incomingAccept.t(language),
              onPressed: onAccept,
            ),
          ],
        ),
      ],
    );
  }
}

class _PulsingSos extends StatefulWidget {
  @override
  State<_PulsingSos> createState() => _PulsingSosState();
}

class _PulsingSosState extends State<_PulsingSos>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final scale = 1.0 + t * 0.15;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8492), Color(0xFFE5354C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: V26.emerg.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontFamily: V26.serif,
                fontSize: 54,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BlinkDot extends StatefulWidget {
  const _BlinkDot();

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.3 + _ctrl.value * 0.7,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B7A),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
