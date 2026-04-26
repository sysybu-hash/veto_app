// ============================================================
//  webrtc_service.dart — WebRTC Peer-to-Peer Call Service
//  VETO Legal Emergency App
//
//  Supports: audio-only calls and video calls
//  Platform:  Flutter Web + iOS + Android (flutter_webrtc)
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';
import 'webrtc_ice_config_service.dart';
import 'webrtc_settings_store.dart';
import 'webrtc_user_settings.dart';

enum CallState { idle, joining, ringing, connected, ended, error }
enum CallType  { audio, video }

class WebRTCService extends ChangeNotifier {
  // ── Dependencies ──────────────────────────────────────────
  final SocketService _socket;

  // ── Call state ────────────────────────────────────────────
  CallState _state      = CallState.idle;
  CallType  _callType   = CallType.video;
  String?   _roomId;
  String?   _peerSocketId;

  bool _micMuted        = false;
  bool _cameraOff       = false;
  final bool _isRecording = false;
  int  _callDuration    = 0;
  Timer? _durationTimer;
  String? _errorMessage;

  /// True while we intentionally tear down the peer connection (avoid treating
  /// `disconnected` from `close()` as a user-visible failure; also reduces duplicate notifies).
  bool _isTearingDown = false;

  /// After [completeMediaTeardown] or [dispose]; avoids double-close.
  bool _mediaTornDown = false;

  /// Set by `room-joined`: first peer creates the offer only after `peer-joined`.
  bool _isCaller = false;

  // ── WebRTC objects ────────────────────────────────────────
  RTCPeerConnection? _pc;
  MediaStream?       _localStream;
  MediaStream?       _remoteStream;

  final RTCVideoRenderer localRenderer  = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // ── Getters ───────────────────────────────────────────────
  CallState get state        => _state;
  CallType  get callType     => _callType;
  String?   get roomId       => _roomId;
  bool      get micMuted     => _micMuted;
  bool      get cameraOff    => _cameraOff;
  bool      get isRecording  => _isRecording;
  int       get callDuration => _callDuration;
  bool      get hasVideo     => _callType == CallType.video && !_cameraOff;
  String?   get errorMessage => _errorMessage;
  MediaStream? get localStream  => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  WebRTCService(this._socket) {
    _registerSocketHandlers();
  }

  // ═══════════════════════════════════════════════════════════
  //  Initialize renderers
  // ═══════════════════════════════════════════════════════════
  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  // ═══════════════════════════════════════════════════════════
  //  Start a call (join room)
  // ═══════════════════════════════════════════════════════════
  Future<void> joinRoom(
    String roomId,
    CallType callType, {
    required String socketRole,
  }) async {
    _isTearingDown = false;
    _mediaTornDown = false;
    _roomId    = roomId;
    _callType  = callType;
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
        'roomId':   roomId,
        'callType': callType == CallType.video ? 'video' : 'audio',
      });
    } catch (e) {
      debugPrint('[WebRTC] joinRoom error: $e');
      _setError('Failed to join the call room.');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  Get user media and init peer connection
  // ═══════════════════════════════════════════════════════════
  Future<void> _initCall(bool isCaller, String? peerSocketId) async {
    _peerSocketId = peerSocketId;

    final WebRtcUserSettings mediaPrefs =
        await WebRtcSettingsStore.instance.load();

    // ── Get local media (constraints from Settings) ───────────
    final constraints = mediaPrefs.mediaConstraints(
      wantVideo: _callType == CallType.video,
    );

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    } catch (e) {
      debugPrint('[WebRTC] getUserMedia failed: $e');
      _setError(
        _callType == CallType.video
            ? 'Camera or microphone permission was denied.'
            : 'Microphone permission was denied.',
      );
      rethrow;
    }
    localRenderer.srcObject = _localStream;

    // ── Create peer connection (local STUN + optional server TURN) ─
    final rtcCfg = Map<String, dynamic>.from(
      mediaPrefs.peerConnectionConfiguration(),
    );
    final serverIce = await WebRtcIceConfigService.instance.fetchServerIceServers();
    if (serverIce != null && serverIce.isNotEmpty) {
      final local = rtcCfg['iceServers'];
      if (local is List) {
        rtcCfg['iceServers'] = <dynamic>[...local, ...serverIce];
      } else {
        rtcCfg['iceServers'] = serverIce;
      }
    }
    rtcCfg['sdpSemantics'] = 'unified-plan';
    _pc = await createPeerConnection(rtcCfg);

    // Add local tracks
    _localStream!.getTracks().forEach((track) {
      _pc!.addTrack(track, _localStream!);
    });

    // Remote stream
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream       = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        notifyListeners();
      }
    };

    // ICE candidates
    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _socket.emit('ice-candidate', {
          'roomId':         _roomId,
          'candidate':      candidate.toMap(),
          'targetSocketId': _peerSocketId,
        });
      }
    };

    // Connection state
    _pc!.onConnectionState = (state) {
      debugPrint('[WebRTC] Connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _errorMessage = null;
        _setState(CallState.connected);
        _startDurationTimer();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (!_isTearingDown) {
          _setError('Peer connection failed.');
        }
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        // `close()` often emits disconnected/closed; do not overwrite a clean [ended] with [error].
        if (!_isTearingDown &&
            (_state == CallState.connected || _state == CallState.ringing)) {
          _setError('Peer connection failed.');
        }
      }
    };

    // ── Caller creates offer, callee waits for offer ──────────
    if (isCaller) {
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': _callType == CallType.video,
      });
      await _pc!.setLocalDescription(offer);
      _socket.emit('webrtc-offer', {
        'roomId':         _roomId,
        'offer':          offer.toMap(),
        'targetSocketId': _peerSocketId,
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  Socket event handlers
  // ═══════════════════════════════════════════════════════════
  void _registerSocketHandlers() {
    // Room joined — now we know if we're caller or callee
    _socket.on('room-joined', (data) async {
      final raw = data['isCaller'];
      final isCaller = raw == true || raw == 'true';
      debugPrint('[WebRTC] Room joined | isCaller=$isCaller');
      _isCaller = isCaller;
      _setState(CallState.ringing);
      // Caller must NOT create an offer here — the room has no peer yet, so the
      // offer would be broadcast to nobody. Callee waits for `webrtc-offer`.
    });

    // Second peer joined: only the caller creates the offer, now that we have a target.
    _socket.on('peer-joined', (data) async {
      final peerSocketId = data['socketId']?.toString();
      debugPrint('[WebRTC] Peer joined: $peerSocketId');
      if (!_isCaller || peerSocketId == null || peerSocketId.isEmpty) return;
      if (_pc != null) return;
      if (_state != CallState.joining && _state != CallState.ringing) return;
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        await _initCall(true, peerSocketId);
      } catch (e, st) {
        debugPrint('[WebRTC] Caller init failed: $e\n$st');
        _setError('Could not start the call.');
      }
    });

    // Received offer (callee side)
    _socket.on('webrtc-offer', (data) async {
      try {
        final fromSid = data['fromSocketId']?.toString();
        if (_pc == null) {
          // Init without creating offer (we're callee)
          await _initCall(false, fromSid);
        }
        _peerSocketId = fromSid;
        final offerMap = Map<String, dynamic>.from(data['offer']);
        await _pc!.setRemoteDescription(
          RTCSessionDescription(offerMap['sdp'], offerMap['type']),
        );
        final wantVideo = _callType == CallType.video;
        final answer = await _pc!.createAnswer({
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': wantVideo,
        });
        await _pc!.setLocalDescription(answer);
        _socket.emit('webrtc-answer', {
          'roomId':         _roomId,
          'answer':         answer.toMap(),
          'targetSocketId': _peerSocketId,
        });
      } catch (e) {
        debugPrint('[WebRTC] Handle offer error: $e');
        _setError('Could not process the incoming call offer.');
      }
    });

    // Received answer (caller side)
    _socket.on('webrtc-answer', (data) async {
      try {
        final answerMap = Map<String, dynamic>.from(data['answer']);
        await _pc!.setRemoteDescription(
          RTCSessionDescription(answerMap['sdp'], answerMap['type']),
        );
      } catch (e) {
        debugPrint('[WebRTC] Handle answer error: $e');
        _setError('Could not process the call answer.');
      }
    });

    // ICE candidate
    _socket.on('ice-candidate', (data) async {
      try {
        if (_pc == null) return;
        final candMap = Map<String, dynamic>.from(data['candidate']);
        await _pc!.addCandidate(
          RTCIceCandidate(
            candMap['candidate'],
            candMap['sdpMid'],
            candMap['sdpMLineIndex'],
          ),
        );
      } catch (e) {
        debugPrint('[WebRTC] ICE candidate error: $e');
      }
    });

    _socket.on('call-error', (data) {
      String? message;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        message = map['message']?.toString();
      }
      _setError(message ?? 'Failed to join the call.');
    });

    // Peer toggled media
    _socket.on('peer-media-toggle', (data) {
      notifyListeners();
    });

    // Peer left / call ended by other side
    _socket.on('call-ended', (data) {
      _onCallEnded(remote: true);
    });

    _socket.on('peer-left', (data) {
      _onCallEnded(remote: true);
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  Controls
  // ═══════════════════════════════════════════════════════════
  void toggleMic() {
    _micMuted = !_micMuted;
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !_micMuted);
    _socket.emit('media-toggle', {'roomId': _roomId, 'audio': !_micMuted, 'video': !_cameraOff});
    notifyListeners();
  }

  void toggleCamera() {
    _cameraOff = !_cameraOff;
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !_cameraOff);
    _socket.emit('media-toggle', {'roomId': _roomId, 'audio': !_micMuted, 'video': !_cameraOff});
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (_callType != CallType.video) return;
    final videoTracks = _localStream?.getVideoTracks();
    if (videoTracks != null && videoTracks.isNotEmpty) {
      await Helper.switchCamera(videoTracks.first);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  End call
  // ═══════════════════════════════════════════════════════════
  Future<void> endCall() async {
    _socket.emit('call-ended', {
      'roomId':   _roomId,
      'duration': _callDuration,
    });
    await _onCallEnded(remote: false);
  }

  /// Ends signaling state only — leaves PC/tracks alive so the browser [MediaRecorder]
  /// can flush WebM after the call (see CallScreen._finalizeAndNavigate).
  Future<void> _onCallEnded({required bool remote}) async {
    _isTearingDown = true;
    _stopDurationTimer();
    _setState(CallState.ended);
  }

  /// Close peer connection and stop tracks — call after local recording is stopped.
  Future<void> completeMediaTeardown() async {
    if (_mediaTornDown) return;
    _mediaTornDown = true;
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    try {
      _localStream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    _localStream = null;
    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (_) {}
    // Do not notifyListeners here: [CallScreen] may be inside another listener
    // callback / finalize path; re-entrant notify caused uncaught errors on web.
  }

  void _syncTeardownMedia() {
    if (_mediaTornDown) return;
    _mediaTornDown = true;
    try {
      _pc?.close();
    } catch (_) {}
    _pc = null;
    try {
      _localStream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    _localStream = null;
    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════
  //  Duration timer
  // ═══════════════════════════════════════════════════════════
  void _startDurationTimer() {
    _callDuration = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration++;
      notifyListeners();
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String get formattedDuration {
    final minutes = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ═══════════════════════════════════════════════════════════
  //  Internal state setter
  // ═══════════════════════════════════════════════════════════
  void _setState(CallState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = CallState.error;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  Dispose
  // ═══════════════════════════════════════════════════════════
  @override
  void dispose() {
    // Unregister all socket event listeners to avoid memory leaks
    _socket.off('room-joined');
    _socket.off('peer-joined');
    _socket.off('webrtc-offer');
    _socket.off('webrtc-answer');
    _socket.off('ice-candidate');
    _socket.off('call-error');
    _socket.off('peer-media-toggle');
    _socket.off('call-ended');
    _socket.off('peer-left');

    _stopDurationTimer();

    _syncTeardownMedia();

    localRenderer.dispose();
    remoteRenderer.dispose();

    super.dispose();
  }
}
