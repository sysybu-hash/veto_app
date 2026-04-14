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

  // ── WebRTC objects ────────────────────────────────────────
  RTCPeerConnection? _pc;
  MediaStream?       _localStream;
  MediaStream?       _remoteStream;

  final RTCVideoRenderer localRenderer  = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // ── STUN servers ──────────────────────────────────────────
  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'iceCandidatePoolSize': 10,
  };

  // ── Getters ───────────────────────────────────────────────
  CallState get state        => _state;
  CallType  get callType     => _callType;
  String?   get roomId       => _roomId;
  bool      get micMuted     => _micMuted;
  bool      get cameraOff    => _cameraOff;
  bool      get isRecording  => _isRecording;
  int       get callDuration => _callDuration;
  bool      get hasVideo     => _callType == CallType.video && !_cameraOff;
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
  Future<void> joinRoom(String roomId, CallType callType) async {
    _roomId    = roomId;
    _callType  = callType;
    _setState(CallState.joining);

    try {
      await initRenderers();
      _socket.emit('join-call-room', {
        'roomId':   roomId,
        'callType': callType == CallType.video ? 'video' : 'audio',
      });
    } catch (e) {
      debugPrint('[WebRTC] joinRoom error: $e');
      _setState(CallState.error);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  Get user media and init peer connection
  // ═══════════════════════════════════════════════════════════
  Future<void> _initCall(bool isCaller, String? peerSocketId) async {
    _peerSocketId = peerSocketId;

    // ── Get local media ───────────────────────────────────────
    final constraints = <String, dynamic>{
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': _callType == CallType.video
          ? {
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
              'facingMode': 'user',
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    localRenderer.srcObject = _localStream;

    // ── Create peer connection ────────────────────────────────
    _pc = await createPeerConnection(_iceConfig);

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
        _setState(CallState.connected);
        _startDurationTimer();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _setState(CallState.error);
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
      final isCaller = data['isCaller'] == true;
      debugPrint('[WebRTC] Room joined | isCaller=$isCaller');
      _setState(CallState.ringing);
      if (isCaller) {
        // Wait a moment for peer to join
        await Future.delayed(const Duration(milliseconds: 500));
        await _initCall(true, null);
      }
    });

    // Peer joined — if we're callee, init and wait for offer
    _socket.on('peer-joined', (data) async {
      final peerSocketId = data['socketId'] as String?;
      debugPrint('[WebRTC] Peer joined: $peerSocketId');
      if (_state == CallState.joining || _state == CallState.ringing) {
        await _initCall(false, peerSocketId);
        _peerSocketId = peerSocketId;
      }
    });

    // Received offer (callee side)
    _socket.on('webrtc-offer', (data) async {
      try {
        if (_pc == null) {
          // Init without creating offer (we're callee)
          await _initCall(false, data['fromSocketId'] as String?);
        }
        _peerSocketId = data['fromSocketId'];
        final offerMap = Map<String, dynamic>.from(data['offer']);
        await _pc!.setRemoteDescription(
          RTCSessionDescription(offerMap['sdp'], offerMap['type']),
        );
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);
        _socket.emit('webrtc-answer', {
          'roomId':         _roomId,
          'answer':         answer.toMap(),
          'targetSocketId': _peerSocketId,
        });
      } catch (e) {
        debugPrint('[WebRTC] Handle offer error: $e');
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

  Future<void> _onCallEnded({required bool remote}) async {
    _stopDurationTimer();
    _setState(CallState.ended);

    await _pc?.close();
    _pc = null;

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;

    localRenderer.srcObject  = null;
    remoteRenderer.srcObject = null;

    notifyListeners();
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
    _socket.off('peer-media-toggle');
    _socket.off('call-ended');
    _socket.off('peer-left');

    _stopDurationTimer();

    _pc?.close();
    _pc = null;

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;

    localRenderer.srcObject  = null;
    remoteRenderer.srcObject = null;
    localRenderer.dispose();
    remoteRenderer.dispose();

    super.dispose();
  }
}
