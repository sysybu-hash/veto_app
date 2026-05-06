// ============================================================
//  global_legal_ai_overlay.dart — fixed-position AI assistant
//  Available on every authenticated screen.
//
//  Features:
//   - Auth gate: hidden until JWT is present.
//   - Route gate: hidden on splash / login / landing / onboarding.
//   - Position: respects mobile bottom navigation + FAB.
//   - Modes: Text + Live Audio (Gemini Multimodal Live).
//   - Context-aware: sends current route + role to backend.
//   - RBAC: refuses sensitive admin actions for non-admins.
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/veto_live_audio_prefs.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../navigation/current_route_observer.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import '../services/auth_service.dart';
import '../services/legal_assistant_api_service.dart';

const Set<String> _kHiddenRoutes = {
  '/',
  '/landing',
  '/login',
  '/wizard_home',
  '/emergency_wizard',
  '/privacy',
  '/terms',
};

class GlobalLegalAiOverlay extends StatefulWidget {
  const GlobalLegalAiOverlay({super.key});

  @override
  State<GlobalLegalAiOverlay> createState() => _GlobalLegalAiOverlayState();
}

class _GlobalLegalAiOverlayState extends State<GlobalLegalAiOverlay> {
  final List<_OverlayMsg> _messages = [];
  final List<Map<String, dynamic>> _history = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _open = false;
  bool _sending = false;
  bool _liveMode = false;
  bool _isListening = false;
  bool _liveSessionActive = false;
  bool _hasToken = false;
  String _lang = 'he';
  String _role = 'user';
  String _voice = 'Kore';
  double _gain = 0.85;
  String _speechLang = 'he';
  String? _token;

  Timer? _authPoll;

  @override
  void initState() {
    super.initState();
    _messages.add(_OverlayMsg.bot('שלום, אני סוכן VETO. במה אפשר לעזור?'));
    _loadPrefs();
    if (kIsWeb) {
      browser_bridge.registerGeminiLiveResultHandler(_onLiveResult);
    }
    _authPoll = Timer.periodic(const Duration(seconds: 4), (_) => _refreshToken());
  }

  Future<void> _loadPrefs() async {
    final role = await AuthService().getStoredRole() ?? 'user';
    final lang = await AuthService().getStoredPreferredLanguage() ?? 'he';
    final v = await VetoLiveAudioPrefs.getVoice();
    final g = await VetoLiveAudioPrefs.getGain();
    final sl = await VetoLiveAudioPrefs.getLang();
    final t = await AuthService().getToken();
    if (!mounted) return;
    setState(() {
      _role = role;
      _lang = lang;
      _voice = v;
      _gain = g;
      _speechLang = sl;
      _token = t;
      _hasToken = (t != null && t.isNotEmpty);
    });
  }

  Future<void> _refreshToken() async {
    if (!mounted) return;
    final t = await AuthService().getToken();
    final has = (t != null && t.isNotEmpty);
    if (has != _hasToken || t != _token) {
      setState(() {
        _token = t;
        _hasToken = has;
      });
    }
  }

  @override
  void dispose() {
    _authPoll?.cancel();
    if (kIsWeb) {
      _safeJs('vetoGeminiLive', 'stop', const []);
    }
    _ctrl.dispose();
    _scrollCtrl.dispose();
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
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(raw.substring(5)) as Map<String, dynamic>?;
    } catch (_) {
      return;
    }
    if (data == null) return;

    setState(() {
      _isListening = false;
      _liveSessionActive = false;
    });

    if (data['err'] != null) {
      final e = data['err'].toString();
      final friendly = e == 'live_socket_closed'
          ? 'החיבור הקולי נותק. הקש שוב על המיקרופון.'
          : e == 'not_supported'
              ? 'הדפדפן הזה לא תומך בקלט קול.'
              : 'שגיאת שמע: $e';
      setState(() => _messages.add(_OverlayMsg.bot(friendly)));
      return;
    }

    final user = (data['u'] as String?)?.trim() ?? '';
    final model = (data['m'] as String?)?.trim() ?? '';

    if (user.isNotEmpty) {
      setState(() => _messages.add(_OverlayMsg.user(user)));
    }
    if (model.isNotEmpty) {
      setState(() => _messages.add(_OverlayMsg.bot(model)));
      _history
        ..add({
          'role': 'user',
          'parts': [
            {'text': user}
          ],
        })
        ..add({
          'role': 'model',
          'parts': [
            {'text': model}
          ],
        });
    } else if (user.isNotEmpty) {
      unawaited(_send(user));
    }
    _scrollToBottom();
  }

  Future<void> _toggleMic() async {
    if (!kIsWeb) {
      setState(() => _messages
          .add(_OverlayMsg.bot('שיחה קולית זמינה רק בגרסת ה-web.')));
      return;
    }
    if (!_hasToken) {
      setState(() => _messages.add(_OverlayMsg.bot('נדרש להתחבר תחילה.')));
      return;
    }
    if (_isListening) {
      setState(() {
        _isListening = false;
        _liveSessionActive = false;
      });
      _safeJs('vetoGeminiLive', 'stop', const []);
      return;
    }
    final supported = browser_bridge.supportsBrowserMethod(
      'vetoGeminiLive',
      'isSupported',
      const [],
    );
    if (!supported) {
      setState(() => _messages.add(
          _OverlayMsg.bot('הדפדפן או המכשיר אינו תומך בשיחה קולית של Gemini.')));
      return;
    }
    setState(() {
      _isListening = true;
      _liveSessionActive = true;
    });
    // Signature: (lang, jwt, apiBase, voiceName, gain) — must match gemini_live.mjs.
    _safeJs('vetoGeminiLive', 'start', <dynamic>[
      _speechLang,
      _token,
      AppConfig.baseUrl,
      _voice,
      _gain,
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
      case '/citizen_tasks':
        return 'משימות';
      case '/citizen_contacts':
        return 'אנשי קשר';
      case '/citizen_notifications':
        return 'התראות';
      case '/citizen_reports':
        return 'דוחות';
      case '/citizen_tools':
        return 'כלים';
      case '/security_center':
        return 'מרכז בטיחות';
      case '/admin_dashboard':
        return 'דשבורד אדמין';
      case '/admin_users':
        return 'ניהול משתמשים';
      case '/admin_lawyers':
        return 'ניהול עורכי דין';
      case '/admin_pending':
        return 'ממתינים לאישור';
      case '/admin_logs':
        return 'יומן אירועים';
      case '/admin_subscriptions':
        return 'מנויים';
      case '/admin_settings':
        return 'הגדרות מערכת';
      case '/lawyer_dashboard':
        return 'דשבורד עורך דין';
      case '/lawyer_settings':
        return 'הגדרות עו״ד';
      case '/maps':
        return 'מפה';
      case '/profile':
        return 'פרופיל';
      case '/settings':
        return 'הגדרות';
      case '/chat':
        return 'שיחות';
      case '/shared_vault':
        return 'כספת משותפת';
      default:
        return 'מסך כללי';
    }
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl
            .animateTo(_scrollCtrl.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut)
            .catchError((_) {});
      }
    });
  }

  Future<void> _send([String? forced]) async {
    final text = (forced ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;
    final route =
        currentRouteNotifier.value.isEmpty ? '/' : currentRouteNotifier.value;
    _ctrl.clear();
    setState(() {
      _sending = true;
      _messages.add(_OverlayMsg.user(text));
    });
    _scrollToBottom();

    final res = await LegalAssistantApiService.instance.contextChat(
      message: text,
      history: _history,
      route: route,
      role: _role,
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
    _scrollToBottom();
  }

  bool _shouldHide(String route) {
    if (!_hasToken) return true;
    if (_kHiddenRoutes.contains(route)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentRouteNotifier,
      builder: (context, route, _) {
        if (_shouldHide(route)) {
          return const SizedBox.shrink();
        }
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final mq = MediaQuery.of(context);
        final isWide = mq.size.width >= 1080;
        // On mobile, lift bubble above bottom nav (~70) + center FAB.
        final bottomPad = isWide
            ? mq.padding.bottom + 24
            : mq.padding.bottom + 92;
        final endPad = isWide ? 24.0 : 16.0;
        return Stack(
          children: [
            PositionedDirectional(
              end: endPad,
              bottom: bottomPad,
              child: _open
                  ? _panel(isRtl, route, mq)
                  : _bubbleButton(),
            ),
          ],
        );
      },
    );
  }

  Widget _bubbleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _open = true),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [VetoMockup.primaryCta, VetoMockup.primaryCtaDark],
            ),
            boxShadow: [
              BoxShadow(
                color: VetoMockup.primaryCta.withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _panel(bool isRtl, String route, MediaQueryData mq) {
    final isWide = mq.size.width >= 1080;
    final width = isWide ? 380.0 : (mq.size.width - 32).clamp(280.0, 400.0);
    final height = isWide ? 520.0 : (mq.size.height * 0.65).clamp(380.0, 600.0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF7FFFFFF), Color(0xEEF8F4FB)],
        ),
        border: Border.all(color: VetoMockup.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _header(route),
            _modeRow(),
            if (_liveSessionActive) _liveBanner(),
            Expanded(child: _conversationList(isRtl)),
            if (_liveMode) _liveModeFooter() else _textModeFooter(),
          ],
        ),
      ),
    );
  }

  Widget _header(String route) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        border: const Border(bottom: BorderSide(color: VetoMockup.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [VetoMockup.primaryCta, VetoMockup.primaryCtaDark],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('סוכן VETO',
                    style: TextStyle(
                      fontFamily: V26.serif,
                      fontWeight: FontWeight.w800,
                      color: VetoMockup.ink,
                      fontSize: 15,
                    )),
                Text(_routeLabel(route),
                    style: const TextStyle(
                      color: VetoMockup.inkSecondary,
                      fontSize: 11.5,
                    )),
              ],
            ),
          ),
          IconButton(
            tooltip: 'סגור',
            onPressed: () => setState(() => _open = false),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _modeRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: _modeChip(
              label: 'Text',
              icon: Icons.chat_bubble_outline_rounded,
              active: !_liveMode,
              onTap: () => setState(() => _liveMode = false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _modeChip(
              label: 'Live Audio',
              icon: Icons.graphic_eq_rounded,
              active: _liveMode,
              onTap: () => setState(() => _liveMode = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFEFFAF2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Gemini Live פעיל — דבר/י חופשי, השיחה משודרת בזמן אמת.',
              style: TextStyle(
                color: Color(0xFF205B26),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conversationList(bool isRtl) {
    return Container(
      color: const Color(0xFFFBFAFD),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: _messages.length + (_sending ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _messages.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: VetoMockup.primaryCta),
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
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              constraints: const BoxConstraints(maxWidth: 300),
              decoration: BoxDecoration(
                gradient: m.user
                    ? LinearGradient(
                        colors: [
                          VetoMockup.primaryCta.withValues(alpha: 0.18),
                          VetoMockup.primaryCta.withValues(alpha: 0.08),
                        ],
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFF7F3F9),
                        ],
                      ),
                border: Border.all(
                  color: m.user
                      ? VetoMockup.primaryCta.withValues(alpha: 0.3)
                      : VetoMockup.hairline,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                m.text,
                style: TextStyle(
                  fontSize: 13,
                  color: m.user ? VetoMockup.primaryCtaDark : VetoMockup.ink,
                  height: 1.4,
                  fontWeight: m.user ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _liveModeFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _liveSessionActive
                  ? 'הקש לעצירה'
                  : 'הקש על המיקרופון להתחלת שיחה קולית',
              style: const TextStyle(
                  color: VetoMockup.inkSecondary, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: _toggleMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? const Color(0xFFD6243A)
                    : VetoMockup.primaryCta,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening
                            ? const Color(0xFFD6243A)
                            : VetoMockup.primaryCta)
                        .withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textModeFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _send(),
              enabled: !_sending,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'כתוב הודעה משפטית...',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: VetoMockup.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: VetoMockup.primaryCta.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendBtn(onTap: _sending ? null : _send),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: active
              ? VetoMockup.primaryCta.withValues(alpha: 0.10)
              : Colors.white,
          border: Border.all(
            color: active
                ? VetoMockup.primaryCta.withValues(alpha: 0.45)
                : VetoMockup.hairline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: active ? VetoMockup.primaryCta : VetoMockup.inkSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? VetoMockup.primaryCta : VetoMockup.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const _SendBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: disabled
              ? null
              : const LinearGradient(
                  colors: [VetoMockup.primaryCta, VetoMockup.primaryCtaDark],
                ),
          color: disabled ? const Color(0xFFE6E2EA) : null,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: VetoMockup.primaryCta.withValues(alpha: 0.35),
                    blurRadius: 14,
                  ),
                ],
        ),
        child: Icon(Icons.send_rounded,
            color: disabled ? VetoMockup.inkSecondary : Colors.white, size: 20),
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
