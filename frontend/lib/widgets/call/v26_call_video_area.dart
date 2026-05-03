// ============================================================
//  v26_call_video_area.dart — Remote video surface + "waiting" /
//  "media unavailable" placeholders + draggable local PIP.
// ============================================================

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import 'call_i18n.dart';

/// Sits in the middle of the video stage when the remote peer has not yet
/// published video.
class V26VideoPlaceholder extends StatelessWidget {
  const V26VideoPlaceholder({
    super.key,
    required this.peerName,
    required this.language,
  });
  final String peerName;
  final String language;

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString();
    return parts.first.characters.take(1).toString() +
        parts.last.characters.take(1).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [V26.navy400, V26.navy500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: V26.navy900.withValues(alpha: 0.4),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(peerName),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: V26.serif,
                fontSize: 48,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            CallI18n.waitingForPeer.t(language),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: V26.sans,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The core video surface. Uses [AgoraVideoView] once there's a remote uid
/// and the remote has started publishing; falls back to placeholder otherwise.
class V26CallVideoArea extends StatelessWidget {
  const V26CallVideoArea({
    super.key,
    required this.engine,
    required this.channelId,
    required this.remoteUid,
    required this.hasRemoteVideo,
    required this.peerName,
    required this.language,
  });

  final RtcEngine? engine;
  final String channelId;
  final int? remoteUid;
  final bool hasRemoteVideo;
  final String peerName;
  final String language;

  @override
  Widget build(BuildContext context) {
    final eng = engine;
    final uid = remoteUid;
    if (eng == null || uid == null || !hasRemoteVideo) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [V26.navy700, V26.ink900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: V26VideoPlaceholder(peerName: peerName, language: language),
      );
    }
    return Container(
      color: Colors.black,
      child: AgoraVideoView(
        key: ValueKey('remote-$uid'),
        controller: VideoViewController.remote(
          rtcEngine: eng,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: channelId),
        ),
      ),
    );
  }
}

/// Local camera preview shown in the corner of the video stage. On web the
/// engine can stall producing a surface — we fall back to a still
/// "Your camera" label in that case.
class V26CallLocalPip extends StatelessWidget {
  const V26CallLocalPip({
    super.key,
    required this.engine,
    required this.previewOk,
    required this.language,
    required this.videoMuted,
  });

  final RtcEngine? engine;
  final bool previewOk;
  final String language;
  final bool videoMuted;

  @override
  Widget build(BuildContext context) {
    Widget body;
    final eng = engine;
    if (videoMuted) {
      body = Container(
        color: V26.navy700,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off,
              color: Colors.white.withValues(alpha: 0.7),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              CallI18n.cameraOffLabel.t(language),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: V26.sans,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else if (eng != null && previewOk) {
      body = AgoraVideoView(
        key: const ValueKey('local-pip'),
        controller: VideoViewController(
          rtcEngine: eng,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      body = Container(
        color: V26.navy700,
        alignment: Alignment.center,
        child: Text(
          CallI18n.cameraLabel.t(language),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontFamily: V26.sans,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      width: kIsWeb ? 140 : 120,
      height: kIsWeb ? 180 : 160,
      decoration: BoxDecoration(
        color: V26.navy700,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: body,
      ),
    );
  }
}
