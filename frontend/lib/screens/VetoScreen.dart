import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/ai_service.dart';
import '../services/payment_service.dart';
import 'EvidenceScreen.dart';

// ── Language config ────────────────────────────────────────
class _Lang {
  final String code;
  final String label;
  final String greeting;
  final String hint;
  final String processing;
  final String dispatching;
  final String protected;
  final String broadcasting;

  const _Lang({
    required this.code,
    required this.label,
    required this.greeting,
    required this.hint,
    required this.processing,
    required this.dispatching,
    required this.protected,
    required this.broadcasting,
  });
}

const _langs = {
  'he': _Lang(
    code: 'he-IL',
    label: 'עברית',
    greeting: 'שלום! אני העוזר המשפטי של VETO.\nתאר את הבעיה המשפטית שלך ואמצא עבורך עורך דין זמין.',
    hint: 'תאר את הבעיה...',
    processing: 'מעבד...',
    dispatching: 'בתהליך שיגור...',
    protected: 'מוגן',
    broadcasting: 'שידור פעיל',
  ),
  'ru': _Lang(
    code: 'ru-RU',
    label: 'Русский',
    greeting: 'Здравствуйте! Я юридический помощник VETO.\nОпишите вашу юридическую проблему — я найду доступного адвоката.',
    hint: 'Опишите проблему...',
    processing: 'Обработка...',
    dispatching: 'Отправка...',
    protected: 'Защищён',
    broadcasting: 'Трансляция',
  ),
  'en': _Lang(
    code: 'en-US',
    label: 'English',
    greeting: 'Hello! I\'m the VETO legal assistant.\nDescribe your legal issue and I\'ll find you an available lawyer.',
    hint: 'Describe your issue...',
    processing: 'Processing...',
    dispatching: 'Dispatching...',
    protected: 'Protected',
    broadcasting: 'Live broadcast',
  ),
};

// ── Chat message model ────────────────────────────────────
class _Msg {
  final String text;
  final bool isUser;
  final bool isSystem;
  _Msg({required this.text, required this.isUser, this.isSystem = false});
}

class VetoScreen extends StatefulWidget {
  const VetoScreen({super.key});
  @override
  State<VetoScreen> createState() => _VetoScreenState();
}

class _VetoScreenState extends State<VetoScreen> {
  String _role = '', _phone = '';
  String _langKey     = 'he';
  bool _isDispatching = false;
  bool _isLoading     = false;
  bool _isListening   = false;

  String? _activeEventId;
  String? _token;
  StreamSubscription<Map<String, dynamic>>? _emergencyCreatedSub;

  final List<_Msg> _messages = [];
  final List<Map<String, dynamic>> _geminiHistory = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl    = ScrollController();

  _Lang get _l => _langs[_langKey]!;

  @override
  void initState() {
    super.initState();
    _loadData();
    js.context['vetoSTTResult'] = (String result) => _onSTTResult(result);
    _emergencyCreatedSub = SocketService().onEmergencyCreated.listen((data) {
      final id = data['eventId'] as String?;
      if (id != null && mounted) setState(() => _activeEventId = id);
    });
    // Check subscription after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSubscription());
  }

  Future<void> _checkSubscription() async {
    final role = await AuthService().getStoredRole();
    if (role == 'admin' || role == 'lawyer') return; // skip for non-users
    final isSubscribed = await AuthService().getStoredIsSubscribed();
    if (!isSubscribed && mounted) {
      final subscribed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SubscriptionGateDialog(),
      );
      if (subscribed != true && mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _safeJsCall('vetoSTT', 'stop', []);
    _safeJsCall('vetoTTS', 'stop', []);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _emergencyCreatedSub?.cancel();
    super.dispose();
  }

  void _safeJsCall(String obj, String method, List args) {
    try { js.context[obj].callMethod(method, args); } catch (_) {}
  }

  Future<void> _loadData() async {
    final r = await AuthService().getStoredRole();
    final p = await AuthService().getStoredPhone();
    final t = await AuthService().getToken();
    if (mounted) {
      setState(() { _role = r ?? ''; _phone = p ?? ''; _token = t; });
      _addWelcome();
    }
  }

  void _addWelcome() {
    _messages.clear();
    _geminiHistory.clear();
    _messages.add(_Msg(text: _l.greeting, isUser: false));
    if (mounted) setState(() {});
  }

  void _switchLang(String key) {
    if (_isDispatching) return;
    setState(() { _langKey = key; _isListening = false; });
    _addWelcome();
  }

  // ── Send ─────────────────────────────────────────────────
  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _isLoading || _isDispatching) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add(_Msg(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final snapshot = List<Map<String, dynamic>>.from(_geminiHistory);
    final result   = await AiService().chat(
      message: text,
      history: snapshot,
      lang: _langKey,
    );

    _geminiHistory
      ..add({'role': 'user',  'parts': [{'text': text}]})
      ..add({'role': 'model', 'parts': [{'text': result['reply'] ?? ''}]});

    final reply = (result['reply'] as String?) ?? '...';
    if (!mounted) return;
    setState(() { _isLoading = false; _messages.add(_Msg(text: reply, isUser: false)); });
    _scrollToBottom();
    _speak(reply);

    if (result['classified'] == true) {
      final spec      = result['specialization'] as String?;
      final lawyerMap = (result['lawyer'] as Map?)?.cast<String, dynamic>();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await _payAndDispatch(spec, lawyerMap?['name'] as String?);
    }
  }

  // ── PayPal consultation payment + dispatch ─────────────────
  Future<void> _payAndDispatch(String? spec, String? lawyerName) async {
    // Step 1: confirm intent + open PayPal
    final orderId = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PaymentDialog(spec: spec),
    );
    if (orderId == null || !mounted) return; // user cancelled

    // Step 2: wait for user to confirm payment in PayPal tab
    final captured = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CaptureDialog(orderId: orderId),
    );
    if (captured != true || !mounted) return;

    // Step 3: dispatch
    _dispatch(spec, lawyerName);
  }

  // ── STT ──────────────────────────────────────────────────
  void _toggleMic() {
    if (_isDispatching) return;
    _isListening ? _stopListening() : _startListening();
  }

  void _startListening() {
    bool supported = false;
    try { supported = js.context['vetoSTT'].callMethod('isSupported', []) as bool; } catch (_) {}
    if (!supported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הדפדפן שלך לא תומך בזיהוי קול')));
      return;
    }
    setState(() => _isListening = true);
    _safeJsCall('vetoSTT', 'start', [_l.code]);
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _safeJsCall('vetoSTT', 'stop', []);
  }

  void _onSTTResult(String result) {
    if (!mounted) return;
    setState(() => _isListening = false);
    if (result.startsWith('OK:')) _send(result.substring(3));
  }

  // ── TTS ──────────────────────────────────────────────────
  void _speak(String text) => _safeJsCall('vetoTTS', 'speak', [text, _l.code]);
  void _stopSpeaking()     => _safeJsCall('vetoTTS', 'stop', []);

  // ── Dispatch ─────────────────────────────────────────────
  Future<void> _dispatch(String? spec, String? lawyerName) async {
    if (_isDispatching) return;
    setState(() => _isDispatching = true);
    HapticFeedback.heavyImpact();

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}

    SocketService().emitStartVeto(
      lat: pos?.latitude  ?? 32.08,
      lng: pos?.longitude ?? 34.78,
      preferredLanguage: _langKey,
      specialization: spec,
    );

    final msg = lawyerName != null
        ? '🔔 ${_langKey == 'he' ? 'מחפש עורך דין בתחום $spec...\n$lawyerName ייצור איתך קשר בקרוב.' : _langKey == 'ru' ? 'Ищу адвоката по $spec...\n$lawyerName скоро свяжется.' : 'Searching for $spec lawyer...\n$lawyerName will contact you.'}'
        : '🔔 ${_langKey == 'he' ? 'מחפש עורך דין זמין בתחום $spec...' : _langKey == 'ru' ? 'Ищу доступного адвоката по $spec...' : 'Searching for a $spec lawyer...'}';

    if (mounted) {
      setState(() => _messages.add(_Msg(text: msg, isUser: false, isSystem: true)));
      _scrollToBottom();
      _speak(msg);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _role.toLowerCase().contains('admin');
    final isRtl = _langKey == 'he';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: _appBar(isAdmin),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _statusBadge(),
              const SizedBox(height: 6),
              _langBar(),
              const SizedBox(height: 4),
              Expanded(child: _chatList(isRtl)),
              _inputRow(isRtl),
              _actionRow(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(bool isAdmin) => AppBar(
    backgroundColor: VetoPalette.surface,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      onPressed: () => Navigator.maybePop(context),
    ),
    title: const Text('VETO'),
    actions: [
      if (isAdmin)
        IconButton(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
        ),
      IconButton(icon: const Icon(Icons.person_outline),
        onPressed: () => Navigator.pushNamed(context, '/profile')),
      IconButton(icon: const Icon(Icons.logout_rounded),
        onPressed: () => AuthService().logout(context)),
    ],
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1, color: VetoPalette.border),
    ),
  );

  Widget _statusBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    decoration: BoxDecoration(
      color: _isDispatching
          ? VetoPalette.emergency.withValues(alpha: 0.12)
          : VetoPalette.success.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: _isDispatching
            ? VetoPalette.emergency.withValues(alpha: 0.3)
            : VetoPalette.success.withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isDispatching ? VetoPalette.emergency : VetoPalette.success,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _isDispatching ? _l.broadcasting : _l.protected,
          style: TextStyle(
            color: _isDispatching ? VetoPalette.emergency : VetoPalette.success,
            fontWeight: FontWeight.w600, fontSize: 13,
          ),
        ),
        if (_phone.isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(_phone,
            style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11),
            textDirection: TextDirection.ltr),
        ],
      ],
    ),
  );

  Widget _langBar() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: _langs.entries.map((e) {
      final sel = e.key == _langKey;
      return GestureDetector(
        onTap: () => _switchLang(e.key),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: sel ? VetoPalette.primary.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: sel ? VetoPalette.primary : VetoPalette.border),
          ),
          child: Text(e.value.label,
            style: TextStyle(
              color: sel ? VetoPalette.primary : VetoPalette.textMuted,
              fontSize: 12,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _chatList(bool isRtl) => ListView.builder(
    controller: _scrollCtrl,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: _messages.length + (_isLoading ? 1 : 0),
    itemBuilder: (context, i) {
      if (i == _messages.length) return _typingIndicator();
      return _bubble(_messages[i], isRtl);
    },
  );

  Widget _bubble(_Msg msg, bool isRtl) {
    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VetoPalette.emergency.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VetoPalette.emergency.withValues(alpha: 0.35)),
        ),
        child: Text(msg.text,
          style: const TextStyle(color: VetoPalette.text, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center),
      );
    }
    final isUser = msg.isUser;
    return Align(
      alignment: isUser
          ? (isRtl ? Alignment.centerRight : Alignment.centerLeft)
          : (isRtl ? Alignment.centerLeft  : Alignment.centerRight),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? VetoPalette.surface : VetoPalette.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isUser ? 4  : 16),
            bottomRight: Radius.circular(isUser ? 16 : 4),
          ),
          border: Border.all(
            color: isUser ? VetoPalette.border : VetoPalette.success.withValues(alpha: 0.3),
          ),
        ),
        child: Text(msg.text,
          style: const TextStyle(color: VetoPalette.text, fontSize: 14, height: 1.4)),
      ),
    );
  }

  Widget _typingIndicator() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            child: LinearProgressIndicator(
              backgroundColor: VetoPalette.border,
              valueColor: const AlwaysStoppedAnimation(VetoPalette.success),
            ),
          ),
          const SizedBox(width: 8),
          Text(_l.processing,
            style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
        ],
      ),
    ),
  );

  Widget _inputRow(bool isRtl) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Row(
      children: [
        // Mic
        GestureDetector(
          onTap: _toggleMic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening ? VetoPalette.emergency : VetoPalette.surface,
              border: Border.all(
                color: _isListening ? VetoPalette.emergency : VetoPalette.border),
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none_rounded,
              color: _isListening ? Colors.white : VetoPalette.textMuted,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Input
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
                borderSide: const BorderSide(color: VetoPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: VetoPalette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: VetoPalette.success),
              ),
            ),
            onSubmitted: _send,
            textInputAction: TextInputAction.send,
          ),
        ),
        const SizedBox(width: 8),
        // Send
        GestureDetector(
          onTap: () => _send(_inputCtrl.text),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isLoading || _isDispatching) ? VetoPalette.border : VetoPalette.success,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    ),
  );

  Widget _actionRow() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionBtn(Icons.camera_alt_outlined,
          _langKey == 'ru' ? 'Камера' : _langKey == 'en' ? 'Camera' : 'תיעוד',
          _openCamera),
        _actionBtn(Icons.volume_off_rounded,
          _langKey == 'ru' ? 'Звук' : _langKey == 'en' ? 'Mute' : 'השתק',
          _stopSpeaking),
        _actionBtn(Icons.location_on_outlined,
          _langKey == 'ru' ? 'Местополож.' : _langKey == 'en' ? 'Location' : 'מיקום',
          _showLocation),
      ],
    ),
  );

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: VetoPalette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: VetoPalette.border),
            ),
            child: Icon(icon, color: VetoPalette.textMuted, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
            style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11)),
        ],
      ),
    );

  void _openCamera() {
    final eventId = _activeEventId;
    final token   = _token;
    if (eventId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_langKey == 'ar'
            ? 'ابدأ طلب VETO أولاً لتفعيل الكاميرا'
            : _langKey == 'en'
                ? 'Start a VETO request first to enable the camera'
                : 'יש להתחיל בקשת VETO כדי לאפשר תיעוד'),
      ));
      return;
    }
    final lang = _langKey == 'he'
        ? EvidenceLanguage.he
        : _langKey == 'ar'
            ? EvidenceLanguage.ar
            : EvidenceLanguage.en;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EvidenceScreen(
        eventId:  eventId,
        token:    token,
        language: lang,
      ),
    ));
  }

  void _showLocation() async {
    Position? pos;
    try { pos = await Geolocator.getCurrentPosition(); } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pos != null
        ? '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
        : 'לא ניתן למצוא מיקום'),
    ));
  }
}

// ══════════════════════════════════════════════════════════════
//  _PaymentDialog — Step 1: confirm charge + open PayPal tab
//  Returns the orderId string, or null if cancelled.
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
          const Text(
            'ייעוץ עורך דין 15 דקות',
            style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            '₪50 (≈ \$13.90 USD) — חיוב חד-פעמי',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
            ),
            child: const Text(
              'לא ניתן לבטל לאחר תשלום.',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
    // Return orderId to caller — next dialog will handle capture
    Navigator.pop(context, orderId);
  }
}

// ══════════════════════════════════════════════════════════════
//  _CaptureDialog — Step 2: wait for user to finish PayPal tab
//  Returns true if capture succeeded, false/null otherwise.
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PayPal נפתח בטאב חדש.\nלאחר אישור התשלום שם — חזור לכאן ולחץ "שילמתי".',
            style: TextStyle(color: Color(0xFF94A3B8), height: 1.6, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _capturing ? null : () => Navigator.pop(context, false),
          child: const Text('ביטול', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
      orderId: widget.orderId,
      type: PaymentType.consultation,
    );
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

// ── Subscription Gate Dialog (paywall) ───────────────────────────────────────
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
      orderId: _orderId!,
      type: PaymentType.subscription,
      userId: phone,
    );
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
        title: Row(children: const [
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('מנוי חודשי', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('₪19.90 / חודש  (\$5.50 USD)',
                    style: TextStyle(color: Color(0xFF22C55E), fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('✓ ייעוץ AI משפטי ללא הגבלה\n✓ הזמנת עורך דין חירום (₪50 נוסף)',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              ]),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
            ],
            if (_orderId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: const Text('שילמת ב-PayPal? לחץ "אישור" למטה',
                    style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13)),
              ),
            ],
          ],
        ),
        actions: _orderId == null
            ? [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                  child: const Text('לאחר מכן', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009CDE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _loading ? null : _openPayPal,
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('שלם עם PayPal'),
                ),
              ]
            : [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                  child: const Text('ביטול', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _loading ? null : _confirmPayment,
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('אישור תשלום ✓'),
                ),
              ],
      ),
    );
  }
}
