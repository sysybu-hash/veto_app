// ============================================================
//  call_screen.dart — Text chat session on /call (callType == 'chat').
//  Audio/video use [CallSessionScreen] via [CallEntryScreen] only.
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/veto_theme.dart';
import '../services/socket_service.dart';
import '../services/vault_save_queue.dart';

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
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  String _roomId = '';
  String _peerName = 'Connecting...';
  String _myRole = 'user';
  String _eventId = '';
  String _language = 'he';

  bool _finalizedCall = false;
  String? _callErrorText;

  bool _chatReady = false;
  final List<_ChatLine> _chatLines = [];
  final TextEditingController _chatInput = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  Timer? _chatDurationTimer;
  int _chatSeconds = 0;

  Timer? _waitTimeout;
  bool _timedOut = false;
  int _waitSeconds = 0;
  Timer? _waitTick;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    try {
      setState(fn);
    } catch (e, st) {
      developer.log('_safeSetState', name: 'VETO.CallScreen', error: e, stackTrace: st);
    }
  }

  Future<void> _init() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/veto_screen');
      return;
    }

    var ct = args['callType']?.toString() ?? 'chat';
    if (ct == 'webrtc') ct = 'video';

    if (ct != 'chat') {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          (args['role']?.toString() == 'lawyer') ? '/lawyer_dashboard' : '/veto_screen',
        );
      }
      return;
    }

    final myRole = args['role']?.toString() ?? 'user';
    _safeSetState(() {
      _roomId = args['roomId']?.toString() ?? '';
      _peerName = args['peerName']?.toString() ?? 'Legal Counsel';
      _myRole = myRole;
      _eventId = args['eventId']?.toString() ?? '';
      _language = args['language']?.toString() ?? 'he';
    });

    if (_roomId.isEmpty) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/veto_screen');
      return;
    }

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

    await _initChatSession(socketService);
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
    if (!mounted || _finalizedCall) return;
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

  String _formatChatAsTranscript() {
    final buf = StringBuffer();
    for (final line in _chatLines) {
      buf.writeln(
        line.mine ? '[Me] ${line.text}' : '[$_peerName] ${line.text}',
      );
    }
    return buf.toString().trim();
  }

  Future<void> _retryJoin() async {
    _waitTimeout?.cancel();
    _waitTick?.cancel();
    _safeSetState(() {
      _timedOut = false;
      _waitSeconds = 0;
      _callErrorText = null;
      _finalizedCall = false;
      _chatReady = false;
      _chatLines.clear();
    });
    final socketService = context.read<SocketService>();
    socketService.removeHandler('chat-ready', _onChatReadyEvent);
    socketService.removeHandler('call-chat-message', _onChatMessageEvent);
    socketService.removeHandler('call-ended', _onCallEndedEvent);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await _initChatSession(socketService);
  }

  void _pushReplacement(NavigatorState nav, String route) {
    nav.pushReplacementNamed(route);
  }

  Future<void> _finalizeAndNavigate() async {
    if (!mounted) return;
    try {
      final nav = Navigator.of(context);
      final queue = context.read<VaultSaveQueue>();
      final myRole = _myRole;
      var goVault = false;
      final t = _formatChatAsTranscript();
      final vaultEventId = _eventId.trim().isNotEmpty ? _eventId.trim() : _roomId.trim();
      if (t.isNotEmpty && vaultEventId.isNotEmpty) {
        queue.enqueueChatTranscript(
          eventId: vaultEventId,
          transcript: t,
          roomLabel: _peerName,
        );
        goVault = true;
      }
      if (!mounted) return;
      final target = goVault
          ? '/files_vault'
          : (myRole == 'lawyer' ? '/lawyer_dashboard' : '/veto_screen');
      _pushReplacement(nav, target);
    } catch (e, st) {
      developer.log('_finalizeAndNavigate', name: 'VETO.CallScreen', error: e, stackTrace: st);
      if (!mounted) return;
      _pushReplacement(
        Navigator.of(context),
        _myRole == 'lawyer' ? '/lawyer_dashboard' : '/veto_screen',
      );
    }
  }

  Future<void> _endCall() async {
    context.read<SocketService>().emit('call-ended', {
      'roomId': _roomId,
      'duration': _chatSeconds,
    });
    _chatDurationTimer?.cancel();
    if (!_finalizedCall) {
      _finalizedCall = true;
      unawaited(_finalizeAndNavigate());
    }
  }

  @override
  void dispose() {
    _waitTimeout?.cancel();
    _waitTick?.cancel();
    _chatDurationTimer?.cancel();
    _fadeCtrl.dispose();
    _chatInput.dispose();
    _chatScroll.dispose();
    final svc = SocketService();
    svc.removeHandler('chat-ready', _onChatReadyEvent);
    svc.removeHandler('call-chat-message', _onChatMessageEvent);
    svc.removeHandler('call-ended', _onCallEndedEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildChatLayer(),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: SafeArea(child: _buildTopBar()),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(child: _buildControls()),
            ),
          ],
        ),
      ),
    );
  }

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
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                    itemCount: _chatLines.length,
                    itemBuilder: (_, i) {
                      final line = _chatLines[i];
                      return Align(
                        alignment: line.mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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

  Widget _buildWaitingPanel() {
    final remaining = 75 - _waitSeconds;
    final label = _language == 'he'
        ? 'מחכה לחיבור... ($remaining שניות)'
        : _language == 'ru'
            ? 'Ожидание подключения... ($remaining сек)'
            : 'Waiting for connection... ($remaining s)';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'Heebo',
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _endCall,
          icon: const Icon(Icons.close_rounded, size: 15, color: Colors.white54),
          label: Text(
            _language == 'he' ? 'בטל' : _language == 'ru' ? 'Отмена' : 'Cancel',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      ],
    );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, color: Colors.white70, size: 32),
          const SizedBox(height: 10),
          Text(
            _language == 'he'
                ? 'לא נמצא עורך דין זמין'
                : _language == 'ru'
                    ? 'Нет доступных адвокатов'
                    : 'No lawyer available right now',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Heebo',
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
                ),
                child: Text(
                  _language == 'he' ? 'חזרה' : _language == 'ru' ? 'Назад' : 'Go back',
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _retryJoin,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5B8FFF)),
                child: Text(
                  _language == 'he' ? 'נסה שוב' : _language == 'ru' ? 'Повторить' : 'Try again',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPanel() {
    final msg = _callErrorText ?? 'Error';
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
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _endCall,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: VetoColors.vetoRedSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VetoColors.vetoRed.withValues(alpha: 0.3)),
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
            _peerName,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Heebo',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_chatReady)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: VetoColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VetoColors.success.withValues(alpha: 0.3)),
              ),
              child: Text(
                _formattedChatDuration,
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

  Widget _buildControls() {
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
              child: const Icon(Icons.call_end, color: VetoColors.white, size: 32),
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
}
