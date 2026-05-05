// ============================================================
//  Pango-class service hub — scenario wheel + central detail bubble
// ============================================================

import 'package:flutter/material.dart';

import '../core/theme/veto_mockup_tokens.dart';
import '../l10n/app_localizations.dart';

class VetoLandingServiceHub extends StatefulWidget {
  const VetoLandingServiceHub({
    super.key,
    required this.l10n,
    required this.onSos,
    this.compact = false,
  });

  final AppLocalizations l10n;
  final VoidCallback onSos;
  final bool compact;

  @override
  State<VetoLandingServiceHub> createState() => _VetoLandingServiceHubState();
}

class _Scenario {
  const _Scenario({
    required this.color,
    required this.icon,
    required this.label,
    required this.title,
    required this.body,
    required this.points,
  });
  final Color color;
  final IconData icon;
  final String label;
  final String title;
  final String body;
  final List<String> points;
}

class _VetoLandingServiceHubState extends State<VetoLandingServiceHub> {
  int _i = 0;

  List<_Scenario> _scenarios(AppLocalizations l) => [
        _Scenario(
          color: VetoMockup.wheelRed,
          icon: Icons.traffic_rounded,
          label: l.wheel1Label,
          title: l.wheel1Title,
          body: l.wheel1Body,
          points: [l.wheel1Point1, l.wheel1Point2, l.wheel1Point3],
        ),
        _Scenario(
          color: VetoMockup.wheelOrange,
          icon: Icons.car_crash_rounded,
          label: l.wheel2Label,
          title: l.wheel2Title,
          body: l.wheel2Body,
          points: [l.wheel2Point1, l.wheel2Point2, l.wheel2Point3],
        ),
        _Scenario(
          color: VetoMockup.wheelTeal,
          icon: Icons.gavel_rounded,
          label: l.wheel3Label,
          title: l.wheel3Title,
          body: l.wheel3Body,
          points: [l.wheel3Point1, l.wheel3Point2, l.wheel3Point3],
        ),
        _Scenario(
          color: VetoMockup.wheelSky,
          icon: Icons.balance_rounded,
          label: l.wheel4Label,
          title: l.wheel4Title,
          body: l.wheel4Body,
          points: [l.wheel4Point1, l.wheel4Point2, l.wheel4Point3],
        ),
        _Scenario(
          color: VetoMockup.primaryCta,
          icon: Icons.support_agent_rounded,
          label: l.wheel5Label,
          title: l.wheel5Title,
          body: l.wheel5Body,
          points: [l.wheel5Point1, l.wheel5Point2, l.wheel5Point3],
        ),
      ];

  void _prev() => setState(() => _i = (_i + 4) % 5);
  void _next() => setState(() => _i = (_i + 1) % 5);

  @override
  Widget build(BuildContext context) {
    final l = widget.l10n;
    final s = _scenarios(l);
    final cur = s[_i];
    final bubbleW = widget.compact ? 300.0 : 340.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 16 : 24,
        vertical: widget.compact ? 20 : 32,
      ),
      child: Column(
        children: [
          Text(
            l.wheelKicker,
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: VetoMockup.primaryCta.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (j) {
              final on = j == _i;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _i = j),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: widget.compact ? 48 : 56,
                            height: widget.compact ? 48 : 56,
                            decoration: BoxDecoration(
                              color: s[j].color,
                              shape: BoxShape.circle,
                              boxShadow: on
                                  ? [
                                      BoxShadow(
                                        color: s[j].color.withValues(alpha: 0.45),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                              border: Border.all(
                                color: on ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(s[j].icon, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s[j].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: widget.compact ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: on ? VetoMockup.ink : VetoMockup.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _prev,
                icon: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  color: VetoMockup.ink,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    CustomPaint(
                      painter: _BubblePointerPainter(color: VetoMockup.primaryCta),
                      size: const Size(28, 12),
                    ),
                    Container(
                      width: bubbleW,
                      constraints: const BoxConstraints(minHeight: 280),
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                      decoration: BoxDecoration(
                        color: VetoMockup.primaryCta,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: VetoMockup.primaryCta.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cur.title,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Heebo',
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cur.body,
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...cur.points.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(top: 6, end: 8),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      p,
                                      style: TextStyle(
                                        fontFamily: 'Heebo',
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: widget.onSos,
                            child: Text(
                              l.wheelTellMore,
                              style: const TextStyle(
                                fontFamily: 'Heebo',
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _next,
                icon: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: VetoMockup.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onSos,
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [VetoMockup.primaryCta, VetoMockup.primaryCtaDeep],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: VetoMockup.primaryGlow,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emergency_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        l.heroCta,
                        style: const TextStyle(
                          fontFamily: 'Heebo',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubblePointerPainter extends CustomPainter {
  _BubblePointerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubblePointerPainter oldDelegate) =>
      oldDelegate.color != color;
}
