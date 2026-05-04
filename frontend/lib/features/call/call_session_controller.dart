import 'dart:async';
import 'dart:developer' as developer;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

import '../../services/call_api_service.dart';
import '../../services/call_route_args_storage.dart';
import '../../services/in_call_permissions.dart';
import '../../services/socket_service.dart';
import 'call_args.dart';

const String kAgoraAppId = 'b40f2355783a4ccca027a91d0d7100ca';

enum CallUiPhase { idle, incoming, connecting, active, reconnecting, ended, error }

enum CallFailureKind {
  none,
  permissionDenied,
  tokenInvalid,
  tokenExpired,
  networkLost,
  connectionFailed,
  mediaUnavailable,
  unknown,
}

class CallFailure {
  const CallFailure(this.kind, this.message);
  final CallFailureKind kind;
  final String message;
}

class CallNetworkQuality {
  const CallNetworkQuality({
    this.up = 0,
    this.down = 0,
    this.rttMs = 0,
    this.txKbps = 0,
  });

  final int up;
  final int down;
  final int rttMs;
  final int txKbps;

  int get worst => up > down ? up : down;
}

class CallChatLine {
  const CallChatLine({required this.text, required this.mine});
  final String text;
  final bool mine;
}

class CallSessionController extends ChangeNotifier {
  CallSessionController({
    required this.args,
    CallApiService? callApi,
    SocketService? socket,
  })  : _callApi = callApi ?? CallApiService(),
        _socket = socket ?? SocketService();

  final CallArgs args;
  final CallApiService _callApi;
  final SocketService _socket;

  RtcEngine? _engine;
  String _token = '';
  int _localUid = 0;
  bool _wantsVideo = false;
  bool _joining = false;
  bool _joined = false;
  bool _leaving = false;
  bool _disposed = false;
  bool _socketRegistered = false;
  bool _joinCallRoomEmitted = false;
  bool _remoteHangup = false;
  int _retryAttempts = 0;
  static const int _maxRetries = 3;

  Timer? _durationTimer;
  Timer? _connectWatchdog;
  Timer? _retryTimer;

  CallUiPhase _phase = CallUiPhase.idle;
  CallFailure? _failure;
  int? _remoteUid;
  bool _remoteVideoReady = false;
  bool _localPreviewReady = false;
  bool _micMuted = false;
  bool _videoMuted = false;
  bool _speakerOn = true;
  bool _screenSharing = false;
  bool _noiseSuppression = true;
  int _durationSec = 0;
  CallNetworkQuality _quality = const CallNetworkQuality();
  final List<CallChatLine> _chatLines = <CallChatLine>[];

  RtcEngine? get engine => _engine;
  CallUiPhase get phase => _phase;
  CallFailure? get failure => _failure;
  int? get remoteUid => _remoteUid;
  bool get remoteVideoReady => _remoteVideoReady;
  bool get localPreviewReady => _localPreviewReady;
  bool get micMuted => _micMuted;
  bool get videoMuted => _videoMuted;
  bool get speakerOn => _speakerOn;
  bool get screenSharing => _screenSharing;
  bool get noiseSuppression => _noiseSuppression;
  int get durationSec => _durationSec;
  CallNetworkQuality get quality => _quality;
  List<CallChatLine> get chatLines => List.unmodifiable(_chatLines);
  bool get isActive =>
      _phase == CallUiPhase.active || _phase == CallUiPhase.reconnecting;

  Future<void> boot() async {
    if (_disposed) return;
    if (args.isIncoming) {
      _setPhase(CallUiPhase.incoming);
      return;
    }
    await connect();
  }

  Future<void> acceptIncoming() async {
    if (_disposed) return;
    await connect();
  }

  Future<void> declineIncoming() async {
    if (_disposed) return;
    try {
      _socket.emit('call-ended', {
        'roomId': args.channelId,
        'reason': 'declined',
      });
    } catch (_) {}
    callRouteArgsStorageClear();
    _setPhase(CallUiPhase.ended);
  }

  Future<void> connect() async {
    if (_disposed || _leaving) return;
    if (_joining || _joined || _phase == CallUiPhase.active) return;

    _failure = null;
    _setPhase(CallUiPhase.connecting);
    _connectWatchdog?.cancel();
    _connectWatchdog = Timer(const Duration(seconds: 45), () {
      if (_disposed || _phase != CallUiPhase.connecting) return;
      _setFatal(
        const CallFailure(
          CallFailureKind.connectionFailed,
          'Join timeout after 45s',
        ),
      );
    });

    try {
      final online = await _socket.ensureConnected(role: args.socketRole);
      if (!online) {
        _setFatal(const CallFailure(CallFailureKind.networkLost, 'Socket offline'));
        return;
      }
      _registerSocketHandlers();
      _emitJoinRoomOnce();

      if (args.chatOnly) {
        _connectWatchdog?.cancel();
        _startDurationTimer();
        _setPhase(CallUiPhase.active);
        return;
      }

      final permissions = await requestCallPermissions(wantVideo: args.wantVideo);
      if (!permissions.microphoneGranted) {
        _setFatal(
          const CallFailure(
            CallFailureKind.permissionDenied,
            'Microphone permission denied',
          ),
        );
        return;
      }

      final enableVideo = args.wantVideo && permissions.cameraGranted;
      await _joinAgora(enableVideo: enableVideo);
    } catch (err, st) {
      developer.log('connect', name: 'VETO.Call', error: err, stackTrace: st);
      _setFatal(CallFailure(CallFailureKind.connectionFailed, err.toString()));
    }
  }

  Future<void> retry() async {
    if (_disposed) return;
    await _leaveAgoraOnly();
    _joined = false;
    _joining = false;
    _retryAttempts = 0;
    _failure = null;
    await connect();
  }

  Future<void> endCall({bool fromRemote = false}) async {
    if (_disposed || _leaving) return;
    _leaving = true;
    _connectWatchdog?.cancel();
    _retryTimer?.cancel();
    _durationTimer?.cancel();
    _unregisterSocketHandlers();

    try {
      if (!fromRemote && !_remoteHangup) {
        _socket.emit('call-ended', {
          'roomId': args.channelId,
          'duration': _durationSec,
        });
      }
    } catch (_) {}

    await _leaveAndReleaseAgora();
    callRouteArgsStorageClear();
    _setPhase(CallUiPhase.ended);
  }

  Future<void> setMicMuted(bool muted) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.muteLocalAudioStream(muted);
      _micMuted = muted;
      notifyListeners();
    } catch (err, st) {
      developer.log('setMicMuted', name: 'VETO.Call', error: err, stackTrace: st);
    }
  }

  Future<void> setVideoMuted(bool muted) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.muteLocalVideoStream(muted);
      _videoMuted = muted;
      notifyListeners();
    } catch (err, st) {
      developer.log('setVideoMuted', name: 'VETO.Call', error: err, stackTrace: st);
    }
  }

  Future<void> switchCamera() async {
    if (kIsWeb) return;
    try {
      await _engine?.switchCamera();
    } catch (err, st) {
      developer.log('switchCamera', name: 'VETO.Call', error: err, stackTrace: st);
    }
  }

  Future<void> setSpeakerOn(bool on) async {
    if (kIsWeb) return;
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.setEnableSpeakerphone(on);
      _speakerOn = on;
      notifyListeners();
    } catch (err, st) {
      developer.log('setSpeakerOn', name: 'VETO.Call', error: err, stackTrace: st);
    }
  }

  Future<void> setNoiseSuppression(bool enabled) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.setAINSMode(
        enabled: enabled,
        mode: AudioAinsMode.ainsModeBalanced,
      );
      _noiseSuppression = enabled;
      notifyListeners();
    } catch (err, st) {
      developer.log(
        'setNoiseSuppression',
        name: 'VETO.Call',
        error: err,
        stackTrace: st,
      );
    }
  }

  Future<void> toggleScreenShare() async {
    final engine = _engine;
    if (engine == null || !kIsWeb) return;
    try {
      if (_screenSharing) {
        await engine.stopScreenCapture();
        _screenSharing = false;
      } else {
        await engine.startScreenCapture(
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
      }
      notifyListeners();
    } catch (err, st) {
      developer.log('toggleScreenShare', name: 'VETO.Call', error: err, stackTrace: st);
      _failure = CallFailure(CallFailureKind.mediaUnavailable, err.toString());
      notifyListeners();
    }
  }

  void sendChat(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      _socket.emit('call-chat-message', {
        'roomId': args.channelId,
        'text': trimmed,
      });
    } catch (_) {}
    _chatLines.add(CallChatLine(text: trimmed, mine: true));
    notifyListeners();
  }

  Future<void> _joinAgora({required bool enableVideo}) async {
    if (_joining || _joined) return;
    _joining = true;
    _token = args.token;
    _localUid = args.agoraUid;
    _wantsVideo = enableVideo;

    try {
      await _initEngine(enableVideoTrack: enableVideo);
      final engine = _engine;
      if (engine == null) return;

      await engine.joinChannel(
        token: _token,
        channelId: args.channelId,
        uid: _localUid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: enableVideo && !kIsWeb,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (err, st) {
      developer.log('joinAgora', name: 'VETO.Call', error: err, stackTrace: st);
      _joining = false;
      _setFatal(CallFailure(CallFailureKind.connectionFailed, err.toString()));
      rethrow;
    }
  }

  Future<void> _initEngine({required bool enableVideoTrack}) async {
    if (_engine != null) return;
    final engine = createAgoraRtcEngine();
    _engine = engine;
    await engine.initialize(
      const RtcEngineContext(
        appId: kAgoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    engine.registerEventHandler(_eventHandler());
    if (enableVideoTrack) {
      await engine.enableVideo();
    } else {
      await engine.disableVideo();
    }
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    try {
      await engine.setAINSMode(enabled: true, mode: AudioAinsMode.ainsModeBalanced);
      _noiseSuppression = true;
    } catch (_) {
      _noiseSuppression = false;
    }
    if (!kIsWeb && enableVideoTrack) {
      await engine.startPreview();
      _localPreviewReady = true;
    }
    notifyListeners();
  }

  RtcEngineEventHandler _eventHandler() {
    return RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _joining = false;
        _joined = true;
        _retryAttempts = 0;
        _connectWatchdog?.cancel();
        _retryTimer?.cancel();
        _startDurationTimer();
        _setPhase(CallUiPhase.active);
        if (kIsWeb && _wantsVideo && !_videoMuted) {
          unawaited(_webStartPreviewAndPublish());
        }
      },
      onRejoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _joining = false;
        _joined = true;
        _retryAttempts = 0;
        _retryTimer?.cancel();
        _setPhase(CallUiPhase.active);
        if (kIsWeb && _wantsVideo && !_videoMuted) {
          unawaited(_webStartPreviewAndPublish());
        }
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        if (_remoteUid != remoteUid) {
          _remoteVideoReady = false;
        }
        _remoteUid = remoteUid;
        notifyListeners();
        unawaited(_ensureRemoteVideoSubscribed(remoteUid));
      },
      onUserOffline: (
        RtcConnection connection,
        int remoteUid,
        UserOfflineReasonType reason,
      ) {
        if (_remoteUid == remoteUid) {
          _remoteUid = null;
          _remoteVideoReady = false;
          notifyListeners();
        }
      },
      onFirstRemoteVideoFrame: (
        RtcConnection connection,
        int remoteUid,
        int width,
        int height,
        int elapsed,
      ) {
        _remoteUid ??= remoteUid;
        _remoteVideoReady = true;
        notifyListeners();
      },
      onRemoteVideoStateChanged: (
        RtcConnection connection,
        int remoteUid,
        RemoteVideoState state,
        RemoteVideoStateReason reason,
        int elapsed,
      ) {
        if (_remoteUid == null) {
          _remoteUid = remoteUid;
        } else if (_remoteUid != remoteUid) {
          return;
        }
        switch (state) {
          case RemoteVideoState.remoteVideoStateStarting:
            break;
          case RemoteVideoState.remoteVideoStateDecoding:
          case RemoteVideoState.remoteVideoStateFrozen:
            _remoteVideoReady = true;
            break;
          case RemoteVideoState.remoteVideoStateFailed:
            _remoteVideoReady = false;
            break;
          case RemoteVideoState.remoteVideoStateStopped:
            break;
        }
        notifyListeners();
      },
      onLocalVideoStateChanged: (
        VideoSourceType source,
        LocalVideoStreamState state,
        LocalVideoStreamReason reason,
      ) {
        if (state == LocalVideoStreamState.localVideoStreamStateCapturing ||
            state == LocalVideoStreamState.localVideoStreamStateEncoding) {
          _localPreviewReady = true;
          notifyListeners();
        } else if (state == LocalVideoStreamState.localVideoStreamStateFailed) {
          _localPreviewReady = false;
          _failure = CallFailure(CallFailureKind.mediaUnavailable, reason.name);
          notifyListeners();
        }
      },
      onConnectionStateChanged: (
        RtcConnection connection,
        ConnectionStateType state,
        ConnectionChangedReasonType reason,
      ) {
        switch (state) {
          case ConnectionStateType.connectionStateConnected:
            _setPhase(CallUiPhase.active);
            break;
          case ConnectionStateType.connectionStateReconnecting:
            if (!_leaving) _setPhase(CallUiPhase.reconnecting);
            break;
          case ConnectionStateType.connectionStateDisconnected:
          case ConnectionStateType.connectionStateFailed:
            unawaited(_handleRtcDisconnect(reason));
            break;
          case ConnectionStateType.connectionStateConnecting:
            break;
        }
      },
      onNetworkQuality: (
        RtcConnection connection,
        int uid,
        QualityType txQuality,
        QualityType rxQuality,
      ) {
        if (uid == 0) {
          _quality = CallNetworkQuality(
            up: txQuality.index,
            down: rxQuality.index,
            rttMs: _quality.rttMs,
            txKbps: _quality.txKbps,
          );
          notifyListeners();
        }
      },
      onRtcStats: (RtcConnection connection, RtcStats stats) {
        _quality = CallNetworkQuality(
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
      onTokenPrivilegeWillExpire: (RtcConnection connection, String currentToken) {
        unawaited(_renewToken());
      },
      onRequestToken: (RtcConnection connection) {
        unawaited(_renewToken());
      },
      onError: (ErrorCodeType error, String message) {
        _failure = CallFailure(_classifyAgoraError(error), '${error.name}: $message');
        notifyListeners();
      },
    );
  }

  Future<void> _handleRtcDisconnect(ConnectionChangedReasonType reason) async {
    if (_disposed || _leaving) return;
    if (reason == ConnectionChangedReasonType.connectionChangedLeaveChannel) {
      return;
    }
    if (reason == ConnectionChangedReasonType.connectionChangedBannedByServer) {
      _setFatal(CallFailure(CallFailureKind.connectionFailed, reason.name));
      return;
    }
    if (_retryAttempts >= _maxRetries) {
      _setFatal(
        CallFailure(
          CallFailureKind.connectionFailed,
          'connection failed after $_retryAttempts retries (${reason.name})',
        ),
      );
      return;
    }
    _retryAttempts++;
    _setPhase(CallUiPhase.reconnecting);
    _retryTimer?.cancel();
    final backoff = Duration(milliseconds: 650 * (1 << (_retryAttempts - 1)));
    _retryTimer = Timer(backoff, () {
      unawaited(_rejoinAfterLeave());
    });
  }

  Future<void> _rejoinAfterLeave() async {
    final engine = _engine;
    if (_disposed || _leaving || engine == null) return;
    try {
      _joining = true;
      _joined = false;
      try {
        await engine.leaveChannel();
      } catch (_) {}
      if (kIsWeb) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      await engine.joinChannel(
        token: _token,
        channelId: args.channelId,
        uid: _localUid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: _wantsVideo && !kIsWeb && !_videoMuted,
          publishMicrophoneTrack: !_micMuted,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (err, st) {
      developer.log('rejoinAfterLeave', name: 'VETO.Call', error: err, stackTrace: st);
      _joining = false;
      _setFatal(CallFailure(CallFailureKind.connectionFailed, err.toString()));
    }
  }

  Future<void> _webStartPreviewAndPublish() async {
    final engine = _engine;
    if (engine == null || !kIsWeb || !_wantsVideo || _videoMuted) return;
    try {
      try {
        await engine.enableLocalVideo(true);
      } catch (_) {}
      await engine.startPreview();
      _localPreviewReady = true;
      await Future<void>.delayed(const Duration(milliseconds: 160));
      await engine.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
      notifyListeners();
    } catch (err, st) {
      developer.log('webStartPreviewAndPublish', name: 'VETO.Call', error: err, stackTrace: st);
      _failure = CallFailure(CallFailureKind.mediaUnavailable, err.toString());
      notifyListeners();
    }
  }

  Future<void> _ensureRemoteVideoSubscribed(int remoteUid) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.muteRemoteVideoStream(uid: remoteUid, mute: false);
    } catch (_) {}
    try {
      await engine.setRemoteVideoStreamType(
        uid: remoteUid,
        streamType: VideoStreamType.videoStreamHigh,
      );
    } catch (_) {}
  }

  Future<void> _renewToken() async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(args.eventId)) return;
    try {
      final fresh = await _callApi.fetchFreshAgoraToken(args.eventId);
      final nextToken = fresh?['agoraToken']?.toString();
      if (nextToken == null || nextToken.isEmpty) return;
      _token = nextToken;
      await _engine?.renewToken(nextToken);
    } catch (err, st) {
      developer.log('renewToken', name: 'VETO.Call', error: err, stackTrace: st);
      _failure = CallFailure(CallFailureKind.tokenExpired, err.toString());
      notifyListeners();
    }
  }

  CallFailureKind _classifyAgoraError(ErrorCodeType error) {
    switch (error) {
      case ErrorCodeType.errInvalidToken:
      case ErrorCodeType.errInvalidAppId:
        return CallFailureKind.tokenInvalid;
      case ErrorCodeType.errTokenExpired:
        return CallFailureKind.tokenExpired;
      case ErrorCodeType.errNoPermission:
        return CallFailureKind.permissionDenied;
      case ErrorCodeType.errConnectionLost:
      case ErrorCodeType.errConnectionInterrupted:
        return CallFailureKind.networkLost;
      default:
        return CallFailureKind.unknown;
    }
  }

  void _registerSocketHandlers() {
    if (_socketRegistered) return;
    _socket.on('call-ended', _onRemoteCallEnded);
    _socket.on('peer-left', _onRemotePeerLeft);
    _socket.on('call-chat-message', _onRemoteChat);
    _socket.on('call-timeout', _onCallTimeout);
    _socket.on('call-token-renewed', _onTokenRenewed);
    _socketRegistered = true;
  }

  void _unregisterSocketHandlers() {
    if (!_socketRegistered) return;
    _socket.removeHandler('call-ended', _onRemoteCallEnded);
    _socket.removeHandler('peer-left', _onRemotePeerLeft);
    _socket.removeHandler('call-chat-message', _onRemoteChat);
    _socket.removeHandler('call-timeout', _onCallTimeout);
    _socket.removeHandler('call-token-renewed', _onTokenRenewed);
    _socketRegistered = false;
  }

  void _emitJoinRoomOnce() {
    if (_joinCallRoomEmitted) return;
    _socket.emit('join-call-room', {
      'roomId': args.channelId,
      'callType': args.chatOnly ? 'chat' : (args.wantVideo ? 'video' : 'audio'),
    });
    _joinCallRoomEmitted = true;
  }

  Map<String, dynamic> _mapOf(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return <String, dynamic>{};
  }

  void _onRemoteCallEnded(dynamic _) {
    if (_disposed || _leaving) return;
    _remoteHangup = true;
    unawaited(endCall(fromRemote: true));
  }

  void _onRemotePeerLeft(dynamic _) {
    if (_disposed || _leaving) return;
    _remoteUid = null;
    _remoteVideoReady = false;
    notifyListeners();
  }

  void _onCallTimeout(dynamic raw) {
    if (_disposed || _phase == CallUiPhase.ended) return;
    final message = _mapOf(raw)['message']?.toString() ?? 'call-timeout';
    _setFatal(CallFailure(CallFailureKind.connectionFailed, message));
  }

  void _onTokenRenewed(dynamic raw) {
    final token = _mapOf(raw)['agoraToken']?.toString() ?? '';
    if (token.isEmpty) return;
    _token = token;
    unawaited(_engine?.renewToken(token));
  }

  void _onRemoteChat(dynamic raw) {
    final data = _mapOf(raw);
    final text = data['text']?.toString() ?? '';
    if (text.isEmpty) return;
    final from = data['fromRole']?.toString() ?? '';
    final meIsCitizen = args.socketRole == 'user' || args.socketRole == 'admin';
    final mine = meIsCitizen ? (from == 'user' || from == 'admin') : from == 'lawyer';
    if (mine) return;
    _chatLines.add(CallChatLine(text: text, mine: false));
    notifyListeners();
  }

  void _startDurationTimer() {
    _durationTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _durationSec++;
      notifyListeners();
    });
  }

  void _setPhase(CallUiPhase next) {
    if (_phase == next) return;
    _phase = next;
    notifyListeners();
  }

  void _setFatal(CallFailure failure) {
    _connectWatchdog?.cancel();
    _retryTimer?.cancel();
    _failure = failure;
    _joining = false;
    _setPhase(CallUiPhase.error);
  }

  Future<void> _leaveAgoraOnly() async {
    _retryTimer?.cancel();
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.leaveChannel();
    } catch (_) {}
    if (kIsWeb) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  Future<void> _leaveAndReleaseAgora() async {
    final engine = _engine;
    _engine = null;
    _joined = false;
    _joining = false;
    _remoteUid = null;
    _remoteVideoReady = false;
    _localPreviewReady = false;
    if (engine == null) return;
    try {
      await engine.leaveChannel();
    } catch (_) {}
    try {
      await engine.release();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _connectWatchdog?.cancel();
    _retryTimer?.cancel();
    _durationTimer?.cancel();
    _unregisterSocketHandlers();
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      unawaited(() async {
        try {
          await engine.leaveChannel();
        } catch (_) {}
        try {
          await engine.release();
        } catch (_) {}
      }());
    }
    super.dispose();
  }
}
