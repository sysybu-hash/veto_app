// ============================================================
//  call_session_screen.dart — Agora A/V + in-call text chat +
//  optional on-device live caption (speech_to_text) + socket end/cleanup.
// ============================================================

import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'in_call_speech.dart';
import '../core/theme/veto_theme.dart';
import '../services/agora_service.dart';
import '../services/socket_service.dart';
import '../services/vault_save_queue.dart';

class _ChatLine {
  _ChatLine({required this.text, required this.mine});

  final String text;
  final bool mine;
}

class CallSessionScreen extends StatefulWidget {
  const CallSessionScreen({
    super.key,
    required this.channelId,
    this.eventId = '',
    this.language = 'he',
    this.token = '',
    this.agoraUid = 0,
    this.peerLabel = 'Lawyer',
    this.wantVideo = true,
    this.socketRole = 'user',
  });

  final String channelId;
  final String eventId;
  final String language;
  final String token;
  final int agoraUid;
  final String peerLabel;
  final bool wantVideo;
  final String socketRole;

  @override
  State<CallSessionScreen> createState() => _CallSessionScreenState();
}

class _CallSessionScreenState extends State<CallSessionScreen>
    with TickerProviderStateMixin {
  late final AgoraService _agora;
  bool _starting = true;
  String? _startError;
  bool _leaving = false;
  bool _remoteHangup = false;
  bool _socketHandlersRegistered = false;
  int _durationSeconds = 0;
  Timer? _durationTimer;
  bool _webVideoSurfaceOk = true;
  Timer? _webVideoGateTimer;

  final _chatScroll = ScrollController();
  final _chatInput = TextEditingController();
  final List<_ChatLine> _chatLines = <_ChatLine>[];

  late final InCallSpeech _inCallSpeech;
  late TabController _sideTabController;

  Map<String, dynamic> _socketMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return <String, dynamic>{};
  }

  void _onCallChatEvent(dynamic raw) {
    if (!mounted) return;
    final m = _socketMap(raw);
    final t = m['text']?.toString() ?? '';
    if (t.isEmpty) return;
    final from = m['fromRole']?.toString() ?? '';
    final r = widget.socketRole;
    final mine = (r == 'user' || r == 'admin')
        ? (from == 'user' || from == 'admin')
        : from == 'lawyer';
    setState(() => _chatLines.add(_ChatLine(text: t, mine: mine)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.jumpTo(_chatScroll.position.maxScrollExtent);
      }
    });
  }

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
    s.on('call-chat-message', _onCallChatEvent);
    _socketHandlersRegistered = true;
  }

  void _unregisterCallSockets() {
    if (!_socketHandlersRegistered) return;
    final s = SocketService();
    s.removeHandler('call-ended', _onSocketCallEnded);
    s.removeHandler('peer-left', _onSocketPeerLeft);
    s.removeHandler('call-chat-message', _onCallChatEvent);
    _socketHandlersRegistered = false;
  }

  Future<void> _finishBecauseRemote() async {
    if (_leaving) return;
    _leaving = true;
    _remoteHangup = true;
    _durationTimer?.cancel();
    unawaited(_inCallSpeech.dispose());
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
    if (kIsWeb && widget.wantVideo) {
      _webVideoSurfaceOk = false;
    }
    _agora = AgoraService();
    _agora.addListener(_onAgora);
    _inCallSpeech = createInCallSpeech(() {
      if (mounted) setState(() {});
    });
    _inCallSpeech.setLanguageCode(widget.language);
    _sideTabController = TabController(length: 2, vsync: this);
    unawaited(_bootstrap());
  }

  void _onAgora() {
    if (_agora.joined && _durationTimer == null) {
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _durationSeconds++);
      });
    }
    if (kIsWeb && widget.wantVideo && _agora.joined && !_webVideoSurfaceOk) {
      _webVideoGateTimer?.cancel();
      _webVideoGateTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _webVideoSurfaceOk = true);
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    try {
      final socket = SocketService();
      final online = await socket.ensureConnected(role: widget.socketRole);
      if (!online) {
        _startError =
            'Could not connect to the server. Check your network and try again.';
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
        try {
          await _agora.setSpeakerOn(true);
        } catch (_) {}
      }
      await _agora.joinChannel(
        channelId: widget.channelId,
        token: widget.token,
        uid: widget.agoraUid,
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
    if (_durationSeconds < 1) return;
    try {
      context.read<VaultSaveQueue>().enqueueAgoraRecordingTranscript(
            eventId: eid,
            language: widget.language,
            roomLabel: widget.peerLabel,
          );
    } catch (_) {}
  }

  void _sendChat() {
    final t = _chatInput.text.trim();
    if (t.isEmpty) return;
    try {
      SocketService().emit('call-chat-message', {
        'roomId': widget.channelId,
        'text': t,
      });
    } catch (_) {}
    _chatInput.clear();
  }

  Future<void> _endCall() async {
    if (_leaving) return;
    _leaving = true;
    _durationTimer?.cancel();
    unawaited(_inCallSpeech.dispose());
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
    required bool useVideoSurface,
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
    if (!useVideoSurface) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white54),
            SizedBox(height: 20),
            Text(
              'מכין תצוגת וידאו (דפדפן)…',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Heebo',
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    return AgoraVideoView(
      key: ValueKey('remote-$remote'),
      controller: VideoViewController.remote(
        rtcEngine: eng,
        canvas: VideoCanvas(uid: remote),
        connection: RtcConnection(channelId: channel),
      ),
    );
  }

  Widget _localPreview({
    required RtcEngine eng,
    required bool useVideoSurface,
  }) {
    if (!_agora.joined) {
      return const Center(
        child: Icon(Icons.videocam_outlined, color: VetoColors.silver),
      );
    }
    if (!useVideoSurface) {
      return const Center(
        child: CircularProgressIndicator(
          color: VetoColors.silver,
          strokeWidth: 2,
        ),
      );
    }
    return AgoraVideoView(
      key: const ValueKey('local-0'),
      controller: VideoViewController(
        rtcEngine: eng,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _buildTopBar() {
    final quality = _agora.networkQualityLabel;
    final rtt = _agora.rttMs;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  SizedBox(width: 5),
                  Text(
                    'VETO',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: VetoColors.vetoRed,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // אינדיקטור איכות רשת בזמן אמת
            if (quality.isNotEmpty) ...
              [
                _NetworkQualityChip(label: quality, rttMs: rtt),
                const SizedBox(width: 8),
              ],
            if (_agora.joined)
              Text(
                '${(_durationSeconds ~/ 60).toString().padLeft(2, '0')}:'
                '${(_durationSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            if (_agora.joined) const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.peerLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Heebo',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlRow() {
    if (!_agora.joined) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // רמקול רעשים (AI Noise Suppression)
            IconButton(
              onPressed: () {
                unawaited(
                  _agora.setNoiseSuppression(!_agora.noiseSuppression),
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: _agora.noiseSuppression
                    ? VetoColors.vetoRed.withValues(alpha: 0.3)
                    : Colors.white12,
              ),
              icon: Icon(
                _agora.noiseSuppression
                    ? Icons.noise_aware
                    : Icons.noise_control_off,
                color: _agora.noiseSuppression ? VetoColors.vetoRed : Colors.white54,
              ),
              tooltip: _agora.noiseSuppression ? 'Noise suppression ON' : 'Noise suppression OFF',
            ),
            const SizedBox(width: 4),
            if (!kIsWeb)
              IconButton(
                onPressed: () {
                  unawaited(_agora.setSpeakerOn(!_agora.speakerOn));
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white12,
                ),
                icon: Icon(
                  _agora.speakerOn
                      ? Icons.volume_up
                      : Icons.hearing,
                  color: Colors.white,
                ),
                tooltip: 'Speaker',
              ),
            if (!kIsWeb) const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                unawaited(
                  _agora.setMicPublishMuted(!_agora.micPublishMuted),
                );
              },
              style: IconButton.styleFrom(
                backgroundColor:
                    _agora.micPublishMuted ? VetoColors.vetoRed : Colors.white12,
              ),
              icon: Icon(
                _agora.micPublishMuted ? Icons.mic_off : Icons.mic,
                color: Colors.white,
              ),
              tooltip: 'Microphone',
            ),
            if (widget.wantVideo) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  unawaited(
                    _agora
                        .setVideoPublishMuted(!_agora.videoPublishMuted),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: _agora.videoPublishMuted
                      ? VetoColors.vetoRed
                      : Colors.white12,
                ),
                icon: Icon(
                  _agora.videoPublishMuted
                      ? Icons.videocam_off
                      : Icons.videocam,
                  color: Colors.white,
                ),
                tooltip: 'Camera',
              ),
            ],
            if (widget.wantVideo && !kIsWeb) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  unawaited(_agora.switchCamera());
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white12,
                ),
                icon: const Icon(
                  Icons.cameraswitch,
                  color: Colors.white,
                ),
                tooltip: 'Flip camera',
              ),
            ],
            // שיתוף מסך (Web only)
            if (kIsWeb) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  unawaited(_agora.toggleScreenShare());
                },
                style: IconButton.styleFrom(
                  backgroundColor: _agora.screenSharing
                      ? const Color(0xFF10B981)
                      : Colors.white12,
                ),
                icon: Icon(
                  _agora.screenSharing
                      ? Icons.stop_screen_share
                      : Icons.screen_share,
                  color: _agora.screenSharing
                      ? Colors.white
                      : Colors.white70,
                ),
                tooltip: _agora.screenSharing ? 'Stop sharing' : 'Share screen',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _endCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _starting ? null : _endCall,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VetoColors.vetoRed,
              boxShadow: VetoDecorations.vetoGlow(intensity: 0.7),
            ),
            child: const Icon(Icons.call_end, color: VetoColors.white, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'End',
          style: TextStyle(
            fontFamily: 'Heebo',
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _sidePanel() {
    return Material(
      color: VetoColors.surface.withValues(alpha: 0.95),
      child: Column(
        children: [
          TabBar(
            controller: _sideTabController,
            labelColor: VetoColors.vetoRed,
            unselectedLabelColor: VetoColors.silver,
            indicatorColor: VetoColors.vetoRed,
            tabs: const [
              Tab(text: 'Chat'),
              Tab(text: 'Caption'),
            ],
          ),
          if (widget.eventId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Text(
                kIsWeb
                    ? 'Server recording may be enabled; transcript can run after the call ends.'
                    : 'After the call, server recording can be transcribed from the vault when available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VetoColors.silver.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontFamily: 'Heebo',
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _sideTabController,
              children: [
                _chatTab(),
                _captionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatTab() {
    return Column(
      children: [
        Expanded(
          child: _chatLines.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet. Type below.',
                    style: TextStyle(
                      color: VetoColors.silver,
                      fontFamily: 'Heebo',
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _chatScroll,
                  padding: const EdgeInsets.all(10),
                  itemCount: _chatLines.length,
                  itemBuilder: (context, i) {
                    final line = _chatLines[i];
                    return Align(
                      alignment: line.mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        constraints: const BoxConstraints(maxWidth: 260),
                        decoration: BoxDecoration(
                          color: line.mine
                              ? VetoColors.vetoRed.withValues(alpha: 0.25)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          line.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Heebo',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          color: Colors.black26,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatInput,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Heebo',
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Message…',
                    hintStyle: TextStyle(
                      color: VetoColors.silver,
                    ),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              IconButton(
                onPressed: _sendChat,
                color: VetoColors.vetoRed,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _captionTab() {
    final s = _inCallSpeech;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'בדפדפן אין כתוביות מקומיות; אחרי השיחה — תמלול דרך Vault כשההקלטה בשרת קיימת. באפליקיית מובייל אפשר כאן תמלול מקומי.',
              style: TextStyle(
                color: Colors.orange.shade200,
                fontSize: 12,
                fontFamily: 'Heebo',
              ),
            ),
          ),
        FilledButton.icon(
          onPressed: _starting
              ? null
              : () {
                  unawaited(s.toggle());
                },
          style: FilledButton.styleFrom(
            backgroundColor:
                s.listening ? VetoColors.vetoRed : VetoColors.surface,
            foregroundColor: s.listening ? Colors.white : VetoColors.silver,
          ),
          icon: Icon(
            s.listening ? Icons.stop_circle_outlined : Icons.mic,
          ),
          label: Text(
            kIsWeb
                ? 'מידע על תמלול'
                : (s.listening
                    ? 'Stop live caption'
                    : 'Start local live caption'),
            style: const TextStyle(fontFamily: 'Heebo'),
          ),
        ),
        if (s.error != null) ...[
          const SizedBox(height: 8),
          Text(
            s.error!,
            style: TextStyle(
              color: Colors.orange.shade200,
              fontSize: 12,
              fontFamily: 'Heebo',
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (s.partial.isNotEmpty) ...[
          Text(
            s.partial,
            style: const TextStyle(
              color: VetoColors.silver,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
        ],
        for (final line in s.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '• $line',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Heebo',
                height: 1.3,
              ),
            ),
          ),
        if (s.lines.isEmpty && s.partial.isEmpty && s.error == null)
          const Text(
            'This is on-device text from your side only (not the peer). Server-side transcription uses the recording when you end the call.',
            style: TextStyle(
              color: VetoColors.silver,
              fontSize: 12,
              fontFamily: 'Heebo',
            ),
          ),
      ],
    );
  }

  Widget _buildVideoStage(
    RtcEngine eng, {
    required int? remote,
    required String channel,
    required bool useVideoSurface,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.wantVideo)
          _remoteVideoOrWaiting(
            eng: eng,
            remote: remote,
            channel: channel,
            useVideoSurface: useVideoSurface,
          )
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  remote != null ? Icons.mic : Icons.mic_none,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 68,
                ),
                const SizedBox(height: 16),
                Text(
                  remote != null
                      ? 'Audio — ${widget.peerLabel}'
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
        if (widget.wantVideo)
          Positioned(
            top: 64,
            right: 10,
            width: 90,
            height: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: VetoColors.surface,
                  border: Border.all(color: VetoColors.border),
                ),
                child: _localPreview(eng: eng, useVideoSurface: useVideoSurface),
              ),
            ),
          ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          child: _buildTopBar(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_agora.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _agora.errorMessage ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange.shade200,
                        fontSize: 11,
                        fontFamily: 'Heebo',
                      ),
                    ),
                  ),
                _buildControlRow(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _endCallButton(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _sideTabController.dispose();
    _webVideoGateTimer?.cancel();
    _durationTimer?.cancel();
    _chatScroll.dispose();
    _chatInput.dispose();
    unawaited(_inCallSpeech.dispose());
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
    final RtcEngine? eng = _agora.engine;
    final int? remote = _agora.remoteUid;
    final String channel = widget.channelId;
    final useVideoSurface = !kIsWeb || _webVideoSurfaceOk;
    final w = MediaQuery.sizeOf(context).width;
    final useWideSide = w >= 900;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: VetoDecorations.gradientBg(),
            ),
          ),
          if (_starting)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
            )
          else if (_startError != null)
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _startError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Heebo',
                    ),
                  ),
                ),
              ),
            )
          else if (eng == null)
            Positioned.fill(child: _buildWaitingForEngine())
          else if (useWideSide)
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: _buildVideoStage(
                      eng,
                      remote: remote,
                      channel: channel,
                      useVideoSurface: useVideoSurface,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: _sidePanel(),
                  ),
                ],
              ),
            )
          else
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: _buildVideoStage(
                      eng,
                      remote: remote,
                      channel: channel,
                      useVideoSurface: useVideoSurface,
                    ),
                  ),
                  SizedBox(
                    height: (MediaQuery.sizeOf(context).height * 0.38)
                        .clamp(220.0, 420.0),
                    child: _sidePanel(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Network Quality Chip ──────────────────────────────────────
class _NetworkQualityChip extends StatelessWidget {
  final String label;
  final int rttMs;

  const _NetworkQualityChip({required this.label, required this.rttMs});

  Color get _color {
    switch (label) {
      case 'מעולה': return const Color(0xFF10B981);
      case 'טובה':  return const Color(0xFF34D399);
      case 'בינונית': return const Color(0xFFF59E0B);
      case 'גרועה': return const Color(0xFFEF4444);
      default: return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            rttMs > 0 ? '$label · ${rttMs}ms' : label,
            style: TextStyle(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Heebo',
            ),
          ),
        ],
      ),
    );
  }
}
