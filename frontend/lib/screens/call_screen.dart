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
  late final CallRecordingService _recordingService;
  final CallApiService _callApiService = CallApiService();

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
    if (args == null) return;

    setState(() {
      _roomId    = args['roomId']?.toString() ?? '';
      _callType  = args['callType']?.toString() ?? 'video';
      _peerName  = args['peerName']?.toString() ?? 'Legal Counsel';
      _myRole    = args['role']?.toString() ?? 'user';
      _eventId   = args['eventId']?.toString() ?? '';
      _language  = args['language']?.toString() ?? 'he';
    });

    final socketService = context.read<SocketService>();
    _webrtc = WebRTCService(socketService);

    await _webrtc.joinRoom(
      _roomId,
      _callType == 'video' ? CallType.video : CallType.audio,
    );

    _webrtc.addListener(_onWebRTCUpdate);
  }

  void _onWebRTCUpdate() {
    if (!mounted) return;
    setState(() {});

    if (_webrtc.state == CallState.connected && !_recordingStarted) {
      _recordingStarted = true;
      _recordingService.start(
        localStream: _webrtc.localStream,
        remoteStream: _webrtc.remoteStream,
        video: _callType == 'video',
      );
    }

    if ((_webrtc.state == CallState.ended || _webrtc.state == CallState.error) &&
        !_finalizedCall) {
      _finalizedCall = true;
      unawaited(_finalizeAndNavigate());
    }
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
      ],
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
              boxShadow: [BoxShadow(color: VetoColors.success.withOpacity(0.5), blurRadius: 6)],
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
                Colors.black.withOpacity(0.6),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.8),
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
              border: Border.all(color: VetoColors.vetoRed.withOpacity(0.3)),
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
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: VetoColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _callType == 'video' ? Icons.videocam : Icons.mic,
                  color: VetoColors.silver,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _callType == 'video' ? 'וידאו' : 'אודיו',
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    color: VetoColors.silver,
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
                color: VetoColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VetoColors.success.withOpacity(0.3)),
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
        color: VetoColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.transcribe, color: VetoColors.accent, size: 16),
              const SizedBox(width: 8),
              const Text(
                'תמלול חי',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: VetoColors.accent,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showTranscript = false),
                child: const Icon(Icons.close, color: VetoColors.silver, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _transcriptText ??
                (_savingArtifacts
                    ? 'שומר הקלטה ומכין תמלול...'
                    : 'התמלול יהיה זמין בסיום השיחה...'),
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 13,
              color: VetoColors.silver,
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
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
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
