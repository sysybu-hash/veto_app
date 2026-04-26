// ============================================================
//  VetoScreen.dart — Legal Shield Wizard Interface
//  Attorney Shield-inspired: scenarios, rights, WhatsApp/Telegram,
//  admin evidence browser, dual-tab (Wizard + AI Chat)
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import '../core/theme/veto_glass_system.dart';
import '../core/theme/veto_theme.dart';
import '../widgets/app_language_menu.dart';
import '../widgets/accessibility_toolbar.dart';
import '../widgets/dispatch_sheets.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/ai_service.dart';
import '../services/payment_service.dart';
import '../services/admin_service.dart';
import 'admin/admin_i18n.dart';
import 'evidence_screen.dart';

part 'veto/veto_screen_models.dart';

// ── VetoScreen ────────────────────────────────────────────
class VetoScreen extends StatefulWidget {
  const VetoScreen({super.key});
  @override
  State<VetoScreen> createState() => _VetoScreenState();
}

class _VetoScreenState extends State<VetoScreen> {
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

  @override
  void initState() {
    super.initState();
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
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _checkSubscription();
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
      await browser_bridge.flowsSetUser(
        userId: uid,
        role: role,
        lang: lang,
      );
    } catch (_) {}
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
        return VetoPalette.success;
      case 'cancelled':
        return VetoPalette.textMuted;
      case 'failed':
        return VetoPalette.emergency;
      case 'accepted':
        return VetoPalette.success;
      case 'in_progress':
      case 'pending':
        return VetoPalette.warning;
      case 'documentation':
        return VetoPalette.primary;
      case 'dispatching':
      case 'active':
        return VetoPalette.emergency;
      default:
        return VetoPalette.textMuted;
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
          backgroundColor: VetoGlassTokens.sheetPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: VetoGlassTokens.glassBorder),
          ),
          title: Text(
            AdminStrings.t(_langKey, 'changeStatus'),
            style: const TextStyle(color: VetoGlassTokens.textPrimary),
          ),
          content: StatefulBuilder(
            builder: (_, ss) => DropdownButton<String>(
              isExpanded: true,
              value: selected,
              dropdownColor: VetoGlassTokens.menuPanel,
              style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 14),
              underline: Container(height: 1, color: VetoGlassTokens.glassBorder),
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
          backgroundColor: VetoGlassTokens.sheetPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: VetoGlassTokens.glassBorder),
          ),
          title: Text(title, style: const TextStyle(color: VetoGlassTokens.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasEvidence)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'clear'),
                  icon: const Icon(Icons.layers_clear_outlined, color: VetoPalette.primary),
                  label: Text(clearLabel, style: const TextStyle(color: VetoGlassTokens.textPrimary)),
                ),
              if (hasEvidence) const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency),
                onPressed: () => Navigator.pop(ctx, 'delete'),
                icon: const Icon(Icons.delete_outline, color: VetoGlassTokens.textPrimary),
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
          backgroundColor: VetoGlassTokens.sheetPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: VetoGlassTokens.glassBorder),
          ),
          title: Text(
            AdminStrings.t(_langKey, 'deleteEvent'),
            style: const TextStyle(color: VetoGlassTokens.textPrimary),
          ),
          content: Text(
            AdminStrings.t(_langKey, 'deleteEventConfirm'),
            style: const TextStyle(color: VetoGlassTokens.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AdminStrings.t(_langKey, 'cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency),
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
        backgroundColor: VetoPalette.emergency,
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
      _safeJs('vetoGeminiLive', 'start', [_langKey, _token, AppConfig.baseUrl]);
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
        if (uRecover.isNotEmpty) {
          unawaited(_ingestGeminiLiveTurn(uRecover, '', nativeAudio: false));
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
        'callType': data['callType']?.toString() ?? 'audio',
        'peerName': data['peerName']?.toString() ??
            (_langKey == 'he' ? 'עורך דין' : 'Lawyer'),
        'role': socketRole,
        'eventId': data['eventId']?.toString() ?? roomId,
        'language': _langKey,
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
        backgroundColor: VetoPalette.warning,
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
      SnackBar(content: Text(message), backgroundColor: VetoPalette.emergency),
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
            backgroundColor: VetoPalette.emergency,
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
          backgroundColor: VetoPalette.emergency,
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
      backgroundColor: VetoPalette.success,
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
    final bool isAdmin = _role == 'admin' || _phone.contains('525640021') || _phone.contains('506400030');
    final bool isRtl = _langKey == 'he';
    // Tab indices: 0=home, 1=chat, 2=files, 3=profile
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoGlassTokens.bgBase,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(isAdmin),
        body: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: VetoFluidBackgroundPainter())),
            SafeArea(
              child: _tab == 0
                  ? _buildWizardTab(isAdmin, isRtl)
                  : _tab == 1
                      ? _buildChatTab(isRtl)
                      : _tab == 2
                          ? _buildFilesTab(isRtl)
                          : _buildProfileTab(isRtl),
            ),
          ],
        ),
        bottomNavigationBar: _buildNavBar(isRtl),
      ),
    );
  }

  // ── AppBar: accessibility+flag left | centered title | hamburger right ──
  PreferredSizeWidget _buildAppBar(bool isAdmin) {
    return AppBar(
      backgroundColor: VetoGlassTokens.glassFill,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      toolbarHeight: 56,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: VetoGlassTokens.glassFill,
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
            ),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: VetoGlassTokens.textPrimary, size: 24),
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
          const Icon(Icons.shield_rounded, color: VetoGlassTokens.neonCyan, size: 20),
          const SizedBox(width: 8),
          Text(
            'VETO — הגנה משפטית',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: VetoGlassTokens.textPrimary,
              letterSpacing: 0.5,
              shadows: [Shadow(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.35), blurRadius: 10)],
            ),
          ),
          if (_isDispatching) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B3B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFF3B3B).withValues(alpha: 0.3)),
              ),
              child: const Text('LIVE',
                  style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 9,
                      fontWeight: FontWeight.w800, letterSpacing: 1.5)),
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
          color: VetoGlassTokens.textMuted,
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
            color: VetoGlassTokens.textPrimary,
            onPressed: () => _showHamburgerMenu(ctx, isAdmin),
            tooltip: _langKey == 'he' ? 'תפריט' : _langKey == 'ru' ? 'Меню' : 'Menu',
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
      ),
    );
  }

  void _showHamburgerMenu(BuildContext ctx, bool isAdmin) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xE6121824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: _langKey == 'he' ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2))),
              if (isAdmin)
                _menuItem(Icons.admin_panel_settings_outlined,
                    _langKey == 'he' ? 'פאנל ניהול' : 'Admin Panel',
                    VetoGlassTokens.neonCyan,
                    () { Navigator.pop(ctx); Navigator.pushNamed(context, '/admin_settings'); }),
              _menuItem(Icons.home_outlined,
                  _langKey == 'he' ? 'דף הבית' : _langKey == 'ru' ? 'Главная' : 'Home',
                  VetoGlassTokens.neonCyan,
                  () { Navigator.pop(ctx); Navigator.pushNamed(context, '/landing'); }),
              _menuItem(Icons.folder_special_outlined,
                  _langKey == 'he' ? 'כספת קבצים' : _langKey == 'ru' ? 'Хранилище' : 'File Vault',
                  VetoGlassTokens.neonCyan,
                  () { Navigator.pop(ctx); Navigator.pushNamed(context, '/files_vault'); }),
              _menuItem(Icons.map_outlined,
                  _langKey == 'he' ? 'מפה' : _langKey == 'ru' ? 'Карта' : 'Map',
                  VetoGlassTokens.neonCyan,
                  () { Navigator.pop(ctx); Navigator.pushNamed(context, '/maps'); }),
              _menuItem(Icons.settings_outlined,
                  _langKey == 'he' ? 'הגדרות' : _langKey == 'ru' ? 'Настройки' : 'Settings',
                  const Color(0xFF64748B),
                  () { Navigator.pop(ctx); Navigator.pushNamed(context, '/settings'); }),
              _menuItem(Icons.person_outline,
                  _langKey == 'he' ? 'פרופיל' : _langKey == 'ru' ? 'Профиль' : 'Profile',
                  const Color(0xFF64748B),
                  () { Navigator.pop(ctx); Navigator.pushNamed(context, '/profile'); }),
              const Divider(height: 20, color: Color(0xFFE2E8F8)),
              _menuItem(Icons.logout_rounded,
                  _langKey == 'he' ? 'התנתקות' : _langKey == 'ru' ? 'Выход' : 'Log out',
                  const Color(0xFFFF3B3B),
                  () { Navigator.pop(ctx); AuthService().logout(context); }),
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
                color: VetoGlassTokens.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  // ── Bottom Nav: 4 tabs ─────────────────────────────────────
  Widget _buildNavBar(bool isRtl) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        decoration: BoxDecoration(
          color: VetoGlassTokens.glassFillStrong,
          border: Border(top: BorderSide(
              color: Colors.white.withValues(alpha: 0.12), width: 1)),
          boxShadow: [
            BoxShadow(
              color: VetoGlassTokens.neonBlue.withValues(alpha: 0.15),
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
      indicatorColor: VetoGlassTokens.neonCyan.withValues(alpha: 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined, color: VetoGlassTokens.textMuted, size: 24),
          selectedIcon: const Icon(Icons.home_rounded, color: VetoGlassTokens.neonCyan, size: 24),
          label: isRtl ? 'בית' : 'Home',
        ),
        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: VetoGlassTokens.textMuted, size: 24),
          selectedIcon: const Icon(Icons.chat_bubble_rounded, color: VetoGlassTokens.neonCyan, size: 24),
          label: isRtl ? "צ'אט" : 'Chat',
        ),
        NavigationDestination(
          icon: const Icon(Icons.folder_outlined, color: VetoGlassTokens.textMuted, size: 24),
          selectedIcon: const Icon(Icons.folder_rounded, color: VetoGlassTokens.neonCyan, size: 24),
          label: isRtl ? 'קבצים' : 'Files',
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded, color: VetoGlassTokens.textMuted, size: 24),
          selectedIcon: const Icon(Icons.person_rounded, color: VetoGlassTokens.neonCyan, size: 24),
          label: isRtl ? 'פרופיל' : 'Profile',
        ),
      ],
        ),
      ),
    ),
  );

  // ── Files tab placeholder (routes to file vault) ───────────
  Widget _buildFilesTab(bool isRtl) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.folder_special_outlined, size: 64, color: VetoGlassTokens.neonCyan),
      const SizedBox(height: 16),
      Text(
        isRtl ? 'כספת קבצים' : _langKey == 'ru' ? 'Хранилище файлов' : 'File Vault',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: VetoGlassTokens.textPrimary),
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
        style: FilledButton.styleFrom(backgroundColor: VetoGlassTokens.neonCyan),
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
          color: VetoGlassTokens.neonCyan.withValues(alpha: 0.12),
          border: Border.all(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.3), width: 2),
        ),
        child: const Icon(Icons.person_rounded, size: 44, color: VetoGlassTokens.neonCyan),
      ),
      const SizedBox(height: 16),
      Text(
        _phone.isNotEmpty ? _phone : (isRtl ? 'המשתמש שלי' : 'My Profile'),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: VetoGlassTokens.textPrimary),
        textDirection: TextDirection.ltr,
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/profile'),
        icon: const Icon(Icons.manage_accounts_rounded),
        label: Text(isRtl ? 'נהל פרופיל'
            : _langKey == 'ru' ? 'Управлять профилем' : 'Manage Profile'),
        style: FilledButton.styleFrom(backgroundColor: VetoGlassTokens.neonCyan),
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
          final compact = constraints.maxWidth < 600;
          final hPad = compact ? 14.0 : 20.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, compact ? 28 : 44),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? double.infinity : 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _statusBadge(),
                    SizedBox(height: compact ? 14 : 18),
                    _sosButton(compact),
                    SizedBox(height: compact ? 14 : 18),
                    _availableLawyersStrip(isRtl, compact),
                    SizedBox(height: compact ? 14 : 18),
                    _securityBar(),
                    SizedBox(height: compact ? 14 : 18),
                    _secLabel(isRtl
                        ? 'מה קורה עכשיו?'
                        : _langKey == 'ru' ? 'Что происходит?' : "What's happening?"),
                    const SizedBox(height: 8),
                    _buildScenarioSelector(isRtl, compact),
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

  // ── Status badge pill ─────────────────────────────────────
  Widget _statusBadge() => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: VetoGlassTokens.glassFillStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: (_isDispatching ? const Color(0xFFFF3B3B) : VetoGlassTokens.neonCyan)
                .withValues(alpha: 0.45),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (_isDispatching ? const Color(0xFFFF3B3B) : VetoGlassTokens.neonCyan)
                .withValues(alpha: 0.22),
            blurRadius: 18,
          ),
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          Icons.shield_rounded,
          size: 16,
          color: _isDispatching ? const Color(0xFFFF3B3B) : VetoGlassTokens.neonCyan,
        ),
        const SizedBox(width: 8),
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isDispatching ? const Color(0xFFFF3B3B) : const Color(0xFF22C55E),
            boxShadow: [
              BoxShadow(
                color: (_isDispatching ? const Color(0xFFFF3B3B) : const Color(0xFF22C55E))
                    .withValues(alpha: 0.7),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          _isDispatching
              ? (_langKey == 'he' ? 'מחובר | שיגור פעיל'
                  : _langKey == 'ru' ? 'Активно | Диспетчеризация'
                  : 'Connected | Dispatching')
              : (_langKey == 'he' ? 'מחובר | ממתין לאירוע'
                  : _langKey == 'ru' ? 'Подключено | Ожидание'
                  : 'Connected | Standby'),
          style: TextStyle(
            color: _isDispatching ? const Color(0xFFFF3B3B) : VetoGlassTokens.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        if (_phone.isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(_phone,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              textDirection: TextDirection.ltr),
        ],
      ]),
    ),
  );

  // ── SOS Button with concentric rings (Set 5: dark glass stage) ──
  Widget _sosButton(bool compact) {
    final orbSize = compact ? 148.0 : 168.0;
    final ringOuter = orbSize + 36;
    final ringMid = orbSize + 20;
    return Semantics(
      button: true,
      label: _langKey == 'he' ? 'לחץ להפעלת מצוקה ושיגור עורך דין'
          : _langKey == 'ru' ? 'Нажмите для вызова адвоката'
          : 'Tap to dispatch a lawyer',
      child: VetoGlassBlur(
        borderRadius: 32,
        sigma: 20,
        fill: const Color(0x2EFFFFFF),
        borderColor: VetoGlassTokens.neonCyan.withValues(alpha: 0.22),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 20 : 24, horizontal: 12),
          child: Column(
            children: [
              GestureDetector(
                onTap: _isDispatching ? null : _onSosOrbTapped,
                child: SizedBox(
                  width: ringOuter + 12,
                  height: ringOuter + 12,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outermost ring
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
                      // Middle ring
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
                      // Inner ring
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
                      // Core orb
                      Container(
                        width: orbSize,
                        height: orbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _isDispatching
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF4B4B).withValues(alpha: 0.30),
                                    blurRadius: 40,
                                    spreadRadius: 6,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: const Color(0xFFFF4B4B).withValues(alpha: 0.22),
                                    blurRadius: 60,
                                    spreadRadius: 18,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFF4B4B).withValues(alpha: 0.45),
                                    blurRadius: 28,
                                    spreadRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFF4B4B).withValues(alpha: 0.65),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _isDispatching
                                  ? [
                                      const Color(0xFFFF6B6B).withValues(alpha: 0.6),
                                      const Color(0xFFCC2222).withValues(alpha: 0.4),
                                    ]
                                  : const [
                                      Color(0xFFFF7777),
                                      Color(0xFFFF3333),
                                      Color(0xFFBB1111),
                                    ],
                              stops: _isDispatching ? const [0.0, 1.0] : const [0.0, 0.55, 1.0],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: _isDispatching ? 0.2 : 0.38),
                              width: 2.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isDispatching)
                                const SizedBox(
                                  width: 30, height: 30,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              else
                                const Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                    shadows: [Shadow(color: Colors.white54, blurRadius: 14)],
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                _isDispatching
                                    ? (_langKey == 'he' ? 'מחפש...'
                                        : _langKey == 'ru' ? 'Поиск...' : 'Searching...')
                                    : (_langKey == 'he' ? 'עזרה מיידית'
                                        : _langKey == 'ru' ? 'ПОМОЩЬ' : 'EMERGENCY'),
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
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isDispatching
                    ? (_langKey == 'he' ? 'עורך דין בדרך אליך...'
                        : _langKey == 'ru' ? 'Адвокат уже едет...'
                        : 'A lawyer is on the way...')
                    : (_langKey == 'he' ? 'לחץ לקבלת עזרה מידית'
                        : _langKey == 'ru' ? 'Нажмите для немедленной помощи'
                        : 'Tap for immediate help'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: VetoGlassTokens.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Set 5 — glass chips: nearby lawyers (illustrative; live matching happens on SOS).
  Widget _availableLawyersStrip(bool isRtl, bool compact) {
    final title = _langKey == 'he'
        ? 'עורכי דין זמינים בקרבת מקום'
        : _langKey == 'ru'
            ? 'Доступные адвокаты рядом'
            : 'Lawyers available nearby';
    final rows = _langKey == 'he'
        ? <(String, String, bool)>[
            ('עו"ד פלילי', '2.1 ק"מ', true),
            ('עו"ד תעבורה', '3.4 ק"מ', true),
            ('עו"ד אזרחי', '4.8 ק"מ', false),
          ]
        : _langKey == 'ru'
            ? <(String, String, bool)>[
                ('Уголовный', '2.1 км', true),
                ('Дорожный', '3.4 км', true),
                ('Гражданский', '4.8 км', false),
              ]
            : <(String, String, bool)>[
                ('Criminal', '2.1 km', true),
                ('Traffic', '3.4 km', true),
                ('Civil', '4.8 km', false),
              ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: VetoGlassTokens.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: compact ? 86 : 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (spec, dist, on) = rows[i];
              return VetoGlassBlur(
                borderRadius: 16,
                sigma: 16,
                fill: VetoGlassTokens.glassFillStrong,
                borderColor: on
                    ? VetoGlassTokens.neonCyan.withValues(alpha: 0.45)
                    : VetoGlassTokens.glassBorder,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 150),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: on
                                    ? VetoGlassTokens.neonCyan
                                    : VetoGlassTokens.textSubtle,
                                boxShadow: on
                                    ? [
                                        BoxShadow(
                                          color: VetoGlassTokens.neonCyan.withValues(alpha: 0.55),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              on
                                  ? (_langKey == 'he'
                                      ? 'זמין'
                                      : _langKey == 'ru'
                                          ? 'Онлайн'
                                          : 'Online')
                                  : (_langKey == 'he'
                                      ? 'עסוק'
                                      : _langKey == 'ru'
                                          ? 'Занят'
                                          : 'Busy'),
                              style: TextStyle(
                                color: on ? VetoGlassTokens.neonCyan : VetoGlassTokens.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          spec,
                          style: const TextStyle(
                            color: VetoGlassTokens.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dist,
                          style: const TextStyle(
                            color: VetoGlassTokens.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Security level bar card (dark frosted) ────────────────
  Widget _securityBar() => VetoGlassBlur(
        borderRadius: 16,
        sigma: 18,
        fill: VetoGlassTokens.glassFillStrong,
        borderColor: VetoGlassTokens.glassBorderBright,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: VetoGlassTokens.neonCyan.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: VetoGlassTokens.neonCyan.withValues(alpha: 0.32),
                ),
              ),
              child: const Icon(Icons.shield_rounded, color: VetoGlassTokens.neonCyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _langKey == 'he' ? 'רמת אבטחה: גבוהה'
                            : _langKey == 'ru' ? 'Уровень защиты: высокий'
                            : 'Security Level: High',
                        style: const TextStyle(
                          color: VetoGlassTokens.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _isDispatching ? '100%' : '85%',
                        style: const TextStyle(
                          color: VetoGlassTokens.neonCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _isDispatching ? 1.0 : 0.85,
                      minHeight: 6,
                      backgroundColor: const Color(0xFF1E293B),
                      valueColor: const AlwaysStoppedAnimation(VetoGlassTokens.neonCyan),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _secLabel(String txt) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(
              color: VetoGlassTokens.neonCyan,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            txt.toUpperCase(),
            style: const TextStyle(
              color: VetoGlassTokens.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ]),
      );

  // ── Scenario tile (single) ────────────────────────────────
  Widget _scenarioTile(MapEntry<_Scenario, _SD> e, bool compact) {
    final sel = e.key == _scenario;
    final lbl = _langKey == 'ru' ? e.value.ru : _langKey == 'en' ? e.value.en : e.value.he;
    final iconSize = compact ? 26.0 : 30.0;
    final circlePad = compact ? 8.0 : 10.0;
    // Arrest scenario uses red icon per mockup
    final isRed = e.key == _Scenario.arrest;
    final iconColor = sel
        ? VetoGlassTokens.neonCyan
        : isRed
            ? const Color(0xFFFF3B3B)
            : VetoGlassTokens.neonCyan;
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
            color: sel
                ? VetoGlassTokens.neonCyan.withValues(alpha: 0.10)
                : VetoGlassTokens.glassFillStrong,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? VetoGlassTokens.neonCyan.withValues(alpha: 0.7)
                  : VetoGlassTokens.glassBorder,
              width: sel ? 1.5 : 1,
            ),
            boxShadow: sel
                ? [BoxShadow(
                    color: VetoGlassTokens.neonCyan.withValues(alpha: 0.2),
                    blurRadius: 18)]
                : [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(circlePad),
                decoration: BoxDecoration(
                  color: sel
                      ? VetoGlassTokens.neonCyan.withValues(alpha: 0.15)
                      : VetoGlassTokens.glassFill,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: sel
                        ? VetoGlassTokens.neonCyan.withValues(alpha: 0.5)
                        : VetoGlassTokens.glassBorder,
                    width: 1,
                  ),
                ),
                child: Icon(_scenarioIcon(e.key), size: iconSize, color: iconColor),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                lbl,
                style: TextStyle(
                  color: sel ? VetoGlassTokens.neonCyan : VetoGlassTokens.textPrimary,
                  fontSize: 12.5,
                  fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                  height: 1.2,
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

  Widget _buildScenarioSelector(bool isRtl, bool compact) {
    // Show only 3 featured scenarios per mockup: traffic, accident, arrest
    final featured = [_Scenario.traffic, _Scenario.accident, _Scenario.arrest];
    final entries = _sdMap.entries
        .where((e) => featured.contains(e.key))
        .toList();
    return Row(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: SizedBox(
            height: compact ? 100 : 116,
            child: _scenarioTile(entries[i], compact),
          )),
        ],
      ],
    );
  }

  // ── Rights card (dark glass) ─────────────────────────────
  /// Rounded + border: Flutter disallows [BorderDirectional] with different side widths
  /// together with [borderRadius]. Use a uniform [Border.all] and a "start" accent strip in a [Stack].
  Widget _rightsCard() {
    const r = 16.0;
    const accentC = VetoGlassTokens.neonCyan;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: VetoGlassTokens.neonCyan.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Container(
              decoration: BoxDecoration(
                color: VetoGlassTokens.glassFillStrong,
                border: Border.all(
                  color: accentC.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Column(children: [
          InkWell(
            onTap: () => setState(() => _rightsExpanded = !_rightsExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                const Icon(Icons.verified_user_rounded,
                    color: VetoGlassTokens.neonCyan, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _langKey == 'he' ? 'הזכויות שלך — $_sLabel'
                        : _langKey == 'ru' ? 'Ваши права — $_sLabel'
                        : 'Your Rights — $_sLabel',
                    style: const TextStyle(
                      color: VetoGlassTokens.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.25,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _rightsExpanded = !_rightsExpanded),
                  style: TextButton.styleFrom(
                    foregroundColor: VetoGlassTokens.neonCyan,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _langKey == 'he' ? 'קרא עוד'
                        : _langKey == 'ru' ? 'Подробнее' : 'Read more',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _rightsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: VetoGlassTokens.neonCyan,
                  size: 26,
                ),
              ]),
            ),
          ),
          if (_rightsExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: _rights.take(3).map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsetsDirectional.only(top: 7, start: 2, end: 2),
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: VetoGlassTokens.neonCyan,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(r,
                          style: const TextStyle(
                            color: VetoGlassTokens.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ]),
            ),
            Builder(
              builder: (context) {
                final rtl =
                    Directionality.of(context) == TextDirection.rtl;
                return Positioned(
                  left: rtl ? null : 0,
                  right: rtl ? 0 : null,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 2,
                      color: accentC.withValues(alpha: 0.45),
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
        const Icon(Icons.folder_open_rounded, color: VetoPalette.primary, size: 16),
        const SizedBox(width: 6),
        Text(
          isRtl ? 'ראיות וקבצי שרת' : 'Server Evidence Files',
          style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12,
              fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
        const Spacer(),
        IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            color: VetoPalette.textMuted,
            onPressed: _loadAdminFiles),
      ]),
      const SizedBox(height: 8),
      if (_adminFilesLoading)
        const Center(child: Padding(padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: VetoPalette.primary, strokeWidth: 2)))
      else if (_adminFiles.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: VetoGlassTokens.glassFillStrong,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VetoGlassTokens.glassBorder)),
          child: Text(
            isRtl ? 'אין אירועים עם ראיות בשרת' : 'No events with evidence on server',
            style: const TextStyle(color: VetoGlassTokens.textMuted),
            textAlign: TextAlign.center,
          ),
        )
      else
        Container(
          decoration: BoxDecoration(color: VetoGlassTokens.glassFillStrong,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VetoGlassTokens.glassBorder)),
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _adminFiles.length > 25 ? 25 : _adminFiles.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: VetoGlassTokens.glassBorder),
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
                        style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (eid != null) ...[
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        tooltip: AdminStrings.t(_langKey, 'edit'),
                        icon: const Icon(Icons.edit_outlined, size: 18, color: VetoPalette.primary),
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
                        icon: const Icon(Icons.cleaning_services_outlined, size: 18, color: VetoPalette.textMuted),
                        onPressed: () => _adminCleanEmergencyEvent(ctx, ev, isRtl),
                      ),
                    ],
                    Text(dateStr,
                        style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11)),
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
                              color: VetoPalette.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: VetoPalette.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                  tp == 'photo' ? Icons.image_outlined
                                      : tp == 'video' ? Icons.videocam_outlined
                                      : Icons.audio_file_outlined,
                                  size: 12, color: VetoPalette.primary),
                              const SizedBox(width: 4),
                              Text(tp,
                                  style: const TextStyle(
                                      color: VetoPalette.primary, fontSize: 10)),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else
                    Text(
                      isRtl ? 'אין ראיות מצורפות' : 'No evidence attached',
                      style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11),
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
        color: VetoPalette.emergency.withValues(alpha: 0.08),
        child: Row(children: [
          const Icon(Icons.broadcast_on_personal_rounded,
              color: VetoPalette.emergency, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
            _langKey == 'he' ? '🚨 בתהליך שיגור — מחפש עורך דין זמין...'
                : _langKey == 'ru' ? '🚨 Диспетчеризация — ищем адвоката...'
                : '🚨 Dispatching — searching for a lawyer...',
            style: const TextStyle(
              color: VetoPalette.emergency, fontSize: 12, fontWeight: FontWeight.w700),
          )),
          if (_activeEventId != null)
            TextButton(
              onPressed: _resetSession,
              style: TextButton.styleFrom(
                  foregroundColor: VetoPalette.textMuted, padding: EdgeInsets.zero),
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
                color: VetoPalette.emergency.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VetoPalette.emergency.withValues(alpha: 0.25)),
              ),
              child: Text(msg.text,
                  style: const TextStyle(
                      color: VetoPalette.emergency,
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
                    ? VetoPalette.primary.withValues(alpha: 0.10)
                    : VetoGlassTokens.glassFillStrong,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                    color: isUser
                        ? VetoPalette.primary.withValues(alpha: 0.30)
                        : VetoGlassTokens.glassBorder,
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(msg.text,
                  style: TextStyle(
                      color: isUser ? VetoPalette.primary : VetoGlassTokens.textPrimary,
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: VetoGlassTokens.blurSigma, sigmaY: VetoGlassTokens.blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: VetoGlassTokens.glassFillStrong,
            border: Border(top: BorderSide(color: VetoGlassTokens.glassBorder.withValues(alpha: 0.9))),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, -6)),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _chatInput(isRtl),
            _chatActBar(),
            const SizedBox(height: 4),
          ]),
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
          color: VetoGlassTokens.glassFillStrong,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
          border: Border.all(color: VetoGlassTokens.glassBorder, width: 1.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: 48,
            child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(4),
                backgroundColor: VetoGlassTokens.glassBorder,
                valueColor: const AlwaysStoppedAnimation(VetoPalette.success))),
        const SizedBox(width: 10),
        Text(_l.processing,
            style: const TextStyle(color: VetoGlassTokens.textMuted,
                fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    ),
  );

  Widget _chatInput(bool isRtl) {
    const sideSlot = 96.0;
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
                      color: _isListening ? const Color(0xFFFF3B3B) : VetoGlassTokens.glassFillStrong,
                      border: Border.all(
                        color: _isListening ? const Color(0xFFFF3B3B).withValues(alpha: 0.7) : VetoGlassTokens.glassBorder,
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
                                color: VetoGlassTokens.neonBlue.withValues(alpha: 0.12),
                                blurRadius: 16,
                              ),
                            ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : VetoGlassTokens.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
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
                      color: VetoGlassTokens.glassFillStrong,
                      border: Border.all(color: VetoGlassTokens.glassBorder),
                    ),
                    child: const Icon(Icons.content_paste,
                        color: VetoGlassTokens.textPrimary, size: 22),
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
              style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isDispatching ? _l.dispatching : _l.hint,
                hintStyle: const TextStyle(color: VetoGlassTokens.textMuted),
                filled: true,
                fillColor: VetoGlassTokens.glassFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: VetoGlassTokens.glassBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: VetoGlassTokens.glassBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.85), width: 1.2)),
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
                    gradient: (_isLoading || _isDispatching) ? null : VetoGlassTokens.neonButton,
                    color: (_isLoading || _isDispatching)
                        ? VetoGlassTokens.glassFill
                        : null,
                    boxShadow: [
                      if (!(_isLoading || _isDispatching))
                        BoxShadow(
                          color: VetoGlassTokens.neonCyan.withValues(alpha: 0.25),
                          blurRadius: 18,
                        ),
                    ],
                  ),
                  child: const Icon(Icons.send, color: VetoGlassTokens.onNeon, size: 22),
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
              style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: _chatActBtn(
                      Icons.camera_alt_outlined,
                      VetoPalette.accentSky,
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
                      VetoPalette.accentSky,
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
                      VetoPalette.success,
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
        : VetoPalette.accentSky;
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
                  color: VetoGlassTokens.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  color: VetoGlassTokens.textMuted,
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: VetoGlassTokens.textPrimary),
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: const TextStyle(color: VetoGlassTokens.textMuted),
                hintText: hintText,
                hintStyle: const TextStyle(color: VetoGlassTokens.textSubtle),
                filled: true,
                fillColor: const Color(0xFF0F1A24),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: VetoGlassTokens.glassBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: VetoGlassTokens.glassBorder)),
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
                    foregroundColor: VetoGlassTokens.onNeon,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: _busy
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: VetoGlassTokens.onNeon))
                    : const Icon(Icons.open_in_new, size: 18, color: VetoGlassTokens.onNeon),
                label: Text(isRtl ? 'פתח' : 'Open',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: VetoGlassTokens.onNeon)),
              ),
            ),
            if (widget.type != 'video') ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => setState(() => _ctrl.text = '+972'),
                child: Text(isRtl ? '▼ ישראל +972...' : '▼ Israel +972...',
                    style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 12)),
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
        Icon(Icons.hourglass_top_rounded, color: VetoPalette.accentSky, size: 22),
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
          Icon(Icons.lock_outline, color: VetoPalette.accentSky),
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
                border: Border.all(color: VetoPalette.accentSky.withValues(alpha: 0.4)),
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

