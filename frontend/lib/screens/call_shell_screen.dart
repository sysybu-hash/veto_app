// ============================================================
//  call_shell_screen.dart — VETO 2026 call orchestrator.
//
//  Single Scaffold that owns the whole lifecycle of a call:
//    idle → connecting → active → ended / error
//
//  Mirrors the 4 mockup states from `2026/communication.html`:
//    * incoming  (lawyer accepts / declines)
//    * connecting (citizen SOS orb)
//    * active (voice/video + side panel)
//    * error (V26CallErrorSheet)
//
//  Wires up:
//    * `AgoraService` for RTC lifecycle, controls and error reporting.
//    * `SocketService` for `call-chat-message`, `call-ended`, `peer-left`
//      and `call-timeout` / `call-token-renewed`.
//    * `CallApiService.fetchFreshAgoraToken` for `onTokenPrivilegeWillExpire`.
//    * `InCallSpeech` facade for on-device captions (mobile).
//    * `VaultSaveQueue` for post-call transcript enqueue.
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/veto_2026.dart';
import '../services/agora_service.dart';
import '../services/call_api_service.dart';
import '../services/call_route_args_storage.dart';
import '../services/in_call_permissions.dart';
import '../services/socket_service.dart';
import '../services/vault_save_queue.dart';
import '../widgets/call/call_i18n.dart';
import '../widgets/call/v26_call_connecting.dart';
import '../widgets/call/v26_call_control_bar.dart';
import '../widgets/call/v26_call_error_sheet.dart';
import '../widgets/call/v26_call_incoming.dart';
import '../widgets/call/v26_call_side_panel.dart';
import '../widgets/call/v26_call_stage.dart';
import '../widgets/call/v26_call_top_bar.dart';
import '../widgets/call/v26_call_video_area.dart';
import '../widgets/call/v26_call_voice_stage.dart';
import 'in_call_speech.dart';

/// Lifecycle states surfaced to the shell (distinct from [CallConnectionPhase]
/// on the Agora service — the shell also covers the "incoming" and "local
/// ended" flows that live outside the RTC engine).
enum CallShellPhase { idle, incoming, connecting, active, ended, error }

/// Arguments decoded from `ModalRoute.settings.arguments` and/or
/// [callRouteArgsStorageRead] (for Web refresh resilience).
class _CallArgs {
  const _CallArgs({
    required this.channelId,
    required this.eventId,
    required this.language,
    required this.token,
    required this.agoraUid,
    required this.peerLabel,
    required this.peerSpecialization,
    required this.caseSummary,
    required this.distanceLabel,
    required this.wantVideo,
    required this.chatOnly,
    required this.socketRole,
    required this.isIncoming,
  });

  final String channelId;
  final String eventId;
  final String language;
  final String token;
  final int agoraUid;
  final String peerLabel;
  final String? peerSpecialization;
  final String caseSummary;
  final String? distanceLabel;
  final bool wantVideo;
  final bool chatOnly;
  final String socketRole;
  final bool isIncoming;

  static _CallArgs? tryParse(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final roomId = raw['roomId']?.toString() ?? '';
    if (roomId.isEmpty) return null;
    var ct = raw['callType']?.toString() ?? 'video';
    if (ct == 'webrtc') ct = 'video';
    int parseUid(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return _CallArgs(
      channelId: roomId,
      eventId: raw['eventId']?.toString() ?? roomId,
      language: raw['language']?.toString() ?? 'he',
      token: raw['agoraToken']?.toString() ?? '',
      agoraUid: parseUid(raw['agoraUid']),
      peerLabel: raw['peerName']?.toString() ?? 'Peer',
      peerSpecialization: raw['peerSpecialization']?.toString(),
      caseSummary: raw['caseSummary']?.toString() ?? '',
      distanceLabel: raw['distanceLabel']?.toString(),
      wantVideo: ct == 'video',
      chatOnly: ct == 'chat',
      socketRole: raw['role']?.toString() ?? 'user',
      isIncoming: raw['mode']?.toString() == 'incoming',
    );
  }
}

/// Entry point for `/call` — handles missing-args guard + state machine.
class CallShellScreen extends StatefulWidget {
  const CallShellScreen({super.key});

  @override
  State<CallShellScreen> createState() => _CallShellScreenState();
}

class _CallShellScreenState extends State<CallShellScreen>
    with TickerProviderStateMixin {
  _CallArgs? _args;
  CallShellPhase _phase = CallShellPhase.idle;

  final AgoraService _agora = AgoraService();
  final CallApiService _callApi = CallApiService();
  late final InCallSpeech _speech;

  StreamSubscription<CallErrorEvent>? _errorSub;
  CallErrorEvent? _activeError;

  final List<CallChatLine> _chatLines = <CallChatLine>[];
  bool _socketRegistered = false;
  bool _leaving = false;
  bool _remoteHangup = false;
  int _connectElapsed = 0;
  Timer? _connectTicker;
  Timer? _joinWatchdog;

  // Side panel drawer visibility (phone layout).
  bool _panelOpen = false;

  bool get _rtl =>
      (_args?.language ?? 'he') == 'he' || (_args?.language ?? 'he') == 'ar';

  @override
  void initState() {
    super.initState();
    _speech = createInCallSpeech(() {
      if (mounted) setState(() {});
    });
    _agora.addListener(_onAgoraChanged);
    _errorSub = _agora.errors.listen(_onAgoraError);
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  // ──────────────────────────────────────────────────────────────
  //  Boot
  // ──────────────────────────────────────────────────────────────

  Future<void> _boot() async {
    // Try route args first, then sessionStorage (Web refresh resilience).
    final raw = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? m;
    if (raw is Map<String, dynamic>) m = raw;
    m ??= callRouteArgsStorageRead();
    final args = _CallArgs.tryParse(m);
    if (args == null) {
      // No args → pop back to home. We do NOT silently render idle forever.
      if (mounted) Navigator.of(context).pushReplacementNamed('/veto_screen');
      return;
    }
    _args = args;
    _speech.setLanguageCode(args.language);

    if (args.isIncoming) {
      setState(() => _phase = CallShellPhase.incoming);
      return;
    }

    await _startConnecting(args);
  }

  Future<void> _startConnecting(_CallArgs args) async {
    setState(() {
      _phase = CallShellPhase.connecting;
      _connectElapsed = 0;
    });
    _connectTicker?.cancel();
    _connectTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _connectElapsed++);
    });
    // Client-side watchdog as a backstop for the server's call-timeout.
    _joinWatchdog?.cancel();
    _joinWatchdog = Timer(const Duration(seconds: 45), () {
      if (!mounted || _phase != CallShellPhase.connecting) return;
      setState(() {
        _activeError = const CallErrorEvent(
          CallErrorKind.connectionFailed,
          'Join timeout after 45s',
        );
        _phase = CallShellPhase.error;
      });
    });

    try {
      final socket = SocketService();
      final online = await socket.ensureConnected(role: args.socketRole);
      if (!online) {
        _setError(const CallErrorEvent(
          CallErrorKind.networkLost,
          'Socket offline',
        ));
        return;
      }
      _registerSockets();
      socket.emit('join-call-room', {
        'roomId': args.channelId,
        'callType': args.chatOnly
            ? 'chat'
            : (args.wantVideo ? 'video' : 'audio'),
      });

      // Chat-only: skip Agora entirely, transition to active as soon as the
      // socket reports the peer is ready (chat-ready) — or after the join
      // emit if the server echoes it back synchronously.
      if (args.chatOnly) {
        _joinWatchdog?.cancel();
        _connectTicker?.cancel();
        if (mounted) setState(() => _phase = CallShellPhase.active);
        return;
      }

      final perms = await requestCallPermissions(wantVideo: args.wantVideo);
      if (!perms.microphoneGranted) {
        _setError(const CallErrorEvent(
          CallErrorKind.permissionDenied,
          'Microphone permission denied',
        ));
        return;
      }
      // Camera denied is not fatal — we downgrade to audio-only below.
      final wantVideo = args.wantVideo && perms.cameraGranted;

      await _agora.joinChannel(
        channelId: args.channelId,
        token: args.token,
        uid: args.agoraUid,
        enableVideo: wantVideo,
        tokenFetcher: () => _fetchTokenForRenewal(args.eventId),
      );

      if (!kIsWeb) {
        unawaited(_agora.setSpeakerOn(true));
      }
    } catch (err) {
      _setError(CallErrorEvent(
        CallErrorKind.connectionFailed,
        err.toString(),
      ));
    }
  }

  Future<String?> _fetchTokenForRenewal(String eventId) async {
    final fresh = await _callApi.fetchFreshAgoraToken(eventId);
    if (fresh == null) return null;
    final t = fresh['agoraToken']?.toString();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  // ──────────────────────────────────────────────────────────────
  //  Agora + socket reactions
  // ──────────────────────────────────────────────────────────────

  void _onAgoraChanged() {
    if (!mounted) return;
    final phase = _agora.phase;
    if (phase == CallConnectionPhase.connected &&
        _phase == CallShellPhase.connecting) {
      _joinWatchdog?.cancel();
      _connectTicker?.cancel();
      setState(() => _phase = CallShellPhase.active);
    } else if (phase == CallConnectionPhase.failed &&
        _phase != CallShellPhase.error) {
      _setError(_agora.lastError ??
          const CallErrorEvent(CallErrorKind.connectionFailed, ''));
    } else {
      setState(() {});
    }
  }

  void _onAgoraError(CallErrorEvent ev) {
    if (!mounted) return;
    // We only surface fatal errors as the "error" phase. Transient
    // issues (brief token refreshes, low network) just bubble to the UI.
    final fatal = ev.kind == CallErrorKind.permissionDenied ||
        ev.kind == CallErrorKind.tokenInvalid ||
        ev.kind == CallErrorKind.connectionFailed;
    if (fatal) {
      _setError(ev);
    } else {
      setState(() => _activeError = ev);
    }
  }

  void _setError(CallErrorEvent ev) {
    if (!mounted) return;
    _joinWatchdog?.cancel();
    _connectTicker?.cancel();
    setState(() {
      _activeError = ev;
      _phase = CallShellPhase.error;
    });
  }

  void _registerSockets() {
    if (_socketRegistered) return;
    final s = SocketService();
    s.on('call-ended', _onRemoteCallEnded);
    s.on('peer-left', _onRemotePeerLeft);
    s.on('call-chat-message', _onRemoteChat);
    s.on('call-timeout', _onCallTimeout);
    s.on('call-token-renewed', _onTokenRenewed);
    _socketRegistered = true;
  }

  void _unregisterSockets() {
    if (!_socketRegistered) return;
    final s = SocketService();
    s.removeHandler('call-ended', _onRemoteCallEnded);
    s.removeHandler('peer-left', _onRemotePeerLeft);
    s.removeHandler('call-chat-message', _onRemoteChat);
    s.removeHandler('call-timeout', _onCallTimeout);
    s.removeHandler('call-token-renewed', _onTokenRenewed);
    _socketRegistered = false;
  }

  Map<String, dynamic> _mapOf(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return <String, dynamic>{};
  }

  void _onRemoteCallEnded(dynamic _) {
    if (_leaving || !mounted) return;
    _remoteHangup = true;
    unawaited(_endCall(fromRemote: true));
  }

  void _onRemotePeerLeft(dynamic _) {
    if (_leaving || !mounted) return;
    _remoteHangup = true;
    unawaited(_endCall(fromRemote: true));
  }

  void _onCallTimeout(dynamic _) {
    if (!mounted) return;
    if (_phase == CallShellPhase.connecting || _phase == CallShellPhase.idle) {
      _setError(const CallErrorEvent(
        CallErrorKind.connectionFailed,
        'Peer did not join (server timeout)',
      ));
    }
  }

  void _onRemoteChat(dynamic raw) {
    if (!mounted) return;
    final m = _mapOf(raw);
    final text = m['text']?.toString() ?? '';
    if (text.isEmpty) return;
    final from = m['fromRole']?.toString() ?? '';
    final args = _args;
    if (args == null) return;
    final meIsCitizen = args.socketRole == 'user' || args.socketRole == 'admin';
    final isMine = meIsCitizen
        ? (from == 'user' || from == 'admin')
        : from == 'lawyer';
    setState(() =>
        _chatLines.add(CallChatLine(text: text, mine: isMine)));
  }

  void _onTokenRenewed(dynamic raw) {
    if (!mounted) return;
    final m = _mapOf(raw);
    final fresh = m['agoraToken']?.toString() ?? '';
    if (fresh.isEmpty) return;
    // Delegating renewal via agora_service's tokenFetcher happens automatically;
    // this path is a defensive fallback when the server pushes a new token
    // proactively (e.g. staff-forced rotation).
    unawaited(_agora.engine?.renewToken(fresh));
  }

  // ──────────────────────────────────────────────────────────────
  //  Controls wiring
  // ──────────────────────────────────────────────────────────────

  Future<void> _endCall({bool fromRemote = false}) async {
    if (_leaving) return;
    _leaving = true;
    _connectTicker?.cancel();
    _joinWatchdog?.cancel();
    _unregisterSockets();
    unawaited(_speech.dispose());
    final args = _args;
    try {
      if (!fromRemote && !_remoteHangup && args != null) {
        SocketService().emit('call-ended', {
          'roomId': args.channelId,
          'duration': _agora.durationSec,
        });
      }
    } catch (_) {}
    if (mounted) {
      _queueTranscript();
    }
    try {
      await _agora.leaveAndRelease();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _phase = CallShellPhase.ended);
    try {
      callRouteArgsStorageClear();
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _queueTranscript() {
    final args = _args;
    if (args == null) return;
    if (args.eventId.isEmpty) return;
    if (_agora.durationSec < 1) return;
    try {
      context.read<VaultSaveQueue>().enqueueAgoraRecordingTranscript(
            eventId: args.eventId,
            language: args.language,
            roomLabel: args.peerLabel,
          );
    } catch (_) {}
  }

  Future<void> _confirmEnd() async {
    if (_leaving) return;
    final lang = _args?.language ?? 'he';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: V26.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          switch (lang) {
            'he' => 'לצאת מהשיחה?',
            'ru' => 'Покинуть звонок?',
            _ => 'Leave call?',
          },
          style: const TextStyle(
            fontFamily: V26.serif,
            fontWeight: FontWeight.w700,
            color: V26.ink900,
          ),
        ),
        content: Text(
          switch (lang) {
            'he' => 'השיחה תיסגר לשני הצדדים.',
            'ru' => 'Сессия завершится для обеих сторон.',
            _ => 'The session will end for both sides.',
          },
          style: const TextStyle(fontFamily: V26.sans, color: V26.ink500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              switch (lang) {
                'he' => 'ביטול',
                'ru' => 'Отмена',
                _ => 'Cancel',
              },
              style: const TextStyle(fontFamily: V26.sans, color: V26.ink500),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: V26.emerg),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              CallI18n.endCall.t(lang),
              style:
                  const TextStyle(fontFamily: V26.sans, color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await _endCall();
  }

  void _sendChat(String text) {
    final args = _args;
    if (args == null) return;
    try {
      SocketService().emit('call-chat-message', {
        'roomId': args.channelId,
        'text': text,
      });
    } catch (_) {}
    setState(() => _chatLines.add(CallChatLine(text: text, mine: true)));
  }

  void _acceptIncoming() {
    final args = _args;
    if (args == null) return;
    setState(() => _phase = CallShellPhase.connecting);
    unawaited(_startConnecting(args));
  }

  void _declineIncoming() {
    final args = _args;
    if (args != null) {
      try {
        SocketService().emit('call-ended', {
          'roomId': args.channelId,
          'reason': 'declined',
        });
      } catch (_) {}
    }
    try {
      callRouteArgsStorageClear();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _retryFromError() async {
    final args = _args;
    if (args == null) return;
    setState(() {
      _activeError = null;
      _phase = CallShellPhase.connecting;
    });
    try {
      await _agora.leaveAndRelease();
    } catch (_) {}
    await _startConnecting(args);
  }

  // ──────────────────────────────────────────────────────────────
  //  Render
  // ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _connectTicker?.cancel();
    _joinWatchdog?.cancel();
    _errorSub?.cancel();
    _agora.removeListener(_onAgoraChanged);
    _unregisterSockets();
    unawaited(_speech.dispose());
    _agora.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dir = _rtl ? TextDirection.rtl : TextDirection.ltr;
    return PopScope(
      canPop: _phase == CallShellPhase.ended ||
          _phase == CallShellPhase.error ||
          _phase == CallShellPhase.incoming,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmEnd();
      },
      child: V26CallStage(
        textDirection: dir,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case CallShellPhase.idle:
        return const Center(
          child: CircularProgressIndicator(color: V26.gold),
        );
      case CallShellPhase.incoming:
        final a = _args!;
        return V26CallIncoming(
          language: a.language,
          callerName: a.peerLabel,
          caseSummary: a.caseSummary,
          specialization: a.peerSpecialization,
          distanceLabel: a.distanceLabel,
          onAccept: _acceptIncoming,
          onDecline: _declineIncoming,
        );
      case CallShellPhase.connecting:
        final a = _args!;
        return V26CallConnecting(
          language: a.language,
          elapsedSec: _connectElapsed,
          onCancel: _endCall,
        );
      case CallShellPhase.active:
        return _buildActive();
      case CallShellPhase.ended:
        return const Center(
          child: CircularProgressIndicator(color: V26.gold),
        );
      case CallShellPhase.error:
        final lang = _args?.language ?? 'he';
        return V26CallErrorSheet(
          language: lang,
          error: _activeError ??
              const CallErrorEvent(CallErrorKind.unknown, ''),
          onRetry: _retryFromError,
          onExit: _endCall,
        );
    }
  }

  Widget _buildActive() {
    final a = _args!;
    final width = MediaQuery.sizeOf(context).width;
    final useWideSide = width >= 900;
    // Chat-only: the whole stage is the side panel (no Agora video/voice).
    if (a.chatOnly) {
      return Column(
        children: [
          V26CallTopBar(
            peerName: a.peerLabel,
            specialization: a.peerSpecialization,
            durationSec: _agora.durationSec,
            quality: _agora.quality,
            language: a.language,
          ),
          Expanded(
            child: Material(
              color: V26.surface,
              child: V26CallSidePanel(
                language: a.language,
                lines: _chatLines,
                onSend: _sendChat,
                captionLines: _speech.lines,
                captionListening: _speech.listening,
                captionError: _speech.error,
                onToggleCaption: () => _speech.toggle(),
              ),
            ),
          ),
          _buildControls(a),
        ],
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: a.wantVideo
              ? _buildVideoStage(a, useWideSide)
              : _buildVoiceStage(a, useWideSide),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: V26CallTopBar(
            peerName: a.peerLabel,
            specialization: a.peerSpecialization,
            durationSec: _agora.durationSec,
            quality: _agora.quality,
            language: a.language,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildControls(a),
        ),
        if (useWideSide)
          Positioned(
            top: 0,
            bottom: 0,
            right: _rtl ? null : 0,
            left: _rtl ? 0 : null,
            width: 340,
            child: Material(
              elevation: 8,
              color: V26.surface,
              child: V26CallSidePanel(
                language: a.language,
                lines: _chatLines,
                onSend: _sendChat,
                captionLines: _speech.lines,
                captionListening: _speech.listening,
                captionError: _speech.error,
                onToggleCaption: () => _speech.toggle(),
              ),
            ),
          )
        else if (_panelOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _panelOpen = false),
              child: Container(
                color: Colors.black54,
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {},
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.65,
                    child: Material(
                      color: V26.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: V26CallSidePanel(
                          language: a.language,
                          lines: _chatLines,
                          onSend: _sendChat,
                          captionLines: _speech.lines,
                          captionListening: _speech.listening,
                          captionError: _speech.error,
                          onToggleCaption: () => _speech.toggle(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoStage(_CallArgs a, bool wideSide) {
    final pipPadEnd = wideSide ? 360.0 : 16.0;
    return Stack(
      children: [
        Positioned.fill(
          child: V26CallVideoArea(
            engine: _agora.engine,
            channelId: a.channelId,
            remoteUid: _agora.remoteUid,
            hasRemoteVideo: _agora.hasRemoteVideo,
            peerName: a.peerLabel,
            language: a.language,
          ),
        ),
        PositionedDirectional(
          top: 86,
          end: pipPadEnd,
          child: V26CallLocalPip(
            engine: _agora.engine,
            previewOk: _agora.localPreviewOk,
            language: a.language,
            videoMuted: _agora.videoPublishMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceStage(_CallArgs a, bool wideSide) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          top: 78,
          bottom: 150,
          start: 16,
          end: wideSide ? 356 : 16,
        ),
        child: V26CallVoiceStage(
          peerName: a.peerLabel,
          specialization: a.peerSpecialization,
          durationSec: _agora.durationSec,
          isRecording: false,
          language: a.language,
        ),
      ),
    );
  }

  Widget _buildControls(_CallArgs a) {
    final lang = a.language;
    if (a.chatOnly) {
      return V26CallControlBar(
        children: [
          V26CallButton(
            icon: Icons.call_end_rounded,
            variant: V26CallButtonVariant.danger,
            tooltip: CallI18n.endCall.t(lang),
            size: 68,
            iconSize: 26,
            onPressed: _confirmEnd,
          ),
        ],
      );
    }
    return V26CallControlBar(
      children: [
        V26CallButton(
          icon: _agora.micPublishMuted ? Icons.mic_off : Icons.mic,
          variant: _agora.micPublishMuted
              ? V26CallButtonVariant.danger
              : V26CallButtonVariant.active,
          tooltip: _agora.micPublishMuted
              ? CallI18n.unmuteMic.t(lang)
              : CallI18n.muteMic.t(lang),
          onPressed: () =>
              _agora.setMicPublishMuted(!_agora.micPublishMuted),
        ),
        if (a.wantVideo)
          V26CallButton(
            icon: _agora.videoPublishMuted
                ? Icons.videocam_off
                : Icons.videocam,
            variant: _agora.videoPublishMuted
                ? V26CallButtonVariant.danger
                : V26CallButtonVariant.active,
            tooltip: _agora.videoPublishMuted
                ? CallI18n.cameraOff.t(lang)
                : CallI18n.camera.t(lang),
            onPressed: () =>
                _agora.setVideoPublishMuted(!_agora.videoPublishMuted),
          ),
        if (a.wantVideo && !kIsWeb)
          V26CallButton(
            icon: Icons.cameraswitch_rounded,
            tooltip: CallI18n.flipCamera.t(lang),
            onPressed: () => _agora.switchCamera(),
          ),
        if (!kIsWeb)
          V26CallButton(
            icon: _agora.speakerOn ? Icons.volume_up : Icons.hearing,
            variant: _agora.speakerOn
                ? V26CallButtonVariant.active
                : V26CallButtonVariant.neutral,
            tooltip: CallI18n.speaker.t(lang),
            onPressed: () => _agora.setSpeakerOn(!_agora.speakerOn),
          ),
        if (kIsWeb)
          V26CallButton(
            icon: _agora.screenSharing
                ? Icons.stop_screen_share_rounded
                : Icons.screen_share_rounded,
            variant: _agora.screenSharing
                ? V26CallButtonVariant.success
                : V26CallButtonVariant.neutral,
            tooltip: _agora.screenSharing
                ? CallI18n.stopScreenShare.t(lang)
                : CallI18n.screenShare.t(lang),
            onPressed: () => _agora.toggleScreenShare(),
          ),
        V26CallButton(
          icon: _agora.noiseSuppression
              ? Icons.noise_aware
              : Icons.noise_control_off,
          variant: _agora.noiseSuppression
              ? V26CallButtonVariant.active
              : V26CallButtonVariant.neutral,
          tooltip: CallI18n.noiseSuppression.t(lang),
          onPressed: () =>
              _agora.setNoiseSuppression(!_agora.noiseSuppression),
        ),
        if (MediaQuery.sizeOf(context).width < 900)
          V26CallButton(
            icon: Icons.chat_bubble_rounded,
            tooltip: CallI18n.openChat.t(lang),
            onPressed: () => setState(() => _panelOpen = !_panelOpen),
          ),
        V26CallButton(
          icon: Icons.call_end_rounded,
          variant: V26CallButtonVariant.danger,
          tooltip: CallI18n.endCall.t(lang),
          size: 68,
          iconSize: 26,
          onPressed: _confirmEnd,
        ),
      ],
    );
  }
}
