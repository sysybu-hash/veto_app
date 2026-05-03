// ============================================================
//  VetoScreen.dart — Legal Shield Wizard Interface
//  Attorney Shield-inspired: scenarios, rights, WhatsApp/Telegram,
//  admin evidence browser, dual-tab (Wizard + AI Chat)
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../config/veto_live_audio_prefs.dart';
import '../core/i18n/app_language.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_theme.dart';
import '../widgets/app_language_menu.dart';
import '../widgets/accessibility_toolbar.dart';
import '../widgets/dispatch_sheets.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/ai_service.dart';
import '../services/payment_service.dart';
import '../services/admin_service.dart';
import '../services/fcm_user_service.dart';
import '../services/push_service.dart';
import 'admin/admin_i18n.dart';
import 'evidence_screen.dart';
import '../widgets/veto_live_voice_sheet.dart';

part 'veto/veto_screen_models.dart';

// ── VetoScreen ────────────────────────────────────────────
class VetoScreen extends StatefulWidget {
  const VetoScreen({super.key});
  @override
  State<VetoScreen> createState() => _VetoScreenState();
}

class _VetoScreenState extends State<VetoScreen> {
  // #region agent log (perf counters)
  static int _buildCount = 0;
  // #endregion agent log (perf counters)
  // ── Navigation
  int _tab = 0;
  // ── Core state
  String _role = '', _phone = '';
  String _langKey = 'he';
  bool _isDispatching = false;
  bool _isLoading = false;
  bool _isListening = false;
  /// Web: Gemini Multimodal Live (mic) session, distinct from [SpeechRecognition] [STT].
  bool _liveSessionActive = false;
  String? _activeEventId;
  String? _token;
  StreamSubscription<Map<String, dynamic>>? _emergencyCreatedSub;
  StreamSubscription<Map<String, dynamic>>? _lawyerFoundSub;
  StreamSubscription<Map<String, dynamic>>? _noLawyersSub;
  StreamSubscription<Map<String, dynamic>>? _vetoDispatchedSub;
  StreamSubscription<Map<String, dynamic>>? _vetoErrorSub;
  StreamSubscription<Map<String, dynamic>>? _caseAlreadyTakenSub;
  StreamSubscription<Map<String, dynamic>>? _sessionReadySub;
  final List<_Msg> _messages = [];
  final List<Map<String, dynamic>> _geminiHistory = [];
  String _geminiLiveVoice = 'Kore';
  double _geminiLiveGain = 0.85;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  // ── Wizard state
  _Scenario _scenario = _Scenario.interrogation;
  bool _rightsExpanded = true;
  // ── Admin state
  List<dynamic> _adminFiles = [];
  bool _adminFilesLoading = false;

  _LL get _l => _langs[_langKey]!;
  _SD get _s => _sdMap[_scenario]!;
  List<String> get _rights =>
      _langKey == 'ru' ? _s.rRu : _langKey == 'en' ? _s.rEn : _s.rHe;
  String get _sLabel =>
      _langKey == 'ru' ? _s.ru : _langKey == 'en' ? _s.en : _s.he;

  /// Web Gemini Live: replaces generic hint while mic session is active.
  String get _geminiLiveInputHint {
    if (_langKey == 'ru') {
      return 'Голосовой режим Gemini Live — нажмите микрофон ещё раз, чтобы остановить';
    }
    if (_langKey == 'en') {
      return 'Gemini Live voice — tap the mic again to stop';
    }
    return 'שיחה קולית (Gemini Live) — הקש שוב על המיקרופון לסיום';
  }

  @override
  void initState() {
    super.initState();
    // #region agent log (perf boot)
    if (kIsWeb) {
      // ignore: avoid_print
      print('[VETO][perf] veto_screen_init mobile=${browser_bridge.isMobileBrowser()}');
    }
    // #endregion agent log (perf boot)
    unawaited(_loadLiveAudioPrefs());
    _loadData();
    browser_bridge.registerSttResultHandler(_onSTTResult);
    if (kIsWeb) {
      browser_bridge.registerGeminiLiveResultHandler(_onGeminiLiveResult);
    }
    _emergencyCreatedSub = SocketService().onEmergencyCreated.listen((data) {
      final id = data['eventId'] as String?;
      if (id != null && mounted) setState(() => _activeEventId = id);
    });
    _lawyerFoundSub = SocketService().onLawyerFound.listen(_handleLawyerFound);
    _noLawyersSub =
        SocketService().onNoLawyersAvailable.listen(_handleNoLawyersAvailable);
    _vetoDispatchedSub =
        SocketService().onVetoDispatched.listen(_handleVetoDispatched);
    _vetoErrorSub = SocketService().onVetoError.listen(_handleVetoError);
    _caseAlreadyTakenSub =
        SocketService().onCaseAlreadyTaken.listen(_handleCaseAlreadyTaken);
    _sessionReadySub =
        SocketService().onSessionReady.listen(_handleSessionReady);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted) unawaited(_checkSubscription());
      });
    });
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 900), _retryWebFlows);
      });
    }
  }

  /// Flows: Flutter Web may build `flt-glass-pane` after first paint — retry after shell mount.
  Future<void> _retryWebFlows() async {
    if (!kIsWeb || !mounted) return;
    final auth = AuthService();
    final uid = await auth.getStoredUserId();
    if (uid == null || uid.isEmpty) return;
    if (!mounted) return;
    final role = (await auth.getStoredRole()) ?? 'user';
    if (!mounted) return;
    final lang = context.read<AppLanguageController>().code;
    try {
      await browser_bridge
          .flowsSetUser(
        userId: uid,
        role: role,
        lang: lang,
      )
          .timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
    } on TimeoutException {
      debugPrint('[VETO] flowsSetUser (veto retry) timed out; continuing');
    } catch (_) {}
  }

  Future<void> _loadLiveAudioPrefs() async {
    final v = await VetoLiveAudioPrefs.getVoice();
    final g = await VetoLiveAudioPrefs.getGain();
    if (!mounted) return;
    setState(() {
      _geminiLiveVoice = v;
      _geminiLiveGain = g;
    });
  }

  Future<void> _checkSubscription() async {
    final role = await AuthService().getStoredRole();
    if (role == 'admin' || role == 'lawyer') return;
    final isPaymentExempt = await AuthService().getStoredIsPaymentExempt();
    if (isPaymentExempt) return;
    final isSubscribed = await AuthService().getStoredIsSubscribed();
    if (!isSubscribed && mounted) {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SubscriptionGateDialog(),
      );
      // Re-check — if still not subscribed, force logout
      if (!mounted) return;
      final nowSubscribed = await AuthService().getStoredIsSubscribed();
      if (!nowSubscribed && mounted) {
        await AuthService().logout(context);
      }
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      _safeJs('vetoGeminiLive', 'stop', []);
    }
    _safeJs('vetoSTT', 'stop', []);
    _safeJs('vetoTTS', 'stop', []);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _emergencyCreatedSub?.cancel();
    _lawyerFoundSub?.cancel();
    _noLawyersSub?.cancel();
    _vetoDispatchedSub?.cancel();
    _vetoErrorSub?.cancel();
    _caseAlreadyTakenSub?.cancel();
    _sessionReadySub?.cancel();
    super.dispose();
  }

  void _safeJs(String obj, String m, List a) {
    try { browser_bridge.callBrowserMethod(obj, m, a); } catch (_) {}
  }

  Future<void> _loadData() async {
    final auth = AuthService();
    final outs = await Future.wait<Object?>([
      auth.getStoredRole(),
      auth.getStoredPhone(),
      auth.getToken(),
      auth.getStoredPreferredLanguage(),
    ]);
    final r = outs[0] as String?;
    final p = outs[1] as String?;
    final t = outs[2] as String?;
    final language = AppLanguage.normalize(outs[3] as String?);
    if (!mounted) return;
    if (r == 'lawyer') {
      Navigator.of(context).pushReplacementNamed('/lawyer_dashboard');
      return;
    }
    // Admins may open /veto_screen on purpose (e.g. from admin panel); do not bounce
    // them back — splash/login still land admins on /admin_settings first.
    final languageController = context.read<AppLanguageController>();
    if (languageController.code != language) {
      await languageController.setLanguage(language, persist: false);
    }
    if (mounted) {
      setState(() {
        _role = r ?? '';
        _phone = p ?? '';
        _token = t;
        _langKey = language;
      });
      _messages.add(_Msg(text: _l.greeting, isUser: false));
      if (_role == 'admin') _loadAdminFiles();
    }
    if ((r ?? '').isNotEmpty) {
      await SocketService().connect(role: r ?? 'user');
    }
    if (kIsWeb) {
      unawaited(PushService().registerUserPush());
    } else {
      unawaited(registerFcmIfAvailable());
    }
  }

  Future<void> _loadAdminFiles() async {
    setState(() => _adminFilesLoading = true);
    final data = await AdminService().getEmergencyLogs();
    if (mounted) setState(() { _adminFiles = data; _adminFilesLoading = false; });
  }

  Color _adminStatusColor(String? s) {
    switch (s) {
      case 'completed':
      case 'resolved':
        return V26.ok;
      case 'cancelled':
        return V26.ink500;
      case 'failed':
        return V26.emerg;
      case 'accepted':
        return V26.ok;
      case 'in_progress':
      case 'pending':
        return V26.warn;
      case 'documentation':
        return V26.navy600;
      case 'dispatching':
      case 'active':
        return V26.emerg;
      default:
        return V26.ink500;
    }
  }

  Future<void> _adminEditEmergencyEvent(BuildContext navContext, dynamic ev, bool isRtl) async {
    final id = _mongoEventId(ev);
    if (id == null) return;
    var current = ev['status']?.toString() ?? 'documentation';
    if (!AdminStrings.emergencyEventStatuses.contains(current)) current = 'documentation';
    var selected = current;

    final ok = await showDialog<bool>(
      context: navContext,
      builder: (ctx) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: V26.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: V26.hairline),
          ),
          title: Text(
            AdminStrings.t(_langKey, 'changeStatus'),
            style: const TextStyle(color: V26.ink900),
          ),
          content: StatefulBuilder(
            builder: (_, ss) => DropdownButton<String>(
              isExpanded: true,
              value: selected,
              dropdownColor: V26.surface,
              style: const TextStyle(color: V26.ink900, fontSize: 14),
              underline: Container(height: 1, color: V26.hairline),
              items: AdminStrings.emergencyEventStatuses
                  .map(
                    (v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(AdminStrings.eventStatus(_langKey, v)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) ss(() => selected = v);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AdminStrings.t(_langKey, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AdminStrings.t(_langKey, 'save')),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selected == current) return;
    final success = await AdminService().updateEmergencyLog(id, {'status': selected});
    if (!mounted) return;
    if (success) {
      await _loadAdminFiles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _langKey == 'he'
                ? 'עדכון נכשל'
                : _langKey == 'ru'
                    ? 'Не удалось обновить'
                    : 'Update failed',
          ),
        ),
      );
    }
  }

  Future<void> _adminCleanEmergencyEvent(BuildContext navContext, dynamic ev, bool isRtl) async {
    final id = _mongoEventId(ev);
    if (id == null) return;
    final evidence = (ev['evidence'] as List?) ?? [];
    final hasEvidence = evidence.isNotEmpty;

    final title = _langKey == 'he'
        ? 'ניקוי'
        : _langKey == 'ru'
            ? 'Очистка'
            : 'Cleaning';
    final clearLabel = _langKey == 'he'
        ? 'הסר ראיות מצורפות בלבד'
        : _langKey == 'ru'
            ? 'Удалить только вложения'
            : 'Remove attached evidence only';
    final clearedMsg = _langKey == 'he'
        ? 'הראיות הוסרו'
        : _langKey == 'ru'
            ? 'Вложения удалены'
            : 'Evidence cleared';

    final action = await showDialog<String>(
      context: navContext,
      builder: (ctx) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: V26.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: V26.hairline),
          ),
          title: Text(title, style: const TextStyle(color: V26.ink900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasEvidence)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'clear'),
                  icon: const Icon(Icons.layers_clear_outlined, color: V26.navy600),
                  label: Text(clearLabel, style: const TextStyle(color: V26.ink900)),
                ),
              if (hasEvidence) const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: V26.emerg),
                onPressed: () => Navigator.pop(ctx, 'delete'),
                icon: const Icon(Icons.delete_outline, color: V26.ink900),
                label: Text(AdminStrings.t(_langKey, 'deleteEvent')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(AdminStrings.t(_langKey, 'cancel')),
            ),
          ],
        ),
      ),
    );

    if (action == 'clear') {
      final success = await AdminService().updateEmergencyLog(id, {'clearEvidence': true});
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(clearedMsg)));
        await _loadAdminFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _langKey == 'he'
                  ? 'ניקוי נכשל'
                  : _langKey == 'ru'
                      ? 'Ошибка очистки'
                      : 'Clear failed',
            ),
          ),
        );
      }
      return;
    }

    if (action != 'delete') return;

    if (!mounted || !navContext.mounted) return;
    final confirm = await showDialog<bool>(
      context: navContext,
      builder: (ctx) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: V26.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: V26.hairline),
          ),
          title: Text(
            AdminStrings.t(_langKey, 'deleteEvent'),
            style: const TextStyle(color: V26.ink900),
          ),
          content: Text(
            AdminStrings.t(_langKey, 'deleteEventConfirm'),
            style: const TextStyle(color: V26.ink500),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AdminStrings.t(_langKey, 'cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: V26.emerg),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AdminStrings.t(_langKey, 'delete')),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    final ok = await AdminService().deleteEmergencyLog(id);
    if (!mounted) return;
    if (ok) {
      await _loadAdminFiles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _langKey == 'he'
                ? 'מחיקה נכשלה'
                : _langKey == 'ru'
                    ? 'Не удалось удалить'
                    : 'Delete failed',
          ),
        ),
      );
    }
  }

  // ── AI send ──────────────────────────────────────────────
  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _isLoading || _isDispatching) return;
    _inputCtrl.clear();
    setState(() { _messages.add(_Msg(text: text, isUser: true)); _isLoading = true; });
    _scrollToBottom();
    final snapshot = List<Map<String, dynamic>>.from(_geminiHistory);
    final result = await AiService().chat(message: text, history: snapshot, lang: _langKey);
    _geminiHistory
      ..add({'role': 'user',  'parts': [{'text': text}]})
      ..add({'role': 'model', 'parts': [{'text': result['reply'] ?? ''}]});
    final reply = (result['reply'] as String?) ?? '...';
    if (!mounted) return;
    setState(() { _isLoading = false; _messages.add(_Msg(text: reply, isUser: false)); });
    _scrollToBottom();
    _speak(reply);
    if (result['classified'] == true) {
      final spec = result['specialization'] as String?;
      final lawyerMap = (result['lawyer'] as Map?)?.cast<String, dynamic>();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await _payAndDispatch(spec, lawyerMap?['name'] as String?);
    }
  }

  Future<void> _payAndDispatch(String? spec, String? lawyerName) async {
    // Admins and payment-exempt users skip the PayPal flow
    final role = await AuthService().getStoredRole();
    final isPaymentExempt = await AuthService().getStoredIsPaymentExempt();
    if (!mounted) return;
    if (role == 'admin' || isPaymentExempt) {
      await _dispatch(spec, lawyerName);
      return;
    }
    final orderId = await showDialog<String?>(
      context: context, barrierDismissible: false,
      builder: (ctx) => _PaymentDialog(spec: spec),
    );
    if (orderId == null || !mounted) return;
    final captured = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (ctx) => _CaptureDialog(orderId: orderId),
    );
    if (captured != true || !mounted) return;
    await _dispatch(spec, lawyerName);
  }

  // ── Dispatch ─────────────────────────────────────────────
  Future<void> _dispatch(String? spec, String? lawyerName) async {
    if (_isDispatching) return;
    setState(() => _isDispatching = true);
    HapticFeedback.heavyImpact();
    final socketRole = _role == 'admin' ? 'admin' : 'user';
    final connected = await SocketService().ensureConnected(role: socketRole);
    if (!mounted) return;
    if (!connected) {
      setState(() => _isDispatching = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_langKey == 'he'
            ? 'אין חיבור לשרת. בדוק רשת והתחבר מחדש.'
            : _langKey == 'ru'
                ? 'Нет связи с сервером. Проверьте сеть.'
                : 'Cannot reach the server. Check your connection.'),
        backgroundColor: V26.emerg,
      ));
      return;
    }
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {}
    SocketService().emitStartVeto(
      lat: pos?.latitude ?? 32.08, lng: pos?.longitude ?? 34.78,
      preferredLanguage: _langKey,
      specialization: spec,
    );
    final specLabel = spec ?? '';
    final msg = lawyerName != null
        ? ('🔔 ${_langKey == 'he'
            ? 'מחפש עורך דין בתחום $specLabel...\n$lawyerName ייצור איתך קשר.'
            : _langKey == 'ru'
            ? 'Ищу адвоката по $specLabel...\n$lawyerName свяжется с вами.'
            : 'Searching $specLabel lawyer...\n$lawyerName will contact you.'}')
        : ('🔔 ${_langKey == 'he'
            ? 'מחפש עורך דין זמין...'
            : _langKey == 'ru'
            ? 'Ищу доступного адвоката...'
            : 'Searching for an available lawyer...'}');
    if (mounted) {
      setState(() => _messages.add(_Msg(text: msg, isUser: false, isSystem: true)));
      _scrollToBottom();
      _speak(msg);
    }
  }

  // ── STT/TTS ──────────────────────────────────────────────
  void _toggleMic() {
    if (_isDispatching) return;
    _isListening ? _stopListening() : _startListening();
  }
  void _startListening() {
    final canGemini = kIsWeb &&
        _token != null &&
        _token!.isNotEmpty &&
        !(_isLoading || _isDispatching) &&
        browser_bridge.supportsBrowserMethod('vetoGeminiLive', 'isSupported', const []);
    if (canGemini) {
      _stopSpeaking();
      setState(() {
        _isListening = true;
        _liveSessionActive = true;
      });
      _safeJs('vetoGeminiLive', 'start', [
        _langKey,
        _token,
        AppConfig.baseUrl,
        _geminiLiveVoice,
        _geminiLiveGain,
      ]);
      return;
    }
    final ok = browser_bridge.supportsBrowserMethod('vetoSTT', 'isSupported', const []);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הדפדפן שלך לא תומך בזיהוי קול')));
      return;
    }
    setState(() => _isListening = true);
    _safeJs('vetoSTT', 'start', [_l.code]);
  }
  void _stopListening() {
    if (_liveSessionActive) {
      setState(() {
        _isListening = false;
        _liveSessionActive = false;
      });
      _safeJs('vetoGeminiLive', 'stop', const []);
      return;
    }
    setState(() => _isListening = false);
    _safeJs('vetoSTT', 'stop', const []);
  }
  void _onSTTResult(String r) {
    if (!mounted) return;
    if (_liveSessionActive) return;
    setState(() => _isListening = false);
    if (r.startsWith('OK:')) _send(r.substring(3));
  }

  void _onGeminiLiveResult(String r) {
    if (!mounted) return;
    if (!kIsWeb) return;
    if (!r.startsWith('LIVE:')) return;
    setState(() {
      _isListening = false;
      _liveSessionActive = false;
    });
    Map<String, dynamic>? o;
    try {
      o = jsonDecode(r.substring(5)) as Map<String, dynamic>?;
    } catch (_) {
      return;
    }
    if (o == null) return;
    if (o['err'] != null) {
      final e = o['err'].toString();
      final uRecover = (o['u'] as String?)?.trim() ?? '';
      // Gemini Live guard (gemini_live.mjs) — not a user-facing raw error string.
      if (e == 'live_socket_closed') {
        final mRecover = (o['m'] as String?)?.trim() ?? '';
        if (uRecover.isNotEmpty || mRecover.isNotEmpty) {
          unawaited(_ingestGeminiLiveTurn(
            uRecover,
            mRecover,
            nativeAudio: o['nativeAudio'] == true,
          ));
        } else if (mounted) {
          final msg = _langKey == 'he'
              ? 'החיבור הקולי נותק. לחץ שוב על המיקרופון.'
              : _langKey == 'ru'
                  ? 'Голосовая сессия прервалась. Нажмите микрофон ещё раз.'
                  : 'Voice session disconnected. Tap the mic to try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      final t = e == 'not_supported'
          ? (_langKey == 'he'
              ? 'הדפדפן/המכשיר לא תומנים בקלט קול (HTTPS ומכשיר נדרשים).'
              : _langKey == 'ru'
                  ? 'Колючий ввод недоступен в этой среде.'
                  : 'Voice input is not available in this browser.')
          : e;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
      return;
    }
    unawaited(_ingestGeminiLiveTurn(
      o['u'] as String? ?? '',
      o['m'] as String? ?? '',
      nativeAudio: o['nativeAudio'] == true,
    ));
  }

  /// Parses the same legal JSON the REST chat model uses (from Multimodal Live [modelRaw]).
  Future<void> _ingestGeminiLiveTurn(String u, String m, {bool nativeAudio = false}) async {
    if (!mounted) return;
    final uText = u.trim();
    final mText = m.trim();
    if (mText.isEmpty && !nativeAudio) {
      if (uText.isNotEmpty) await _send(uText);
      return;
    }
    if (mText.isEmpty && nativeAudio) {
      setState(() => _isLoading = false);
      if (uText.isNotEmpty) {
        setState(() {
          _messages.add(_Msg(text: uText, isUser: true));
        });
      }
      _scrollToBottom();
      return;
    }
    if (uText.isNotEmpty) {
      setState(() {
        _messages.add(_Msg(text: uText, isUser: true));
      });
    }
    _inputCtrl.clear();
    _scrollToBottom();
    var displayReply = mText;
    var classified = false;
    String? spec;
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(mText);
      final j = jsonMatch != null
          ? jsonDecode(jsonMatch.group(0)!) as Map<dynamic, dynamic>?
          : null;
      if (j != null) {
        classified = j['classified'] == true;
        displayReply = (j['reply'] as String?)?.trim() ?? mText;
        if (j['specialization'] != null) {
          spec = j['specialization'] as String?;
        }
      }
    } catch (_) {
      displayReply = mText;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    final uHist = uText.isNotEmpty ? uText : _langKey == 'he' ? '(קלט קולי)' : '(voice)';
    _geminiHistory
      ..add({'role': 'user', 'parts': [
            {'text': uHist}
          ]})
      ..add({'role': 'model', 'parts': [
            {'text': displayReply}
          ]});
    setState(() {
      _messages.add(_Msg(text: displayReply, isUser: false));
    });
    _scrollToBottom();
    if (!nativeAudio) {
      _speak(displayReply);
    }
    if (classified) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await _payAndDispatch(spec, null);
    }
  }
  void _speak(String t) => _safeJs('vetoTTS', 'speak', [t, _l.code]);
  void _stopSpeaking() => _safeJs('vetoTTS', 'stop', []);
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _onSosOrbTapped() async {
    if (_isDispatching) return;
    final spec = await showDispatchSpecialtySheet(context, langKey: _langKey);
    if (spec == null || !mounted) return;
    await _payAndDispatch(spec, null);
  }

  void _handleSessionReady(Map<String, dynamic> data) {
    final roomId = data['roomId']?.toString();
    if (!mounted || roomId == null || roomId.isEmpty) return;

    setState(() {
      _isDispatching = false;
      _activeEventId = data['eventId']?.toString() ?? roomId;
    });

    final socketRole = _role == 'admin' ? 'admin' : 'user';
    Navigator.of(context).pushNamed(
      '/call',
      arguments: {
        'roomId': roomId,
        'callType': data['callType']?.toString() ?? 'video',
        'peerName': data['peerName']?.toString() ??
            (_langKey == 'he' ? 'עורך דין' : 'Lawyer'),
        'role': socketRole,
        'eventId': data['eventId']?.toString() ?? roomId,
        'language': _langKey,
        'agoraToken': data['agoraToken']?.toString() ?? '',
        'agoraUid': data['agoraUid'],
      },
    );
  }

  void _handleLawyerFound(Map<String, dynamic> data) {
    final roomId = data['roomId']?.toString();
    if (!mounted || roomId == null || roomId.isEmpty) return;

    setState(() {
      _isDispatching = false;
      _activeEventId = data['eventId']?.toString() ?? roomId;
    });

    final awaiting = data['awaitingCitizenChoice'] == true;
    if (awaiting) {
      final eid = data['eventId']?.toString() ?? roomId;
      unawaited(() async {
        final chosen = await showCitizenSessionModeSheet(
          context,
          langKey: _langKey,
          lawyerName: data['lawyerName']?.toString(),
        );
        if (chosen != null && mounted) {
          SocketService().emitCitizenChoseSession(eventId: eid, callType: chosen);
        }
      }());
      return;
    }

    _handleSessionReady(data);
  }

  void _handleVetoDispatched(Map<String, dynamic> data) {
    if (!mounted) return;
    final n = data['lawyersNotified'];
    final count = n is int ? n : int.tryParse('$n') ?? 0;
    final msg = _langKey == 'ru'
        ? '📡 Запрос отправлен. Уведомлено адвокатов: $count.'
        : _langKey == 'en'
            ? '📡 Request broadcast. Lawyers notified: $count.'
            : '📡 הבקשה שודרה לעורכי דין. נשלחה התראה ל־$count עורכי דין.';
    setState(() {
      _messages.add(_Msg(text: msg, isUser: false, isSystem: true));
    });
    _scrollToBottom();
  }

  void _handleNoLawyersAvailable(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _isDispatching = false;
      _messages.add(_Msg(text: data['message']?.toString() ??
          (_langKey == 'he'
              ? 'כרגע אין עורכי דין זמינים.'
              : _langKey == 'ru'
                  ? 'В данный момент нет доступных адвокатов.'
                  : 'No lawyers are currently available.'), isUser: false, isSystem: true));
    });
    final message = data['message']?.toString() ??
        (_langKey == 'he'
            ? 'כרגע אין עורכי דין זמינים.'
            : _langKey == 'ru'
                ? 'В данный момент нет доступных адвокатов.'
                : 'No lawyers are currently available.');
    _scrollToBottom();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: V26.warn,
      ),
    );
  }

  void _handleVetoError(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() => _isDispatching = false);
    final message = data['message']?.toString() ??
        (_langKey == 'he'
            ? 'שליחת החירום נכשלה. נסה שוב.'
            : _langKey == 'ru'
                ? 'Не удалось отправить сигнал. Попробуйте ещё раз.'
                : 'Dispatch failed. Please try again.');
    setState(() {
      _messages.add(_Msg(text: message, isUser: false, isSystem: true));
    });
    _scrollToBottom();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: V26.emerg),
    );
  }

  void _handleCaseAlreadyTaken(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() => _isDispatching = false);
    final message = data['message']?.toString() ??
        (_langKey == 'he'
            ? 'עורך דין אחר כבר קיבל את הקריאה.'
            : _langKey == 'ru'
                ? 'Другой адвокат уже принял вызов.'
                : 'Another lawyer has already taken this case.');
    setState(() {
      _messages.add(_Msg(text: message, isUser: false, isSystem: true));
    });
    _scrollToBottom();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF64748B)),
    );
  }

  Future<void> _openCamera() async {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_langKey == 'he'
            ? 'נדרשת התחברות לתיעוד ראיות'
            : _langKey == 'ru'
                ? 'Войдите, чтобы записывать доказательства'
                : 'Sign in to capture evidence'),
      ));
      return;
    }

    var eventId = _activeEventId;
    if (eventId == null) {
      try {
        final res = await http
            .post(
              Uri.parse('${AppConfig.baseUrl}/events/documentation-session'),
              headers:
                  AppConfig.httpHeaders({'Authorization': 'Bearer $_token'}),
            )
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 201) {
          final b = jsonDecode(res.body) as Map<String, dynamic>;
          eventId = b['eventId']?.toString();
          if (eventId != null && mounted) {
            setState(() => _activeEventId = eventId);
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_langKey == 'he'
                ? 'לא ניתן לפתוח תיעוד ראיות (${res.statusCode})'
                : _langKey == 'ru'
                    ? 'Не удалось начать запись (${res.statusCode})'
                    : 'Could not start evidence session (${res.statusCode})'),
            backgroundColor: V26.emerg,
          ));
          return;
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_langKey == 'he'
              ? 'שגיאת רשת בתיעוד ראיות'
              : _langKey == 'ru'
                  ? 'Ошибка сети'
                  : 'Network error starting evidence'),
          backgroundColor: V26.emerg,
        ));
        return;
      }
    }

    if (!mounted || eventId == null) return;
    final String eid = eventId;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EvidenceScreen(
        eventId: eid,
        token: _token!,
        language: _langKey == 'he'
            ? EvidenceLanguage.he
            : _langKey == 'ru'
                ? EvidenceLanguage.ru
                : EvidenceLanguage.en,
      ),
    ));
  }

  Future<void> _shareLocation() async {
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {}
    if (!mounted) return;
    final lat = pos?.latitude ?? 32.08;
    final lng = pos?.longitude ?? 34.78;
    await Clipboard.setData(ClipboardData(text: 'https://maps.google.com/?q=$lat,$lng'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_langKey == 'he'
          ? 'קישור מיקום הועתק ללוח הגזירים'
          : _langKey == 'ru'
          ? 'Ссылка на местоположение скопирована'
          : 'Location link copied to clipboard'),
      backgroundColor: V26.ok,
    ));
  }

  void _resetSession() {
    setState(() {
      _isDispatching = false;
      _activeEventId = null;
      _messages.clear();
      _geminiHistory.clear();
      _messages.add(_Msg(text: _l.greeting, isUser: false));
    });
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // #region agent log (perf build)
    _buildCount++;
    if (kIsWeb && browser_bridge.isMobileBrowser() && _buildCount % 30 == 0) {
      // ignore: avoid_print
      print('[VETO][perf] veto_screen_build count=$_buildCount tab=$_tab loading=$_isLoading dispatching=$_isDispatching listening=$_isListening');
    }
    // #endregion agent log (perf build)
    final bool isAdmin = _role == 'admin' || _phone.contains('525640021') || _phone.contains('506400030');
    final bool isRtl = _langKey == 'he';
    final bool isWide =
        MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;

    // Desktop uses the 2026 pill-nav shell and renders the wizard/home
    // directly (other routes navigate to their dedicated screens).
    if (isWide) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: V26AppShell(
          destinations: V26CitizenNav.destinations(_langKey),
          currentIndex: 0, // דף הבית
          onDestinationSelected: (i) {
            const routes = V26CitizenNav.routes;
            V26CitizenNav.go(context, routes[i], current: '/veto_screen');
          },
          desktopStatusText: _langKey == 'he'
              ? 'מחובר · ממתין לאירוע · זמני תגובה ממוצעים 3:21 דק\''
              : (_langKey == 'ru'
                  ? 'Подключено · ожидание события · среднее время 3:21'
                  : 'Connected · ready · average response 3:21'),
          desktopTrailing: [
            V26LangPill(
              label: _langKey == 'he'
                  ? 'עברית'
                  : (_langKey == 'ru' ? 'Русский' : 'English'),
              onTap: () {
                final next = _langKey == 'he'
                    ? 'en'
                    : _langKey == 'ru'
                        ? 'he'
                        : 'ru';
                setState(() => _langKey = next);
              },
            ),
            const SizedBox(width: 8),
            V26IconBtn(
              icon: Icons.accessibility_new_rounded,
              onTap: () => showAccessibilitySheet(context),
              tooltip: _langKey == 'he' ? 'נגישות' : 'Accessibility',
            ),
            const SizedBox(width: 8),
            V26PillCTA(
              label: _langKey == 'he'
                  ? 'הפרופיל שלי'
                  : (_langKey == 'ru' ? 'Мой профиль' : 'My Profile'),
              icon: Icons.person_rounded,
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 8),
              V26IconBtn(
                icon: Icons.admin_panel_settings_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, '/admin_settings'),
                tooltip: 'Admin',
              ),
            ],
          ],
          child: SafeArea(
            top: false,
            child: RepaintBoundary(
              child: _buildWizardTab(isAdmin, isRtl),
            ),
          ),
        ),
      );
    }

    // Mobile: keep legacy bottom-nav shell (4 tabs + hamburger appBar).
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: V26.paper,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(isAdmin),
        body: V26Backdrop(
          child: SafeArea(
            child: RepaintBoundary(
              child: _tab == 0
                  ? _buildWizardTab(isAdmin, isRtl)
                  : _tab == 1
                      ? _buildChatTab(isRtl)
                      : _tab == 2
                          ? _buildFilesTab(isRtl)
                          : _buildProfileTab(isRtl),
            ),
          ),
        ),
        bottomNavigationBar: _buildNavBar(isRtl),
      ),
    );
  }

  // ── AppBar: accessibility+flag left | centered title | hamburger right ──
  PreferredSizeWidget _buildAppBar(bool isAdmin) {
    return AppBar(
      backgroundColor: V26.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      toolbarHeight: 56,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: V26.surface,
          border: Border(bottom: BorderSide(color: V26.hairline)),
        ),
      ),
      iconTheme: const IconThemeData(color: V26.ink900, size: 24),
      // Start side: language only (accessibility sits next to hamburger in [actions])
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          AppLanguageMenu(
            compact: true,
            tooltip: _langKey == 'he' ? 'שפה' : _langKey == 'ru' ? 'Язык' : 'Language',
            onLanguageChanged: (k) {
              if (!mounted) return;
              setState(() {
                _langKey = k;
                _messages.clear();
                _geminiHistory.clear();
                _messages.add(_Msg(text: _langs[k]!.greeting, isUser: false));
              });
            },
          ),
        ],
      ),
      leadingWidth: 120,
      // Centered brand title
      title: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_rounded, color: V26.navy600, size: 20),
          const SizedBox(width: 8),
          Text(
            'VETO — הגנה משפטית',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: V26.ink900,
              letterSpacing: 0.5,
              shadows: [Shadow(color: V26.navy600.withValues(alpha: 0.35), blurRadius: 10)],
            ),
          ),
          if (_isDispatching) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: V26.emergSoft,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: V26.emerg.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: V26.emerg,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
      centerTitle: true,
      // End side: accessibility immediately beside hamburger (stable on RTL Web)
      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
          icon: Icon(
            Icons.accessibility_new_rounded,
            size: 22,
            semanticLabel: kIsWeb
                ? (_langKey == 'he'
                    ? 'נגישות'
                    : _langKey == 'ru'
                        ? 'Доступность'
                        : 'Accessibility')
                : null,
          ),
          color: V26.ink500,
          onPressed: () => showAccessibilitySheet(context),
          tooltip: kIsWeb
              ? null
              : (_langKey == 'he' ? 'נגישות' : _langKey == 'ru' ? 'Доступность' : 'Accessibility'),
        ),
        Builder(
          builder: (ctx) => IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.menu_rounded, size: 26),
            color: V26.ink900,
            onPressed: () => _showHamburgerMenu(ctx, isAdmin),
            tooltip: _langKey == 'he' ? 'תפריט' : _langKey == 'ru' ? 'Меню' : 'Menu',
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: SizedBox(height: 0),
      ),
    );
  }

  void _showHamburgerMenu(BuildContext ctx, bool isAdmin) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: V26.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(V26.r2xl)),
      ),
      builder: (_) => Directionality(
        textDirection: _langKey == 'he' ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: V26.hairlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isAdmin)
                _menuItem(
                  Icons.admin_panel_settings_outlined,
                  _langKey == 'he' ? 'פאנל ניהול' : 'Admin Panel',
                  V26.navy600,
                  () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/admin_settings');
                  },
                ),
              _menuItem(
                Icons.home_outlined,
                _langKey == 'he'
                    ? 'דף הבית'
                    : _langKey == 'ru'
                        ? 'Главная'
                        : 'Home',
                V26.navy600,
                () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/landing');
                },
              ),
              _menuItem(
                Icons.folder_special_outlined,
                _langKey == 'he'
                    ? 'כספת קבצים'
                    : _langKey == 'ru'
                        ? 'Хранилище'
                        : 'File Vault',
                V26.navy600,
                () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/files_vault');
                },
              ),
              _menuItem(
                Icons.calendar_month_outlined,
                _langKey == 'he' ? 'יומן משפטי' : 'Legal calendar',
                V26.navy600,
                () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/legal_calendar');
                },
              ),
              _menuItem(
                Icons.menu_book_outlined,
                _langKey == 'he' ? 'מחברת (Enterprise)' : 'Notebook (Enterprise)',
                V26.navy600,
                () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/legal_notebook');
                },
              ),
              _menuItem(
                Icons.map_outlined,
                _langKey == 'he'
                    ? 'מפה'
                    : _langKey == 'ru'
                        ? 'Карта'
                        : 'Map',
                V26.navy600,
                () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/maps');
                },
              ),
              _menuItem(
                Icons.settings_outlined,
                _langKey == 'he'
                    ? 'הגדרות'
                    : _langKey == 'ru'
                        ? 'Настройки'
                        : 'Settings',
                V26.ink500,
                () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              _menuItem(
                Icons.person_outline,
                _langKey == 'he'
                    ? 'פרופיל'
                    : _langKey == 'ru'
                        ? 'Профиль'
                        : 'Profile',
                V26.ink500,
                () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              const Divider(height: 20, color: V26.hairline),
              _menuItem(
                Icons.logout_rounded,
                _langKey == 'he'
                    ? 'התנתקות'
                    : _langKey == 'ru'
                        ? 'Выход'
                        : 'Log out',
                V26.emerg,
                () {
                  Navigator.pop(ctx);
                  AuthService().logout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(
                color: V26.ink900, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  // ── Bottom Nav: 4 tabs ─────────────────────────────────────
  Widget _buildNavBar(bool isRtl) => Container(
        decoration: BoxDecoration(
          color: V26.surface,
          border: const Border(top: BorderSide(color: V26.hairline)),
          boxShadow: [
            BoxShadow(
              color: V26.ink900.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: _tab,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: V26.navy600.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined, color: V26.ink500, size: 24),
              selectedIcon:
                  const Icon(Icons.home_rounded, color: V26.navy600, size: 24),
              label: isRtl ? 'בית' : 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  color: V26.ink500, size: 24),
              selectedIcon: const Icon(Icons.chat_bubble_rounded,
                  color: V26.navy600, size: 24),
              label: isRtl ? "צ'אט" : 'Chat',
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_outlined, color: V26.ink500, size: 24),
              selectedIcon:
                  const Icon(Icons.folder_rounded, color: V26.navy600, size: 24),
              label: isRtl ? 'קבצים' : 'Files',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded,
                  color: V26.ink500, size: 24),
              selectedIcon:
                  const Icon(Icons.person_rounded, color: V26.navy600, size: 24),
              label: isRtl ? 'פרופיל' : 'Profile',
            ),
          ],
        ),
      );

  // ── Files tab placeholder (routes to file vault) ───────────
  Widget _buildFilesTab(bool isRtl) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.folder_special_outlined, size: 64, color: V26.navy600),
      const SizedBox(height: 16),
      Text(
        isRtl ? 'כספת קבצים' : _langKey == 'ru' ? 'Хранилище файлов' : 'File Vault',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: V26.ink900),
      ),
      const SizedBox(height: 8),
      Text(
        isRtl ? 'שמור ונהל את כל קבצי הראיות שלך'
            : _langKey == 'ru' ? 'Сохраняйте и управляйте доказательствами'
            : 'Store and manage all your evidence files',
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/files_vault'),
        icon: const Icon(Icons.open_in_new),
        label: Text(isRtl ? 'פתח כספת קבצים'
            : _langKey == 'ru' ? 'Открыть хранилище' : 'Open File Vault'),
        style: FilledButton.styleFrom(backgroundColor: V26.navy600),
      ),
    ]),
  );

  // ── Profile tab placeholder ────────────────────────────────
  Widget _buildProfileTab(bool isRtl) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: V26.navy600.withValues(alpha: 0.12),
          border: Border.all(color: V26.navy600.withValues(alpha: 0.3), width: 2),
        ),
        child: const Icon(Icons.person_rounded, size: 44, color: V26.navy600),
      ),
      const SizedBox(height: 16),
      Text(
        _phone.isNotEmpty ? _phone : (isRtl ? 'המשתמש שלי' : 'My Profile'),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: V26.ink900),
        textDirection: TextDirection.ltr,
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/profile'),
        icon: const Icon(Icons.manage_accounts_rounded),
        label: Text(isRtl ? 'נהל פרופיל'
            : _langKey == 'ru' ? 'Управлять профилем' : 'Manage Profile'),
        style: FilledButton.styleFrom(backgroundColor: V26.navy600),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => AuthService().logout(context),
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF3B3B)),
        label: Text(
          isRtl ? 'התנתקות' : _langKey == 'ru' ? 'Выход' : 'Log out',
          style: const TextStyle(color: Color(0xFFFF3B3B)),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFF3B3B)),
        ),
      ),
    ]),
  );

  // ══════════════════════════════════════════════════════════
  // WIZARD TAB (Home)
  // ══════════════════════════════════════════════════════════
  Widget _buildWizardTab(bool isAdmin, bool isRtl) => LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final compact = w < 600;
          final isDesktop = w >= 900;
          final hPad = compact ? 14.0 : (isDesktop ? 32.0 : 20.0);
          final maxW = compact
              ? double.infinity
              : (isDesktop ? 1200.0 : 720.0);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, compact ? 28 : 44),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _statusBadge(),
                    SizedBox(height: compact ? 14 : 18),
                    _citizenHero2026(compact, isDesktop),
                    SizedBox(height: compact ? 20 : 28),
                    _secLabel(isRtl
                        ? 'מה קורה עכשיו?'
                        : _langKey == 'ru' ? 'Что происходит?' : "What's happening?"),
                    const SizedBox(height: 6),
                    Text(
                      isRtl
                          ? 'בחר את התרחיש שמתאים לך כעת'
                          : _langKey == 'ru'
                              ? 'Выберите подходящий сценарий'
                              : 'Choose the situation you are in right now',
                      style: const TextStyle(
                        fontFamily: V26.serif,
                        color: V26.ink900,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRtl
                          ? 'בהתאם לבחירתך נתאים זכויות, הנחיות וסוג עורך הדין שיוזעק.'
                          : _langKey == 'ru'
                              ? 'Подстроим права и инструкции под ваш выбор.'
                              : 'We will tailor rights, guidance, and counsel type to your choice.',
                      style: const TextStyle(
                        color: V26.ink500,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildScenarioSelector(isRtl, compact, isDesktop),
                    SizedBox(height: compact ? 12 : 14),
                    _scenarioDetailPanel(isRtl, compact),
                    SizedBox(height: compact ? 12 : 14),
                    _rightsCard(),
                    if (isAdmin) ...[
                      const SizedBox(height: 20),
                      _adminSection(isRtl),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );

  // ── Status badge pill (2026 surface) ───────────────────────
  Widget _statusBadge() => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: V26.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (_isDispatching ? V26.emerg : V26.navy500).withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isDispatching ? V26.emerg : V26.navy500).withValues(alpha: 0.18),
            blurRadius: 18,
          ),
          BoxShadow(color: V26.ink900.withValues(alpha: 0.06), blurRadius: 12),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          Icons.shield_rounded,
          size: 16,
          color: _isDispatching ? V26.emerg : V26.navy600,
        ),
        const SizedBox(width: 8),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isDispatching ? V26.emerg : V26.ok,
            boxShadow: [
              BoxShadow(
                color: (_isDispatching ? V26.emerg : V26.ok).withValues(alpha: 0.55),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          _isDispatching
              ? (_langKey == 'he'
                  ? 'מחובר | שיגור פעיל'
                  : _langKey == 'ru'
                      ? 'Активно | Диспетчеризация'
                      : 'Connected | Dispatching')
              : (_langKey == 'he'
                  ? 'מחובר | ממתין לאירוע'
                  : _langKey == 'ru'
                      ? 'Подключено | Ожидание'
                      : 'Connected | Standby'),
          style: TextStyle(
            color: _isDispatching ? V26.emerg : V26.ink900,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        if (_phone.isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(
            _phone,
            style: const TextStyle(color: V26.ink500, fontSize: 11),
            textDirection: TextDirection.ltr,
          ),
        ],
      ]),
    ),
  );

  // ── Citizen hero (aligned with 2026/citizen.html rev 2) ─────────
  Widget _citizenHero2026(bool compact, bool isDesktop) {
    const r = 28.0;
    return V26Card(
      radius: r,
      lift: true,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      V26.navy500.withValues(alpha: 0.10),
                      Colors.transparent,
                      const Color(0xFFD6243A).withValues(alpha: 0.07),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : (isDesktop ? 28 : 22),
                compact ? 20 : 28,
                compact ? 18 : (isDesktop ? 28 : 22),
                compact ? 20 : 28,
              ),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _heroCopyBlock(compact, isDesktop)),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Center(
                            child: _buildSosOrbCore(compact, isDesktop),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _buildSosOrbCore(compact, isDesktop)),
                        if (_isDispatching) ...[
                          const SizedBox(height: 10),
                          Text(
                            _langKey == 'he'
                                ? 'עורך דין בדרך אליך...'
                                : _langKey == 'ru'
                                    ? 'Адвокат уже едет...'
                                    : 'A lawyer is on the way...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: V26.ink500,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _heroCopyBlock(compact, isDesktop),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCopyBlock(bool compact, bool isDesktop) {
    const align = TextAlign.start;
    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _langKey == 'he'
                ? 'VETO · עזרה משפטית מיידית'
                : _langKey == 'ru'
                    ? 'VETO · Срочная юридическая помощь'
                    : 'VETO · Immediate legal help',
            textAlign: align,
            style: const TextStyle(
              color: V26.navy600,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          _heroHeadlineDesktop(),
          const SizedBox(height: 12),
          Text(
            _langKey == 'he'
                ? 'הקש על כפתור ה-SOS ועורך דין פלילי מתמחה יוצר איתך קשר תוך דקות — קולי או בווידאו, עם תיעוד שיחה מלא, גיבוי בכספת אישית מוצפנת, ומסירת כל הראיות לידיך בלבד.'
                : _langKey == 'ru'
                    ? 'Нажмите SOS — уголовный адвокат свяжется с вами за минуты: голос или видео, полная запись разговора, шифрованное хранение и доступ к доказательствам только у вас.'
                    : 'Tap SOS — a specialist criminal lawyer reaches you in minutes: voice or video, full call logging, encrypted vault backup, and evidence stays in your hands only.',
            textAlign: align,
            style: const TextStyle(
              color: V26.ink500,
              fontSize: 15,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: _heroTrustPills(),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heroHeadlineMobile(),
        const SizedBox(height: 8),
        Text(
          _langKey == 'he'
              ? 'הקש על SOS ועו"ד מתמחה ייצור איתך קשר תוך דקות. תיעוד שיחה מלא, מוצפן וגיבוי לכספת.'
              : _langKey == 'ru'
                  ? 'Нажмите SOS — адвокат свяжется за минуты. Полная запись, шифрование и резерв в сейфе.'
                  : 'Tap SOS — a lawyer connects within minutes. Encrypted call log and vault backup.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: V26.ink500,
            fontSize: 13,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _heroHeadlineDesktop() {
    if (_langKey == 'he') {
      return const Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: V26.serif,
            fontSize: 30,
            height: 1.18,
            color: V26.ink900,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(text: 'כשהדקה הראשונה\nקובעת את '),
            TextSpan(
              text: 'כל היתר',
              style: TextStyle(color: V26.navy600),
            ),
            TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.start,
      );
    }
    if (_langKey == 'ru') {
      return const Text(
        'Когда первая минута решает всё остальное.',
        textAlign: TextAlign.start,
        style: TextStyle(
          fontFamily: V26.serif,
          fontSize: 28,
          height: 1.2,
          color: V26.ink900,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return const Text.rich(
      TextSpan(
        style: TextStyle(
          fontFamily: V26.serif,
          fontSize: 28,
          height: 1.2,
          color: V26.ink900,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: 'When the first minute decides '),
          TextSpan(
            text: 'everything else',
            style: TextStyle(color: V26.navy600),
          ),
          TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _heroHeadlineMobile() {
    if (_langKey == 'he') {
      return const Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: V26.serif,
            fontSize: 17,
            height: 1.35,
            color: V26.ink900,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: 'עורך דין מטעמך — '),
            TextSpan(
              text: 'תוך דקות',
              style: TextStyle(color: V26.navy600, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }
    if (_langKey == 'ru') {
      return const Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: V26.serif,
            fontSize: 17,
            height: 1.35,
            color: V26.ink900,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: 'Адвокат на вашей стороне — '),
            TextSpan(
              text: 'за минуты',
              style: TextStyle(color: V26.navy600, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }
    return const Text.rich(
      TextSpan(
        style: TextStyle(
          fontFamily: V26.serif,
          fontSize: 17,
          height: 1.35,
          color: V26.ink900,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: 'A lawyer on your side — '),
          TextSpan(
            text: 'in minutes',
            style: TextStyle(color: V26.navy600, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  List<Widget> _heroTrustPills() {
    String a;
    String b;
    String c;
    if (_langKey == 'he') {
      a = 'תיעוד שיחה מלא';
      b = 'כספת מוצפנת E2E';
      c = 'זמין 24/7';
    } else if (_langKey == 'ru') {
      a = 'Полная запись разговора';
      b = 'Шифрованный сейф E2E';
      c = 'Доступно 24/7';
    } else {
      a = 'Full call logging';
      b = 'E2E encrypted vault';
      c = 'Available 24/7';
    }
    Widget pill(String label, IconData icon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: V26.paper2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: V26.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: V26.ink700),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: V26.ink700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return [
      pill(a, Icons.check_rounded),
      pill(b, Icons.lock_outline_rounded),
      pill(c, Icons.schedule_rounded),
    ];
  }

  Widget _buildSosOrbCore(bool compact, bool isDesktop) {
    final orbSize = isDesktop ? 188.0 : (compact ? 148.0 : 168.0);
    final ringOuter = orbSize + 36;
    final ringMid = orbSize + 20;
    return Semantics(
      button: true,
      label: _langKey == 'he'
          ? 'לחץ להפעלת מצוקה ושיגור עורך דין'
          : _langKey == 'ru'
              ? 'Нажмите для вызова адвоката'
              : 'Tap to dispatch a lawyer',
      child: GestureDetector(
        onTap: _isDispatching ? null : _onSosOrbTapped,
        child: SizedBox(
          width: ringOuter + 12,
          height: ringOuter + 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringOuter + 10,
                height: ringOuter + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF3B3B).withValues(alpha: 0.08),
                    width: 8,
                  ),
                ),
              ),
              Container(
                width: ringMid + 8,
                height: ringMid + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF3B3B).withValues(alpha: 0.16),
                    width: 6,
                  ),
                ),
              ),
              Container(
                width: orbSize + 10,
                height: orbSize + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF3B3B).withValues(alpha: 0.28),
                    width: 4,
                  ),
                ),
              ),
              Container(
                width: orbSize,
                height: orbSize,
                decoration: VetoDecorations.light3DOrb(active: _isDispatching),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isDispatching)
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    else
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 40 : 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          shadows: const [
                            Shadow(color: Colors.white54, blurRadius: 14),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _isDispatching
                          ? (_langKey == 'he'
                              ? 'מחפש...'
                              : _langKey == 'ru'
                                  ? 'Поиск...'
                                  : 'Searching...')
                          : (_langKey == 'he'
                              ? 'עזרה מיידית'
                              : _langKey == 'ru'
                                  ? 'ПОМОЩЬ'
                                  : 'EMERGENCY'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _scenarioSub(_Scenario s) {
    switch (s) {
      case _Scenario.interrogation:
        return _langKey == 'he'
            ? 'זימון, חקירה תחת אזהרה, מעצר'
            : _langKey == 'ru'
                ? 'Вызов, допрос, арест'
                : 'Summons, caution interview, arrest';
      case _Scenario.traffic:
        return _langKey == 'he'
            ? 'מהירות, אלכוהול, רישיון'
            : _langKey == 'ru'
                ? 'Скорость, алкоголь, права'
                : 'Speed, alcohol, license';
      case _Scenario.arrest:
        return _langKey == 'he'
            ? 'זכויות במעצר, קשר עם עו"ד'
            : _langKey == 'ru'
                ? 'Права при аресте, адвокат'
                : 'Custody rights, counsel';
      case _Scenario.accident:
        return _langKey == 'he'
            ? 'פציעות, ביטוח, תיעוד'
            : _langKey == 'ru'
                ? 'Травмы, страховка, документы'
                : 'Injuries, insurance, records';
      case _Scenario.other:
        return _langKey == 'he'
            ? 'כל מצב אחר שדורש ייעוץ'
            : _langKey == 'ru'
                ? 'Любая другая ситуация'
                : 'Any other situation';
    }
  }

  Widget _secLabel(String txt) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: V26.navy600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            txt.toUpperCase(),
            style: const TextStyle(
              color: V26.ink300,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ]),
      );

  // ── Scenario detail panel (2026/citizen.html rev 2) ─────────
  Widget _scenarioDetailPanel(bool isRtl, bool compact) {
    final sd = _sdMap[_scenario]!;
    final title = _langKey == 'ru'
        ? sd.ru
        : _langKey == 'en'
            ? sd.en
            : sd.he;
    final sub = _scenarioSub(_scenario);
    final icon = _scenarioIcon(_scenario);
    final bullets = _langKey == 'ru'
        ? sd.rRu
        : _langKey == 'en'
            ? sd.rEn
            : sd.rHe;
    final whatToKnow = bullets.take(2).toList();
    final firstAction = bullets.skip(2).take(2).toList();
    final criticalTime = _langKey == 'he'
        ? '60 הדקות הראשונות מקבלות משקל מכריע. הקש SOS עכשיו וקבל ייעוץ ראשוני.'
        : _langKey == 'ru'
            ? 'Первые 60 минут — критически важны. Нажмите SOS сейчас.'
            : 'The first 60 minutes are critical. Press SOS now for immediate guidance.';
    final criticalLabel = _langKey == 'he'
        ? 'זמן קריטי:'
        : _langKey == 'ru'
            ? 'Критическое время:'
            : 'Critical time:';
    final labelKnow = _langKey == 'he'
        ? 'מה הכי חשוב לדעת'
        : _langKey == 'ru'
            ? 'Что важно знать'
            : 'What to know first';
    final labelAction = _langKey == 'he'
        ? 'פעולה ראשונה'
        : _langKey == 'ru'
            ? 'Первое действие'
            : 'First action';

    return V26Card(
      padding: EdgeInsets.zero,
      lift: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Head
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFBFCFE), V26.surface],
              ),
              border: Border(bottom: BorderSide(color: V26.hairline)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [V26.navy600, V26.navy500],
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: V26.serif,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: V26.ink900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: const TextStyle(
                          fontFamily: V26.sans,
                          fontSize: 12,
                          color: V26.ink500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body: what-to-know + first-action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sdBlock(labelKnow, whatToKnow),
                const SizedBox(height: 10),
                _sdBlock(labelAction, firstAction),
              ],
            ),
          ),
          // Warn
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF8D6CB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4B59C),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.warning_amber_rounded,
                        size: 14, color: Color(0xFF5A1F0E)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: V26.sans,
                          color: Color(0xFF7A2A12),
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: '$criticalLabel ',
                            style: const TextStyle(
                              color: Color(0xFF5A1F0E),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(text: criticalTime),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sdBlock(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: V26.sans,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: V26.navy600,
          ),
        ),
        const SizedBox(height: 6),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: V26.navy500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    it,
                    style: const TextStyle(
                      fontFamily: V26.sans,
                      fontSize: 13,
                      color: V26.ink700,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Scenario tile (single) ────────────────────────────────
  Widget _scenarioTile(MapEntry<_Scenario, _SD> e, bool compact) {
    final sel = e.key == _scenario;
    final lbl = _langKey == 'ru' ? e.value.ru : _langKey == 'en' ? e.value.en : e.value.he;
    final sub = _scenarioSub(e.key);
    final iconSize = compact ? 26.0 : 30.0;
    final circlePad = compact ? 8.0 : 10.0;
    // Arrest scenario uses red icon per mockup
    final isRed = e.key == _Scenario.arrest;
    final iconColor =
        sel ? V26.navy600 : (isRed ? V26.emerg : V26.navy500);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() { _scenario = e.key; _rightsExpanded = true; });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: sel ? V26.navy500.withValues(alpha: 0.08) : V26.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel
                  ? V26.navy500.withValues(alpha: 0.55)
                  : V26.hairline,
              width: sel ? 1.5 : 1,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: V26.navy500.withValues(alpha: 0.18),
                      blurRadius: 18,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: V26.ink900.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(circlePad),
                decoration: BoxDecoration(
                  color: sel
                      ? V26.navy500.withValues(alpha: 0.12)
                      : V26.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: sel
                        ? V26.navy500.withValues(alpha: 0.45)
                        : V26.hairline,
                    width: 1,
                  ),
                ),
                child: Icon(_scenarioIcon(e.key), size: iconSize, color: iconColor),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                lbl,
                style: TextStyle(
                  color: sel ? V26.navy600 : V26.ink900,
                  fontSize: 12.5,
                  fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: compact ? 4 : 5),
              Text(
                sub,
                style: TextStyle(
                  color: sel ? V26.ink500 : V26.ink300,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioSelector(bool isRtl, bool compact, bool isDesktop) {
    const order = <_Scenario>[
      _Scenario.interrogation,
      _Scenario.traffic,
      _Scenario.arrest,
      _Scenario.accident,
      _Scenario.other,
    ];
    final entries = order.map((k) => MapEntry(k, _sdMap[k]!)).toList();
    final cols = isDesktop ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: isDesktop ? 0.92 : 0.88,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) => _scenarioTile(entries[i], compact),
    );
  }

  // ── Rights card (2026 light surface) ─────────────────────
  /// Rounded + border: use uniform [Border.all] and a "start" accent strip in a [Stack].
  Widget _rightsCard() {
    const r = V26.rLg;
    const accentC = V26.navy600;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: V26.shadow2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Container(
              decoration: BoxDecoration(
                color: V26.surface,
                border: Border.all(
                  color: V26.hairline,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _rightsExpanded = !_rightsExpanded),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(r)),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: V26.navy600,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _langKey == 'he'
                                  ? 'הזכויות שלך — $_sLabel'
                                  : _langKey == 'ru'
                                      ? 'Ваши права — $_sLabel'
                                      : 'Your Rights — $_sLabel',
                              style: const TextStyle(
                                color: V26.ink900,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                height: 1.25,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _rightsExpanded = !_rightsExpanded),
                            style: TextButton.styleFrom(
                              foregroundColor: V26.navy600,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _langKey == 'he'
                                  ? 'קרא עוד'
                                  : _langKey == 'ru'
                                      ? 'Подробнее'
                                      : 'Read more',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _rightsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: V26.navy600,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_rightsExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: _rights
                            .take(3)
                            .map(
                              (line) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin:
                                          const EdgeInsetsDirectional.only(
                                        top: 7,
                                        start: 2,
                                        end: 2,
                                      ),
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: V26.navy500,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style: const TextStyle(
                                          color: V26.ink700,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            Builder(
              builder: (context) {
                final rtl = Directionality.of(context) == TextDirection.rtl;
                return Positioned(
                  left: rtl ? null : 0,
                  right: rtl ? 0 : null,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 2,
                      color: accentC.withValues(alpha: 0.35),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Admin Evidence Files ──────────────────────────────────
  Widget _adminSection(bool isRtl) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(children: [
        const Icon(Icons.folder_open_rounded, color: V26.navy600, size: 16),
        const SizedBox(width: 6),
        Text(
          isRtl ? 'ראיות וקבצי שרת' : 'Server Evidence Files',
          style: const TextStyle(color: V26.ink500, fontSize: 12,
              fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
        const Spacer(),
        IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            color: V26.ink500,
            onPressed: _loadAdminFiles),
      ]),
      const SizedBox(height: 8),
      if (_adminFilesLoading)
        const Center(child: Padding(padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: V26.navy600, strokeWidth: 2)))
      else if (_adminFiles.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: V26.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: V26.hairline)),
          child: Text(
            isRtl ? 'אין אירועים עם ראיות בשרת' : 'No events with evidence on server',
            style: const TextStyle(color: V26.ink500),
            textAlign: TextAlign.center,
          ),
        )
      else
        Container(
          decoration: BoxDecoration(color: V26.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: V26.hairline)),
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _adminFiles.length > 25 ? 25 : _adminFiles.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: V26.hairline),
            itemBuilder: (ctx, i) {
              final ev = _adminFiles[i];
              final user = ev['user_id'];
              final status = ev['status'] as String? ?? '?';
              final evidence = (ev['evidence'] as List?) ?? [];
              final eid = _mongoEventId(ev);
              String dateStr = '';
              try {
                final d = DateTime.parse(ev['triggered_at']).toLocal();
                dateStr = '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
              } catch (_) {}
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _adminStatusColor(status))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user is Map ? (user['full_name'] ?? user['phone'] ?? 'משתמש').toString() : 'משתמש',
                        style: const TextStyle(color: V26.ink900, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (eid != null) ...[
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        tooltip: AdminStrings.t(_langKey, 'edit'),
                        icon: const Icon(Icons.edit_outlined, size: 18, color: V26.navy600),
                        onPressed: () => _adminEditEmergencyEvent(ctx, ev, isRtl),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        tooltip: _langKey == 'he'
                            ? 'ניקוי'
                            : _langKey == 'ru'
                                ? 'Очистка'
                                : 'Cleaning',
                        icon: const Icon(Icons.cleaning_services_outlined, size: 18, color: V26.ink500),
                        onPressed: () => _adminCleanEmergencyEvent(ctx, ev, isRtl),
                      ),
                    ],
                    Text(dateStr,
                        style: const TextStyle(color: V26.ink300, fontSize: 11)),
                  ]),
                  if (evidence.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: evidence.take(6).map<Widget>((ev2) {
                        final url = ev2['cloud_url'] as String? ?? '';
                        final tp = ev2['type'] as String? ?? 'file';
                        if (url.isEmpty) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () => launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: V26.navy600.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: V26.navy600.withValues(alpha: 0.2)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                  tp == 'photo' ? Icons.image_outlined
                                      : tp == 'video' ? Icons.videocam_outlined
                                      : Icons.audio_file_outlined,
                                  size: 12, color: V26.navy600),
                              const SizedBox(width: 4),
                              Text(tp,
                                  style: const TextStyle(
                                      color: V26.navy600, fontSize: 10)),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else
                    Text(
                      isRtl ? 'אין ראיות מצורפות' : 'No evidence attached',
                      style: const TextStyle(color: V26.ink300, fontSize: 11),
                    ),
                ]),
              );
            },
          ),
        ),
    ],
  );

  // ══════════════════════════════════════════════════════════
  // CHAT TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildChatTab(bool isRtl) => Column(children: [
    // ── Status banner when dispatching ──────────────────────
    if (_isDispatching)
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: V26.emerg.withValues(alpha: 0.08),
        child: Row(children: [
          const Icon(Icons.broadcast_on_personal_rounded,
              color: V26.emerg, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
            _langKey == 'he' ? '🚨 בתהליך שיגור — מחפש עורך דין זמין...'
                : _langKey == 'ru' ? '🚨 Диспетчеризация — ищем адвоката...'
                : '🚨 Dispatching — searching for a lawyer...',
            style: const TextStyle(
              color: V26.emerg, fontSize: 12, fontWeight: FontWeight.w700),
          )),
          if (_activeEventId != null)
            TextButton(
              onPressed: _resetSession,
              style: TextButton.styleFrom(
                  foregroundColor: V26.ink500, padding: EdgeInsets.zero),
              child: Text(_langKey == 'he' ? 'ביטול'
                  : _langKey == 'ru' ? 'Отмена' : 'Cancel',
                  style: const TextStyle(fontSize: 12)),
            ),
        ]),
      ),
    // ── Messages ─────────────────────────────────────────────
    Expanded(
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _messages.length) return _typingBubble();
          final msg = _messages[i];
          if (msg.isSystem) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: V26.emerg.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: V26.emerg.withValues(alpha: 0.25)),
              ),
              child: Text(msg.text,
                  style: const TextStyle(
                      color: V26.emerg,
                      fontSize: 14, height: 1.5, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            );
          }
          final isUser = msg.isUser;
          return Align(
            alignment: isUser
                ? (isRtl ? Alignment.centerRight : Alignment.centerLeft)
                : (isRtl ? Alignment.centerLeft : Alignment.centerRight),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: isUser
                    ? V26.navy600.withValues(alpha: 0.10)
                    : V26.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                    color: isUser
                        ? V26.navy600.withValues(alpha: 0.30)
                        : V26.hairline,
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(msg.text,
                  style: TextStyle(
                      color: isUser ? V26.navy600 : V26.ink900,
                      fontSize: 14.5,
                      height: 1.55,
                      fontWeight: isUser ? FontWeight.w700 : FontWeight.w600)),
            ),
          );
        },
      ),
    ),
    // ── Input row ────────────────────────────────────────────
    ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: V26.surface,
          border: Border(top: BorderSide(color: V26.hairline.withValues(alpha: 0.9))),
          boxShadow: [
            BoxShadow(
              color: V26.ink900.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chatInput(isRtl),
            _chatActBar(),
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
  ]);

  Widget _typingBubble() => Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: V26.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
          border: Border.all(color: V26.hairline, width: 1.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: 48,
            child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(4),
                backgroundColor: V26.hairline,
                valueColor: const AlwaysStoppedAnimation(V26.ok))),
        const SizedBox(width: 10),
        Text(_l.processing,
            style: const TextStyle(color: V26.ink500,
                fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    ),
  );

  Widget _chatInput(bool isRtl) {
    // Web: mic + optional Gemini Live tune + paste — needs extra width vs mobile STT+paste.
    const sideSlot = 152.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          SizedBox(
            width: sideSlot,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                GestureDetector(
                  onTap: _toggleMic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? const Color(0xFFFF3B3B) : V26.surface,
                      border: Border.all(
                        color: _isListening ? const Color(0xFFFF3B3B).withValues(alpha: 0.7) : V26.hairline,
                      ),
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF3B3B).withValues(alpha: 0.35),
                                blurRadius: 18,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: V26.navy500.withValues(alpha: 0.12),
                                blurRadius: 16,
                              ),
                            ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : V26.ink900,
                      size: 22,
                    ),
                  ),
                ),
                if (kIsWeb &&
                    browser_bridge.supportsBrowserMethod('vetoGeminiLive', 'isSupported', const [])) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: _langKey == 'he'
                        ? 'הגדרות שמע (Gemini Live)'
                        : _langKey == 'ru'
                            ? 'Настройки звука (Gemini Live)'
                            : 'Live voice & volume',
                    child: GestureDetector(
                      onTap: () async {
                        await showVetoLiveVoiceSheet(context);
                        if (!mounted) return;
                        final v = await VetoLiveAudioPrefs.getVoice();
                        final g = await VetoLiveAudioPrefs.getGain();
                        if (mounted) {
                          setState(() {
                            _geminiLiveVoice = v;
                            _geminiLiveGain = g;
                          });
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: V26.surface,
                          border: Border.all(color: V26.hairline),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: V26.navy600,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && mounted) {
                      setState(() => _inputCtrl.text = data!.text!);
                      _inputCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: _inputCtrl.text.length),
                      );
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: V26.surface,
                      border: Border.all(color: V26.hairline),
                    ),
                    child: const Icon(Icons.content_paste,
                        color: V26.ink900, size: 22),
                  ),
                ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !_isDispatching,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(color: V26.ink900, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isDispatching
                    ? _l.dispatching
                    : (_isListening && _liveSessionActive && kIsWeb
                        ? _geminiLiveInputHint
                        : _l.hint),
                hintStyle: const TextStyle(color: V26.ink500),
                filled: true,
                fillColor: V26.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: V26.hairline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: V26.hairline)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: V26.navy600.withValues(alpha: 0.85), width: 1.2)),
              ),
              onSubmitted: _send,
              textInputAction: TextInputAction.send,
            ),
          ),
          SizedBox(
            width: sideSlot,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                onTap: () => _send(_inputCtrl.text),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (_isLoading || _isDispatching)
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [V26.navy700, V26.navy500],
                          ),
                    color: (_isLoading || _isDispatching)
                        ? V26.surface
                        : null,
                    boxShadow: [
                      if (!(_isLoading || _isDispatching))
                        BoxShadow(
                          color: V26.navy600.withValues(alpha: 0.25),
                          blurRadius: 18,
                        ),
                    ],
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatActBar() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _langKey == 'he'
                  ? 'כלים מהירים'
                  : _langKey == 'ru'
                      ? 'Быстрые действия'
                      : 'Quick tools',
              textAlign: TextAlign.center,
              style: const TextStyle(color: V26.ink300, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: _chatActBtn(
                      Icons.camera_alt_outlined,
                      V26.navy500,
                      _langKey == 'he'
                          ? 'תיעוד'
                          : _langKey == 'ru'
                              ? 'Камера'
                              : 'Camera',
                      _openCamera,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _chatActBtn(
                      Icons.volume_off_rounded,
                      V26.navy500,
                      _langKey == 'he'
                          ? 'השתק'
                          : _langKey == 'ru'
                              ? 'Звук'
                              : 'Mute',
                      _stopSpeaking,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _chatActBtn(
                      Icons.location_on_outlined,
                      V26.ok,
                      _langKey == 'he'
                          ? 'מיקום'
                          : _langKey == 'ru'
                              ? 'Геолок.'
                              : 'Location',
                      _shareLocation,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _chatActBtn(IconData icon, Color color, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.25))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  _ContactSheet — WhatsApp / Telegram / Video chooser
// ══════════════════════════════════════════════════════════════
class _ContactSheet extends StatefulWidget {
  final String type, langKey, scenarioLabel;
  const _ContactSheet({required this.type, required this.langKey, required this.scenarioLabel});
  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _buildMsg() {
    if (widget.langKey == 'he') {
      return 'שלום, אני זקוק לסיוע משפטי דחוף — ${widget.scenarioLabel}. אנא פנה אליי בהקדם.';
    }
    if (widget.langKey == 'ru') {
      return 'Здравствуйте, мне нужна срочная юридическая помощь — ${widget.scenarioLabel}.';
    }
    return 'Hello, I need urgent legal assistance regarding: ${widget.scenarioLabel}. Please contact me immediately.';
  }

  Future<void> _go() async {
    setState(() => _busy = true);
    final t = _ctrl.text.trim();
    try {
      Uri uri;
      if (widget.type == 'whatsapp') {
        final p = t.replaceAll(RegExp(r'[^\d+]'), '');
        uri = Uri.parse('https://wa.me/$p?text=${Uri.encodeComponent(_buildMsg())}');
      } else if (widget.type == 'telegram') {
        if (t.startsWith('@')) {
          uri = Uri.parse('https://t.me/${t.substring(1)}');
        } else {
          final p = t.replaceAll(RegExp(r'[^\d+]'), '');
          uri = Uri.parse('https://t.me/$p');
        }
      } else {
        uri = Uri.parse(t.startsWith('http') ? t : 'https://$t');
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('לא ניתן לפתוח את הקישור')));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.langKey == 'he';
    final Color accent = widget.type == 'whatsapp' ? const Color(0xFF25D366)
        : widget.type == 'telegram' ? const Color(0xFF229ED9)
        : V26.navy500;
    final String title = widget.type == 'whatsapp' ? 'WhatsApp'
        : widget.type == 'telegram' ? 'Telegram'
        : (isRtl ? 'שיחת וידאו' : 'Video Call');
    final String hintText = widget.type == 'whatsapp' ? '+972XXXXXXXXX'
        : widget.type == 'telegram' ? '@username'
        : 'https://zoom.us/j/...';
    final String labelText = widget.type == 'video'
        ? (isRtl ? 'קישור לשיחה' : 'Call link')
        : (isRtl ? 'מספר טלפון' : 'Phone number');

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(
                      widget.type == 'whatsapp' ? Icons.chat_rounded
                          : widget.type == 'telegram' ? Icons.send_rounded
                          : Icons.videocam_rounded,
                      color: accent, size: 18)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(
                  color: V26.ink900, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  color: V26.ink500,
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: V26.ink900),
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: const TextStyle(color: V26.ink500),
                hintText: hintText,
                hintStyle: const TextStyle(color: V26.ink300),
                filled: true,
                fillColor: const Color(0xFF0F1A24),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: V26.hairline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: V26.hairline)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: _ctrl,
              builder: (_, __) => FilledButton.icon(
                onPressed: _busy || _ctrl.text.trim().isEmpty ? null : _go,
                style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: _busy
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.open_in_new, size: 18, color: Colors.white),
                label: Text(isRtl ? 'פתח' : 'Open',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            if (widget.type != 'video') ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => setState(() => _ctrl.text = '+972'),
                child: Text(isRtl ? '▼ ישראל +972...' : '▼ Israel +972...',
                    style: const TextStyle(color: V26.ink500, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  _PaymentDialog — Step 1: open PayPal tab
// ══════════════════════════════════════════════════════════════
class _PaymentDialog extends StatefulWidget {
  final String? spec;
  const _PaymentDialog({this.spec});
  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0C1827),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.paypal_rounded, color: Color(0xFF009CDE), size: 24),
        SizedBox(width: 10),
        Text('תשלום עם PayPal',
            style: TextStyle(color: Color(0xFF0C1827), fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ייעוץ עורך דין 15 דקות',
              style: TextStyle(color: Color(0xFF0C1827), fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('₪50 (≈ \$13.90 USD) — חיוב חד-פעמי',
              style: TextStyle(color: Color(0xFFA8A090), fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
            ),
            child: const Text('לא ניתן לבטל לאחר תשלום.',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, null),
          child: const Text('ביטול', style: TextStyle(color: Color(0xFF7A7260))),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009CDE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: _loading ? null : _openPayPal,
          icon: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.open_in_new, size: 16),
          label: Text(_loading ? 'פותח...' : 'שלם עם PayPal'),
        ),
      ],
    );
  }

  Future<void> _openPayPal() async {
    setState(() => _loading = true);
    final orderId = await PaymentService.createAndOpenOrder(PaymentType.consultation);
    if (!mounted) return;
    if (orderId == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה ביצירת הזמנת PayPal. נסה שוב.')));
      return;
    }
    Navigator.pop(context, orderId);
  }
}

// ══════════════════════════════════════════════════════════════
//  _CaptureDialog — Step 2: confirm payment
// ══════════════════════════════════════════════════════════════
class _CaptureDialog extends StatefulWidget {
  final String orderId;
  const _CaptureDialog({required this.orderId});
  @override
  State<_CaptureDialog> createState() => _CaptureDialogState();
}

class _CaptureDialogState extends State<_CaptureDialog> {
  bool _capturing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0C1827),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.hourglass_top_rounded, color: V26.navy500, size: 22),
        SizedBox(width: 10),
        Text('אשר את התשלום',
            style: TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
            'PayPal נפתח בטאב חדש.\nלאחר אישור התשלום שם — חזור לכאן ולחץ "שילמתי".',
            style: TextStyle(color: Color(0xFFA8A090), height: 1.6, fontSize: 13),
            textAlign: TextAlign.center),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
        ],
      ]),
      actions: [
        TextButton(
          onPressed: _capturing ? null : () => Navigator.pop(context, false),
          child: const Text('ביטול', style: TextStyle(color: Color(0xFF7A7260))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: _capturing ? null : _capture,
          child: _capturing
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('שילמתי ✓', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Future<void> _capture() async {
    setState(() { _capturing = true; _error = null; });
    final result = await PaymentService.captureOrder(
        orderId: widget.orderId, type: PaymentType.consultation);
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _capturing = false;
        _error = result.error != null
            ? 'שגיאה: ${result.error}'
            : 'התשלום לא הושלם. נסה שוב לאחר אישור ב-PayPal.';
      });
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  _SubscriptionGateDialog — monthly subscription paywall
// ══════════════════════════════════════════════════════════════
class _SubscriptionGateDialog extends StatefulWidget {
  const _SubscriptionGateDialog();
  @override
  State<_SubscriptionGateDialog> createState() => _SubscriptionGateDialogState();
}

class _SubscriptionGateDialogState extends State<_SubscriptionGateDialog> {
  bool _loading = false;
  String? _error;
  String? _orderId;

  Future<void> _openPayPal() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orderId = await PaymentService.createAndOpenOrder(PaymentType.subscription);
      if (!mounted) return;
      if (orderId == null) {
        setState(() { _loading = false; _error = 'לא ניתן לפתוח את PayPal. נסה שוב.'; });
        return;
      }
      setState(() { _loading = false; _orderId = orderId; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'שגיאה: $e'; });
    }
  }

  Future<void> _confirmPayment() async {
    if (_orderId == null) return;
    setState(() { _loading = true; _error = null; });
    final phone = await AuthService().getStoredPhone();
    final result = await PaymentService.captureOrder(
        orderId: _orderId!, type: PaymentType.subscription, userId: phone);
    if (!mounted) return;
    if (result.success) {
      await AuthService().setSubscribed(true);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      setState(() { _loading = false; _error = result.error ?? 'התשלום לא אושר.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: const Color(0xFF0C1827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.lock_outline, color: V26.navy500),
          SizedBox(width: 10),
          Text('נדרש מנוי', style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('כדי להשתמש ב-VETO נדרש מנוי חודשי.',
                style: TextStyle(color: Color(0xFFA8A090), fontSize: 14)),
            const SizedBox(height: 4),
            const Text('ללא מנוי פעיל לא ניתן להשתמש במערכת.',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF07101C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: V26.navy500.withValues(alpha: 0.4)),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('מנוי חודשי',
                    style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 6),
                Row(children: [
                  Text('₪19.90',
                      style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.w800, fontSize: 22)),
                  SizedBox(width: 6),
                  Text('/ חודש  (USD \$5.50)',
                      style: TextStyle(color: Color(0xFFA8A090), fontSize: 13)),
                ]),
                SizedBox(height: 8),
                Text('✓ ייעוץ AI משפטי ללא הגבלה',
                    style: TextStyle(color: Color(0xFFA8A090), fontSize: 12)),
                Text('✓ הזמנת עורך דין חרום (₪50 נוסף)',
                    style: TextStyle(color: Color(0xFFA8A090), fontSize: 12)),
              ]),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ],
          ],
        ),
        actions: _orderId == null
            ? [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('התנתק', style: TextStyle(color: Color(0xFFEF4444))),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009CDE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: _loading ? null : _openPayPal,
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.paypal_rounded, size: 18),
                  label: Text(_loading ? 'פותח...' : 'שלם עם PayPal'),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('התנתק', style: TextStyle(color: Color(0xFFEF4444))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: _loading ? null : _confirmPayment,
                  child: _loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('שילמתי ✓', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
      ),
    );
  }
}

