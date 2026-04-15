// ============================================================
//  VetoScreen.dart — Legal Shield Wizard Interface
//  Attorney Shield-inspired: scenarios, rights, WhatsApp/Telegram,
//  admin evidence browser, dual-tab (Wizard + AI Chat)
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import '../core/theme/veto_theme.dart';
import '../widgets/app_language_menu.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/ai_service.dart';
import '../services/payment_service.dart';
import '../services/admin_service.dart';
import 'admin/admin_i18n.dart';
import 'evidence_screen.dart';

String? _mongoEventId(dynamic ev) {
  final id = ev['_id'];
  if (id == null) return null;
  if (id is String) return id.isEmpty ? null : id;
  if (id is Map) {
    final o = id[r'$oid'] ?? id['oid'];
    if (o != null) return o.toString();
  }
  final t = id.toString();
  return (t.isEmpty || t == 'null') ? null : t;
}

// ── Scenarios ─────────────────────────────────────────────
enum _Scenario { traffic, interrogation, arrest, accident, other }

IconData _scenarioIcon(_Scenario s) {
  switch (s) {
    case _Scenario.traffic:
      return Icons.directions_car_filled_rounded;
    case _Scenario.interrogation:
      return Icons.local_police_rounded;
    case _Scenario.arrest:
      return Icons.gavel_rounded;
    case _Scenario.accident:
      return Icons.medical_services_rounded;
    case _Scenario.other:
      return Icons.balance;
  }
}

class _SD {
  final String emoji, he, ru, en;
  final List<String> rHe, rRu, rEn;
  const _SD({required this.emoji, required this.he, required this.ru,
      required this.en, required this.rHe, required this.rRu, required this.rEn});
}

const Map<_Scenario, _SD> _sdMap = {
  _Scenario.traffic: _SD(
    emoji: '\u{1F697}',
    he: 'עצירת תנועה',
    ru: 'Остановка авто',
    en: 'Traffic Stop',
    rHe: [
      'הצג תעודת זהות ורישיון נהיגה בלבד',
      'אינך חייב להסכים לחיפוש ברכב',
      'שמור על שתיקה מעבר לנתוני זיהוי',
      'צלם את רכב המשטרה ולוחית הרישוי',
      'בקש שם ומספר עטרה של השוטר',
    ],
    rRu: [
      'Предъявите только документы',
      'Не обязаны соглашаться на обыск авто',
      'Храните молчание сверх идентификации',
      'Сфотографируйте полицейскую машину',
      'Запросите имя и жетон офицера',
    ],
    rEn: [
      'Present ID and driving license only',
      'Not required to consent to vehicle search',
      'Remain silent beyond identification data',
      'Photograph the police vehicle and its plate',
      'Request the officer name and badge number',
    ],
  ),
  _Scenario.interrogation: _SD(
    emoji: '\u{1F46E}',
    he: 'חקירת משטרה',
    ru: 'Допрос',
    en: 'Police Questioning',
    rHe: [
      'יש לך זכות חוקתית לשתוק — אל תענה על שאלות',
      'דרוש עורך דין לפני תחילת כל חקירה',
      'כל דבר שתאמר יכול לשמש נגדך בבית משפט',
      'אינך חייב לחתום על מסמכים ללא ייעוץ משפטי',
      'הצהר: "שומר אני על זכות השתיקה"',
    ],
    rRu: [
      'Конституционное право хранить молчание',
      'Требуйте адвоката до начала допроса',
      'Всё сказанное может быть использовано против вас',
      'Не подписывайте документы без адвоката',
      'Заявите: "Я пользуюсь правом на молчание"',
    ],
    rEn: [
      'Constitutional right to remain silent — do not answer',
      'Demand a lawyer before any interrogation begins',
      'Anything you say can be used against you in court',
      'Do not sign documents without legal counsel',
      'State clearly: "I am exercising my right to silence"',
    ],
  ),
  _Scenario.arrest: _SD(
    emoji: '\u26D3',
    he: 'מעצר',
    ru: 'Арест',
    en: 'Arrest',
    rHe: [
      'יש לך זכות לעורך דין מיידי — דרוש זאת בקול',
      'יש לך זכות להודיע לבן משפחה על עצרתך',
      'שמור שתיקה מוחלטת לפני הגעת עורך הדין',
      'המשטרה חייבת לציין מהי עילת המעצר',
      'בקש עותק מצו המעצר',
    ],
    rRu: [
      'Право на немедленного адвоката',
      'Право сообщить родственнику об аресте',
      'Полное молчание до прибытия адвоката',
      'Полиция обязана назвать причину ареста',
      'Требуйте копию ордера на арест',
    ],
    rEn: [
      'Right to an immediate attorney — demand it aloud',
      'Right to notify a family member of your arrest',
      'Complete silence until your lawyer arrives',
      'Police must state the reason for your arrest',
      'Request a copy of the arrest warrant',
    ],
  ),
  _Scenario.accident: _SD(
    emoji: '\u{1F691}',
    he: 'תאונה',
    ru: 'ДТП',
    en: 'Accident',
    rHe: [
      'תעד נזקים לרכב מכל זווית — מיידית',
      'אסוף שמות ופרטי קשר של עדים',
      'אל תודה באחריות — לא לפני שדיברת עם עורך דין',
      'צלם לוחיות רישוי של כל הרכבים המעורבים',
      'הייוועץ עם עורך דין לפני שמוסר מידע לביטוח',
    ],
    rRu: [
      'Сфотографируйте все повреждения немедленно',
      'Соберите данные свидетелей',
      'Не признавайте вину без адвоката',
      'Сфотографируйте все номерные знаки',
      'Проконсультируйтесь с адвокатом перед страховой',
    ],
    rEn: [
      'Document all vehicle damage from every angle immediately',
      'Collect witness names and contact information',
      'Do not admit fault before consulting a lawyer',
      'Photograph all license plates involved',
      'Consult a lawyer before speaking to insurance',
    ],
  ),
  _Scenario.other: _SD(
    emoji: '\u2696',
    he: 'אחר',
    ru: 'Другое',
    en: 'Other',
    rHe: [
      'יש לך זכות לייצוג משפטי בכל הליך',
      'שמור על זכות השתיקה תמיד',
      'תעד הכל: צלם, הקלט, כתוב',
      'אל תחתום על שום מסמך ללא עורך דין',
      'VETO ישגר עורך דין לעמדתך בהקדם',
    ],
    rRu: [
      'Право на юридическое представительство',
      'Всегда пользуйтесь правом на молчание',
      'Документируйте всё: фото, аудио, запись',
      'Не подписывайте ничего без адвоката',
      'VETO направит адвоката к вам',
    ],
    rEn: [
      'Right to legal representation in any proceeding',
      'Always exercise your right to remain silent',
      'Document everything: photos, audio, written notes',
      'Do not sign anything without a lawyer present',
      'VETO will dispatch a lawyer to your location',
    ],
  ),
};

// ── Language labels ───────────────────────────────────────
class _LL {
  final String label, code, greeting, hint, processing, dispatching, protected, broadcasting;
  const _LL({required this.label, required this.code, required this.greeting,
      required this.hint, required this.processing, required this.dispatching,
      required this.protected, required this.broadcasting});
}

const Map<String, _LL> _langs = {
  'he': _LL(
    label: 'עברית', code: 'he-IL',
    greeting: 'שלום! אני העוזר המשפטי של VETO.\nתאר את הבעיה המשפטית שלך ואמצא עבורך עורך דין זמין.',
    hint: 'תאר את הבעיה...',
    processing: 'מעבד...',
    dispatching: 'בתהליך שיגור...',
    protected: 'מוגן',
    broadcasting: 'שידור פעיל',
  ),
  'ru': _LL(
    label: 'Русский', code: 'ru-RU',
    greeting: 'Здравствуйте! Я юридический помощник VETO.\nОпишите вашу проблему — я найду адвоката.',
    hint: 'Опишите проблему...',
    processing: 'Обработка...',
    dispatching: 'Отправка...',
    protected: 'Защищён',
    broadcasting: 'Трансляция',
  ),
  'en': _LL(
    label: 'English', code: 'en-US',
    greeting: "Hello! I'm the VETO legal assistant.\nDescribe your legal issue and I'll find you an available lawyer.",
    hint: 'Describe your issue...',
    processing: 'Processing...',
    dispatching: 'Dispatching...',
    protected: 'Protected',
    broadcasting: 'Live broadcast',
  ),
};

// ── Chat message ──────────────────────────────────────────
class _Msg {
  final String text;
  final bool isUser, isSystem;
  _Msg({required this.text, required this.isUser, this.isSystem = false});
}

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
  String _pendingCallType = 'audio';
  String? _activeEventId;
  String? _token;
  StreamSubscription<Map<String, dynamic>>? _emergencyCreatedSub;
  StreamSubscription<Map<String, dynamic>>? _lawyerFoundSub;
  StreamSubscription<Map<String, dynamic>>? _noLawyersSub;
  StreamSubscription<Map<String, dynamic>>? _vetoDispatchedSub;
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
    _emergencyCreatedSub = SocketService().onEmergencyCreated.listen((data) {
      final id = data['eventId'] as String?;
      if (id != null && mounted) setState(() => _activeEventId = id);
    });
    _lawyerFoundSub = SocketService().onLawyerFound.listen(_handleLawyerFound);
    _noLawyersSub =
        SocketService().onNoLawyersAvailable.listen(_handleNoLawyersAvailable);
    _vetoDispatchedSub =
        SocketService().onVetoDispatched.listen(_handleVetoDispatched);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _checkSubscription();
      });
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
    _safeJs('vetoSTT', 'stop', []);
    _safeJs('vetoTTS', 'stop', []);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _emergencyCreatedSub?.cancel();
    _lawyerFoundSub?.cancel();
    _noLawyersSub?.cancel();
    _vetoDispatchedSub?.cancel();
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
          backgroundColor: VetoPalette.surface,
          title: Text(
            AdminStrings.t(_langKey, 'changeStatus'),
            style: const TextStyle(color: VetoPalette.text),
          ),
          content: StatefulBuilder(
            builder: (_, ss) => DropdownButton<String>(
              isExpanded: true,
              value: selected,
              dropdownColor: VetoPalette.surface,
              style: const TextStyle(color: VetoPalette.text, fontSize: 14),
              underline: Container(height: 1, color: VetoPalette.border),
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
          backgroundColor: VetoPalette.surface,
          title: Text(title, style: const TextStyle(color: VetoPalette.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasEvidence)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'clear'),
                  icon: const Icon(Icons.layers_clear_outlined, color: VetoPalette.primary),
                  label: Text(clearLabel, style: const TextStyle(color: VetoPalette.text)),
                ),
              if (hasEvidence) const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency),
                onPressed: () => Navigator.pop(ctx, 'delete'),
                icon: const Icon(Icons.delete_outline, color: Colors.white),
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
          backgroundColor: VetoPalette.surface,
          title: Text(
            AdminStrings.t(_langKey, 'deleteEvent'),
            style: const TextStyle(color: VetoPalette.text),
          ),
          content: Text(
            AdminStrings.t(_langKey, 'deleteEventConfirm'),
            style: const TextStyle(color: VetoPalette.textMuted),
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
      _dispatch(spec, lawyerName);
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
    _dispatch(spec, lawyerName);
  }

  // ── Dispatch ─────────────────────────────────────────────
  Future<void> _dispatchSOS() async {
    if (_isDispatching) return;
    HapticFeedback.heavyImpact();
    setState(() => _isDispatching = true);
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
      specialization: _s.he,
      callType: _pendingCallType,
    );
    final msg = _langKey == 'ru' ? '🚨 SOS отправлен! Поиск адвоката...'
        : _langKey == 'en' ? '🚨 SOS sent! Searching for a lawyer...'
        : '🚨 SOS נשלח! מחפש עורך דין...';
    if (mounted) {
      setState(() { _messages.add(_Msg(text: msg, isUser: false, isSystem: true)); _tab = 1; });
      _speak(msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: VetoPalette.emergency,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  Future<void> _dispatch(String? spec, String? lawyerName) async {
    if (_isDispatching) return;
    setState(() => _isDispatching = true);
    HapticFeedback.heavyImpact();
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
      callType: _pendingCallType,
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
    final ok = browser_bridge.supportsBrowserMethod('vetoSTT', 'isSupported', const []);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הדפדפן שלך לא תומך בזיהוי קול')));
      return;
    }
    setState(() => _isListening = true);
    _safeJs('vetoSTT', 'start', [_l.code]);
  }
  void _stopListening() { setState(() => _isListening = false); _safeJs('vetoSTT', 'stop', []); }
  void _onSTTResult(String r) {
    if (!mounted) return;
    setState(() => _isListening = false);
    if (r.startsWith('OK:')) _send(r.substring(3));
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

  // ── Contact / Tools ───────────────────────────────────────
  void _openContact(String type) {
    _pendingCallType = type == 'video' ? 'video' : 'audio';
    _dispatchSOS();
  }

  void _handleLawyerFound(Map<String, dynamic> data) {
    final roomId = data['roomId']?.toString();
    if (!mounted || roomId == null || roomId.isEmpty) return;

    setState(() {
      _isDispatching = false;
      _activeEventId = data['eventId']?.toString() ?? roomId;
    });

    Navigator.of(context).pushNamed(
      '/call',
      arguments: {
        'roomId': roomId,
        'callType': data['callType']?.toString() ?? _pendingCallType,
        'peerName': data['lawyerName']?.toString() ??
            (_langKey == 'he' ? 'עורך דין' : 'Lawyer'),
        'role': 'user',
        'eventId': data['eventId']?.toString() ?? roomId,
        'language': _langKey,
      },
    );
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
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: _buildAppBar(isAdmin),
        body: SafeArea(
          child: IndexedStack(
            index: _tab,
            children: [
              _buildWizardTab(isAdmin, isRtl),
              _buildChatTab(isRtl),
            ],
          ),
        ),
        bottomNavigationBar: _buildNavBar(isRtl),
      ),
    );
  }

  // ── AppBar (balanced: langs | brand | tools) ──────────────
  PreferredSizeWidget _buildAppBar(bool isAdmin) => AppBar(
    backgroundColor: VetoColors.surface,
    surfaceTintColor: const Color(0x0D0D9488),
    automaticallyImplyLeading: false,
    elevation: 0,
    scrolledUnderElevation: 1,
    shadowColor: const Color(0x140D9488),
    shape: const Border(
      bottom: BorderSide(color: Color(0xFF0D9488), width: 2),
    ),
    centerTitle: false,
    titleSpacing: 0,
    toolbarHeight: 56,
    // Must stay visible on light AppBar surface (white icons disappear on web).
    iconTheme: const IconThemeData(color: VetoColors.accentDark, size: 24),
    actionsIconTheme: const IconThemeData(color: VetoColors.accentDark, size: 24),
    title: Row(
      children: [
        Expanded(
          flex: 1,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AppLanguageMenu(
                compact: true,
                tooltip: _langKey == 'he'
                    ? 'שפה'
                    : _langKey == 'ru'
                        ? 'Язык'
                        : 'Language',
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
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: VetoColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: VetoColors.accent.withValues(alpha: 0.3), width: 1),
                  ),
                  child: const Icon(Icons.shield_rounded, color: VetoColors.accent, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'VETO',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    fontSize: 17,
                    color: VetoColors.accent,
                    shadows: [Shadow(color: VetoColors.accent.withValues(alpha: 0.3), blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: 4),
                if (_isDispatching)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VetoPalette.emergency.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: VetoPalette.emergency.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: VetoPalette.emergency,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdmin)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 24),
                      color: VetoColors.accent,
                      onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
                      tooltip: 'פאנל ניהול',
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: const Icon(Icons.home_outlined, size: 24),
                    color: VetoColors.accentDark,
                    onPressed: () => Navigator.pushNamed(context, '/landing'),
                    tooltip: _langKey == 'he' ? 'דף הבית' : _langKey == 'ru' ? 'Главная' : 'Home',
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: const Icon(Icons.folder_special_outlined, size: 24),
                    color: VetoColors.accentDark,
                    onPressed: () => Navigator.pushNamed(context, '/files_vault'),
                    tooltip: _langKey == 'he' ? 'כספת קבצים' : _langKey == 'ru' ? 'Хранилище' : 'File Vault',
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: const Icon(Icons.map_outlined, size: 24),
                    color: VetoColors.accentDark,
                    onPressed: () => Navigator.pushNamed(context, '/maps'),
                    tooltip: _langKey == 'he'
                        ? 'מפת Google'
                        : _langKey == 'ru'
                            ? 'Google Карты'
                            : 'Google Maps',
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: const Icon(Icons.settings_outlined, size: 24),
                    color: VetoColors.accentDark,
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    tooltip: _langKey == 'he' ? 'הגדרות' : _langKey == 'ru' ? 'Настройки' : 'Settings',
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: const Icon(Icons.person_outline, size: 24),
                    color: VetoColors.accentDark,
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                    tooltip: _langKey == 'he' ? 'פרופיל' : _langKey == 'ru' ? 'Профиль' : 'Profile',
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: const Icon(Icons.logout_rounded, size: 24),
                    color: VetoColors.silver,
                    tooltip: _langKey == 'he' ? 'התנתקות' : _langKey == 'ru' ? 'Выход' : 'Log out',
                    onPressed: () => AuthService().logout(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: VetoColors.accent.withValues(alpha: 0.2)),
    ),
  );

  // ── Bottom Nav ────────────────────────────────────────────
  Widget _buildNavBar(bool isRtl) => Container(
    decoration: BoxDecoration(
      color: VetoColors.surface,
      border: Border(top: BorderSide(color: VetoColors.accent.withValues(alpha:0.25), width: 1)),
    ),
    child: NavigationBar(
      height: 72,
      selectedIndex: _tab,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: VetoColors.accent.withValues(alpha: 0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.shield_outlined, color: VetoColors.accentDark, size: 26),
          selectedIcon: const Icon(Icons.shield, color: VetoColors.accent, size: 26),
          label: isRtl ? 'VETO מגן' : 'VETO Shield',
        ),
        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: VetoColors.accentDark, size: 26),
          selectedIcon: const Icon(Icons.chat_bubble_rounded, color: VetoColors.accent, size: 26),
          label: isRtl ? 'AI עוזר' : 'AI Assistant',
        ),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════
  // WIZARD TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildWizardTab(bool isAdmin, bool isRtl) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final hPad = compact ? 12.0 : 18.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 10, hPad, compact ? 28 : 44),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? double.infinity : 720,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _statusBadge(),
                    SizedBox(height: compact ? 12 : 14),
                    _sosButton(compact),
                    SizedBox(height: compact ? 16 : 20),
                    _secLabel(isRtl
                        ? 'מה קורה עכשיו?'
                        : _langKey == 'ru'
                            ? 'Что происходит?'
                            : "What's happening?"),
                    const SizedBox(height: 8),
                    _buildScenarioSelector(isRtl, compact),
                    SizedBox(height: compact ? 12 : 14),
                    _rightsCard(),
                    SizedBox(height: compact ? 14 : 16),
                    _secLabel(isRtl
                        ? 'צור קשר מיידי'
                        : _langKey == 'ru'
                            ? 'Быстрая связь'
                            : 'Quick Contact'),
                    const SizedBox(height: 8),
                    _liveContactGrid(isRtl, compact),
                    SizedBox(height: compact ? 14 : 16),
                    _secLabel(isRtl
                        ? 'כלים מהירים'
                        : _langKey == 'ru'
                            ? 'Инструменты'
                            : 'Quick Tools'),
                    const SizedBox(height: 8),
                    _toolsGrid(isRtl, compact),
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

  Widget _statusBadge() => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (_isDispatching ? VetoPalette.emergency : VetoPalette.success)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: (_isDispatching ? VetoPalette.emergency : VetoPalette.success)
                .withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isDispatching ? VetoPalette.emergency : VetoPalette.success)),
        const SizedBox(width: 8),
        Text(
          _isDispatching ? _l.broadcasting : _l.protected,
          style: TextStyle(
              color: _isDispatching ? VetoPalette.emergency : VetoPalette.success,
              fontWeight: FontWeight.w800,
              fontSize: 14),
        ),
        if (_phone.isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(_phone,
              style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11),
              textDirection: TextDirection.ltr),
        ],
      ]),
    ),
  );

  Widget _sosButton(bool compact) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isDispatching ? null : _dispatchSOS,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDispatching
                    ? [
                        VetoPalette.emergency.withValues(alpha: 0.35),
                        VetoPalette.emergency.withValues(alpha: 0.15),
                      ]
                    : [VetoPalette.emergency, const Color(0xFFB91C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: _isDispatching
                  ? []
                  : [
                      BoxShadow(
                        color: VetoPalette.emergency.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: compact ? 18 : 22,
                horizontal: compact ? 16 : 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.crisis_alert_rounded,
                    color: Colors.white,
                    size: compact ? 34 : 38,
                  ),
                  SizedBox(width: compact ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDispatching
                              ? (_langKey == 'he'
                                  ? 'שיגור פעיל — מחפש עורך דין'
                                  : _langKey == 'ru'
                                      ? 'Активный поиск адвоката...'
                                      : 'Active — finding your lawyer...')
                              : (_langKey == 'he'
                                  ? 'SOS — שלח עזרה עכשיו'
                                  : _langKey == 'ru'
                                      ? 'SOS — Вызвать адвоката'
                                      : 'SOS — Send Legal Help Now'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 17 : 19,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isDispatching
                              ? (_langKey == 'he'
                                  ? 'עורך דין בדרך אליך...'
                                  : _langKey == 'ru'
                                      ? 'Адвокат уже едет к вам...'
                                      : 'A lawyer is on the way to you...')
                              : (_langKey == 'he'
                                  ? 'לחץ לשגר עורך דין לעמדתך מיידית'
                                  : _langKey == 'ru'
                                      ? 'Нажмите для немедленного вызова адвоката'
                                      : 'Tap to instantly dispatch a lawyer to you'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _secLabel(String txt) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: VetoColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              txt.toUpperCase(),
              style: const TextStyle(
                color: VetoColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
      );

  Widget _scenarioTile(MapEntry<_Scenario, _SD> e, bool compact) {
    final sel = e.key == _scenario;
    final lbl = _langKey == 'ru'
        ? e.value.ru
        : _langKey == 'en'
            ? e.value.en
            : e.value.he;
    final iconSize = compact ? 26.0 : 32.0;
    final circlePad = compact ? 8.0 : 10.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _scenario = e.key;
          _rightsExpanded = true;
        }),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: sel
                ? VetoPalette.primary.withValues(alpha: 0.14)
                : VetoPalette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? VetoPalette.primary : VetoPalette.border,
              width: sel ? 2.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(circlePad),
                decoration: BoxDecoration(
                  color: (sel ? VetoPalette.primary : VetoPalette.textMuted)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _scenarioIcon(e.key),
                  size: iconSize,
                  color: sel ? VetoPalette.primary : VetoPalette.textMuted,
                ),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                lbl,
                style: TextStyle(
                  color: sel ? VetoPalette.primary : VetoPalette.text,
                  fontSize: compact ? 12.5 : 12.5,
                  fontWeight: sel ? FontWeight.w900 : FontWeight.w700,
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
    final entries = _sdMap.entries.toList();
    if (compact) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
        ),
        itemBuilder: (_, i) => _scenarioTile(entries[i], true),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const minTile = 108.0;
        const maxTile = 132.0;
        final n = entries.length;
        final raw = (constraints.maxWidth - spacing * (n - 1)) / n;
        final tileW = raw.clamp(minTile, maxTile);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final e in entries)
                SizedBox(
                  width: tileW,
                  height: 128,
                  child: _scenarioTile(e, false),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _rightsCard() => Container(
        decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: BorderDirectional(
            top: BorderSide(color: VetoPalette.border.withValues(alpha: 0.9)),
            start: const BorderSide(color: VetoPalette.primary, width: 4),
            end: BorderSide(color: VetoPalette.border.withValues(alpha: 0.9)),
            bottom: BorderSide(color: VetoPalette.border.withValues(alpha: 0.9)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _rightsExpanded = !_rightsExpanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: VetoPalette.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _langKey == 'he'
                            ? 'הזכויות שלך — $_sLabel'
                            : _langKey == 'ru'
                                ? 'Ваши права — $_sLabel'
                                : 'Your Rights — $_sLabel',
                        style: const TextStyle(
                          color: VetoPalette.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.25,
                        ),
                      ),
                    ),
                    Icon(
                      _rightsExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: VetoPalette.primary,
                      size: 28,
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
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsetsDirectional.only(
                                    top: 7, start: 2, end: 2),
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: VetoPalette.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  r,
                                  style: const TextStyle(
                                    color: VetoPalette.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
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
      );

  Widget _liveContactGrid(bool isRtl, bool compact) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    clipBehavior: Clip.none,
    crossAxisCount: compact ? 1 : 2,
    // Taller cells on narrow screens so label + subtitle + icons are not clipped.
    childAspectRatio: compact ? 2.05 : 2.05,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    children: [
      _ctCard(
        Icons.phone_in_talk_rounded,
        _langKey == 'he'
            ? 'עורך דין אנושי'
            : _langKey == 'ru'
                ? 'Адвокат עכשיו'
                : 'Human Lawyer',
        _langKey == 'he'
            ? 'חיבור מיידי לנציג אנושי'
            : _langKey == 'ru'
                ? 'Соединение с живым адвокатом'
                : 'Connect with a live representative',
        VetoPalette.primary,
        () => _openContact('audio'),
      ),
      _ctCard(
        Icons.mic_rounded,
        _langKey == 'he'
            ? 'שיחת אודיו'
            : _langKey == 'ru'
                ? 'Аудиозвонок'
                : 'Audio Call',
        _langKey == 'he'
            ? 'שיחה קולית מאובטחת'
            : _langKey == 'ru'
                ? 'Защищённый голосовой звонок'
                : 'Encrypted voice session',
        const Color(0xFF0EA5A4),
        () => _openContact('audio'),
      ),
      _ctCard(
        Icons.videocam_rounded,
        _langKey == 'he'
            ? 'שיחת וידאו'
            : _langKey == 'ru'
                ? 'Видеозвонок'
                : 'Video Call',
        _langKey == 'he'
            ? 'וידאו מוצפן (WebRTC)'
            : _langKey == 'ru'
                ? 'Видео через WebRTC'
                : 'Secure WebRTC video',
        VetoPalette.accentSky,
        () => _openContact('video'),
      ),
      _ctCard(
        Icons.bolt_rounded,
        _langKey == 'he'
            ? 'SOS מהיר'
            : _langKey == 'ru'
                ? 'Быстрый SOS'
                : 'Quick SOS',
        _langKey == 'he'
            ? 'שיגור חירום למערכת'
            : _langKey == 'ru'
                ? 'Экстренный сигнал в систему'
                : 'Emergency signal to VETO',
        VetoPalette.emergency,
        _dispatchSOS,
      ),
    ],
  );

  Widget _ctCard(
    IconData icon,
    String label,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) =>
      Material(
        color: VetoPalette.surface,
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: VetoPalette.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: VetoPalette.text.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 22,
                  color: color.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _toolsGrid(bool isRtl, bool compact) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: compact ? 2 : 4,
    childAspectRatio: compact ? 1.35 : 0.88,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    children: [
      _toolBtn(Icons.camera_alt_outlined,
          _langKey == 'he' ? 'תיעוד\nראיות'
              : _langKey == 'ru' ? 'Запись\nдоказ.'
              : 'Evidence\nRecord',
          VetoPalette.warning, _openCamera),
      _toolBtn(Icons.location_on_outlined,
          _langKey == 'he' ? 'שתף\nמיקום'
              : _langKey == 'ru' ? 'Копировать\nгео'
              : 'Copy\nLocation',
          VetoPalette.success, _shareLocation),
      _toolBtn(Icons.volume_off_rounded,
          _langKey == 'he' ? 'השתק\nקריינות'
              : _langKey == 'ru' ? 'Стоп\nзвук'
              : 'Mute\nVoice',
          VetoPalette.textMuted, _stopSpeaking),
      _toolBtn(Icons.refresh_rounded,
          _langKey == 'he' ? 'חדש\nשיחה'
              : _langKey == 'ru' ? 'Новый\nсеанс'
              : 'New\nSession',
          VetoPalette.info, _resetSession),
    ],
  );

  Widget _toolBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
      Material(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: VetoPalette.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

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
          decoration: BoxDecoration(color: VetoPalette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VetoPalette.border)),
          child: Text(
            isRtl ? 'אין אירועים עם ראיות בשרת' : 'No events with evidence on server',
            style: const TextStyle(color: VetoPalette.textMuted),
            textAlign: TextAlign.center,
          ),
        )
      else
        Container(
          decoration: BoxDecoration(color: VetoPalette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VetoPalette.border)),
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _adminFiles.length > 25 ? 25 : _adminFiles.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: VetoPalette.border),
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
                        style: const TextStyle(color: VetoPalette.text, fontSize: 13, fontWeight: FontWeight.w600),
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
                    : VetoPalette.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                    color: isUser
                        ? VetoPalette.primary.withValues(alpha: 0.30)
                        : VetoPalette.border,
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(msg.text,
                  style: TextStyle(
                      color: isUser ? VetoPalette.primary : VetoPalette.text,
                      fontSize: 14.5,
                      height: 1.55,
                      fontWeight: isUser ? FontWeight.w700 : FontWeight.w600)),
            ),
          );
        },
      ),
    ),
    // ── Input row ────────────────────────────────────────────
    Container(
      decoration: const BoxDecoration(
        color: VetoPalette.surface,
        border: Border(top: BorderSide(color: VetoPalette.border)),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _chatInput(isRtl),
        _chatActBar(),
        const SizedBox(height: 4),
      ]),
    ),
  ]);

  Widget _typingBubble() => Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
          border: Border.all(color: VetoPalette.border, width: 1.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: 48,
            child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(4),
                backgroundColor: VetoPalette.border,
                valueColor: const AlwaysStoppedAnimation(VetoPalette.success))),
        const SizedBox(width: 10),
        Text(_l.processing,
            style: const TextStyle(color: VetoPalette.textMuted,
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
                      color: _isListening ? VetoPalette.emergency : VetoPalette.surface,
                      border: Border.all(
                        color: _isListening ? VetoPalette.emergency : VetoPalette.border,
                      ),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : VetoPalette.textMuted,
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
                      color: VetoPalette.surface,
                      border: Border.all(color: VetoPalette.border),
                    ),
                    child: const Icon(Icons.content_paste,
                        color: VetoPalette.textMuted, size: 22),
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
              style: const TextStyle(color: VetoPalette.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isDispatching ? _l.dispatching : _l.hint,
                hintStyle: const TextStyle(color: VetoPalette.textMuted),
                filled: true,
                fillColor: VetoPalette.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: VetoPalette.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: VetoPalette.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: VetoPalette.success)),
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
                    color: (_isLoading || _isDispatching)
                        ? VetoPalette.border
                        : VetoPalette.success,
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
                  color: VetoPalette.text, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  color: VetoPalette.textMuted,
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: VetoPalette.text),
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: const TextStyle(color: VetoPalette.textMuted),
                hintText: hintText,
                hintStyle: const TextStyle(color: VetoPalette.textSubtle),
                filled: true,
                fillColor: VetoPalette.bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: VetoPalette.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: VetoPalette.border)),
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
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: _busy
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.open_in_new, size: 18),
                label: Text(isRtl ? 'פתח' : 'Open',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            if (widget.type != 'video') ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => setState(() => _ctrl.text = '+972'),
                child: Text(isRtl ? '▼ ישראל +972...' : '▼ Israel +972...',
                    style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
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
      title: Row(children: [
        Icon(Icons.hourglass_top_rounded, color: VetoPalette.accentSky, size: 22),
        const SizedBox(width: 10),
        const Text('אשר את התשלום',
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
        title: Row(children: [
          Icon(Icons.lock_outline, color: VetoPalette.accentSky),
          const SizedBox(width: 10),
          const Text('נדרש מנוי', style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18)),
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
