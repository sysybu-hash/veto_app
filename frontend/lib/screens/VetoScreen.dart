// ============================================================
//  VetoScreen.dart — Legal Shield Wizard Interface
//  Attorney Shield-inspired: scenarios, rights, WhatsApp/Telegram,
//  admin evidence browser, dual-tab (Wizard + AI Chat)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/i18n/app_language.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/ai_service.dart';
import '../services/payment_service.dart';
import '../services/admin_service.dart';
import 'EvidenceScreen.dart';

// ── Scenarios ─────────────────────────────────────────────
enum _Scenario { traffic, interrogation, arrest, accident, other }

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
  String? _activeEventId;
  String? _token;
  StreamSubscription<Map<String, dynamic>>? _emergencyCreatedSub;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSubscription());
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
      // User dismissed — stay on screen with limited access (no redirect to login)
    }
  }

  @override
  void dispose() {
    _safeJs('vetoSTT', 'stop', []);
    _safeJs('vetoTTS', 'stop', []);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _emergencyCreatedSub?.cancel();
    super.dispose();
  }

  void _safeJs(String obj, String m, List a) {
    try { browser_bridge.callBrowserMethod(obj, m, a); } catch (_) {}
  }

  Future<void> _loadData() async {
    final r = await AuthService().getStoredRole();
    final p = await AuthService().getStoredPhone();
    final t = await AuthService().getToken();
    final language = AppLanguage.normalize(
      await AuthService().getStoredPreferredLanguage(),
    );
    if (!mounted) return;
    if (r == 'lawyer') {
      Navigator.of(context).pushReplacementNamed('/lawyer_dashboard');
      return;
    }
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
  }

  Future<void> _loadAdminFiles() async {
    setState(() => _adminFilesLoading = true);
    final data = await AdminService().getEmergencyLogs();
    if (mounted) setState(() { _adminFiles = data; _adminFilesLoading = false; });
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
    try { pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high); } catch (_) {}
    SocketService().emitStartVeto(
      lat: pos?.latitude ?? 32.08, lng: pos?.longitude ?? 34.78,
      preferredLanguage: _langKey, specialization: _s.he,
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
    try { pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high); } catch (_) {}
    SocketService().emitStartVeto(
      lat: pos?.latitude ?? 32.08, lng: pos?.longitude ?? 34.78,
      preferredLanguage: _langKey, specialization: spec,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: VetoPalette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ContactSheet(type: type, langKey: _langKey, scenarioLabel: _sLabel),
    );
  }

  void _openCamera() {
    if (_activeEventId == null || _token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_langKey == 'he'
            ? 'לחץ SOS תחילה כדי להפעיל תיעוד ראיות'
            : _langKey == 'ru'
            ? 'Сначала нажмите SOS для записи доказательств'
            : 'Tap SOS first to enable evidence recording'),
      ));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EvidenceScreen(
        eventId: _activeEventId!,
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
    try { pos = await Geolocator.getCurrentPosition(); } catch (_) {}
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
    final bool isAdmin = _role == 'admin';
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

  // ── AppBar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isAdmin) => AppBar(
    backgroundColor: VetoPalette.surface,
    automaticallyImplyLeading: false,
    title: Row(children: [
      const Icon(Icons.shield, color: VetoPalette.primary, size: 22),
      const SizedBox(width: 8),
      const Text('VETO',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 4, color: VetoPalette.text)),
      const SizedBox(width: 4),
      if (_isDispatching)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: VetoPalette.emergency.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: VetoPalette.emergency.withValues(alpha: 0.3))),
          child: const Text('LIVE',
              style: TextStyle(color: VetoPalette.emergency, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ),
    ]),
    bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: VetoPalette.border)),
    actions: [
      for (final k in ['he', 'ru', 'en'])
        GestureDetector(
          onTap: () async {
            await context.read<AppLanguageController>().setLanguage(k);
            if (!mounted) return;
            setState(() {
              _langKey = k;
              _messages.clear();
              _geminiHistory.clear();
              _messages.add(_Msg(text: _langs[k]!.greeting, isUser: false));
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: k == _langKey
                  ? VetoPalette.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                  color: k == _langKey ? VetoPalette.primary : Colors.transparent),
            ),
            child: Text(_langs[k]!.label,
                style: TextStyle(
                    color: k == _langKey ? VetoPalette.primary : VetoPalette.textMuted,
                    fontSize: 11,
                    fontWeight: k == _langKey ? FontWeight.w700 : FontWeight.normal)),
          ),
        ),
      const SizedBox(width: 2),
      if (isAdmin)
        IconButton(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          color: VetoPalette.primary,
          onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
          tooltip: 'פאנל ניהול',
        ),
      IconButton(
          icon: const Icon(Icons.person_outline),
          color: VetoPalette.textMuted,
          onPressed: () => Navigator.pushNamed(context, '/profile')),
      IconButton(
          icon: const Icon(Icons.logout_rounded),
          color: VetoPalette.textMuted,
          onPressed: () => AuthService().logout(context)),
    ],
  );

  // ── Bottom Nav ────────────────────────────────────────────
  Widget _buildNavBar(bool isRtl) => NavigationBar(
    selectedIndex: _tab,
    backgroundColor: VetoPalette.surface,
    indicatorColor: VetoPalette.primary.withValues(alpha: 0.2),
    onDestinationSelected: (i) => setState(() => _tab = i),
    destinations: [
      NavigationDestination(
        icon: const Icon(Icons.shield_outlined, color: VetoPalette.textMuted),
        selectedIcon: const Icon(Icons.shield, color: VetoPalette.primary),
        label: isRtl ? 'VETO מגן' : 'VETO Shield',
      ),
      NavigationDestination(
        icon: const Icon(Icons.smart_toy_outlined, color: VetoPalette.textMuted),
        selectedIcon: const Icon(Icons.smart_toy, color: VetoPalette.primary),
        label: isRtl ? 'AI עוזר' : 'AI Assistant',
      ),
    ],
  );

  // ══════════════════════════════════════════════════════════
  // WIZARD TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildWizardTab(bool isAdmin, bool isRtl) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _statusBadge(),
          const SizedBox(height: 14),
          _sosButton(),
          const SizedBox(height: 20),
          _secLabel(isRtl
              ? 'מה קורה עכשיו?'
              : _langKey == 'ru'
              ? 'Что происходит?'
              : "What's happening?"),
          const SizedBox(height: 8),
          _scenarioBar(isRtl),
          const SizedBox(height: 14),
          _rightsCard(),
          const SizedBox(height: 16),
          _secLabel(isRtl
              ? 'צור קשר מיידי'
              : _langKey == 'ru'
              ? 'Быстрая связь'
              : 'Quick Contact'),
          const SizedBox(height: 8),
          _contactGrid(isRtl),
          const SizedBox(height: 16),
          _secLabel(isRtl ? 'כלים מהירים' : _langKey == 'ru' ? 'Инструменты' : 'Quick Tools'),
          const SizedBox(height: 8),
          _toolsGrid(isRtl),
          if (isAdmin) ...[
            const SizedBox(height: 20),
            _adminSection(isRtl),
          ],
          const SizedBox(height: 40),
        ]),
      ),
    ),
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
              fontWeight: FontWeight.w600,
              fontSize: 13),
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

  Widget _sosButton() => GestureDetector(
    onTap: _isDispatching ? null : _dispatchSOS,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDispatching
              ? [VetoPalette.emergency.withValues(alpha: 0.35),
                 VetoPalette.emergency.withValues(alpha: 0.15)]
              : [VetoPalette.emergency, const Color(0xFFB91C1C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isDispatching
            ? []
            : [BoxShadow(
                color: VetoPalette.emergency.withValues(alpha: 0.4),
                blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 38),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _isDispatching
                  ? (_langKey == 'he' ? 'שיגור פעיל — מחפש עורך דין'
                      : _langKey == 'ru' ? 'Активный поиск адвоката...'
                      : 'Active — finding your lawyer...')
                  : (_langKey == 'he' ? 'SOS — שלח עזרה עכשיו'
                      : _langKey == 'ru' ? 'SOS — Вызвать адвоката'
                      : 'SOS — Send Legal Help Now'),
              style: const TextStyle(
                  color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              _isDispatching
                  ? (_langKey == 'he' ? 'עורך דין בדרך אליך...'
                      : _langKey == 'ru' ? 'Адвокат уже едет к вам...'
                      : 'A lawyer is on the way to you...')
                  : (_langKey == 'he' ? 'לחץ לשגר עורך דין לעמדתך מיידית'
                      : _langKey == 'ru' ? 'Нажмите для немедленного вызова адвоката'
                      : 'Tap to instantly dispatch a lawyer to you'),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ]),
        ),
      ]),
    ),
  );

  Widget _secLabel(String txt) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(txt.toUpperCase(),
        style: const TextStyle(
            color: VetoPalette.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5)),
  );

  Widget _scenarioBar(bool isRtl) => SizedBox(
    height: 92,
    child: ListView(
      scrollDirection: Axis.horizontal,
      reverse: isRtl,
      children: _sdMap.entries.map((e) {
        final sel = e.key == _scenario;
        final lbl = _langKey == 'ru' ? e.value.ru
            : _langKey == 'en' ? e.value.en
            : e.value.he;
        return GestureDetector(
          onTap: () => setState(() { _scenario = e.key; _rightsExpanded = true; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 90,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: sel ? VetoPalette.primary.withValues(alpha: 0.15) : VetoPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: sel
                  ? Border(
                      left: const BorderSide(color: VetoPalette.primary, width: 3),
                      top: BorderSide(color: VetoPalette.primary.withValues(alpha: 0.35)),
                      right: BorderSide(color: VetoPalette.primary.withValues(alpha: 0.35)),
                      bottom: BorderSide(color: VetoPalette.primary.withValues(alpha: 0.35)),
                    )
                  : Border.all(color: VetoPalette.border),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(e.value.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(lbl,
                  style: TextStyle(
                      color: sel ? VetoPalette.primary : VetoPalette.textMuted,
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      }).toList(),
    ),
  );

  Widget _rightsCard() => Container(
    decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: const BorderSide(color: VetoPalette.primary, width: 3),
          top: BorderSide(color: VetoPalette.border),
          right: BorderSide(color: VetoPalette.border),
          bottom: BorderSide(color: VetoPalette.border),
        )),
    child: Column(children: [
      InkWell(
        onTap: () => setState(() => _rightsExpanded = !_rightsExpanded),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            const Icon(Icons.verified_user_outlined, color: VetoPalette.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _langKey == 'he' ? 'הזכויות שלך — $_sLabel'
                    : _langKey == 'ru' ? 'Ваши права — $_sLabel'
                    : 'Your Rights — $_sLabel',
                style: const TextStyle(
                    color: VetoPalette.text, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Icon(
              _rightsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: VetoPalette.textMuted,
            ),
          ]),
        ),
      ),
      if (_rightsExpanded)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            children: _rights.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    margin: const EdgeInsets.only(top: 5, left: 2, right: 2),
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: VetoPalette.primary)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r,
                      style: const TextStyle(
                          color: VetoPalette.textMuted, fontSize: 13, height: 1.5)),
                ),
              ]),
            )).toList(),
          ),
        ),
    ]),
  );

  Widget _contactGrid(bool isRtl) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    childAspectRatio: 2.8,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    children: [
      _ctCard(Icons.phone_in_talk_rounded,
          _langKey == 'he' ? 'עורך דין עכשיו'
              : _langKey == 'ru' ? 'Вызвать юриста'
              : 'Call Lawyer',
          VetoPalette.primary, _dispatchSOS),
      _ctCard(Icons.chat_rounded, 'WhatsApp', const Color(0xFF25D366),
          () => _openContact('whatsapp')),
      _ctCard(Icons.send_rounded, 'Telegram', const Color(0xFF229ED9),
          () => _openContact('telegram')),
      _ctCard(Icons.videocam_rounded,
          _langKey == 'he' ? 'שיחת וידאו'
              : _langKey == 'ru' ? 'Видеозвонок'
              : 'Video Call',
          const Color(0xFF8B5CF6), () => _openContact('video')),
    ],
  );

  Widget _ctCard(IconData icon, String label, Color color, VoidCallback onTap) =>
      Material(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.25))),
            child: Row(children: [
              Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 17)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
          ),
        ),
      );

  Widget _toolsGrid(bool isRtl) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4,
    childAspectRatio: 0.85,
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VetoPalette.border)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 18)),
              const SizedBox(height: 5),
              Text(label,
                  style: const TextStyle(color: VetoPalette.textMuted, fontSize: 9.5),
                  textAlign: TextAlign.center),
            ]),
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
            itemBuilder: (_, i) {
              final ev = _adminFiles[i];
              final user = ev['user_id'];
              final status = ev['status'] as String? ?? '?';
              final evidence = (ev['evidence'] as List?) ?? [];
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
                            color: status == 'active' ? VetoPalette.emergency
                                : status == 'resolved' ? VetoPalette.success
                                : VetoPalette.warning)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user is Map ? (user['full_name'] ?? user['phone'] ?? 'משתמש').toString() : 'משתמש',
                        style: const TextStyle(color: VetoPalette.text, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
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
    Expanded(
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _messages.length) return _typingBubble();
          final msg = _messages[i];
          if (msg.isSystem) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VetoPalette.emergency.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VetoPalette.emergency.withValues(alpha: 0.3)),
              ),
              child: Text(msg.text,
                  style: const TextStyle(color: VetoPalette.text, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center),
            );
          }
          return Align(
            alignment: msg.isUser
                ? (isRtl ? Alignment.centerRight : Alignment.centerLeft)
                : (isRtl ? Alignment.centerLeft : Alignment.centerRight),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: msg.isUser ? VetoPalette.surface : VetoPalette.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 4 : 16),
                  bottomRight: Radius.circular(msg.isUser ? 16 : 4),
                ),
                border: Border.all(
                    color: msg.isUser ? VetoPalette.border : VetoPalette.success.withValues(alpha: 0.3)),
              ),
              child: Text(msg.text,
                  style: const TextStyle(color: VetoPalette.text, fontSize: 14, height: 1.4)),
            ),
          );
        },
      ),
    ),
    _chatInput(isRtl),
    _chatActBar(isRtl),
    const SizedBox(height: 6),
  ]);

  Widget _typingBubble() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VetoPalette.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
            width: 36,
            child: LinearProgressIndicator(
                backgroundColor: VetoPalette.border,
                valueColor: AlwaysStoppedAnimation(VetoPalette.success))),
        const SizedBox(width: 8),
        Text(_l.processing,
            style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
      ]),
    ),
  );

  Widget _chatInput(bool isRtl) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
    child: Row(children: [
      GestureDetector(
        onTap: _toggleMic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44, height: 44,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening ? VetoPalette.emergency : VetoPalette.surface,
              border: Border.all(
                  color: _isListening ? VetoPalette.emergency : VetoPalette.border)),
          child: Icon(
              _isListening ? Icons.mic : Icons.mic_none_rounded,
              color: _isListening ? Colors.white : VetoPalette.textMuted,
              size: 20),
        ),
      ),
      const SizedBox(width: 8),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => _send(_inputCtrl.text),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isLoading || _isDispatching) ? VetoPalette.border : VetoPalette.success),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    ]),
  );

  Widget _chatActBar(bool isRtl) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _chatActBtn(Icons.camera_alt_outlined,
          _langKey == 'he' ? 'תיעוד' : _langKey == 'ru' ? 'Камера' : 'Camera',
          _openCamera),
      _chatActBtn(Icons.volume_off_rounded,
          _langKey == 'he' ? 'השתק' : _langKey == 'ru' ? 'Звук' : 'Mute',
          _stopSpeaking),
      _chatActBtn(Icons.location_on_outlined,
          _langKey == 'he' ? 'מיקום' : _langKey == 'ru' ? 'Геолок.' : 'Location',
          _shareLocation),
    ]),
  );

  Widget _chatActBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: VetoPalette.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: VetoPalette.border)),
              child: Icon(icon, color: VetoPalette.textMuted, size: 22)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11)),
        ]),
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
        : const Color(0xFF8B5CF6);
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
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.paypal_rounded, color: Color(0xFF009CDE), size: 24),
        SizedBox(width: 10),
        Text('תשלום עם PayPal',
            style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ייעוץ עורך דין 15 דקות',
              style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('₪50 (≈ \$13.90 USD) — חיוב חד-פעמי',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
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
          child: const Text('ביטול', style: TextStyle(color: Color(0xFF64748B))),
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
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 22),
        SizedBox(width: 10),
        Text('אשר את התשלום',
            style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
            'PayPal נפתח בטאב חדש.\nלאחר אישור התשלום שם — חזור לכאן ולחץ "שילמתי".',
            style: TextStyle(color: Color(0xFF94A3B8), height: 1.6, fontSize: 13),
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
          child: const Text('ביטול', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.lock_outline, color: Color(0xFF3B82F6)),
          SizedBox(width: 10),
          Text('נדרש מנוי', style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('כדי להשתמש ב-VETO נדרש מנוי חודשי.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('מנוי חודשי',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 6),
                Row(children: [
                  Text('₪19.90',
                      style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w800, fontSize: 22)),
                  SizedBox(width: 6),
                  Text('/ חודש  (USD \$5.50)',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                ]),
                SizedBox(height: 8),
                Text('✓ ייעוץ AI משפטי ללא הגבלה',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                Text('✓ הזמנת עורך דין חרום (₪50 נוסף)',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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
                  child: const Text('לאחר מכן', style: TextStyle(color: Color(0xFF64748B))),
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
                  child: const Text('ביטול', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
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
