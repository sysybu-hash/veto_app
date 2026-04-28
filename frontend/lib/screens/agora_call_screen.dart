// ============================================================
//  agora_call_screen.dart — Agora video/audio; socket room for end/cleanup.
// ============================================================

import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:provider/provider.dart';

import '../core/theme/veto_theme.dart';
import '../services/agora_service.dart';
import '../services/socket_service.dart';
import '../services/vault_save_queue.dart';

class AgoraCallScreen extends StatefulWidget {
  const AgoraCallScreen({
    super.key,
    required this.channelId,
    this.eventId = '',
    this.language = 'he',
    this.token = '',
    this.peerLabel = 'Lawyer',
    this.wantVideo = true,
    this.socketRole = 'user',
  });

  final String channelId;
  final String eventId;
  final String language;
  final String token;
  final String peerLabel;
  final bool wantVideo;
  final String socketRole;

  @override
  State<AgoraCallScreen> createState() => _AgoraCallScreenState();
}

class _AgoraCallScreenState extends State<AgoraCallScreen> {
  late final AgoraService _agora;
  bool _starting = true;
  String? _startError;
  bool _leaving = false;
  bool _remoteHangup = false;
  bool _socketHandlersRegistered = false;
  int _durationSeconds = 0;
  Timer? _durationTimer;

  void _onSocketCallEnded(dynamic _) {
    if (_leaving || !mounted) return;
    unawaited(_finishBecauseRemote());
  }

  void _onSocketPeerLeft(dynamic _) {
    if (_leaving || !mounted) return;
    unawaited(_finishBecauseRemote());
  }

  void _registerCallSockets() {
    if (_socketHandlersRegistered) return;
    final s = SocketService();
    s.on('call-ended', _onSocketCallEnded);
    s.on('peer-left', _onSocketPeerLeft);
    _socketHandlersRegistered = true;
  }

  void _unregisterCallSockets() {
    if (!_socketHandlersRegistered) return;
    final s = SocketService();
    s.removeHandler('call-ended', _onSocketCallEnded);
    s.removeHandler('peer-left', _onSocketPeerLeft);
    _socketHandlersRegistered = false;
  }

  Future<void> _finishBecauseRemote() async {
    if (_leaving) return;
    _leaving = true;
    _remoteHangup = true;
    _durationTimer?.cancel();
    _unregisterCallSockets();
    if (mounted) {
      _queueVaultTranscribe();
    }
    try {
      await _agora.leaveChannelAndRelease();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    _agora = AgoraService();
    _agora.addListener(_onAgora);
    unawaited(_bootstrap());
  }

  void _onAgora() {
    if (_agora.joined && _durationTimer == null) {
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _durationSeconds++);
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    try {
      final socket = SocketService();
      final online = await socket.ensureConnected(role: widget.socketRole);
      if (!online) {
        _startError = 'Could not connect to the server. Check your network and try again.';
        return;
      }

      _registerCallSockets();
      socket.emit('join-call-room', {
        'roomId': widget.channelId,
        'callType': widget.wantVideo ? 'video' : 'audio',
      });

      if (!kIsWeb) {
        await Permission.microphone.request();
        if (widget.wantVideo) {
          await Permission.camera.request();
        }
      }

      await _agora.joinChannel(
        channelId: widget.channelId,
        token: widget.token,
        publishVideo: widget.wantVideo,
      );
    } catch (e) {
      _startError = e.toString();
      _unregisterCallSockets();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _queueVaultTranscribe() {
    final eid = widget.eventId;
    if (eid.isEmpty) return;
    // Server-side recording may be absent for instant hangups; transcribe would 400.
    if (_durationSeconds < 1) return;
    try {
      context.read<VaultSaveQueue>().enqueueAgoraRecordingTranscript(
        eventId: eid,
        language: widget.language,
        roomLabel: widget.peerLabel,
      );
    } catch (_) {}
  }

  Future<void> _endCall() async {
    if (_leaving) return;
    _leaving = true;
    _durationTimer?.cancel();
    _unregisterCallSockets();
    try {
      if (!_remoteHangup) {
        SocketService().emit('call-ended', {
          'roomId': widget.channelId,
          'duration': _durationSeconds,
        });
      }
    } catch (_) {}
    if (mounted) {
      _queueVaultTranscribe();
    }
    try {
      await _agora.leaveChannelAndRelease();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildWaitingForEngine() {
    if (kIsWeb) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'מתחבר למדיה (דפדפן)… אם נשאר כך — בדקו מצלמה/מיקרופן בהרשאות האתר',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'Heebo',
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'מכין שיחה…',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontFamily: 'Heebo',
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _remoteVideoOrWaiting({
    required RtcEngine eng,
    required int? remote,
    required String channel,
  }) {
    if (remote == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(
              'Waiting for ${widget.peerLabel}…',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Heebo',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: eng,
        canvas: VideoCanvas(uid: remote),
        connection: RtcConnection(channelId: channel),
      ),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _agora.removeListener(_onAgora);
    _unregisterCallSockets();
    unawaited(() async {
      try {
        await _agora.leaveChannelAndRelease();
      } catch (_) {}
      _agora.dispose();
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Copy for stable null-promotion: engine can be null after leave/dispose or on Web edge cases.
    final RtcEngine? eng = _agora.engine;
    final int? remote = _agora.remoteUid;
    final String channel = widget.channelId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: VetoDecorations.gradientBg(),
          ),
          if (_starting)
            const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            )
          else if (_startError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _startError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontFamily: 'Heebo'),
                ),
              ),
            )
          else if (eng == null) _buildWaitingForEngine()
          else ...[
            if (widget.wantVideo)
              Positioned.fill(
                child: _remoteVideoOrWaiting(
                  eng: eng,
                  remote: remote,
                  channel: channel,
                ),
              )
            else
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        remote != null ? Icons.mic : Icons.mic_none,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 72,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        remote != null
                            ? 'Connected — ${widget.peerLabel}'
                            : 'Waiting for ${widget.peerLabel}…',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Heebo',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.wantVideo)
              Positioned(
                top: 100,
                right: 16,
                width: 100,
                height: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: VetoColors.surface,
                      border: Border.all(color: VetoColors.border),
                    ),
                    child: _agora.joined
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: eng,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.videocam_outlined, color: VetoColors.silver),
                          ),
                  ),
                ),
              ),
          ],
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: VetoColors.vetoRedSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: VetoColors.vetoRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield, color: VetoColors.vetoRed, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'VETO',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: VetoColors.vetoRed,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.peerLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Heebo',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_agora.joined)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${(_durationSeconds ~/ 60).toString().padLeft(2, '0')}:${(_durationSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    if (_agora.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                        child: Text(
                          _agora.errorMessage ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange.shade200,
                            fontSize: 12,
                            fontFamily: 'Heebo',
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: _starting ? null : _endCall,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: VetoColors.vetoRed,
                          boxShadow: VetoDecorations.vetoGlow(intensity: 0.8),
                        ),
                        child: const Icon(Icons.call_end, color: VetoColors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'End Call',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
