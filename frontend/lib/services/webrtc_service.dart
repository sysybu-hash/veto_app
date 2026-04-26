// ============================================================
//  webrtc_service.dart — WebRTC Peer-to-Peer Call Service
//  VETO Legal Emergency App
//
//  Supports: audio-only calls and video calls
//  Platform:  Flutter Web + iOS + Android (flutter_webrtc)
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'socket_service.dart';
import 'webrtc_ice_config_service.dart';
import 'webrtc_settings_store.dart';
import 'webrtc_user_settings.dart';

enum CallState { idle, joining, ringing, connected, ended, error }
enum CallType { audio, video }

class WebRTCService extends ChangeNotifier {
  final SocketService _socket;

  CallState _state = CallState.idle;
  CallType _callType = CallType.video;
  String? _roomId;
  String? _peerSocketId;

  bool _micMuted = false;
  bool _cameraOff = false;
  final bool _isRecording = false;
  int _callDuration = 0;
  Timer? _durationTimer;
  String? _errorMessage;

  bool _isTearingDown = false;
  bool _mediaTornDown = false;
  /// Prevents duplicate [CallState.ended] / teardown when local + remote race.
  bool _sessionFinished = false;
  bool _isCaller = false;
  /// After [silenceNativeEvents], suppresses [notifyListeners] during route exit.
  bool _isExitingService = false;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  CallState get state => _state;
  CallType get callType => _callType;
  String? get roomId => _roomId;
  bool get micMuted => _micMuted;
  bool get cameraOff => _cameraOff;
  bool get isRecording => _isRecording;
  int get callDuration => _callDuration;
  bool get hasVideo => _callType == CallType.video && !_cameraOff;
  String? get errorMessage => _errorMessage;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  WebRTCService(this._socket) {
    _registerSocketHandlers();
  }

  static void _logError(String where, Object e, StackTrace st) {
    developer.log(
      where,
      name: 'VETO.WebRTC',
      error: e,
      stackTrace: st,
    );
    debugPrint('[WebRTC] $where\nError: $e\nStackTrace:\n$st');
  }

  Future<void> initRenderers() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    } catch (e, st) {
      _logError('initRenderers', e, st);
      rethrow;
    }
  }

  Future<void> joinRoom(
    String roomId,
    CallType callType, {
    required String socketRole,
  }) async {
    _isTearingDown = false;
    _mediaTornDown = false;
    _sessionFinished = false;
    _isExitingService = false;
    _roomId = roomId;
    _callType = callType;
    _errorMessage = null;
    _setState(CallState.joining);

    try {
      final online = await _socket.ensureConnected(role: socketRole);
      if (!online) {
        _setError(
          'Could not connect to the server. Check your network and try again.',
        );
        return;
      }
      await initRenderers();
      _socket.emit('join-call-room', {
        'roomId': roomId,
        'callType': callType == CallType.video ? 'video' : 'audio',
      });
    } catch (e, st) {
      _logError('joinRoom', e, st);
      _setError('Failed to join the call room.');
    }
  }

  Future<void> _initCall(bool isCaller, String? peerSocketId) async {
    _peerSocketId = peerSocketId;

    final WebRtcUserSettings mediaPrefs =
        await WebRtcSettingsStore.instance.load();

    final constraints = mediaPrefs.mediaConstraints(
      wantVideo: _callType == CallType.video,
    );

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    } catch (e, st) {
      _logError('getUserMedia', e, st);
      _setError(
        _callType == CallType.video
            ? 'Camera or microphone permission was denied.'
            : 'Microphone permission was denied.',
      );
      rethrow;
    }

    final local = _localStream;
    if (local == null) {
      debugPrint('[WebRTC] _initCall: local stream null after getUserMedia');
      _setError('Could not access microphone or camera.');
      return;
    }

    try {
      localRenderer.srcObject = local;
    } catch (e, st) {
      _logError('localRenderer.srcObject', e, st);
    }

    final rtcCfg = Map<String, dynamic>.from(
      mediaPrefs.peerConnectionConfiguration(),
    );
    final serverIce = await WebRtcIceConfigService.instance.fetchServerIceServers();
    if (serverIce != null && serverIce.isNotEmpty) {
      final localIce = rtcCfg['iceServers'];
      if (localIce is List) {
        rtcCfg['iceServers'] = <dynamic>[...localIce, ...serverIce];
      } else {
        rtcCfg['iceServers'] = serverIce;
      }
    }
    rtcCfg['sdpSemantics'] = 'unified-plan';

    RTCPeerConnection? pc;
    try {
      pc = await createPeerConnection(rtcCfg);
      _pc = pc;
    } catch (e, st) {
      _logError('createPeerConnection', e, st);
      _setError('Could not create peer connection.');
      return;
    }

    try {
      final tracks = local.getTracks();
      for (final track in tracks) {
        try {
          await pc.addTrack(track, local);
        } catch (e, st) {
          _logError('addTrack', e, st);
        }
      }
    } catch (e, st) {
      _logError('_initCall add tracks loop', e, st);
    }

    pc.onTrack = (event) {
      try {
        if (_isTearingDown || _mediaTornDown) return;
        if (event.streams.isEmpty) return;
        _remoteStream = event.streams.first;
        try {
          remoteRenderer.srcObject = _remoteStream;
        } catch (e, st) {
          _logError('onTrack remoteRenderer.srcObject', e, st);
        }
        _notifyListenersIfActive();
      } catch (e, st) {
        _logError('onTrack', e, st);
      }
    };

    pc.onIceCandidate = (candidate) {
      try {
        if (_isTearingDown || _mediaTornDown) return;
        if (candidate.candidate == null) return;
        if (!_socket.isConnected) return;
        try {
          _socket.emit('ice-candidate', {
            'roomId': _roomId,
            'candidate': candidate.toMap(),
            'targetSocketId': _peerSocketId,
          });
        } catch (e, st) {
          _logError('onIceCandidate emit', e, st);
        }
      } catch (e, st) {
        _logError('onIceCandidate', e, st);
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      try {
        if (_isTearingDown || _mediaTornDown) return;
        developer.log('Connection state: $state', name: 'VETO.WebRTC');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _errorMessage = null;
          _setState(CallState.connected);
          _startDurationTimer();
          return;
        }
        // Ignore RTCPeerConnectionStateDisconnected — often transient on Web (ICE restart).
        final fatal = state ==
                RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed;
        if (!fatal) return;
        if (_isTearingDown || _mediaTornDown) return;
        final inCall = _state == CallState.connected ||
            _state == CallState.ringing;
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed &&
            !inCall) {
          return;
        }
        developer.log(
          'Connection fatally lost or closed; surfacing error to UI.',
          name: 'VETO.WebRTC',
        );
        _setError(
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed
              ? 'Peer connection failed.'
              : 'Peer connection closed.',
        );
      } catch (e, st) {
        _logError('onConnectionState', e, st);
      }
    };

    if (isCaller) {
      try {
        if (_isTearingDown || _mediaTornDown) return;
        final offer = await pc.createOffer({
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': _callType == CallType.video,
        });
        await pc.setLocalDescription(offer);
        if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
        if (!_socket.isConnected) return;
        _socket.emit('webrtc-offer', {
          'roomId': _roomId,
          'offer': offer.toMap(),
          'targetSocketId': _peerSocketId,
        });
      } catch (e, st) {
        _logError('createOffer / emit offer', e, st);
        _setError('Could not start the call negotiation.');
      }
    }
  }

  Future<void> _onSocketRoomJoined(dynamic data) async {
    try {
      if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
      final raw = data['isCaller'];
      final isCaller = raw == true || raw == 'true';
      debugPrint('[WebRTC] Room joined | isCaller=$isCaller');
      _isCaller = isCaller;
      _setState(CallState.ringing);
    } catch (e, st) {
      _logError('socket room-joined', e, st);
    }
  }

  Future<void> _onSocketPeerJoined(dynamic data) async {
    try {
      if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
      final peerSocketId = data['socketId']?.toString();
      debugPrint('[WebRTC] Peer joined: $peerSocketId');
      if (!_isCaller || peerSocketId == null || peerSocketId.isEmpty) return;
      if (_pc != null) return;
      if (_state != CallState.joining && _state != CallState.ringing) return;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
      try {
        await _initCall(true, peerSocketId);
      } catch (e, st) {
        _logError('peer-joined _initCall', e, st);
        _setError('Could not start the call.');
      }
    } catch (e, st) {
      _logError('socket peer-joined', e, st);
    }
  }

  Future<void> _onSocketWebrtcOffer(dynamic data) async {
    try {
      if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
      final fromSid = data['fromSocketId']?.toString();
      if (_pc == null) {
        await _initCall(false, fromSid);
      }
      if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
      final pc = _pc;
      if (pc == null) {
        debugPrint('[WebRTC] webrtc-offer: peer connection is null');
        return;
      }
      _peerSocketId = fromSid;
      final offerMap = Map<String, dynamic>.from(data['offer']);
      await pc.setRemoteDescription(
        RTCSessionDescription(offerMap['sdp'], offerMap['type']),
      );
      final wantVideo = _callType == CallType.video;
      final answer = await pc.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': wantVideo,
      });
      await pc.setLocalDescription(answer);
      if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
      if (!_socket.isConnected) return;
      _socket.emit('webrtc-answer', {
        'roomId': _roomId,
        'answer': answer.toMap(),
        'targetSocketId': _peerSocketId,
      });
    } catch (e, st) {
      _logError('webrtc-offer handler', e, st);
      _setError('Could not process the incoming call offer.');
    }
  }

  Future<void> _onSocketWebrtcAnswer(dynamic data) async {
    try {
      if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
      final pc = _pc;
      if (pc == null) return;
      final answerMap = Map<String, dynamic>.from(data['answer']);
      await pc.setRemoteDescription(
        RTCSessionDescription(answerMap['sdp'], answerMap['type']),
      );
    } catch (e, st) {
      _logError('webrtc-answer handler', e, st);
      _setError('Could not process the call answer.');
    }
  }

  Future<void> _onSocketIceCandidate(dynamic data) async {
    try {
      if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
      final pc = _pc;
      if (pc == null) return;
      final candMap = Map<String, dynamic>.from(data['candidate']);
      try {
        await pc.addCandidate(
          RTCIceCandidate(
            candMap['candidate'],
            candMap['sdpMid'],
            candMap['sdpMLineIndex'],
          ),
        );
      } catch (e, st) {
        if (_isTearingDown || _mediaTornDown) return;
        _logError('ice-candidate addCandidate', e, st);
      }
    } catch (e, st) {
      _logError('ice-candidate handler', e, st);
    }
  }

  void _onSocketCallError(dynamic data) {
    try {
      if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
      String? message;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        message = map['message']?.toString();
      }
      _setError(message ?? 'Failed to join the call.');
    } catch (e, st) {
      _logError('call-error handler', e, st);
    }
  }

  void _onSocketPeerMediaToggle(dynamic data) {
    try {
      if (_isTearingDown || _mediaTornDown || _sessionFinished) return;
      _notifyListenersIfActive();
    } catch (e, st) {
      _logError('peer-media-toggle', e, st);
    }
  }

  void _onSocketCallEndedEvent(dynamic _) {
    unawaited(() async {
      try {
        if (_sessionFinished) return;
        await _onCallEnded(remote: true);
      } catch (e, st) {
        _logError('_onCallEnded(remote from call-ended)', e, st);
      }
    }());
  }

  void _onSocketPeerLeft(dynamic _) {
    unawaited(() async {
      try {
        if (_sessionFinished) return;
        await _onCallEnded(remote: true);
      } catch (e, st) {
        _logError('_onCallEnded(remote from peer-left)', e, st);
      }
    }());
  }

  void _unregisterCallSocketHandlers() {
    try {
      _socket.removeHandler('room-joined', _onSocketRoomJoined);
      _socket.removeHandler('peer-joined', _onSocketPeerJoined);
      _socket.removeHandler('webrtc-offer', _onSocketWebrtcOffer);
      _socket.removeHandler('webrtc-answer', _onSocketWebrtcAnswer);
      _socket.removeHandler('ice-candidate', _onSocketIceCandidate);
      _socket.removeHandler('call-error', _onSocketCallError);
      _socket.removeHandler('peer-media-toggle', _onSocketPeerMediaToggle);
      _socket.removeHandler('call-ended', _onSocketCallEndedEvent);
      _socket.removeHandler('peer-left', _onSocketPeerLeft);
    } catch (e, st) {
      _logError('_unregisterCallSocketHandlers', e, st);
    }
  }

  /// Null all peer-connection delegates during internal teardown (full sever).
  void _nullPeerConnectionHandlers() {
    final pc = _pc;
    if (pc == null) return;
    try {
      pc.onIceCandidate = null;
      pc.onTrack = null;
      pc.onConnectionState = null;
      pc.onIceConnectionState = null;
      pc.onSignalingState = null;
      pc.onIceGatheringState = null;
      pc.onAddStream = null;
      pc.onRemoveStream = null;
      pc.onAddTrack = null;
      pc.onRemoveTrack = null;
      pc.onDataChannel = null;
      pc.onRenegotiationNeeded = null;
    } catch (e, st) {
      _logError('_nullPeerConnectionHandlers', e, st);
    }
  }

  /// Blackout: clear renderer [srcObject] first (Web), stop tracks, mute notifications, null PC handlers.
  void silenceNativeEvents() {
    try {
      localRenderer.srcObject = null;
    } catch (e, st) {
      _logError('silenceNativeEvents localRenderer.srcObject', e, st);
    }
    try {
      remoteRenderer.srcObject = null;
    } catch (e, st) {
      _logError('silenceNativeEvents remoteRenderer.srcObject', e, st);
    }
    _localStream?.getTracks().forEach((t) => t.stop());
    _remoteStream?.getTracks().forEach((t) => t.stop());
    _isExitingService = true;
    final pc = _pc;
    if (pc != null) {
      pc.onIceCandidate = null;
      pc.onTrack = null;
      pc.onConnectionState = null;
      pc.onIceConnectionState = null;
      pc.onSignalingState = null;
    }
  }

  void _notifyListenersIfActive() {
    if (_isExitingService) return;
    notifyListeners();
  }

  /// Stops native callbacks from reaching Dart during internal teardown.
  void _suppressPeerConnectionCallbacks() => _nullPeerConnectionHandlers();

  void _registerSocketHandlers() {
    _socket.on('room-joined', _onSocketRoomJoined);
    _socket.on('peer-joined', _onSocketPeerJoined);
    _socket.on('webrtc-offer', _onSocketWebrtcOffer);
    _socket.on('webrtc-answer', _onSocketWebrtcAnswer);
    _socket.on('ice-candidate', _onSocketIceCandidate);
    _socket.on('call-error', _onSocketCallError);
    _socket.on('peer-media-toggle', _onSocketPeerMediaToggle);
    _socket.on('call-ended', _onSocketCallEndedEvent);
    _socket.on('peer-left', _onSocketPeerLeft);
  }

  void toggleMic() {
    try {
      if (_isTearingDown || _mediaTornDown) return;
      _micMuted = !_micMuted;
      final stream = _localStream;
      if (stream != null) {
        for (final t in stream.getAudioTracks()) {
          try {
            t.enabled = !_micMuted;
          } catch (e, st) {
            _logError('toggleMic track', e, st);
          }
        }
      }
      _socket.emit('media-toggle', {
        'roomId': _roomId,
        'audio': !_micMuted,
        'video': !_cameraOff,
      });
      _notifyListenersIfActive();
    } catch (e, st) {
      _logError('toggleMic', e, st);
    }
  }

  void toggleCamera() {
    try {
      if (_isTearingDown || _mediaTornDown) return;
      _cameraOff = !_cameraOff;
      final stream = _localStream;
      if (stream != null) {
        for (final t in stream.getVideoTracks()) {
          try {
            t.enabled = !_cameraOff;
          } catch (e, st) {
            _logError('toggleCamera track', e, st);
          }
        }
      }
      _socket.emit('media-toggle', {
        'roomId': _roomId,
        'audio': !_micMuted,
        'video': !_cameraOff,
      });
      _notifyListenersIfActive();
    } catch (e, st) {
      _logError('toggleCamera', e, st);
    }
  }

  Future<void> switchCamera() async {
    try {
      if (_isTearingDown || _mediaTornDown) return;
      if (_callType != CallType.video) return;
      final stream = _localStream;
      final videoTracks = stream?.getVideoTracks();
      if (videoTracks != null && videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks.first);
      }
    } catch (e, st) {
      _logError('switchCamera', e, st);
    }
  }

  Future<void> endCall() async {
    silenceNativeEvents();
    try {
      await _onCallEnded(remote: false);
      try {
        _socket.emit('call-ended', {
          'roomId': _roomId,
          'duration': _callDuration,
        });
      } catch (e, st) {
        _logError('endCall emit call-ended', e, st);
      }
    } catch (e, st) {
      _logError('endCall', e, st);
    }
  }

  Future<void> _onCallEnded({required bool remote}) async {
    try {
      if (_sessionFinished) return;
      _sessionFinished = true;
      _isTearingDown = true;
      _stopDurationTimer();
      _suppressPeerConnectionCallbacks();
      _setState(CallState.ended);
      try {
        _unregisterCallSocketHandlers();
      } catch (e, st) {
        _logError('_onCallEnded unregister', e, st);
      }
    } catch (e, st) {
      _logError('_onCallEnded(remote=$remote)', e, st);
    }
  }

  /// Stops tracks and releases the native stream (flutter_webrtc Web best practice).
  Future<void> _disposeStreamFully(MediaStream? stream) async {
    if (stream == null) return;
    try {
      for (final t in stream.getTracks()) {
        try {
          t.stop();
        } catch (e, st) {
          _logError('_disposeStreamFully track.stop', e, st);
        }
      }
    } catch (e, st) {
      _logError('_disposeStreamFully getTracks', e, st);
    }
    try {
      await stream.dispose();
    } catch (e, st) {
      _logError('_disposeStreamFully stream.dispose', e, st);
    }
  }

  Future<void> completeMediaTeardown() async {
    if (_mediaTornDown) return;
    try {
      _mediaTornDown = true;
      developer.log('Starting async media teardown', name: 'VETO.WebRTC');
      _suppressPeerConnectionCallbacks();
      final pc = _pc;
      _pc = null;
      if (pc != null) {
        try {
          await pc.close();
        } catch (e, st) {
          _logError('completeMediaTeardown pc.close', e, st);
        }
      }

      final loc = _localStream;
      _localStream = null;
      await _disposeStreamFully(loc);

      final rem = _remoteStream;
      _remoteStream = null;
      await _disposeStreamFully(rem);

      developer.log('Async media teardown complete', name: 'VETO.WebRTC');
    } catch (e, st) {
      _logError('completeMediaTeardown', e, st);
    }
  }

  /// Used from [dispose]: cannot await [close] / [MediaStream.dispose]; schedule async work.
  void _syncTeardownMedia() {
    if (_mediaTornDown) return;
    try {
      _mediaTornDown = true;
      developer.log('Starting sync-scheduled media teardown', name: 'VETO.WebRTC');
      _suppressPeerConnectionCallbacks();
      final pc = _pc;
      _pc = null;
      if (pc != null) {
        unawaited(() async {
          try {
            await pc.close();
          } catch (e, st) {
            _logError('_syncTeardownMedia pc.close', e, st);
          }
        }());
      }

      final loc = _localStream;
      _localStream = null;
      unawaited(_disposeStreamFully(loc));

      final rem = _remoteStream;
      _remoteStream = null;
      unawaited(_disposeStreamFully(rem));
      // [silenceNativeEvents] may already have cleared renderer srcObject; finish streams & PC here.
    } catch (e, st) {
      _logError('_syncTeardownMedia', e, st);
    }
  }

  void _startDurationTimer() {
    try {
      _callDuration = 0;
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        try {
          _callDuration++;
          _notifyListenersIfActive();
        } catch (e, st) {
          _logError('_startDurationTimer tick', e, st);
        }
      });
    } catch (e, st) {
      _logError('_startDurationTimer', e, st);
    }
  }

  void _stopDurationTimer() {
    try {
      _durationTimer?.cancel();
      _durationTimer = null;
    } catch (e, st) {
      _logError('_stopDurationTimer', e, st);
    }
  }

  String get formattedDuration {
    final minutes = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _setState(CallState s) {
    try {
      _state = s;
      // [CallScreen] must observe [CallState.ended] once to run [_finalizeAndNavigate] after [endCall].
      if (s == CallState.ended) {
        notifyListeners();
      } else {
        _notifyListenersIfActive();
      }
    } catch (e, st) {
      _logError('_setState', e, st);
    }
  }

  void _setError(String message) {
    try {
      _errorMessage = message;
      _state = CallState.error;
      _notifyListenersIfActive();
    } catch (e, st) {
      _logError('_setError', e, st);
    }
  }

  @override
  void dispose() {
    try {
      silenceNativeEvents();
    } catch (e, st) {
      _logError('dispose silenceNativeEvents', e, st);
    }

    developer.log(
      'WebRTCService: Starting dispose sequence',
      name: 'VETO.WebRTC',
    );

    try {
      _stopDurationTimer();
    } catch (e, st) {
      _logError('dispose _stopDurationTimer', e, st);
    }

    // 1. Sync teardown of media channels; 2. drop signaling listeners
    try {
      _syncTeardownMedia();
    } catch (e, st) {
      _logError('dispose _syncTeardownMedia', e, st);
    }
    try {
      _unregisterCallSocketHandlers();
    } catch (e, st) {
      _logError('dispose _unregisterCallSocketHandlers', e, st);
    }

    super.dispose();
  }
}
