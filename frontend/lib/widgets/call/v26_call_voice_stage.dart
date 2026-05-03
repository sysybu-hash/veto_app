// ============================================================
//  v26_call_voice_stage.dart — Voice-only call body.
//  Big avatar + peer name + live timer + recording pill.
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import 'call_i18n.dart';

/// Returns up to two initials from [full], preferring the first word.
String _initials(String full) {
  final parts = full.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final s = parts.first;
    return s.characters.take(2).toString();
  }
  return parts.first.characters.take(1).toString() +
      parts.last.characters.take(1).toString();
}

class V26CallVoiceStage extends StatelessWidget {
  const V26CallVoiceStage({
    super.key,
    required this.peerName,
    required this.specialization,
    required this.durationSec,
    required this.isRecording,
    required this.language,
  });

  final String peerName;
  final String? specialization;
  final int durationSec;
  final bool isRecording;
  final String language;

  String _formatDuration(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: V26.navy500.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(V26.rPill),
              border: Border.all(color: V26.navy400.withValues(alpha: 0.4)),
            ),
            child: Text(
              CallI18n.voiceHeader.t(language),
              style: const TextStyle(
                color: V26.navy200,
                fontFamily: V26.sans,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            peerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: V26.serif,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (specialization != null && specialization!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              specialization!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: V26.navy300,
                fontFamily: V26.sans,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            _formatDuration(durationSec),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Heebo',
              fontSize: 32,
              fontFeatures: [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          _PulsingAvatar(initials: _initials(peerName)),
          if (isRecording) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: V26.emerg.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(V26.rPill),
                border: Border.all(color: V26.emerg.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BlinkDot(),
                  const SizedBox(width: 8),
                  Text(
                    CallI18n.recordingPill.t(language),
                    style: const TextStyle(
                      color: Color(0xFFFFB6BD),
                      fontFamily: V26.sans,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  const _PulsingAvatar({required this.initials});
  final String initials;

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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
        final expand = 1.0 + t * 0.25;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: expand,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: V26.navy400.withValues(alpha: 0.30 * opacity),
                      width: 2,
                    ),
                  ),
                  width: 160,
                  height: 160,
                ),
              ),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [V26.navy400, V26.navy500],
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: V26.navy500.withValues(alpha: 0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: V26.serif,
                    fontSize: 48,
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
      duration: const Duration(milliseconds: 1200),
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
        opacity: 0.4 + _ctrl.value * 0.6,
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
