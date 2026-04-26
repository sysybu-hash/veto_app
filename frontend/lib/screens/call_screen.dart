// ============================================================
//  call_screen.dart — WebRTC Audio/Video Call Screen
//  VETO Legal Emergency App
//
//  Route: /call
//  Args:  { roomId, callType: 'video'|'audio', peerName, role }
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../core/theme/veto_theme.dart';
import '../services/call_recording_service.dart';
import '../services/vault_save_queue.dart';
import '../services/webrtc_service.dart';
import '../services/socket_service.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _ChatLine {
  _ChatLine({required this.text, required this.mine});
  final String text;
  final bool mine;
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  WebRTCService? _webrtc;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  String  _roomId   = '';
  String  _callType = 'video';
  String  _peerName = 'Connecting...';
  String  _myRole   = 'user';
  String  _eventId  = '';
  String  _language = 'he';

  bool _recordingStarted = false;
  bool _finalizedCall = false;
  String? _callErrorText;
  late final CallRecordingService _recordingService;

  bool _userOptedRecord = false;
  bool _liveRecording = false;

  // Text session (same room, no WebRTC media)
  bool get _isChat => _callType == 'chat';
  bool _chatReady = false;
  final List<_ChatLine> _chatLines = [];
  final TextEditingController _chatInput = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  Timer? _chatDurationTimer;
  int _chatSeconds = 0;

  // Timeout: if no peer joins within 75 seconds, show cancel option
  Timer? _waitTimeout;
  bool _timedOut = false;
  int _waitSeconds = 0;
  Timer? _waitTick;

  @override
  void initState() {
    super.initState();

    // Pulse animation for connecting state
    _pulseCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Fade in animation
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    _recordingService = createCallRecordingService();

    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    try {
      setState(fn);
    } catch (e, st) {
      developer.log(
        '_safeSetState',
        name: 'VETO.CallScreen',
        error: e,
        stackTrace: st,
      );
      debugPrint('[CallScreen] _safeSetState: $e\n$st');
    }
  }

  Future<void> _init() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      // Navigated directly to /call without arguments — go back
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/veto_screen');
      }
      return;
    }

    final myRole = args['role']?.toString() ?? 'user';
    var ct = args['callType']?.toString() ?? 'video';
    if (ct == 'webrtc') ct = 'video';

    _safeSetState(() {
      _roomId    = args['roomId']?.toString() ?? '';
      _callType  = ct;
      _peerName  = args['peerName']?.toString() ?? 'Legal Counsel';
      _myRole    = myRole;
      _eventId   = args['eventId']?.toString() ?? '';
      _language  = args['language']?.toString() ?? 'he';
      _userOptedRecord = true;
    });

    final socketService = context.read<SocketService>();

    final online = await socketService.ensureConnected(role: myRole);
    if (!mounted) return;
    if (!online) {
      _safeSetState(() {
        _callErrorText = _language == 'he'
            ? 'אין חיבור לשרת. בדוק רשת ונסה שוב.'
            : _language == 'ru'
                ? 'Нет связи с сервером. Проверьте сеть и повторите.'
                : 'Cannot reach the server. Check your connection and try again.';
      });
      return;
    }

    if (_isChat) {
      await _initChatSession(socketService);
      return;
    }

    final w = WebRTCService(socketService);
    _webrtc = w;

    await w.joinRoom(
      _roomId,
      _callType == 'video' ? CallType.video : CallType.audio,
      socketRole: myRole,
    );

    w.addListener(_onWebRTCUpdate);

    _waitTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _safeSetState(() => _waitSeconds++);
    });
    _waitTimeout = Timer(const Duration(seconds: 75), () {
      if (!mounted) return;
      if (w.state != CallState.connected) {
        _safeSetState(() => _timedOut = true);
        _waitTick?.cancel();
      }
    });
  }

  void _onChatReadyEvent(dynamic raw) {
    if (!mounted) return;
    final m = _socketMap(raw);
    if (m['roomId']?.toString() != _roomId) return;
    _safeSetState(() => _chatReady = true);
    _waitTimeout?.cancel();
    _waitTick?.cancel();
    _startChatDurationTimer();
  }

  void _onChatMessageEvent(dynamic raw) {
    if (!mounted) return;
    final m = _socketMap(raw);
    final t = m['text']?.toString() ?? '';
    if (t.isEmpty) return;
    final from = m['fromRole']?.toString() ?? '';
    final mine = (_myRole == 'user' || _myRole == 'admin')
        ? (from == 'user' || from == 'admin')
        : from == 'lawyer';
    _safeSetState(() {
      _chatLines.add(_ChatLine(text: t, mine: mine));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.jumpTo(_chatScroll.position.maxScrollExtent);
      }
    });
  }

  void _onCallEndedEvent(dynamic raw) {
    if (!_isChat || !mounted || _finalizedCall) return;
    final m = _socketMap(raw);
    final rid = m['roomId']?.toString();
    if (rid != null && rid.isNotEmpty && rid != _roomId) return;
    _finalizedCall = true;
    unawaited(_finalizeAndNavigate());
  }

  Future<void> _initChatSession(SocketService socketService) async {
    socketService.on('chat-ready', _onChatReadyEvent);
    socketService.on('call-chat-message', _onChatMessageEvent);
    socketService.on('call-ended', _onCallEndedEvent);

    socketService.emit('join-call-room', {
      'roomId': _roomId,
      'callType': 'chat',
    });

    _waitTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _safeSetState(() => _waitSeconds++);
    });
    _waitTimeout = Timer(const Duration(seconds: 75), () {
      if (!mounted) return;
      if (!_chatReady) {
        _safeSetState(() => _timedOut = true);
        _waitTick?.cancel();
      }
    });
  }

  Map<String, dynamic> _socketMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return {};
  }

  void _startChatDurationTimer() {
    _chatDurationTimer?.cancel();
    _chatSeconds = 0;
    _chatDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _safeSetState(() => _chatSeconds++);
    });
  }

  String get _formattedChatDuration {
    final m = (_chatSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_chatSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onWebRTCUpdate() {
    final w = _webrtc;
    if (w == null) return;
    if (!mounted) return;
    // [WebRTCService] may notify again after we start navigation — avoid setState after dispose.
    if (_finalizedCall) return;
    _safeSetState(() {});

    if (w.errorMessage != null && w.errorMessage!.trim().isNotEmpty) {
      _callErrorText = w.errorMessage;
    }

    if (w.state == CallState.connected && !_recordingStarted) {
      _waitTimeout?.cancel();
      _waitTick?.cancel();
      _safeSetState(() {
        _timedOut = false;
        _waitSeconds = 0;
        _callErrorText = null;
      });
      _maybeStartRecording(w);
    }

    if (w.state == CallState.ended && !_finalizedCall) {
      _finalizedCall = true;
      w.removeListener(_onWebRTCUpdate);
      unawaited(_finalizeAndNavigate());
    }
  }

  void _maybeStartRecording(WebRTCService w) {
    if (_recordingStarted) return;
    if (!_userOptedRecord) return;
    _recordingStarted = true;
    _liveRecording = true;
    _recordingService.start(
      localStream: w.localStream,
      remoteStream: w.remoteStream,
      video: _callType == 'video',
    );
  }

  Future<void> _toggleRecordingOptIn() async {
    if (!mounted) return;
    _safeSetState(() => _userOptedRecord = !_userOptedRecord);
    final w = _webrtc;
    if (_userOptedRecord && w != null && w.state == CallState.connected && !_recordingStarted) {
      _maybeStartRecording(w);
    }
    if (!_userOptedRecord && _liveRecording) {
      try {
        await _recordingService.stop();
      } catch (e, st) {
        developer.log(
          '_toggleRecordingOptIn stop',
          name: 'VETO.CallScreen',
          error: e,
          stackTrace: st,
        );
        debugPrint('[CallScreen] _toggleRecordingOptIn stop: $e\n$st');
      }
      if (!mounted) return;
      _safeSetState(() {
        _recordingStarted = false;
        _liveRecording = false;
      });
    }
  }

  Future<void> _retryJoin() async {
    _waitTimeout?.cancel();
    _waitTick?.cancel();
    _safeSetState(() {
      _timedOut = false;
      _waitSeconds = 0;
      _callErrorText = null;
      _finalizedCall = false;
      _recordingStarted = false;
      _liveRecording = false;
    });

    if (_isChat) {
      _safeSetState(() {
        _chatReady = false;
        _chatLines.clear();
      });
      final socketService = context.read<SocketService>();
      socketService.removeHandler('chat-ready', _onChatReadyEvent);
      socketService.removeHandler('call-chat-message', _onChatMessageEvent);
      socketService.removeHandler('call-ended', _onCallEndedEvent);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await _initChatSession(socketService);
      return;
    }

    _webrtc?.removeListener(_onWebRTCUpdate);
    _webrtc?.dispose();
    _webrtc = null;

    final socketService = context.read<SocketService>();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final online = await socketService.ensureConnected(role: _myRole);
    if (!mounted) return;
    if (!online) {
      _safeSetState(() {
        _callErrorText = _language == 'he'
            ? 'אין חיבור לשרת. בדוק רשת ונסה שוב.'
            : _language == 'ru'
                ? 'Нет связи с сервером. Проверьте сеть и повторите.'
                : 'Cannot reach the server. Check your connection and try again.';
      });
      return;
    }
    final w = WebRTCService(socketService);
    _webrtc = w;
    w.addListener(_onWebRTCUpdate);
    await w.joinRoom(
      _roomId,
      _callType == 'video' ? CallType.video : CallType.audio,
      socketRole: _myRole,
    );

    _waitTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _safeSetState(() => _waitSeconds++);
    });
    _waitTimeout = Timer(const Duration(seconds: 75), () {
      if (!mounted) return;
      if (w.state != CallState.connected) {
        _safeSetState(() => _timedOut = true);
        _waitTick?.cancel();
      }
    });
  }

  String _formatChatAsTranscript() {
    final buf = StringBuffer();
    for (final line in _chatLines) {
      buf.writeln(
        line.mine ? '[Me] ${line.text}' : '[$_peerName] ${line.text}',
      );
    }
    return buf.toString().trim();
  }

  /// Stops the recorder, enqueues long uploads to the vault queue, and navigates
  /// immediately (work continues in the background).
  Future<void> _finalizeAndNavigate() async {
    if (!mounted) return;
    _webrtc?.removeListener(_onWebRTCUpdate);
    final vaultEventId =
        _eventId.trim().isNotEmpty ? _eventId.trim() : _roomId.trim();
    try {
      final nav = Navigator.of(context);
      final queue = context.read<VaultSaveQueue>();
      final myRole = _myRole;
      var goVault = false;
      if (_isChat) {
        final t = _formatChatAsTranscript();
        if (t.isNotEmpty && vaultEventId.isNotEmpty) {
          queue.enqueueChatTranscript(
            eventId: vaultEventId,
            transcript: t,
            roomLabel: _peerName,
          );
          goVault = true;
        }
      } else {
        CallRecordingResult? rec;
        if (_recordingStarted) {
          try {
            rec = await _recordingService.stop();
          } catch (e, st) {
            developer.log(
              'recording stop failed',
              name: 'VETO.CallScreen',
              error: e,
              stackTrace: st,
            );
            debugPrint('[CallScreen] recording stop failed: $e\n$st');
            rec = null;
          }
          _liveRecording = false;
          _recordingStarted = false;
        }
        final webrtc = _webrtc;
        try {
          await webrtc?.completeMediaTeardown();
        } catch (e, st) {
          developer.log(
            'media teardown',
            name: 'VETO.CallScreen',
            error: e,
            stackTrace: st,
          );
          debugPrint('[CallScreen] media teardown: $e\n$st');
        }
        if (rec != null &&
            rec.bytes.isNotEmpty &&
            vaultEventId.isNotEmpty) {
          queue.enqueueWebrtcCallArtifacts(
            eventId: vaultEventId,
            language: _language,
            roomLabel: _peerName,
            recording: rec,
          );
          goVault = true;
        }
      }
      if (!mounted) return;
      final target = goVault
          ? '/files_vault'
          : (myRole == 'lawyer' ? '/lawyer_dashboard' : '/veto_screen');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        nav.pushReplacementNamed(target);
      });
    } catch (e, st) {
      developer.log(
        '_finalizeAndNavigate',
        name: 'VETO.CallScreen',
        error: e,
        stackTrace: st,
      );
      debugPrint('[CallScreen] _finalizeAndNavigate: $e\n$st');
      if (!mounted) return;
      final fallback = _myRole == 'lawyer' ? '/lawyer_dashboard' : '/veto_screen';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(fallback);
      });
    }
  }

  Future<void> _endCall() async {
    if (_isChat) {
      context.read<SocketService>().emit('call-ended', {
        'roomId': _roomId,
        'duration': _chatSeconds,
      });
      _chatDurationTimer?.cancel();
      if (!_finalizedCall) {
        _finalizedCall = true;
        unawaited(_finalizeAndNavigate());
      }
      return;
    }
    try {
      await _webrtc?.endCall();
    } catch (e, st) {
      developer.log(
        '_endCall WebRTC',
        name: 'VETO.CallScreen',
        error: e,
        stackTrace: st,
      );
      debugPrint('[CallScreen] _endCall WebRTC: $e\n$st');
    }
  }

  @override
  void dispose() {
    developer.log(
      'CallScreen: Starting dispose sequence',
      name: 'VETO.CallScreen',
    );

    final w = _webrtc;
    _webrtc = null;

    if (w != null) {
      try {
        w.removeListener(_onWebRTCUpdate);
        final svc = w;
        Future<void>.delayed(Duration.zero, () {
          try {
            svc.dispose();
            developer.log(
              'WebRTCService disposed successfully after frame',
              name: 'VETO.CallScreen',
            );
          } catch (e, stack) {
            developer.log(
              'Error disposing WebRTC service (deferred)',
              name: 'VETO.CallScreen',
              error: e,
              stackTrace: stack,
            );
          }
        });
      } catch (e, stack) {
        developer.log(
          'Error during CallScreen teardown sync phase',
          name: 'VETO.CallScreen',
          error: e,
          stackTrace: stack,
        );
      }
    }

    _waitTimeout?.cancel();
    _waitTick?.cancel();
    _chatDurationTimer?.cancel();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _chatInput.dispose();
    _chatScroll.dispose();
    final svc = SocketService();
    svc.removeHandler('chat-ready', _onChatReadyEvent);
    svc.removeHandler('call-chat-message', _onChatMessageEvent);
    svc.removeHandler('call-ended', _onCallEndedEvent);

    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            if (_isChat) _buildChatLayer() else _buildVideoLayer(),
            if (!_isChat) _buildGradientOverlay(),
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(child: _buildTopBar()),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(child: _buildControls()),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Text session layer
  // ─────────────────────────────────────────────────────────
  Widget _buildChatLayer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: VetoDecorations.gradientBg(),
      child: Column(
        children: [
          Expanded(
            child: !_chatReady
                ? Center(child: _buildChatWaitingBody())
                : ListView.builder(
                    controller: _chatScroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatLines.length,
                    itemBuilder: (_, i) {
                      final line = _chatLines[i];
                      return Align(
                        alignment:
                            line.mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: line.mine
                                ? const Color(0xFF5B8FFF).withValues(alpha: 0.45)
                                : Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            line.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Heebo',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_chatReady)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatInput,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _language == 'he'
                            ? 'הקלד הודעה…'
                            : _language == 'ru'
                                ? 'Сообщение…'
                                : 'Type a message…',
                        hintStyle:
                            TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _sendChatLine(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendChatLine,
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF5B8FFF)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _sendChatLine() {
    final t = _chatInput.text.trim();
    if (t.isEmpty || !_chatReady) return;
    context.read<SocketService>().emit('call-chat-message', {
      'roomId': _roomId,
      'text': t,
    });
    _safeSetState(() {
      _chatLines.add(_ChatLine(text: t, mine: true));
      _chatInput.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.jumpTo(_chatScroll.position.maxScrollExtent);
      }
    });
  }

  Widget _buildChatWaitingBody() {
    if (_callErrorText != null) return _buildErrorPanel();
    if (_timedOut) return _buildTimeoutPanel();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _peerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontFamily: 'Heebo',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildWaitingPanel(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Video layer
  // ─────────────────────────────────────────────────────────
  Widget _buildVideoLayer() {
    final w = _webrtc;
    if (w == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: VetoDecorations.gradientBg(),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }

    final isVideo = _callType == 'video';
    final isConnected = w.state == CallState.connected;

    if (!isVideo || !isConnected) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: VetoDecorations.gradientBg(),
        child: Center(child: _buildAvatar(w)),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: RTCVideoView(
            w.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
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
                border: Border.all(color: VetoColors.border, width: 1),
              ),
              child: w.cameraOff
                  ? const Center(
                      child: Icon(Icons.videocam_off, color: VetoColors.silver, size: 28),
                    )
                  : RTCVideoView(
                      w.localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Avatar (audio mode / connecting)
  // ─────────────────────────────────────────────────────────
  Widget _buildAvatar(WebRTCService w) {
    final isConnecting = w.state != CallState.connected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: isConnecting ? _pulseAnim.value : 1.0,
            child: child,
          ),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [VetoColors.accent, VetoColors.accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: VetoDecorations.accentGlow(intensity: isConnecting ? 1.5 : 1.0),
            ),
            child: Center(
              child: Text(
                _peerName.isNotEmpty ? _peerName[0].toUpperCase() : 'L',
                style: const TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: VetoColors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _peerName,
          style: const TextStyle(
            fontFamily: 'Heebo',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: VetoColors.white,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatusText(w),
        const SizedBox(height: 20),
        if (w.state == CallState.error) ...[
          _buildErrorPanel(),
        ] else if (w.state == CallState.joining || w.state == CallState.ringing) ...[
          _timedOut ? _buildTimeoutPanel() : _buildWaitingPanel(),
        ],
      ],
    );
  }

  Widget _buildWaitingPanel() {
    final remaining = 75 - _waitSeconds;
    final label = _language == 'he'
        ? 'מחכה לחיבור... ($remaining שניות)'
        : _language == 'ru'
            ? 'Ожидание подключения... ($remaining сек)'
            : 'Waiting for connection... ($remaining s)';
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Progress bar
      SizedBox(
        width: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _waitSeconds / 75,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B8FFF)),
            minHeight: 4,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Heebo')),
      const SizedBox(height: 12),
      // Cancel button
      TextButton.icon(
        onPressed: _endCall,
        icon: const Icon(Icons.close_rounded, size: 15, color: Colors.white54),
        label: Text(
          _language == 'he' ? 'בטל' : _language == 'ru' ? 'Отмена' : 'Cancel',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ),
    ]);
  }

  Widget _buildTimeoutPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.access_time_rounded, color: Colors.white70, size: 32),
        const SizedBox(height: 10),
        Text(
          _language == 'he'
              ? 'לא נמצא עורך דין זמין'
              : _language == 'ru'
                  ? 'Нет доступных адвокатов'
                  : 'No lawyer available right now',
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Heebo'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          _language == 'he'
              ? 'ניתן לנסות שוב או לחזור לאפליקציה'
              : _language == 'ru'
                  ? 'Попробуйте позже или вернитесь в приложение'
                  : 'Try again or go back to the app',
          style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Heebo'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton(
            onPressed: _endCall,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(_language == 'he' ? 'חזרה' : _language == 'ru' ? 'Назад' : 'Go back'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _retryJoin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5B8FFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(_language == 'he' ? 'נסה שוב' : _language == 'ru' ? 'Повторить' : 'Try again'),
          ),
        ]),
      ]),
    );
  }

  Widget _buildErrorPanel() {
    final msg = _callErrorText ??
        (_language == 'he'
            ? 'שגיאה בחיבור לשיחה.'
            : _language == 'ru'
                ? 'Ошибка подключения к звонку.'
                : 'Call connection failed.');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetoColors.error.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: VetoColors.error, size: 32),
          const SizedBox(height: 10),
          Text(
            _language == 'he'
                ? 'השיחה לא הצליחה להתחיל'
                : _language == 'ru'
                    ? 'Не удалось начать звонок'
                    : 'The call could not start',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Heebo',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Heebo',
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _endCall,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  _language == 'he'
                      ? 'חזרה'
                      : _language == 'ru'
                          ? 'Назад'
                          : 'Go back',
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _retryJoin,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5B8FFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  _language == 'he'
                      ? 'נסה שוב'
                      : _language == 'ru'
                          ? 'Повторить'
                          : 'Try again',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(WebRTCService w) {
    String text;
    Color  color;

    switch (w.state) {
      case CallState.joining:
        text  = 'מתחבר לחדר...';
        color = VetoColors.accent;
      case CallState.ringing:
        text  = 'מחכה לצד השני...';
        color = VetoColors.warning;
      case CallState.connected:
        text  = w.formattedDuration;
        color = VetoColors.success;
      case CallState.ended:
        text  = 'השיחה הסתיימה';
        color = VetoColors.error;
      case CallState.error:
        text  = 'שגיאה בחיבור';
        color = VetoColors.error;
      default:
        text  = '';
        color = VetoColors.silver;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (w.state == CallState.connected)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VetoColors.success,
              boxShadow: [BoxShadow(color: VetoColors.success.withValues(alpha:0.5), blurRadius: 6)],
            ),
          ),
        Text(text, style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: color)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Gradient overlay
  // ─────────────────────────────────────────────────────────
  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha:0.6),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha:0.8),
              ],
              stops: const [0.0, 0.15, 0.75, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Top bar
  // ─────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final w = _webrtc;
    final webrtcConnected = w != null && w.state == CallState.connected;
    final showDur = _isChat ? _chatReady : webrtcConnected;
    final durText = _isChat ? _formattedChatDuration : (w?.formattedDuration ?? '00:00');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: VetoColors.vetoRedSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VetoColors.vetoRed.withValues(alpha:0.3)),
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

          if (_liveRecording)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.red.shade200, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      _language == 'he' ? 'מוקלט' : 'REC',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade100,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha:0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: VetoColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _callType == 'video'
                      ? Icons.videocam
                      : _callType == 'chat'
                          ? Icons.chat
                          : Icons.mic,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _callType == 'video'
                      ? 'וידאו'
                      : _callType == 'chat'
                          ? (_language == 'he' ? 'צ\'ט' : 'Chat')
                          : 'אודיו',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          if (showDur)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: VetoColors.success.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VetoColors.success.withValues(alpha:0.3)),
              ),
              child: Text(
                durText,
                style: const TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: VetoColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Controls
  // ─────────────────────────────────────────────────────────
  Widget _buildControls() {
    final w = _webrtc;

    if (_isChat) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _endCall,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VetoColors.vetoRed,
                  boxShadow: VetoDecorations.vetoGlow(intensity: 0.8),
                ),
                child: const Icon(
                  Icons.call_end,
                  color: VetoColors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _language == 'he' ? 'סיום שיחה' : 'End',
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 12,
                color: VetoColors.silverDim,
              ),
            ),
          ],
        ),
      );
    }

    if (w == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlBtn(
                icon: w.micMuted ? Icons.mic_off : Icons.mic,
                label: w.micMuted ? 'הפעל' : 'השתק',
                color: w.micMuted ? VetoColors.error : VetoColors.silver,
                onTap: w.toggleMic,
              ),
              const SizedBox(width: 16),
              if (_callType == 'video') ...[
                _buildControlBtn(
                  icon: w.cameraOff ? Icons.videocam_off : Icons.videocam,
                  label: w.cameraOff ? 'הפעל' : 'כבה',
                  color: w.cameraOff ? VetoColors.error : VetoColors.silver,
                  onTap: w.toggleCamera,
                ),
                const SizedBox(width: 16),
                _buildControlBtn(
                  icon: Icons.flip_camera_ios,
                  label: 'הפוך',
                  color: VetoColors.silver,
                  onTap: w.switchCamera,
                ),
                const SizedBox(width: 16),
              ],
              _buildControlBtn(
                icon: _userOptedRecord ? Icons.radio_button_checked : Icons.radio_button_off,
                label: _language == 'he' ? 'הקלטה' : 'Rec',
                color: _userOptedRecord ? Colors.redAccent : VetoColors.silver,
                onTap: () => unawaited(_toggleRecordingOptIn()),
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VetoColors.vetoRed,
                boxShadow: VetoDecorations.vetoGlow(intensity: 0.8),
              ),
              child: const Icon(
                Icons.call_end,
                color: VetoColors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'סיום שיחה',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 12,
              color: VetoColors.silverDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String   label,
    required Color    color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha:0.1),
              border: Border.all(color: Colors.white.withValues(alpha:0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 11,
              color: VetoColors.silver,
            ),
          ),
        ],
      ),
    );
  }
}
