// ============================================================
//  call_screen.dart — WebRTC Audio/Video Call Screen
//  VETO Legal Emergency App
//
//  Route: /call
//  Args:  { roomId, callType: 'video'|'audio', peerName, role }
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../core/theme/veto_theme.dart';
import '../services/call_api_service.dart';
import '../services/call_recording_service.dart';
import '../services/webrtc_service.dart';
import '../services/socket_service.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late WebRTCService  _webrtc;
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
    setState(() {
      _roomId    = args['roomId']?.toString() ?? '';
      _callType  = args['callType']?.toString() ?? 'video';
      _peerName  = args['peerName']?.toString() ?? 'Legal Counsel';
      _myRole    = myRole;
      _eventId   = args['eventId']?.toString() ?? '';
      _language  = args['language']?.toString() ?? 'he';
    });

    final socketService = context.read<SocketService>();
    // WebRTC registers listeners on the underlying socket — it must exist first.
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

    _webrtc = WebRTCService(socketService);

    await _webrtc.joinRoom(
      _roomId,
      _callType == 'video' ? CallType.video : CallType.audio,
      socketRole: myRole,
    );

    _webrtc.addListener(_onWebRTCUpdate);

    // Start waiting countdown — 75 seconds max
    _waitTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _waitSeconds++);
    });
    _waitTimeout = Timer(const Duration(seconds: 75), () {
      if (!mounted) return;
      if (_webrtc.state != CallState.connected) {
        setState(() => _timedOut = true);
        _waitTick?.cancel();
      }
    });
  }

  void _onWebRTCUpdate() {
    if (!mounted) return;
    setState(() {});

    if (_webrtc.errorMessage != null && _webrtc.errorMessage!.trim().isNotEmpty) {
      _callErrorText = _webrtc.errorMessage;
    }

    if (_webrtc.state == CallState.connected && !_recordingStarted) {
      // Cancel waiting timeout — call connected
      _waitTimeout?.cancel();
      _waitTick?.cancel();
      if (mounted) {
        setState(() {
          _timedOut = false;
          _waitSeconds = 0;
          _callErrorText = null;
        });
      }
      _recordingStarted = true;
      _recordingService.start(
        localStream: _webrtc.localStream,
        remoteStream: _webrtc.remoteStream,
        video: _callType == 'video',
      );
    }

    if (_webrtc.state == CallState.ended && !_finalizedCall) {
      _finalizedCall = true;
      unawaited(_finalizeAndNavigate());
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
    });

    _webrtc.dispose();
    final socketService = context.read<SocketService>();
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
    _webrtc = WebRTCService(socketService);
    _webrtc.addListener(_onWebRTCUpdate);
    await _webrtc.joinRoom(
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
      if (_webrtc.state != CallState.connected) {
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
    await _webrtc.endCall();
  }

  Future<void> _finalizeArtifacts() async {
    if (_savingArtifacts || _eventId.isEmpty) return;
    _savingArtifacts = true;
    if (mounted) {
      setState(() => _showTranscript = true);
    }

    try {
      final recording = await _recordingService.stop();
      if (recording == null || recording.bytes.isEmpty) return;

      await _callApiService.uploadRecording(
        eventId: _eventId,
        bytes: recording.bytes,
        mimeType: recording.mimeType,
        fileName: recording.fileName,
      );

      final transcript = await _callApiService.transcribeRecording(
        eventId: _eventId,
        bytes: recording.bytes,
        mimeType: recording.mimeType,
        language: _language,
      );

      if (mounted) {
        setState(() => _transcriptText = transcript);
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

  @override
  void dispose() {
    _waitTimeout?.cancel();
    _waitTick?.cancel();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _webrtc.removeListener(_onWebRTCUpdate);
    _webrtc.dispose();
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
            // ── Video layer ─────────────────────────────────
            _buildVideoLayer(),

            // ── Gradient overlay ────────────────────────────
            _buildGradientOverlay(),

            // ── Top bar ─────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(child: _buildTopBar()),
            ),

            // ── Transcript drawer ───────────────────────────
            if (_showTranscript)
              Positioned(
                bottom: 120, left: 16, right: 16,
                child: _buildTranscriptPanel(),
              ),

            // ── Controls ────────────────────────────────────
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
  //  Video layer
  // ─────────────────────────────────────────────────────────
  Widget _buildVideoLayer() {
    final isVideo = _callType == 'video';
    final isConnected = _webrtc.state == CallState.connected;

    if (!isVideo || !isConnected) {
      // Audio call or connecting — show avatar
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: VetoDecorations.gradientBg(),
        child: Center(child: _buildAvatar()),
      );
    }

    return Stack(
      children: [
        // Remote video (full screen)
        Positioned.fill(
          child: RTCVideoView(
            _webrtc.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),

        // Local video (picture-in-picture)
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
              child: _webrtc.cameraOff
                  ? const Center(
                      child: Icon(Icons.videocam_off, color: VetoColors.silver, size: 28),
                    )
                  : RTCVideoView(
                      _webrtc.localRenderer,
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
  Widget _buildAvatar() {
    final isConnecting = _webrtc.state != CallState.connected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle
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

        // Status
        _buildStatusText(),

        const SizedBox(height: 20),

        // Waiting countdown + cancel
        if (_webrtc.state == CallState.error) ...[
          _buildErrorPanel(),
        ] else if (_webrtc.state == CallState.joining || _webrtc.state == CallState.ringing) ...[
          _timedOut
              ? _buildTimeoutPanel()
              : _buildWaitingPanel(),
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

  Widget _buildStatusText() {
    String text;
    Color  color;

    switch (_webrtc.state) {
      case CallState.joining:
        text  = 'מתחבר לחדר...';
        color = VetoColors.accent;
      case CallState.ringing:
        text  = 'מחכה לצד השני...';
        color = VetoColors.warning;
      case CallState.connected:
        text  = _webrtc.formattedDuration;
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
        if (_webrtc.state == CallState.connected)
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // VETO logo / badge
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

          // Call type indicator
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
                  _callType == 'video' ? Icons.videocam : Icons.mic,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _callType == 'video' ? 'וידאו' : 'אודיו',
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

          // Duration when connected
          if (_webrtc.state == CallState.connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: VetoColors.success.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VetoColors.success.withValues(alpha:0.3)),
              ),
              child: Text(
                _webrtc.formattedDuration,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Secondary controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlBtn(
                icon: _webrtc.micMuted ? Icons.mic_off : Icons.mic,
                label: _webrtc.micMuted ? 'הפעל' : 'השתק',
                color: _webrtc.micMuted ? VetoColors.error : VetoColors.silver,
                onTap: _webrtc.toggleMic,
              ),
              const SizedBox(width: 16),
              if (_callType == 'video') ...[
                _buildControlBtn(
                  icon: _webrtc.cameraOff ? Icons.videocam_off : Icons.videocam,
                  label: _webrtc.cameraOff ? 'הפעל' : 'כבה',
                  color: _webrtc.cameraOff ? VetoColors.error : VetoColors.silver,
                  onTap: _webrtc.toggleCamera,
                ),
                const SizedBox(width: 16),
                _buildControlBtn(
                  icon: Icons.flip_camera_ios,
                  label: 'הפוך',
                  color: VetoColors.silver,
                  onTap: _webrtc.switchCamera,
                ),
                const SizedBox(width: 16),
              ],
              _buildControlBtn(
                icon: Icons.transcribe,
                label: 'תמלול',
                color: _showTranscript ? VetoColors.accent : VetoColors.silver,
                onTap: () => setState(() => _showTranscript = !_showTranscript),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // End call button
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
