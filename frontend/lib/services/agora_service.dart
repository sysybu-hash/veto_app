// ============================================================
//  agora_service.dart — VETO 2026 Agora RTC wrapper
//
//  One ChangeNotifier that owns the full lifecycle of an Agora
//  RTC engine: init · join · publish · quality · token renewal.
//
//  Design goals:
//    * Web / iOS / Android parity. Platform splits are limited to:
//       - Web video: join with `publishCameraTrack: false`, then
//         `startPreview()` after join, then `updateChannelMediaOptions`
//         to publish camera — avoids iris error "can not publish a disabled
//         track" (join used to publish before the camera track was enabled).
//       - `startPreview()` still runs only after join on web (before join
//         has been reported to deadlock Chromium tabs).
//       - `switchCamera` / `setEnableSpeakerphone` are native-only.
//       - Screen share uses `startScreenCapture2` on web, is a no-op
//         on mobile (Flutter lacks a ready-made foreground service
//         surface we want to maintain here).
//    * Auto-retry: up to 3 attempts with exponential backoff when
//      `onConnectionStateChanged` reports disconnected/failed.
//    * Token renewal: a callback the caller wires to their backend
//      (`POST /api/calls/:eventId/token`). When `onTokenPrivilegeWillExpire`
//      fires the service calls it and forwards the fresh token to the
//      engine via `renewToken`.
//    * Error routing: a stream of ([CallErrorKind], rawMessage) pairs
//      the UI can translate to he/en/ru and display in an error sheet.
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

/// Agora project App ID (Agora Console). Swap for an env-driven value once
/// the Render → Vercel env pipeline exposes it to the Flutter build.
const String kAgoraAppId = 'b40f2355783a4ccca027a91d0d7100ca';

/// Category of an Agora failure — the UI uses this to pick a translated
/// message and to decide whether retry is user-actionable.
enum CallErrorKind {
  none,
  permissionDenied,
  tokenInvalid,
  tokenExpired,
  networkLost,
  connectionFailed,
  mediaUnavailable,
  unknown,
}

/// Lifecycle of a single call attempt.
enum CallConnectionPhase {
  idle,
  connecting,
  reconnecting,
  connected,
  failed,
  left,
}

/// Resolved signal for the UI "connection chip".
class NetworkQuality {
  const NetworkQuality({this.up = 0, this.down = 0, this.rttMs = 0, this.txKbps = 0});
  final int up;
  final int down;
  final int rttMs;
  final int txKbps;

  /// Worse of up/down for display.
  int get worst => up > down ? up : down;
}

/// Emits one event per Agora error; the UI listens and surfaces a
/// translated message without polluting the engine field with strings.
class CallErrorEvent {
  const CallErrorEvent(this.kind, this.message);
  final CallErrorKind kind;
  final String message;
}

/// Signature of the "go fetch me a fresh RTC token" callback.
typedef AgoraTokenFetcher = Future<String?> Function();

class AgoraService extends ChangeNotifier {
  AgoraService();

  // ── Engine + channel state ────────────────────────────────────
  RtcEngine? _engine;
  String? _channelId;
  int _localUid = 0;
  String _token = '';
  bool _wantsVideo = true;
  AgoraTokenFetcher? _tokenFetcher;

  CallConnectionPhase _phase = CallConnectionPhase.idle;
  int? _remoteUid;
  bool _remoteVideoPlaying = false;
  bool _localPreviewOk = false;
  int _durationSec = 0;
  Timer? _durationTimer;

  // ── Published media toggles (local) ───────────────────────────
  bool _micMuted = false;
  bool _videoMuted = false;
  bool _speakerOn = true;
  bool _screenSharing = false;
  bool _noiseSuppression = true;

  // ── Quality & stats ────────────────────────────────────────────
  NetworkQuality _quality = const NetworkQuality();

  // ── Error reporting ────────────────────────────────────────────
  final StreamController<CallErrorEvent> _errorCtrl =
      StreamController<CallErrorEvent>.broadcast();
  CallErrorEvent? _lastError;

  // ── Retry bookkeeping ──────────────────────────────────────────
  int _retryAttempts = 0;
  static const int _maxRetries = 3;
  Timer? _retryTimer;

  // ── Public getters ─────────────────────────────────────────────
  RtcEngine? get engine => _engine;
  String? get channelId => _channelId;
  int get localUid => _localUid;
  CallConnectionPhase get phase => _phase;
  bool get joined => _phase == CallConnectionPhase.connected ||
      _phase == CallConnectionPhase.reconnecting;
  int? get remoteUid => _remoteUid;
  bool get remoteVideoPlaying => _remoteVideoPlaying;
  bool get localPreviewOk => _localPreviewOk;
  bool get micPublishMuted => _micMuted;
  bool get videoPublishMuted => _videoMuted;
  bool get speakerOn => _speakerOn;
  bool get screenSharing => _screenSharing;
  bool get noiseSuppression => _noiseSuppression;
  NetworkQuality get quality => _quality;
  int get durationSec => _durationSec;
  Stream<CallErrorEvent> get errors => _errorCtrl.stream;
  CallErrorEvent? get lastError => _lastError;

  /// Derived: has the call reached a playable frame?
  bool get hasRemoteVideo => _remoteUid != null && _remoteVideoPlaying;

  // ──────────────────────────────────────────────────────────────
  //  Lifecycle
  // ──────────────────────────────────────────────────────────────

  /// Create the engine once. Safe to call again — returns early if already up.
  Future<void> init({bool enableVideoTrack = true}) async {
    if (_engine != null) return;
    RtcEngine? eng;
    try {
      eng = createAgoraRtcEngine();
      _engine = eng;
      await eng.initialize(
        const RtcEngineContext(
          appId: kAgoraAppId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      eng.registerEventHandler(_buildEventHandler());

      if (enableVideoTrack) {
        await eng.enableVideo();
      } else {
        await eng.disableVideo();
      }
      await eng.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );
      // Best-effort AI noise suppression — never fatal if the SDK
      // doesn't expose AINS on this platform (e.g. older web build).
      try {
        await eng.setAINSMode(
          enabled: true,
          mode: AudioAinsMode.ainsModeBalanced,
        );
        _noiseSuppression = true;
      } catch (_) {
        _noiseSuppression = false;
      }
      if (!kIsWeb && enableVideoTrack) {
        // Native can start the camera preview before join safely.
        await eng.startPreview();
        _localPreviewOk = true;
      }
      notifyListeners();
    } catch (err, st) {
      _emitError(CallErrorKind.unknown, 'init failed: $err');
      developer.log('init', name: 'VETO.Agora', error: err, stackTrace: st);
      try {
        await eng?.release();
      } catch (_) {}
      _engine = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Join a channel. Use [tokenFetcher] to hand back a fresh token during
  /// the call when `onTokenPrivilegeWillExpire` fires or when a reconnect
  /// with an invalid token is detected.
  Future<void> joinChannel({
    required String channelId,
    String token = '',
    int uid = 0,
    bool enableVideo = true,
    AgoraTokenFetcher? tokenFetcher,
  }) async {
    await init(enableVideoTrack: enableVideo);
    final eng = _engine;
    if (eng == null) return;

    _channelId = channelId;
    _token = token;
    _localUid = uid;
    _wantsVideo = enableVideo;
    _tokenFetcher = tokenFetcher;
    _retryAttempts = 0;
    _lastError = null;

    _setPhase(CallConnectionPhase.connecting);

    try {
      await eng.joinChannel(
        token: token,
        channelId: channelId,
        uid: uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          // Web: do not publish camera until startPreview() enables the track
          // (see _webStartPreviewSafe + updateChannelMediaOptions).
          publishCameraTrack: enableVideo && !kIsWeb,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (err) {
      _setPhase(CallConnectionPhase.failed);
      _emitError(CallErrorKind.connectionFailed, 'joinChannel: $err');
      rethrow;
    }
  }

  Future<void> leaveAndRelease() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    try {
      await _engine?.leaveChannel();
    } catch (err, st) {
      developer.log('leaveChannel', name: 'VETO.Agora', error: err, stackTrace: st);
    }
    try {
      await _engine?.release();
    } catch (err, st) {
      developer.log('release', name: 'VETO.Agora', error: err, stackTrace: st);
    }
    _engine = null;
    _channelId = null;
    _remoteUid = null;
    _remoteVideoPlaying = false;
    _localPreviewOk = false;
    _micMuted = false;
    _videoMuted = false;
    _speakerOn = true;
    _screenSharing = false;
    _quality = const NetworkQuality();
    _setPhase(CallConnectionPhase.left);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _durationTimer?.cancel();
    unawaited(_errorCtrl.close());
    // Best-effort async release — don't await inside dispose.
    final eng = _engine;
    if (eng != null) {
      _engine = null;
      unawaited(() async {
        try {
          await eng.leaveChannel();
        } catch (_) {}
        try {
          await eng.release();
        } catch (_) {}
      }());
    }
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  //  Controls
  // ──────────────────────────────────────────────────────────────

  Future<void> setMicPublishMuted(bool muted) async {
    final e = _engine;
    if (e == null) return;
    try {
      await e.muteLocalAudioStream(muted);
      _micMuted = muted;
      notifyListeners();
    } catch (err, st) {
      developer.log('setMicPublishMuted', name: 'VETO.Agora', error: err, stackTrace: st);
    }
  }

  Future<void> setVideoPublishMuted(bool muted) async {
    final e = _engine;
    if (e == null) return;
    try {
      await e.muteLocalVideoStream(muted);
      _videoMuted = muted;
      notifyListeners();
    } catch (err, st) {
      developer.log('setVideoPublishMuted', name: 'VETO.Agora', error: err, stackTrace: st);
    }
  }

  /// Mobile only — no-op on web.
  Future<void> switchCamera() async {
    if (kIsWeb) return;
    try {
      await _engine?.switchCamera();
    } catch (err, st) {
      developer.log('switchCamera', name: 'VETO.Agora', error: err, stackTrace: st);
    }
  }

  /// Route audio to the loudspeaker. Mobile-only.
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
          _screenSharing = true;
        } else {
          // Mobile screen share skipped intentionally — would require a
          // foreground service on Android and RPSystemBroadcast on iOS.
          return;
        }
      }
      notifyListeners();
    } catch (err, st) {
      _emitError(CallErrorKind.mediaUnavailable, 'screen share: $err');
      developer.log('toggleScreenShare', name: 'VETO.Agora', error: err, stackTrace: st);
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  Internals
  // ──────────────────────────────────────────────────────────────

  void _setPhase(CallConnectionPhase next) {
    if (_phase == next) return;
    _phase = next;
    if (next == CallConnectionPhase.connected && _durationTimer == null) {
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _durationSec++;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _emitError(CallErrorKind kind, String msg) {
    _lastError = CallErrorEvent(kind, msg);
    if (!_errorCtrl.isClosed) _errorCtrl.add(_lastError!);
    notifyListeners();
  }

  RtcEngineEventHandler _buildEventHandler() {
    return RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection conn, int elapsed) {
        _retryAttempts = 0;
        _setPhase(CallConnectionPhase.connected);
        if (kIsWeb && _wantsVideo && !_videoMuted) {
          unawaited(_webStartPreviewSafe());
        }
      },
      onRejoinChannelSuccess: (RtcConnection conn, int elapsed) {
        _retryAttempts = 0;
        _setPhase(CallConnectionPhase.connected);
        if (kIsWeb && _wantsVideo && !_videoMuted) {
          unawaited(_webStartPreviewSafe());
        }
      },
      onUserJoined: (RtcConnection conn, int remoteUid, int elapsed) {
        _remoteUid = remoteUid;
        notifyListeners();
      },
      onUserOffline:
          (RtcConnection conn, int remoteUid, UserOfflineReasonType reason) {
        if (_remoteUid == remoteUid) {
          _remoteUid = null;
          _remoteVideoPlaying = false;
          notifyListeners();
        }
      },
      onRemoteVideoStateChanged: (
        RtcConnection conn,
        int remoteUid,
        RemoteVideoState state,
        RemoteVideoStateReason reason,
        int elapsed,
      ) {
        _remoteVideoPlaying = state == RemoteVideoState.remoteVideoStateDecoding ||
            state == RemoteVideoState.remoteVideoStateStarting;
        notifyListeners();
      },
      onFirstRemoteVideoFrame:
          (RtcConnection conn, int remoteUid, int width, int height, int elapsed) {
        _remoteVideoPlaying = true;
        notifyListeners();
      },
      onLocalVideoStateChanged: (
        VideoSourceType source,
        LocalVideoStreamState state,
        LocalVideoStreamReason reason,
      ) {
        if (state == LocalVideoStreamState.localVideoStreamStateCapturing ||
            state == LocalVideoStreamState.localVideoStreamStateEncoding) {
          _localPreviewOk = true;
          notifyListeners();
        } else if (state == LocalVideoStreamState.localVideoStreamStateFailed) {
          _localPreviewOk = false;
          _emitError(CallErrorKind.mediaUnavailable,
              'local video failed: ${reason.name}');
        }
      },
      onNetworkQuality: (
        RtcConnection conn,
        int uid,
        QualityType txQuality,
        QualityType rxQuality,
      ) {
        if (uid == 0) {
          _quality = NetworkQuality(
            up: txQuality.index,
            down: rxQuality.index,
            rttMs: _quality.rttMs,
            txKbps: _quality.txKbps,
          );
          notifyListeners();
        }
      },
      onRtcStats: (RtcConnection conn, RtcStats stats) {
        _quality = NetworkQuality(
          up: _quality.up,
          down: _quality.down,
          rttMs: stats.lastmileDelay ?? _quality.rttMs,
          txKbps: stats.txKBitRate ?? _quality.txKbps,
        );
        if (stats.duration != null && stats.duration! > 0) {
          _durationSec = stats.duration!;
        }
        notifyListeners();
      },
      onConnectionStateChanged: (
        RtcConnection conn,
        ConnectionStateType state,
        ConnectionChangedReasonType reason,
      ) {
        switch (state) {
          case ConnectionStateType.connectionStateReconnecting:
            _setPhase(CallConnectionPhase.reconnecting);
            break;
          case ConnectionStateType.connectionStateConnected:
            _setPhase(CallConnectionPhase.connected);
            break;
          case ConnectionStateType.connectionStateDisconnected:
          case ConnectionStateType.connectionStateFailed:
            _handleDisconnect(reason);
            break;
          case ConnectionStateType.connectionStateConnecting:
            _setPhase(CallConnectionPhase.connecting);
            break;
        }
      },
      onTokenPrivilegeWillExpire: (RtcConnection conn, String currentToken) {
        unawaited(_renewToken());
      },
      onRequestToken: (RtcConnection conn) {
        unawaited(_renewToken());
      },
      onError: (ErrorCodeType err, String msg) {
        final kind = _classifyError(err);
        _emitError(kind, '${err.name}: $msg');
      },
    );
  }

  CallErrorKind _classifyError(ErrorCodeType err) {
    switch (err) {
      case ErrorCodeType.errInvalidToken:
      case ErrorCodeType.errInvalidAppId:
        return CallErrorKind.tokenInvalid;
      case ErrorCodeType.errTokenExpired:
        return CallErrorKind.tokenExpired;
      case ErrorCodeType.errNoPermission:
        return CallErrorKind.permissionDenied;
      case ErrorCodeType.errConnectionLost:
      case ErrorCodeType.errConnectionInterrupted:
        return CallErrorKind.networkLost;
      default:
        return CallErrorKind.unknown;
    }
  }

  Future<void> _renewToken() async {
    final fetcher = _tokenFetcher;
    final eng = _engine;
    if (fetcher == null || eng == null) return;
    try {
      final fresh = await fetcher();
      if (fresh == null || fresh.isEmpty) return;
      _token = fresh;
      await eng.renewToken(fresh);
    } catch (err, st) {
      developer.log('renewToken', name: 'VETO.Agora', error: err, stackTrace: st);
      _emitError(CallErrorKind.tokenExpired, 'renewToken failed: $err');
    }
  }

  void _handleDisconnect(ConnectionChangedReasonType reason) {
    // When the engine reports a clean "leave channel" reason we should NOT
    // trigger the auto-retry loop — that's a local tear-down.
    if (reason ==
            ConnectionChangedReasonType.connectionChangedLeaveChannel ||
        reason == ConnectionChangedReasonType.connectionChangedBannedByServer) {
      _setPhase(CallConnectionPhase.left);
      return;
    }

    if (_retryAttempts >= _maxRetries) {
      _setPhase(CallConnectionPhase.failed);
      _emitError(
        CallErrorKind.connectionFailed,
        'connection failed after $_retryAttempts attempts (${reason.name})',
      );
      return;
    }

    _retryAttempts++;
    _setPhase(CallConnectionPhase.reconnecting);
    final backoff = Duration(milliseconds: 500 * (1 << (_retryAttempts - 1)));
    _retryTimer?.cancel();
    _retryTimer = Timer(backoff, () async {
      final eng = _engine;
      if (eng == null || _channelId == null) return;
      try {
        final wantCam = _wantsVideo && !_videoMuted;
        await eng.joinChannel(
          token: _token,
          channelId: _channelId!,
          uid: _localUid,
          options: ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            channelProfile: ChannelProfileType.channelProfileCommunication,
            publishCameraTrack: wantCam && !kIsWeb,
            publishMicrophoneTrack: !_micMuted,
            autoSubscribeAudio: true,
            autoSubscribeVideo: true,
          ),
        );
      } catch (err) {
        _emitError(CallErrorKind.connectionFailed, 'retry: $err');
      }
    });
  }

  Future<void> _webStartPreviewSafe() async {
    final eng = _engine;
    if (eng == null || !kIsWeb) return;
    try {
      await eng.startPreview();
      _localPreviewOk = true;
      if (_wantsVideo && !_videoMuted) {
        await eng.updateChannelMediaOptions(
          const ChannelMediaOptions(
            publishCameraTrack: true,
          ),
        );
      }
      notifyListeners();
    } catch (err, st) {
      _emitError(CallErrorKind.mediaUnavailable, 'web startPreview: $err');
      developer.log('web startPreview', name: 'VETO.Agora', error: err, stackTrace: st);
    }
  }
}
