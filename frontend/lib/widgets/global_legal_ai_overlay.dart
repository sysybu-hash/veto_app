import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../config/veto_live_audio_prefs.dart';
import '../navigation/current_route_observer.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../core/theme/veto_2026.dart';

class GlobalLegalAiOverlay extends StatefulWidget {
  const GlobalLegalAiOverlay({super.key});

  @override
  State<GlobalLegalAiOverlay> createState() => _GlobalLegalAiOverlayState();
}

class _GlobalLegalAiOverlayState extends State<GlobalLegalAiOverlay> {
  final List<_OverlayMsg> _messages = [];
  final List<Map<String, dynamic>> _history = [];
  final TextEditingController _ctrl = TextEditingController();

  bool _open = false;
  bool _sending = false;
  bool _liveMode = false;
  bool _isListening = false;
  bool _liveSessionActive = false;
  String _lang = 'he';
  String _role = 'user';
  String _voice = 'Kore';
  double _gain = 0.85;
  String _speechLang = 'he';

  @override
  void initState() {
    super.initState();
    _messages.add(_OverlayMsg.bot('שלום, אני סוכן VETO. במה אפשר לעזור?'));
    _loadPrefs();
    if (kIsWeb) {
      browser_bridge.registerGeminiLiveResultHandler(_onLiveResult);
    }
  }

  Future<void> _loadPrefs() async {
    final role = await AuthService().getStoredRole() ?? 'user';
    final lang = await AuthService().getStoredPreferredLanguage() ?? 'he';
    final v = await VetoLiveAudioPrefs.getVoice();
    final g = await VetoLiveAudioPrefs.getGain();
    final sl = await VetoLiveAudioPrefs.getLang();
    if (!mounted) return;
    setState(() {
      _role = role;
      _lang = lang;
      _voice = v;
      _gain = g;
      _speechLang = sl;
    });
  }

  @override
  void dispose() {
    if (kIsWeb) {
      _safeJs('vetoGeminiLive', 'stop', const []);
    }
    _ctrl.dispose();
    super.dispose();
  }

  void _safeJs(String objectName, String methodName, List<dynamic> args) {
    try {
      browser_bridge.callBrowserMethod(objectName, methodName, args);
    } catch (_) {}
  }

  void _onLiveResult(String raw) {
    if (!mounted) return;
    if (!raw.startsWith('LIVE:')) return;
    final payload = raw.substring(5);
    if (payload.startsWith('OPEN')) {
      setState(() {
        _liveSessionActive = true;
        _isListening = true;
      });
      return;
    }
    if (payload.startsWith('CLOSE')) {
      setState(() {
        _liveSessionActive = false;
        _isListening = false;
      });
      return;
    }
    if (payload.startsWith('ERROR:')) {
      setState(() {
        _liveSessionActive = false;
        _isListening = false;
      });
      final msg = payload.replaceFirst('ERROR:', '').trim();
      _messages.add(_OverlayMsg.bot('שגיאת שמע: $msg'));
      setState(() {});
      return;
    }
    if (payload.startsWith('TRANSCRIPT:')) {
      final text = payload.replaceFirst('TRANSCRIPT:', '').trim();
      if (text.isNotEmpty) {
        unawaited(_send(text));
      }
      return;
    }
  }

  Future<void> _toggleMic() async {
    if (!kIsWeb) return;
    if (_isListening) {
      setState(() {
        _isListening = false;
        _liveSessionActive = false;
      });
      _safeJs('vetoGeminiLive', 'stop', const []);
      return;
    }
    setState(() {
      _isListening = true;
    });
    final supported = browser_bridge.supportsBrowserMethod(
      'vetoGeminiLive',
      'isSupported',
      const [],
    );
    if (!supported) {
      setState(() => _isListening = false);
      _messages.add(_OverlayMsg.bot('Gemini Live לא נתמך בדפדפן הזה.'));
      setState(() {});
      return;
    }
    _safeJs('vetoGeminiLive', 'start', <dynamic>[
      _speechLang,
      _voice,
      _gain,
      true,
    ]);
  }

  String _routeLabel(String route) {
    switch (route) {
      case '/legal_calendar':
        return 'יומן משפטי';
      case '/legal_notebook':
        return 'מחברת משפטית';
      case '/files_vault':
        return 'כספת קבצים';
      case '/citizen_contracts':
        return 'חוזים';
      case '/admin_dashboard':
        return 'דשבורד אדמין';
      case '/lawyer_dashboard':
        return 'דשבורד עורך דין';
      default:
        return 'מסך כללי';
    }
  }

  bool _isActionAllowed(String msg) {
    final m = msg.toLowerCase();
    if (_role == 'admin') return true;
    if (_role == 'lawyer') {
      return !m.contains('delete user') && !m.contains('מחק משתמש');
    }
    return !(m.contains('admin') ||
        m.contains('system settings') ||
        m.contains('הגדרות מערכת'));
  }

  Future<void> _send([String? forced]) async {
    final text = (forced ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;
    final route =
        currentRouteNotifier.value.isEmpty ? '/' : currentRouteNotifier.value;
    if (!_isActionAllowed(text)) {
      setState(() {
        _messages.add(_OverlayMsg.bot(
            'אין לך הרשאה לפעולה זו במסך ${_routeLabel(route)}.'));
      });
      return;
    }
    _ctrl.clear();
    setState(() {
      _sending = true;
      _messages.add(_OverlayMsg.user(text));
    });

    final contextualMessage = '''
הקשר מערכת:
- תפקיד: $_role
- מסך: $route (${_routeLabel(route)})
- שפה: $_lang

בקשת משתמש:
$text
''';

    final res = await AiService().chat(
      message: contextualMessage,
      history: _history,
      lang: _lang,
    );

    final reply = (res['reply'] ?? 'לא התקבלה תשובה כרגע.').toString();
    _history
      ..add({
        'role': 'user',
        'parts': [
          {'text': text}
        ]
      })
      ..add({
        'role': 'model',
        'parts': [
          {'text': reply}
        ]
      });

    if (!mounted) return;
    setState(() {
      _sending = false;
      _messages.add(_OverlayMsg.bot(reply));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentRouteNotifier,
      builder: (context, route, _) {
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final bottomPad = MediaQuery.of(context).padding.bottom + 20;
        return Stack(
          children: [
            PositionedDirectional(
              end: 20,
              bottom: bottomPad,
              child: _open
                  ? _panel(isRtl, route)
                  : _bubbleButton(),
            ),
          ],
        );
      },
    );
  }

  Widget _bubbleButton() {
    return GestureDetector(
      onTap: () => setState(() => _open = true),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [V26.navy700, V26.navy500],
          ),
          boxShadow: [
            BoxShadow(
              color: V26.navy600.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      ),
    );
  }

  Widget _panel(bool isRtl, String route) {
    return Container(
      width: 360,
      height: 480,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF7FFFFFF), Color(0xEEF4FAFF)],
        ),
        border: Border.all(color: V26.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: V26.hairline)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel_rounded, color: V26.navy600, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'סוכן AI • ${_routeLabel(route)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: V26.ink900),
                  ),
                ),
                IconButton(
                  tooltip: 'סגור',
                  onPressed: () => setState(() => _open = false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                Expanded(
                  child: _modeChip(
                    label: 'Text',
                    active: !_liveMode,
                    onTap: () => setState(() => _liveMode = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _modeChip(
                    label: 'Live Audio',
                    active: _liveMode,
                    onTap: () => setState(() => _liveMode = true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final m = _messages[i];
                return Align(
                  alignment: m.user
                      ? (isRtl ? Alignment.centerRight : Alignment.centerLeft)
                      : (isRtl ? Alignment.centerLeft : Alignment.centerRight),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      gradient: m.user
                          ? LinearGradient(
                              colors: [
                                V26.navy600.withValues(alpha: 0.2),
                                V26.navy500.withValues(alpha: 0.12)
                              ],
                            )
                          : const LinearGradient(
                              colors: [Color(0xF8FFFFFF), Color(0xEEF2F7FF)],
                            ),
                      border: Border.all(
                        color: m.user
                            ? V26.navy600.withValues(alpha: 0.25)
                            : V26.hairline,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: m.user ? V26.navy700 : V26.ink700,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_liveMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _liveSessionActive
                          ? 'Gemini Live פעיל. דבר חופשי.'
                          : 'הפעלת שיחה קולית Gemini Live',
                      style: const TextStyle(color: V26.ink500, fontSize: 12),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleMic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _isListening ? const Color(0xFFFF3B3B) : V26.surface,
                        border: Border.all(
                          color: _isListening
                              ? const Color(0xFFFF3B3B).withValues(alpha: 0.7)
                              : V26.hairline,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.white : V26.ink900,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'כתוב הודעה משפטית...',
                        isDense: true,
                        filled: true,
                        fillColor: V26.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: V26.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: V26.navy600.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: active ? V26.navy500.withValues(alpha: 0.12) : V26.surface,
          border: Border.all(
            color: active
                ? V26.navy500.withValues(alpha: 0.35)
                : V26.hairline.withValues(alpha: 0.9),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? V26.navy600 : V26.ink500,
          ),
        ),
      ),
    );
  }
}

class _OverlayMsg {
  final String text;
  final bool user;
  const _OverlayMsg(this.text, this.user);

  factory _OverlayMsg.user(String t) => _OverlayMsg(t, true);
  factory _OverlayMsg.bot(String t) => _OverlayMsg(t, false);
}

