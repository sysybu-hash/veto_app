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
import '../core/theme/veto_2026.dart';
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
  /// RTL layout for Hebrew / Arabic call args (video stage chrome + wide chat side).
  bool get _rtl => widget.language == 'he' || widget.language == 'ar';

  String _str({required String en, required String he, String? ru}) {
    switch (widget.language) {
      case 'he':
        return he;
      case 'ru':
        return ru ?? en;
      default:
        return en;
    }
  }

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
  bool _agoraFailed = false;

  final _chatScroll = ScrollController();
  final _chatInput = TextEditingController();
  final List<_ChatLine> _chatLines = <_ChatLine>[];

  late final InCallSpeech _inCallSpeech;
  late TabController _sideTabController;
  Timer? _bootstrapWatchdog;

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
    _bootstrapWatchdog = Timer(const Duration(seconds: 85), () {
      if (!mounted || !_starting) return;
      debugPrint('[VETO][CallSession] watchdog: forcing end of loading state');
      setState(() {
        _starting = false;
        _startError ??= _str(
          en: 'Connection took too long. Check login, network, camera/mic permission, and try again.',
          he: 'החיבור ארך יותר מדי. וודא התחברות, רשת והרשאות מצלמה/מיקרופון ונסה שוב.',
          ru: 'Подключение слишком долгое. Проверьте вход, сеть и доступ к камере/микрофону.',
        );
        _agoraFailed = true;
      });
      unawaited(_agora.leaveChannelAndRelease());
    });
    unawaited(_bootstrap());
  }

  void _onAgora() {
    if (_agora.errorMessage != null && _startError == null) {
      _startError = _agora.errorMessage;
      _starting = false;
    }
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
        _startError = _str(
          en: 'Could not connect to the server. Check your network and try again.',
          he: 'אין חיבור לשרת. בדוק רשת ונסה שוב.',
          ru: 'Не удалось подключиться к серверу. Проверьте сеть.',
        );
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
      // Web: joinChannel can hang indefinitely if WebRTC/camera is blocked — always cap wait time.
      await _agora
          .joinChannel(
            channelId: widget.channelId,
            token: widget.token,
            uid: widget.agoraUid,
            publishVideo: widget.wantVideo,
          )
          .timeout(
            const Duration(seconds: 40),
            onTimeout: () => throw TimeoutException(
              'Agora joinChannel exceeded 40s (often camera/mic permission or token).',
            ),
          );

      // Wait for Agora to fully join the channel
      int waitMs = 0;
      while (!_agora.joined && waitMs < 10000) {
        await Future.delayed(const Duration(milliseconds: 250));
        waitMs += 250;
      }
      if (!_agora.joined) {
        throw TimeoutException(
            'Agora media connection timed out waiting to join channel. Please verify token/App ID.');
      }
    } catch (e) {
      debugPrint('Agora connection failed: $e. Proceeding to chat fallback.');
      _agoraFailed = true;
    } finally {
      _bootstrapWatchdog?.cancel();
      _bootstrapWatchdog = null;
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

  Future<void> _confirmSystemBack() async {
    if (_leaving || _starting) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: V26.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _str(en: 'Leave call?', he: 'לצאת מהשיחה?', ru: 'Покинуть звонок?'),
          style: const TextStyle(
            fontFamily: V26.serif,
            color: V26.ink900,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          _str(
            en: 'The session will end for both sides.',
            he: 'השיחה תיסגר לשני הצדדים.',
            ru: 'Сессия завершится для обеих сторон.',
          ),
          style: const TextStyle(fontFamily: V26.sans, color: V26.ink500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _str(en: 'Cancel', he: 'ביטול', ru: 'Отмена'),
              style: const TextStyle(color: V26.ink500, fontFamily: V26.sans),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: V26.emerg,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _str(en: 'End call', he: 'סיים שיחה', ru: 'Завершить'),
              style: const TextStyle(fontFamily: V26.sans),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _endCall();
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
    final webMsg = _str(
      en: 'Connecting to media (browser)… If this stays stuck, allow camera/microphone for this site.',
      he: 'מתחבר למדיה (דפדפן)… אם נשאר כך — אשר מצלמה ומיקרופן בהרשאות האתר',
      ru: 'Подключение к медиа… Если зависло — разрешите камеру и микрофон для сайта.',
    );
    final nativeMsg = _str(
      en: 'Preparing call…',
      he: 'מכין שיחה…',
      ru: 'Подготовка звонка…',
    );
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            webMsg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: V26.sans,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          nativeMsg,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: V26.sans,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _remoteVideoOrWaiting({
    RtcEngine? eng,
    required int? remote,
    required String channel,
    required bool useVideoSurface,
  }) {
    if (_agoraFailed || eng == null) {
      final msg = _str(
        en: 'Media unavailable (camera/microphone).\nYou can still use the chat panel.',
        he: 'חיבור מדיה לא זמין (מצלמה/מיקרופון).\nאפשר להמשיך בצ׳אט בלוח הצד.',
        ru: 'Медиа недоступно (камера/микрофон).\nМожно пользоваться чатом на панели.',
      );
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: V26.sans,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    if (remote == null) {
      final wait = _str(
        en: 'Waiting for ${widget.peerLabel}…',
        he: 'ממתין ל־${widget.peerLabel}…',
        ru: 'Ожидание: ${widget.peerLabel}…',
      );
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(
              wait,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: V26.sans,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    if (!useVideoSurface) {
      final prep = _str(
        en: 'Preparing video view (browser)…',
        he: 'מכין תצוגת וידאו (דפדפן)…',
        ru: 'Подготовка видео (браузер)…',
      );
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white54),
            const SizedBox(height: 20),
            Text(
              prep,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: V26.sans,
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
    RtcEngine? eng,
    required bool useVideoSurface,
  }) {
    if (_agoraFailed || eng == null || !_agora.joined) {
      return const Center(
        child: Icon(Icons.videocam_outlined, color: V26.ink300),
      );
    }

    if (!useVideoSurface) {
      return const Center(
        child: CircularProgressIndicator(
          color: V26.navy300,
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
                color: V26.navy800.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(V26.rSm),
                border: Border.all(color: V26.gold.withValues(alpha: 0.35)),
                boxShadow: V26.shadow1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_rounded, color: V26.gold, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'VETO',
                    style: TextStyle(
                      fontFamily: V26.serif,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.95),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // אינדיקטור איכות רשת בזמן אמת
            if (quality.isNotEmpty) ...[
              _NetworkQualityChip(label: quality, rttMs: rtt),
              const SizedBox(width: 8),
            ],
            if (_agora.joined)
              Text(
                '${(_durationSeconds ~/ 60).toString().padLeft(2, '0')}:'
                '${(_durationSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontFamily: V26.sans,
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
                  fontFamily: V26.sans,
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
                    ? V26.navy500.withValues(alpha: 0.45)
                    : const Color(0x26FFFFFF),
              ),
              icon: Icon(
                _agora.noiseSuppression
                    ? Icons.noise_aware
                    : Icons.noise_control_off,
                color: _agora.noiseSuppression ? V26.navy200 : Colors.white54,
              ),
              tooltip: _agora.noiseSuppression
                  ? _str(
                      en: 'Noise suppression on',
                      he: 'דיכוי רעשים פעיל',
                      ru: 'Шумоподавление вкл.')
                  : _str(
                      en: 'Noise suppression off',
                      he: 'דיכוי רעשים כבוי',
                      ru: 'Шумоподавление выкл.'),
            ),
            const SizedBox(width: 4),
            if (!kIsWeb)
              IconButton(
                onPressed: () {
                  unawaited(_agora.setSpeakerOn(!_agora.speakerOn));
                },
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x26FFFFFF),
                ),
                icon: Icon(
                  _agora.speakerOn ? Icons.volume_up : Icons.hearing,
                  color: Colors.white,
                ),
                tooltip: _str(en: 'Speaker', he: 'רמקול', ru: 'Динамик'),
              ),
            if (!kIsWeb) const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                unawaited(
                  _agora.setMicPublishMuted(!_agora.micPublishMuted),
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: _agora.micPublishMuted
                    ? V26.emerg.withValues(alpha: 0.85)
                    : const Color(0x26FFFFFF),
              ),
              icon: Icon(
                _agora.micPublishMuted ? Icons.mic_off : Icons.mic,
                color: Colors.white,
              ),
              tooltip: _str(en: 'Microphone', he: 'מיקרופון', ru: 'Микрофон'),
            ),
            if (widget.wantVideo) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  unawaited(
                    _agora.setVideoPublishMuted(!_agora.videoPublishMuted),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: _agora.videoPublishMuted
                      ? V26.emerg.withValues(alpha: 0.9)
                      : const Color(0x26FFFFFF),
                ),
                icon: Icon(
                  _agora.videoPublishMuted
                      ? Icons.videocam_off
                      : Icons.videocam,
                  color: Colors.white,
                ),
                tooltip: _str(en: 'Camera', he: 'מצלמה', ru: 'Камера'),
              ),
            ],
            if (widget.wantVideo && !kIsWeb) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  unawaited(_agora.switchCamera());
                },
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x26FFFFFF),
                ),
                icon: const Icon(
                  Icons.cameraswitch,
                  color: Colors.white,
                ),
                tooltip: _str(
                    en: 'Flip camera', he: 'החלפת מצלמה', ru: 'Сменить камеру'),
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
                  backgroundColor:
                      _agora.screenSharing ? V26.ok : const Color(0x26FFFFFF),
                ),
                icon: Icon(
                  _agora.screenSharing
                      ? Icons.stop_screen_share
                      : Icons.screen_share,
                  color: _agora.screenSharing ? Colors.white : Colors.white70,
                ),
                tooltip: _agora.screenSharing
                    ? _str(
                        en: 'Stop sharing', he: 'עצור שיתוף', ru: 'Остановить')
                    : _str(
                        en: 'Share screen',
                        he: 'שיתוף מסך',
                        ru: 'Поделиться экраном',
                      ),
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: V26.emerg,
              boxShadow: V26.shadowEmerg,
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _str(en: 'End', he: 'סיום', ru: 'Конец'),
          style: TextStyle(
            fontFamily: V26.sans,
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _sidePanel() {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: V26.surface,
        elevation: 0,
        child: Column(
          children: [
            TabBar(
              controller: _sideTabController,
              labelColor: V26.navy600,
              unselectedLabelColor: V26.ink300,
              indicatorColor: V26.gold,
              labelStyle: const TextStyle(
                fontFamily: V26.sans,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: V26.sans,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: _str(en: 'Chat', he: 'צ׳אט', ru: 'Чат')),
                Tab(text: _str(en: 'Caption', he: 'כיתוב', ru: 'Субтитры')),
              ],
            ),
            if (widget.eventId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Text(
                  kIsWeb
                      ? _str(
                          en: 'Server recording may be enabled; transcript can run after the call ends.',
                          he: 'אם יש הקלטה בשרת, תמלול יתאפשר מהכספת לאחר השיחה.',
                          ru: 'При записи на сервере расшифровка может быть в хранилище после звонка.',
                        )
                      : _str(
                          en: 'After the call, server recording can be transcribed from the vault when available.',
                          he: 'לאחר השיחה ניתן לתמלל הקלטת שרת מהכספת כשקיימת.',
                          ru: 'После звонка расшифровка записи сервера — из хранилища, если доступна.',
                        ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: V26.ink300,
                    fontSize: 10,
                    fontFamily: V26.sans,
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
      ),
    );
  }

  Widget _chatTab() {
    return Column(
      children: [
        Expanded(
          child: _chatLines.isEmpty
              ? Center(
                  child: Text(
                    _str(
                      en: 'No messages yet. Type below.',
                      he: 'אין הודעות. כתוב למטה.',
                      ru: 'Пока нет сообщений. Введите текст ниже.',
                    ),
                    style: const TextStyle(
                      color: V26.ink300,
                      fontFamily: V26.sans,
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
                          ? (_rtl
                              ? Alignment.centerLeft
                              : Alignment.centerRight)
                          : (_rtl
                              ? Alignment.centerRight
                              : Alignment.centerLeft),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        constraints: const BoxConstraints(maxWidth: 260),
                        decoration: BoxDecoration(
                          color: line.mine ? V26.infoSoft : V26.paper2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: V26.hairline),
                        ),
                        child: Text(
                          line.text,
                          style: TextStyle(
                            color: line.mine ? V26.ink900 : V26.ink700,
                            fontFamily: V26.sans,
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
          decoration: const BoxDecoration(
            color: V26.paper,
            border: Border(top: BorderSide(color: V26.hairline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatInput,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(
                    color: V26.ink900,
                    fontFamily: V26.sans,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        _str(en: 'Message…', he: 'הודעה…', ru: 'Сообщение…'),
                    hintStyle: const TextStyle(
                      color: V26.ink300,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(V26.rSm),
                      borderSide: const BorderSide(color: V26.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(V26.rSm),
                      borderSide: const BorderSide(color: V26.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(V26.rSm),
                      borderSide:
                          const BorderSide(color: V26.navy500, width: 1.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              IconButton(
                onPressed: _sendChat,
                color: V26.navy600,
                icon: const Icon(Icons.send_rounded),
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
              _str(
                en: 'Live captions are limited in the browser. After the call, vault transcription may apply when server recording exists. On mobile you can use local live caption here.',
                he: 'בדפדפן כתוביות חיות מוגבלות; אחרי השיחה — תמלול מהכספת כשיש הקלטת שרת. במובייל אפשר תמלול מקומי כאן.',
                ru: 'В браузере субтитры ограничены; после звонка — расшифровка из хранилища при записи на сервере.',
              ),
              style: const TextStyle(
                color: V26.warn,
                fontSize: 12,
                fontFamily: V26.sans,
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
            backgroundColor: s.listening ? V26.emerg : V26.paper2,
            foregroundColor: s.listening ? Colors.white : V26.ink700,
          ),
          icon: Icon(
            s.listening ? Icons.stop_circle_outlined : Icons.mic,
          ),
          label: Text(
            kIsWeb
                ? _str(
                    en: 'About transcription',
                    he: 'מידע על תמלול',
                    ru: 'О расшифровке',
                  )
                : (s.listening
                    ? _str(
                        en: 'Stop live caption',
                        he: 'עצור כיתוב חי',
                        ru: 'Остановить субтитры',
                      )
                    : _str(
                        en: 'Start live caption',
                        he: 'התחל כיתוב חי',
                        ru: 'Запустить субтитры',
                      )),
            style: const TextStyle(fontFamily: V26.sans),
          ),
        ),
        if (s.error != null) ...[
          const SizedBox(height: 8),
          Text(
            s.error!,
            style: const TextStyle(
              color: V26.warn,
              fontSize: 12,
              fontFamily: V26.sans,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (s.partial.isNotEmpty) ...[
          Text(
            s.partial,
            style: const TextStyle(
              color: V26.ink300,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontFamily: V26.sans,
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
                color: V26.ink900,
                fontSize: 14,
                fontFamily: V26.sans,
                height: 1.3,
              ),
            ),
          ),
        if (s.lines.isEmpty && s.partial.isEmpty && s.error == null)
          Text(
            _str(
              en: 'On-device text from your side only (not the peer). Server transcription uses the recording after you end the call.',
              he: 'טקסט מקומי מהצד שלך בלבד (לא מהצד השני). תמלול שרת משתמש בהקלטה אחרי סיום השיחה.',
              ru: 'Только локальный текст с вашей стороны. Серверная расшифровка — после записи.',
            ),
            style: const TextStyle(
              color: V26.ink300,
              fontSize: 12,
              fontFamily: V26.sans,
            ),
          ),
      ],
    );
  }

  Widget _buildVideoStage(
    RtcEngine? eng, {
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
                      ? _str(
                          en: 'Voice — ${widget.peerLabel}',
                          he: 'קול — ${widget.peerLabel}',
                          ru: 'Аудио — ${widget.peerLabel}',
                        )
                      : _str(
                          en: 'Waiting for ${widget.peerLabel}…',
                          he: 'ממתין ל־${widget.peerLabel}…',
                          ru: 'Ожидание: ${widget.peerLabel}…',
                        ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: V26.sans,
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
            right: _rtl ? null : 10,
            left: _rtl ? 10 : null,
            width: 90,
            height: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: V26.surface,
                  border: Border.all(color: V26.hairline),
                  boxShadow: V26.shadow1,
                ),
                child:
                    _localPreview(eng: eng, useVideoSurface: useVideoSurface),
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
                      style: const TextStyle(
                        color: V26.warnSoft,
                        fontSize: 11,
                        fontFamily: V26.sans,
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
    _bootstrapWatchdog?.cancel();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _confirmSystemBack();
      },
      child: Scaffold(
        backgroundColor: V26.navy900,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      V26.navy900,
                      V26.navy900.withValues(alpha: 0.98),
                      const Color(0xFF05070E),
                    ],
                  ),
                ),
              ),
            ),
            if (_starting)
              Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(
                    color: V26.gold.withValues(alpha: 0.9),
                  ),
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
                        fontFamily: V26.sans,
                      ),
                    ),
                  ),
                ),
              )
            else if ((eng == null || !_agora.joined) && !_agoraFailed)
              Positioned.fill(child: _buildWaitingForEngine())
            else if (useWideSide)
              Positioned.fill(
                child: Directionality(
                  textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
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
      case 'מעולה':
        return const Color(0xFF10B981);
      case 'טובה':
        return const Color(0xFF34D399);
      case 'בינונית':
        return const Color(0xFFF59E0B);
      case 'גרועה':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFEF4444);
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
              fontFamily: V26.sans,
            ),
          ),
        ],
      ),
    );
  }
}
