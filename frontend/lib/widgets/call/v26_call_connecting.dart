// ============================================================
//  v26_call_connecting.dart — SOS "connecting" screen shown on
//  the citizen side while the app waits for room-joined.
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import 'call_i18n.dart';
import 'v26_call_control_bar.dart';
import 'v26_call_stage.dart';

class V26CallConnecting extends StatefulWidget {
  const V26CallConnecting({
    super.key,
    required this.language,
    required this.elapsedSec,
    this.onCancel,
  });
  final String language;
  final int elapsedSec;
  final VoidCallback? onCancel;

  @override
  State<V26CallConnecting> createState() => _V26CallConnectingState();
}

class _V26CallConnectingState extends State<V26CallConnecting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 56),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: V26CallGlassPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: V26.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(V26.rPill),
                    border: Border.all(color: V26.callGoldHair),
                  ),
                  child: Text(
                    CallI18n.badgeConnecting.t(widget.language),
                    style: const TextStyle(
                      color: V26.goldSoft,
                      fontFamily: V26.sans,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  CallI18n.findingLawyer.t(widget.language),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: V26.serif,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  CallI18n.connectingNearby.t(widget.language),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontFamily: V26.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${widget.elapsedSec}s',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontFamily: 'Heebo',
                    fontSize: 18,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _SosOrb(animation: _pulse),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _Bouncer(animation: _pulse, delayFraction: i / 3),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            CallI18n.connectingDetails.t(widget.language),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: V26.goldSoft,
              fontFamily: V26.sans,
              fontSize: 13,
            ),
          ),
        ),
        const Spacer(),
        V26CallControlBar(
          children: [
            V26CallButton(
              icon: Icons.close_rounded,
              variant: V26CallButtonVariant.danger,
              size: 80,
              iconSize: 30,
              tooltip: CallI18n.cancelRequest.t(widget.language),
              onPressed: widget.onCancel,
            ),
          ],
        ),
      ],
    );
  }
}

class _SosOrb extends StatelessWidget {
  const _SosOrb({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        final expand = 1.0 + t * 0.28;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: expand,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF8492)
                          .withValues(alpha: 0.35 * opacity),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF8492), Color(0xFFE5354C)],
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: V26.emerg.withValues(alpha: 0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: V26.serif,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bouncer extends StatelessWidget {
  const _Bouncer({required this.animation, required this.delayFraction});
  final Animation<double> animation;
  final double delayFraction;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        double t = (animation.value - delayFraction * 0.45) % 1.0;
        if (t < 0) t += 1.0;
        // Trigonometry-free ease: start and end dim, peak 40% through.
        final wave = t < 0.4 ? t / 0.4 : (1 - (t - 0.4) / 0.6);
        final opacity = (0.25 + wave * 0.75).clamp(0.0, 1.0);
        final dy = -wave * 4;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
