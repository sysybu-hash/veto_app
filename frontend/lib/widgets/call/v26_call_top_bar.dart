// ============================================================
//  v26_call_top_bar.dart — Top overlay for active calls.
//  Shows VETO shield, peer name + role, live timer,
//  NetworkQualityChip, REC pill (when recording).
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import '../../services/agora_service.dart';
import 'call_i18n.dart';
import 'v26_call_stage.dart';

/// Compact REC pill (pulsing red dot). Included in the top bar when
/// the backend has flagged the call as recording.
class V26RecordingPill extends StatelessWidget {
  const V26RecordingPill({super.key, this.label = 'REC'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return V26CallPill(
      background: V26.emerg.withValues(alpha: 0.30),
      border: V26.emerg.withValues(alpha: 0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B7A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFB6BD),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontFamily: V26.sans,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dot + text chip mapping Agora network quality (0..6) to the 2026 palette.
class V26NetworkQualityChip extends StatelessWidget {
  const V26NetworkQualityChip({
    super.key,
    required this.quality,
    required this.language,
  });
  final NetworkQuality quality;
  final String language;

  ({Color color, String label}) _derive() {
    switch (quality.worst) {
      case 1:
        return (color: V26.ok, label: CallI18n.qualityExcellent.t(language));
      case 2:
        return (color: const Color(0xFF34D399), label: CallI18n.qualityGood.t(language));
      case 3:
        return (color: V26.warn, label: CallI18n.qualityFair.t(language));
      case 4:
        return (color: V26.emerg, label: CallI18n.qualityPoor.t(language));
      case 5:
      case 6:
        return (color: V26.emerg2, label: CallI18n.qualityVeryPoor.t(language));
      default:
        return (color: V26.ink300, label: '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final derived = _derive();
    if (derived.label.isEmpty) return const SizedBox.shrink();
    return V26CallPill(
      background: derived.color.withValues(alpha: 0.18),
      border: derived.color.withValues(alpha: 0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: derived.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: derived.color.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            quality.rttMs > 0 ? '${derived.label} · ${quality.rttMs}ms' : derived.label,
            style: TextStyle(
              color: derived.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: V26.sans,
            ),
          ),
        ],
      ),
    );
  }
}

/// Top overlay used by both voice and video stages.
class V26CallTopBar extends StatelessWidget {
  const V26CallTopBar({
    super.key,
    required this.peerName,
    this.specialization,
    required this.durationSec,
    required this.quality,
    required this.language,
    this.isRecording = false,
    this.onBack,
  });

  final String peerName;
  final String? specialization;
  final int durationSec;
  final NetworkQuality quality;
  final String language;
  final bool isRecording;
  final VoidCallback? onBack;

  String _formatDuration(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(
          children: [
            const V26CallShieldBadge(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: V26.serif,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (specialization != null && specialization!.isNotEmpty)
                    Text(
                      specialization!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: V26.navy300,
                        fontFamily: V26.sans,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (quality.worst > 0) ...[
              const SizedBox(width: 6),
              V26NetworkQualityChip(quality: quality, language: language),
            ],
            const SizedBox(width: 6),
            V26CallPill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: V26.ok,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(durationSec),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: V26.sans,
                    ),
                  ),
                ],
              ),
            ),
            if (isRecording) ...[
              const SizedBox(width: 6),
              const V26RecordingPill(),
            ],
          ],
        ),
      ),
    );
  }
}
