// ============================================================
//  webrtc_user_settings.dart — Local WebRTC preferences
//  Used by WebRTCService (calls) and SettingsScreen.
// ============================================================

import 'dart:convert';

/// Preset STUN server lists (no TURN — add your own if needed behind NAT).
enum WebRtcIcePreset {
  minimal,
  extended,
}

/// Saved user choices for getUserMedia + RTCPeerConnection.
class WebRtcUserSettings {
  final WebRtcIcePreset icePreset;
  final int iceCandidatePoolSize;
  final bool echoCancellation;
  final bool noiseSuppression;
  final bool autoGainControl;
  /// ideal width for video capture
  final int videoWidth;
  final int videoHeight;
  /// `user` (front) or `environment` (back)
  final String facingMode;
  final String bundlePolicy;
  final String rtcpMuxPolicy;

  const WebRtcUserSettings({
    required this.icePreset,
    required this.iceCandidatePoolSize,
    required this.echoCancellation,
    required this.noiseSuppression,
    required this.autoGainControl,
    required this.videoWidth,
    required this.videoHeight,
    required this.facingMode,
    required this.bundlePolicy,
    required this.rtcpMuxPolicy,
  });

  factory WebRtcUserSettings.defaults() => const WebRtcUserSettings(
        icePreset: WebRtcIcePreset.minimal,
        iceCandidatePoolSize: 10,
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
        videoWidth: 1280,
        videoHeight: 720,
        facingMode: 'user',
        bundlePolicy: 'max-bundle',
        rtcpMuxPolicy: 'require',
      );

  factory WebRtcUserSettings.fromJson(Map<String, dynamic> m) {
    WebRtcIcePreset preset = WebRtcIcePreset.minimal;
    final p = m['icePreset'] as String?;
    if (p == 'extended') preset = WebRtcIcePreset.extended;

    return WebRtcUserSettings(
      icePreset: preset,
      iceCandidatePoolSize: (m['iceCandidatePoolSize'] as num?)?.toInt().clamp(0, 30) ?? 10,
      echoCancellation: m['echoCancellation'] as bool? ?? true,
      noiseSuppression: m['noiseSuppression'] as bool? ?? true,
      autoGainControl: m['autoGainControl'] as bool? ?? true,
      videoWidth: (m['videoWidth'] as num?)?.toInt().clamp(320, 1920) ?? 1280,
      videoHeight: (m['videoHeight'] as num?)?.toInt().clamp(240, 1080) ?? 720,
      facingMode: (m['facingMode'] as String?) == 'environment' ? 'environment' : 'user',
      bundlePolicy: _validBundle(m['bundlePolicy'] as String?),
      rtcpMuxPolicy: _validMux(m['rtcpMuxPolicy'] as String?),
    );
  }

  static String _validBundle(String? v) {
    const allowed = {'balanced', 'max-bundle', 'max-compat'};
    if (v != null && allowed.contains(v)) return v;
    return 'max-bundle';
  }

  static String _validMux(String? v) {
    const allowed = {'require', 'negotiate'};
    if (v != null && allowed.contains(v)) return v;
    return 'require';
  }

  Map<String, dynamic> toJson() => {
        'icePreset': icePreset == WebRtcIcePreset.extended ? 'extended' : 'minimal',
        'iceCandidatePoolSize': iceCandidatePoolSize,
        'echoCancellation': echoCancellation,
        'noiseSuppression': noiseSuppression,
        'autoGainControl': autoGainControl,
        'videoWidth': videoWidth,
        'videoHeight': videoHeight,
        'facingMode': facingMode,
        'bundlePolicy': bundlePolicy,
        'rtcpMuxPolicy': rtcpMuxPolicy,
      };

  static String encode(WebRtcUserSettings s) => jsonEncode(s.toJson());

  static WebRtcUserSettings decode(String? raw) {
    if (raw == null || raw.isEmpty) return WebRtcUserSettings.defaults();
    try {
      return WebRtcUserSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return WebRtcUserSettings.defaults();
    }
  }

  /// STUN entries only — safe defaults for development.
  static List<Map<String, dynamic>> _iceServers(WebRtcIcePreset preset) {
    final base = <Map<String, dynamic>>[
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ];
    if (preset == WebRtcIcePreset.extended) {
      base.addAll([
        {'urls': 'stun:stun3.l.google.com:19302'},
        {'urls': 'stun:stun4.l.google.com:19302'},
      ]);
    }
    return base;
  }

  /// Map for `createPeerConnection` (flutter_webrtc).
  Map<String, dynamic> peerConnectionConfiguration() {
    return {
      'iceServers': _iceServers(icePreset),
      'iceCandidatePoolSize': iceCandidatePoolSize,
      'bundlePolicy': bundlePolicy,
      'rtcpMuxPolicy': rtcpMuxPolicy,
    };
  }

  /// Constraints for `getUserMedia` (Web / mobile).
  WebRtcUserSettings copyWith({
    WebRtcIcePreset? icePreset,
    int? iceCandidatePoolSize,
    bool? echoCancellation,
    bool? noiseSuppression,
    bool? autoGainControl,
    int? videoWidth,
    int? videoHeight,
    String? facingMode,
    String? bundlePolicy,
    String? rtcpMuxPolicy,
  }) {
    return WebRtcUserSettings(
      icePreset: icePreset ?? this.icePreset,
      iceCandidatePoolSize: iceCandidatePoolSize ?? this.iceCandidatePoolSize,
      echoCancellation: echoCancellation ?? this.echoCancellation,
      noiseSuppression: noiseSuppression ?? this.noiseSuppression,
      autoGainControl: autoGainControl ?? this.autoGainControl,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
      facingMode: facingMode ?? this.facingMode,
      bundlePolicy: bundlePolicy ?? this.bundlePolicy,
      rtcpMuxPolicy: rtcpMuxPolicy ?? this.rtcpMuxPolicy,
    );
  }

  Map<String, dynamic> mediaConstraints({required bool wantVideo}) {
    return {
      'audio': {
        'echoCancellation': echoCancellation,
        'noiseSuppression': noiseSuppression,
        'autoGainControl': autoGainControl,
      },
      'video': wantVideo
          ? {
              'width': {'ideal': videoWidth},
              'height': {'ideal': videoHeight},
              'facingMode': facingMode,
            }
          : false,
    };
  }

}
