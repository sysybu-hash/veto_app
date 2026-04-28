// ============================================================
//  agora_service.dart — Agora RTC engine wrapper (ChangeNotifier)
//  Includes: Video, Audio, Screen Share, Noise Suppression,
//  Network Quality, Connection Stats (Agora SDK v6.x)
// ============================================================

import 'dart:async' show unawaited;
import 'dart:developer' as developer;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

/// Agora project App ID (from Agora Console).
const String kAgoraAppIdPlaceholder = 'b40f2355783a4ccca027a91d0d7100ca';

class AgoraService extends ChangeNotifier {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _joined = false;
  String? _activeChannelId;
  String? _errorMessage;
  /// Web: [startPreview] after join only (see Agora web issues — preview before join can hard-crash the tab).
  bool _webPreviewAfterJoin = false;

  RtcEngine? get engine => _engine;
  int? get remoteUid => _remoteUid;
  bool get joined => _joined;
  String? get activeChannelId => _activeChannelId;
  String? get errorMessage => _errorMessage;

  bool _micPublishMuted = false;
  bool _videoPublishMuted = false;
  bool _speakerOn = true;
  bool _screenSharing = false;
  bool _noiseSuppression = true;

  // Network quality (0=Unknown 1=Excellent 2=Good 3=Poor 4=Bad 5=VBad 6=Down)
  int _localNetworkQuality = 0;
  int _remoteNetworkQuality = 0;
  // RtcStats
  int _rttMs = 0;
  int _txPacketLossRate = 0;
  int _rxPacketLossRate = 0;
  int _txBitrateKbps = 0;
  int _rxBitrateKbps = 0;

  bool get micPublishMuted => _micPublishMuted;
  bool get videoPublishMuted => _videoPublishMuted;
  /// Mobile: earpiece vs speaker (no-op on web).
  bool get speakerOn => _speakerOn;
  bool get screenSharing => _screenSharing;
  bool get noiseSuppression => _noiseSuppression;
  int get localNetworkQuality => _localNetworkQuality;
  int get remoteNetworkQuality => _remoteNetworkQuality;
  int get rttMs => _rttMs;
  int get txPacketLossRate => _txPacketLossRate;
  int get rxPacketLossRate => _rxPacketLossRate;
  int get txBitrateKbps => _txBitrateKbps;
  int get rxBitrateKbps => _rxBitrateKbps;

  /// Signal quality label for UI (uses worst of tx/rx).
  String get networkQualityLabel {
    final worst = _localNetworkQuality > _remoteNetworkQuality
        ? _localNetworkQuality
        : _remoteNetworkQuality;
    switch (worst) {
      case 1: return 'מעולה';
      case 2: return 'טובה';
      case 3: return 'בינונית';
      case 4: return 'גרועה';
      case 5:
      case 6: return 'נוראית';
      default: return '';
    }
  }

  /// Mute/unmute **published** local audio (remote hears silence when muted).
  Future<void> setMicPublishMuted(bool muted) async {
    final e = _engine;
    if (e == null) return;
    await e.muteLocalAudioStream(muted);
    _micPublishMuted = muted;
    notifyListeners();
  }

  /// Mute/unmute **published** local video (camera off for remote; capture may continue).
  Future<void> setVideoPublishMuted(bool muted) async {
    final e = _engine;
    if (e == null) return;
    await e.muteLocalVideoStream(muted);
    _videoPublishMuted = muted;
    notifyListeners();
  }

  /// Mobile only: switch front/back camera.
  Future<void> switchCamera() async {
    if (kIsWeb) return;
    final e = _engine;
    if (e == null) return;
    await e.switchCamera();
  }

  /// Toggle screen sharing (Web + desktop). No-op on mobile.
  Future<void> toggleScreenShare() async {
    final e = _engine;
    if (e == null) return;
    try {
      if (_screenSharing) {
        await e.stopScreenCapture();
        _screenSharing = false;
      } else {
        if (kIsWeb) {
          await e.startScreenCapture(
            const ScreenCaptureParameters2(
              captureAudio: true,
              captureVideo: true,
              videoParams: ScreenVideoParameters(
                dimensions: VideoDimensions(width: 1280, height: 720),
                frameRate: 15,
                bitrate: 1500,
              ),
              audioParams: ScreenAudioParameters(
                sampleRate: 16000,
                channels: 2,
                captureSignalVolume: 100,
              ),
            ),
          );
        } else {
          // Mobile screen share not supported in this build.
          return;
        }
        _screenSharing = true;
      }
      notifyListeners();
    } catch (err, st) {
      developer.log('toggleScreenShare', name: 'VETO.Agora', error: err, stackTrace: st);
    }
  }

  /// Enable/disable AI noise suppression.
  Future<void> setNoiseSuppression(bool enable) async {
    final e = _engine;
    if (e == null) return;
    try {
      await e.setAINSMode(
        enabled: enable,
        mode: AudioAinsMode.ainsModeBalanced,
      );
      _noiseSuppression = enable;
      notifyListeners();
    } catch (err, st) {
      developer.log('setNoiseSuppression', name: 'VETO.Agora', error: err, stackTrace: st);
    }
  }

  /// Route playback to the loudspeaker (iOS/Android). No-op on web.
  Future<void> setSpeakerOn(bool on) async {
    if (kIsWeb) return;
    final e = _engine;
    if (e == null) return;
    try {
      await e.setEnableSpeakerphone(on);
      _speakerOn = on;
      notifyListeners();
    } catch (err, st) {
      developer.log('setSpeakerOn', name: 'VETO.Agora', error: err, stackTrace: st);
    }
  }

  /// Creates and initializes [RtcEngine] once. Safe to call again if already ready.
  Future<void> initializeEngine({bool enableVideoTrack = true}) async {
    if (_engine != null) return;
    RtcEngine? eng;
    try {
      eng = createAgoraRtcEngine();
      _engine = eng;
      await eng.initialize(
        const RtcEngineContext(
          appId: kAgoraAppIdPlaceholder,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      eng.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _joined = true;
            _errorMessage = null;
            if (_webPreviewAfterJoin) {
              _webPreviewAfterJoin = false;
              unawaited(_webStartPreviewSafe());
            }
            notifyListeners();
          },
          onUserJoined:
              (RtcConnection connection, int remoteUid, int elapsed) {
            _remoteUid = remoteUid;
            notifyListeners();
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            if (_remoteUid == remoteUid) {
              _remoteUid = null;
              notifyListeners();
            }
          },
          onError: (ErrorCodeType err, String msg) {
            _errorMessage = '$err: $msg';
            notifyListeners();
          },
          onConnectionStateChanged: (RtcConnection connection,
              ConnectionStateType state, ConnectionChangedReasonType reason) {
            if (state == ConnectionStateType.connectionStateFailed) {
              _errorMessage =
                  'Agora connection failed ($reason). Check token, App ID, and network.';
              notifyListeners();
            }
          },
          // Network quality callback — fires every 2 seconds.
          onNetworkQuality: (RtcConnection connection, int uid,
              QualityType txQuality, QualityType rxQuality) {
            if (uid == 0) {
              // uid=0 means local user
              _localNetworkQuality = txQuality.index;
            } else {
              _remoteNetworkQuality = rxQuality.index;
            }
            notifyListeners();
          },
          // RTC Stats — fires every 2 seconds.
          onRtcStats: (RtcConnection connection, RtcStats stats) {
            _rttMs = stats.lastmileDelay ?? 0;
            _txPacketLossRate = stats.txPacketLossRate ?? 0;
            _rxPacketLossRate = stats.rxPacketLossRate ?? 0;
            _txBitrateKbps = (stats.txKBitRate ?? 0);
            _rxBitrateKbps = (stats.rxKBitRate ?? 0);
            notifyListeners();
          },
        ),
      );

      if (enableVideoTrack) {
        await eng.enableVideo();
        // Set audio profile optimized for speech/legal consultation
        await eng.setAudioProfile(
          profile: AudioProfileType.audioProfileSpeechStandard,
          scenario: AudioScenarioType.audioScenarioChatroom,
        );
        // Enable AI noise suppression by default
        try {
          await eng.setAINSMode(
            enabled: true,
            mode: AudioAinsMode.ainsModeBalanced,
          );
        } catch (_) {}
        // On iOS/Android, preview before join is normal. On **web**, starting preview
        // before join has been reported to hang or kill the tab; we start preview in
        // [onJoinChannelSuccess] when [_webPreviewAfterJoin] is set.
        if (!kIsWeb) {
          await eng.startPreview();
        }
      } else {
        await eng.disableVideo();
        // Audio-only: use highest quality speech profile
        await eng.setAudioProfile(
          profile: AudioProfileType.audioProfileSpeechStandard,
          scenario: AudioScenarioType.audioScenarioChatroom,
        );
      }
      notifyListeners();
    } catch (e, st) {
      _errorMessage = e.toString();
      developer.log(
        'initializeEngine',
        name: 'VETO.Agora',
        error: e,
        stackTrace: st,
      );
      // Singleton engine must not stay half-initialized; next call would return early and break join.
      try {
        if (eng != null) {
          await eng.release();
        }
      } catch (_) {}
      _engine = null;
      eng = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Joins a channel.
  /// - [token] + [uid] from server must match (see [buildRtcTokenForUid] in backend).
  /// - For dev without certificate, [token] is empty and [uid] should be 0.
  Future<void> _webStartPreviewSafe() async {
    final e = _engine;
    if (e == null) return;
    if (kIsWeb) {
      // ignore: avoid_print
      print('[VETO][Agora] startPreview (web, after join)');
    }
    try {
      await e.startPreview();
      notifyListeners();
    } catch (err, st) {
      _errorMessage = 'שגיאת מצלמה (דפדפן): $err';
      developer.log('web startPreview', name: 'VETO.Agora', error: err, stackTrace: st);
      notifyListeners();
    }
  }

  Future<void> joinChannel({
    required String channelId,
    String token = '',
    int uid = 0,
    bool publishVideo = true,
  }) async {
    await initializeEngine(enableVideoTrack: publishVideo);
    final eng = _engine;
    if (eng == null) return;

    _activeChannelId = channelId;
    _errorMessage = null;
    if (kIsWeb && publishVideo) {
      _webPreviewAfterJoin = true;
    }
    notifyListeners();

    try {
      await eng.joinChannel(
        token: token,
        channelId: channelId,
        uid: uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: publishVideo,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      _webPreviewAfterJoin = false;
      rethrow;
    }
  }

  /// Leaves the current channel (engine stays alive for reuse).
  Future<void> leaveChannel() async {
    try {
      await _engine?.leaveChannel();
    } catch (e, st) {
      developer.log('leaveChannel', name: 'VETO.Agora', error: e, stackTrace: st);
    } finally {
      _joined = false;
      _remoteUid = null;
      _activeChannelId = null;
      _micPublishMuted = false;
      _videoPublishMuted = false;
      _speakerOn = true;
      _screenSharing = false;
      _localNetworkQuality = 0;
      _remoteNetworkQuality = 0;
      _rttMs = 0;
      notifyListeners();
    }
  }

  /// Leaves channel and releases native engine (call when screen closes).
  Future<void> leaveChannelAndRelease() async {
    await leaveChannel();
    try {
      await _engine?.release();
    } catch (e, st) {
      developer.log(
        'release',
        name: 'VETO.Agora',
        error: e,
        stackTrace: st,
      );
    } finally {
      _engine = null;
      notifyListeners();
    }
  }
}
