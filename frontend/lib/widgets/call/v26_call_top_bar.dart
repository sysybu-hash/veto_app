// ============================================================
//  v26_call_top_bar.dart — VETO Bold top chrome for active calls.
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
      background: V26.callRecBg,
      border: V26.emerg.withValues(alpha: 0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: V26.callDangerRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFC2C8),
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
        return (
          color: const Color(0xFF34D399),
          label: CallI18n.qualityGood.t(language)
        );
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
    return Tooltip(
      message: quality.rttMs > 0
          ? '${derived.label} · ${quality.rttMs}ms'
          : derived.label,
      child: Icon(Icons.network_cell_rounded,
          color: V26.gold.withValues(alpha: 0.85), size: 18),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: V26CallGlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        borderRadius: 14,
        child: Row(
          children: [
            Flexible(
              flex: 3,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(durationSec),
                        style: const TextStyle(
                          color: V26.gold,
                          fontSize: 18,
                          fontFeatures: [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w700,
                          fontFamily: V26.sans,
                        ),
                      ),
                      if (isRecording) ...[
                        const SizedBox(width: 10),
                        V26RecordingPill(
                            label: CallI18n.recordingShort.t(language)),
                      ],
                      if (quality.worst > 0) ...[
                        const SizedBox(width: 8),
                        V26NetworkQualityChip(
                            quality: quality, language: language),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: V26.serif,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: V26.callStatusGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          specialization?.trim().isNotEmpty == true
                              ? '${CallI18n.connectedEncrypted.t(language)} · $specialization'
                              : CallI18n.connectedEncrypted.t(language),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontFamily: V26.sans,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Flexible(
              flex: 3,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: V26CallShieldBadge(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
