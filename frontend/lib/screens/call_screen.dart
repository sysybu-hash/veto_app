// ============================================================
//  call_screen.dart — WebRTC Audio/Video Call Screen
//  VETO Legal Emergency App
//
//  Route: /call
//  Args:  { roomId, callType: 'video'|'audio', peerName, role }
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/call_api_service.dart';
import '../services/call_recording_service.dart';
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

  bool _showTranscript = false;
  bool _recordingStarted = false;
  bool _finalizedCall = false;
  bool _savingArtifacts = false;
  String? _transcriptText;
  String? _callErrorText;
  late final CallRecordingService _recordingService;
  final CallApiService _callApiService = CallApiService();

  /// Subscriber-only: user must opt in before we capture media.
  bool _isSubscriber = false;
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

    setState(() {
      _roomId    = args['roomId']?.toString() ?? '';
      _callType  = ct;
      _peerName  = args['peerName']?.toString() ?? 'Legal Counsel';
      _myRole    = myRole;
      _eventId   = args['eventId']?.toString() ?? '';
      _language  = args['language']?.toString() ?? 'he';
    });

    final socketService = context.read<SocketService>();
    _isSubscriber = await AuthService().getStoredIsSubscribed();
    if (!mounted) return;

    final online = await socketService.ensureConnected(role: myRole);
    if (!mounted) return;
    if (!online) {
      setState(() {
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
      setState(() => _waitSeconds++);
    });
    _waitTimeout = Timer(const Duration(seconds: 75), () {
      if (!mounted) return;
      if (w.state != CallState.connected) {
        setState(() => _timedOut = true);
        _waitTick?.cancel();
      }
    });
  }

  void _onChatReadyEvent(dynamic raw) {
    if (!mounted) return;
    final m = _socketMap(raw);
    if (m['roomId']?.toString() != _roomId) return;
    setState(() => _chatReady = true);
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
    setState(() {
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
      setState(() => _waitSeconds++);
    });
    _waitTimeout = Timer(const Duration(seconds: 75), () {
      if (!mounted) return;
      if (!_chatReady) {
        setState(() => _timedOut = true);
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
      setState(() => _chatSeconds++);
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
    setState(() {});

    if (w.errorMessage != null && w.errorMessage!.trim().isNotEmpty) {
      _callErrorText = w.errorMessage;
    }

    if (w.state == CallState.connected && !_recordingStarted) {
      _waitTimeout?.cancel();
      _waitTick?.cancel();
      if (mounted) {
        setState(() {
          _timedOut = false;
          _waitSeconds = 0;
          _callErrorText = null;
        });
      }
      _maybeStartRecording(w);
    }

    if (w.state == CallState.ended && !_finalizedCall) {
      _finalizedCall = true;
      unawaited(_finalizeAndNavigate());
    }
  }

  void _maybeStartRecording(WebRTCService w) {
    if (_recordingStarted) return;
    if (!_isSubscriber || !_userOptedRecord) return;
    _recordingStarted = true;
    _liveRecording = true;
    _recordingService.start(
      localStream: w.localStream,
      remoteStream: w.remoteStream,
      video: _callType == 'video',
    );
  }

  Future<void> _toggleRecordingOptIn() async {
    if (!_isSubscriber) return;
    setState(() => _userOptedRecord = !_userOptedRecord);
    final w = _webrtc;
    if (_userOptedRecord && w != null && w.state == CallState.connected && !_recordingStarted) {
      _maybeStartRecording(w);
    }
    if (!_userOptedRecord && _liveRecording) {
      await _recordingService.stop();
      _recordingStarted = false;
      _liveRecording = false;
    }
  }

  Future<void> _retryJoin() async {
    _waitTimeout?.cancel();
    _waitTick?.cancel();
    setState(() {
      _timedOut = false;
      _waitSeconds = 0;
      _callErrorText = null;
      _finalizedCall = false;
      _recordingStarted = false;
      _liveRecording = false;
    });

    if (_isChat) {
      setState(() {
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
      setState(() {
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
      setState(() => _waitSeconds++);
    });
    _waitTimeout = Timer(const Duration(seconds: 75), () {
      if (!mounted) return;
      if (w.state != CallState.connected) {
        setState(() => _timedOut = true);
        _waitTick?.cancel();
      }
    });
  }

  Future<void> _finalizeAndNavigate() async {
    await _finalizeArtifacts();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      _myRole == 'lawyer' ? '/lawyer_dashboard' : '/veto_screen',
    );
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
    await _webrtc?.endCall();
  }

  Future<void> _finalizeArtifacts() async {
    if (_savingArtifacts || _eventId.isEmpty) return;
    _savingArtifacts = true;
    if (mounted) {
      setState(() => _showTranscript = true);
    }

    try {
      if (_isChat) {
        final buf = StringBuffer();
        for (final line in _chatLines) {
          buf.writeln(line.mine ? '[Me] ${line.text}' : '[$_peerName] ${line.text}');
        }
        final transcript = buf.toString().trim();
        if (mounted) setState(() => _transcriptText = transcript);
        if (transcript.isNotEmpty && mounted) {
          await _maybeOfferVaultSave(transcript: transcript, audioBytes: null);
        }
        return;
      }

      final recording = await _recordingService.stop();
      _liveRecording = false;

      String? transcript;
      if (recording != null && recording.bytes.isNotEmpty) {
        await _callApiService.uploadRecording(
          eventId: _eventId,
          bytes: recording.bytes,
          mimeType: recording.mimeType,
          fileName: recording.fileName,
        );

        transcript = await _callApiService.transcribeRecording(
          eventId: _eventId,
          bytes: recording.bytes,
          mimeType: recording.mimeType,
          language: _language,
        );
      }

      if (mounted) {
        setState(() => _transcriptText = transcript);
      }

      if (mounted && transcript != null && transcript.isNotEmpty) {
        await _maybeOfferVaultSave(
          transcript: transcript,
          audioBytes: recording?.bytes,
          audioMime: recording?.mimeType,
          audioName: recording?.fileName,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _transcriptText = _language == 'he'
              ? 'שמירת ההקלטה או התמלול נכשלה.'
              : 'Recording or transcription failed to save.';
        });
      }
    } finally {
      _savingArtifacts = false;
    }
  }

  Future<void> _maybeOfferVaultSave({
    required String transcript,
    Uint8List? audioBytes,
    String? audioMime,
    String? audioName,
  }) async {
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_language == 'he'
            ? 'שמירה לכספת'
            : _language == 'ru'
                ? 'Сохранить в хранилище'
                : 'Save to vault'),
        content: Text(_language == 'he'
            ? 'לשמור את התמלול (וההקלטה אם קיימת) לתיק המסמכים?'
            : _language == 'ru'
                ? 'Сохранить расшифровку (и запись) в хранилище?'
                : 'Save transcript (and recording if any) to your file vault?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_language == 'he' ? 'לא' : _language == 'ru' ? 'Нет' : 'No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_language == 'he' ? 'שמור' : _language == 'ru' ? 'Сохранить' : 'Save'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;

    final token = await AuthService().getToken();
    if (token == null) return;

    try {
      final tReq = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/vault/files/upload'),
      );
      tReq.headers.addAll(
        AppConfig.httpHeadersBinary({'Authorization': 'Bearer $token'}),
      );
      tReq.fields['name'] = 'veto-transcript-$_eventId.txt';
      tReq.fields['mimeType'] = 'text/plain';
      tReq.files.add(http.MultipartFile.fromBytes(
        'file',
        utf8.encode(transcript),
        filename: 'veto-transcript-$_eventId.txt',
      ));
      final tRes = await tReq.send();
      if (tRes.statusCode < 200 || tRes.statusCode >= 300) {
        throw Exception('transcript vault ${tRes.statusCode}');
      }

      if (audioBytes != null && audioBytes.isNotEmpty) {
        final aReq = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConfig.baseUrl}/vault/files/upload'),
        );
        aReq.headers.addAll(
          AppConfig.httpHeadersBinary({'Authorization': 'Bearer $token'}),
        );
        aReq.fields['name'] = audioName ?? 'veto-call-$_eventId.webm';
        aReq.fields['mimeType'] = audioMime ?? 'audio/webm';
        aReq.files.add(http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: audioName ?? 'recording.webm',
        ));
        await aReq.send();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_language == 'he'
                ? 'נשמר בכספת'
                : _language == 'ru'
                    ? 'Сохранено'
                    : 'Saved to vault'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_language == 'he'
                ? 'שמירה לכספת נכשלה'
                : 'Vault save failed'),
            backgroundColor: VetoColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
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
    _webrtc?.removeListener(_onWebRTCUpdate);
    _webrtc?.dispose();
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
            if (_showTranscript)
              Positioned(
                bottom: 120, left: 16, right: 16,
                child: _buildTranscriptPanel(),
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
    setState(() {
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
  //  Transcript panel
  // ─────────────────────────────────────────────────────────
  Widget _buildTranscriptPanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.transcribe, color: Color(0xFF5B8FFF), size: 16),
              const SizedBox(width: 8),
              const Text(
                'תמלול חי',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B8FFF),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showTranscript = false),
                child: const Icon(Icons.close, color: Color(0xFF64748B), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _transcriptText ??
                (            _savingArtifacts
                    ? 'שומר הקלטה ומכין תמלול...'
                    : 'התמלול יהיה זמין בסיום השיחה...'),
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 13,
              color: Color(0xFF334155),
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
              if (_isSubscriber)
                _buildControlBtn(
                  icon: _userOptedRecord ? Icons.radio_button_checked : Icons.radio_button_off,
                  label: _language == 'he' ? 'הקלטה' : 'Rec',
                  color: _userOptedRecord ? Colors.redAccent : VetoColors.silver,
                  onTap: () => unawaited(_toggleRecordingOptIn()),
                ),
              if (_isSubscriber) const SizedBox(width: 16),
              _buildControlBtn(
                icon: Icons.transcribe,
                label: 'תמלול',
                color: _showTranscript ? VetoColors.accent : VetoColors.silver,
                onTap: () => setState(() => _showTranscript = !_showTranscript),
              ),
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
