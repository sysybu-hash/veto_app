// ============================================================
//  SettingsScreen.dart — Per-role user settings
//  Roles: user (citizen), lawyer, admin
//  Sections: profile, notifications, language, subscription,
//            lawyer schedule/specializations, admin system
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/webrtc_settings_store.dart';
import '../services/webrtc_user_settings.dart';

// ── i18n ──────────────────────────────────────────────────────
const _i18n = {
  'he': {
    'title': 'הגדרות',
    'profile': 'פרופיל',
    'name': 'שם',
    'phone': 'טלפון',
    'email': 'כתובת מייל',
    'language': 'שפה',
    'hebrew': 'עברית',
    'english': 'English',
    'russian': 'Русский',
    'notifications': 'התראות',
    'notifyEmergency': 'התראות חירום',
    'notifyUpdates': 'עדכוני מערכת',
    'notifySms': 'SMS',
    'subscription': 'מנוי',
    'currentPlan': 'תוכנית נוכחית',
    'upgrade': 'שדרג',
    'managePayment': 'ניהול תשלום',
    'lawyerSettings': 'הגדרות עורך דין',
    'availability': 'זמינות',
    'specializations': 'התמחויות',
    'contactLinks': 'קישורי יצירת קשר',
    'whatsapp': 'WhatsApp',
    'telegram': 'Telegram',
    'adminSettings': 'הגדרות מנהל',
    'systemEmail': 'מייל מערכת',
    'maintenanceMode': 'מצב תחזוקה',
    'maxFileSizeMb': 'גודל קובץ מקסימלי (MB)',
    'defaultQuotaMb': 'מכסת קבצים ברירת מחדל (MB)',
    'danger': 'אזור מסוכן',
    'deleteAccount': 'מחק חשבון',
    'deleteConfirm': 'פעולה זו בלתי הפיכה. לאשר?',
    'save': 'שמור שינויים',
    'saved': 'הגדרות נשמרו',
    'cancel': 'ביטול',
    'yes': 'כן',
    'no': 'לא',
    'logout': 'התנתק',
    'addLink': 'הוסף קישור',
    'planFree': 'חינמי',
    'planBasic': 'בסיסי',
    'planPro': 'מקצועי',
    'webrtcTitle': 'שיחות WebRTC',
    'webrtcHint': 'חל על השיחה הבאה. STUN מההגדרות כאן; אם בשרת הוגדרו TURN/ICE (משתני סביבה), הם יתווספו אוטומטית לשיחה.',
    'webrtcIce': 'רשימת STUN',
    'webrtcIceMin': 'מינימלי (3 שרתים)',
    'webrtcIceExt': 'מורחב (5 שרתים)',
    'webrtcPool': 'גודל מאגר ICE',
    'webrtcEcho': 'ביטול הד (אודיו)',
    'webrtcNoise': 'דיכוי רעש',
    'webrtcAgc': 'בקרת רווח אוטומטית',
    'webrtcRes': 'רזולוציית וידאו',
    'webrtcResSd': 'SD ‎640×480',
    'webrtcResHd': 'HD ‎1280×720',
    'webrtcResFhd': 'Full HD ‎1920×1080',
    'webrtcFacing': 'כיוון מצלמה',
    'webrtcFacingUser': 'קדמית (selfie)',
    'webrtcFacingEnv': 'אחורית',
    'webrtcBundle': 'מדיניות Bundle',
    'webrtcBundleBalanced': 'balanced',
    'webrtcBundleMaxBundle': 'max-bundle (מומלץ)',
    'webrtcBundleMaxCompat': 'max-compat',
    'webrtcMux': 'RTCP mux',
    'webrtcMuxReq': 'require (מומלץ)',
    'webrtcMuxNeg': 'negotiate',
    'wizStep': 'שלב',
    'wizOf': 'מתוך',
    'wizNext': 'הבא',
    'wizBack': 'חזרה',
    'wiz1Title': 'כללי',
    'wiz2Title': 'שפה והתראות',
    'wiz3Title': 'שיחות ומדיה',
    'wiz4Title': 'חשבון ומנוי',
    'wiz5Title': 'בטיחות',
  },
  'en': {
    'title': 'Settings',
    'profile': 'Profile',
    'name': 'Name',
    'phone': 'Phone',
    'email': 'Email',
    'language': 'Language',
    'hebrew': 'עברית',
    'english': 'English',
    'russian': 'Русский',
    'notifications': 'Notifications',
    'notifyEmergency': 'Emergency alerts',
    'notifyUpdates': 'System updates',
    'notifySms': 'SMS alerts',
    'subscription': 'Subscription',
    'currentPlan': 'Current plan',
    'upgrade': 'Upgrade',
    'managePayment': 'Manage payment',
    'lawyerSettings': 'Lawyer settings',
    'availability': 'Availability',
    'specializations': 'Specializations',
    'contactLinks': 'Contact links',
    'whatsapp': 'WhatsApp',
    'telegram': 'Telegram',
    'adminSettings': 'Admin settings',
    'systemEmail': 'System email',
    'maintenanceMode': 'Maintenance mode',
    'maxFileSizeMb': 'Max file size (MB)',
    'defaultQuotaMb': 'Default file quota (MB)',
    'danger': 'Danger Zone',
    'deleteAccount': 'Delete account',
    'deleteConfirm': 'This is irreversible. Confirm?',
    'save': 'Save changes',
    'saved': 'Settings saved',
    'cancel': 'Cancel',
    'yes': 'Yes',
    'no': 'No',
    'logout': 'Sign out',
    'addLink': 'Add link',
    'planFree': 'Free',
    'planBasic': 'Basic',
    'planPro': 'Pro',
    'webrtcTitle': 'WebRTC calls',
    'webrtcHint': 'Applies to the next call. STUN from here; if the backend exposes TURN/ICE env vars, they are merged automatically.',
    'webrtcIce': 'STUN server set',
    'webrtcIceMin': 'Minimal (3 servers)',
    'webrtcIceExt': 'Extended (5 servers)',
    'webrtcPool': 'ICE candidate pool size',
    'webrtcEcho': 'Echo cancellation',
    'webrtcNoise': 'Noise suppression',
    'webrtcAgc': 'Auto gain control',
    'webrtcRes': 'Video resolution',
    'webrtcResSd': 'SD 640×480',
    'webrtcResHd': 'HD 1280×720',
    'webrtcResFhd': 'Full HD 1920×1080',
    'webrtcFacing': 'Camera facing',
    'webrtcFacingUser': 'Front (user)',
    'webrtcFacingEnv': 'Back (environment)',
    'webrtcBundle': 'Bundle policy',
    'webrtcBundleBalanced': 'balanced',
    'webrtcBundleMaxBundle': 'max-bundle (recommended)',
    'webrtcBundleMaxCompat': 'max-compat',
    'webrtcMux': 'RTCP mux policy',
    'webrtcMuxReq': 'require (recommended)',
    'webrtcMuxNeg': 'negotiate',
    'wizStep': 'Step',
    'wizOf': 'of',
    'wizNext': 'Next',
    'wizBack': 'Back',
    'wiz1Title': 'General',
    'wiz2Title': 'Language & alerts',
    'wiz3Title': 'Calls & media',
    'wiz4Title': 'Account & plan',
    'wiz5Title': 'Safety',
  },
  'ru': {
    'title': 'Настройки',
    'profile': 'Профиль',
    'name': 'Имя',
    'phone': 'Телефон',
    'email': 'Email',
    'language': 'Язык',
    'hebrew': 'עברית',
    'english': 'English',
    'russian': 'Русский',
    'notifications': 'Уведомления',
    'notifyEmergency': 'Экстренные уведомления',
    'notifyUpdates': 'Системные обновления',
    'notifySms': 'SMS-уведомления',
    'subscription': 'Подписка',
    'currentPlan': 'Текущий план',
    'upgrade': 'Обновить',
    'managePayment': 'Управление оплатой',
    'lawyerSettings': 'Настройки адвоката',
    'availability': 'Доступность',
    'specializations': 'Специализации',
    'contactLinks': 'Контакты',
    'whatsapp': 'WhatsApp',
    'telegram': 'Telegram',
    'adminSettings': 'Настройки администратора',
    'systemEmail': 'Системный email',
    'maintenanceMode': 'Режим обслуживания',
    'maxFileSizeMb': 'Макс. размер файла (МБ)',
    'defaultQuotaMb': 'Квота файлов по умолчанию (МБ)',
    'danger': 'Опасная зона',
    'deleteAccount': 'Удалить аккаунт',
    'deleteConfirm': 'Это необратимо. Подтвердить?',
    'save': 'Сохранить изменения',
    'saved': 'Настройки сохранены',
    'cancel': 'Отмена',
    'yes': 'Да',
    'no': 'Нет',
    'logout': 'Выйти',
    'addLink': 'Добавить ссылку',
    'planFree': 'Бесплатный',
    'planBasic': 'Базовый',
    'planPro': 'Pro',
    'webrtcTitle': 'Звонки WebRTC',
    'webrtcHint': 'Со следующего звонка. STUN — здесь; TURN/ICE с сервера (env) подмешиваются автоматически.',
    'webrtcIce': 'Набор STUN',
    'webrtcIceMin': 'Минимальный (3 сервера)',
    'webrtcIceExt': 'Расширенный (5 серверов)',
    'webrtcPool': 'Размер пула ICE',
    'webrtcEcho': 'Подавление эха',
    'webrtcNoise': 'Шумоподавление',
    'webrtcAgc': 'Автоусиление (AGC)',
    'webrtcRes': 'Разрешение видео',
    'webrtcResSd': 'SD 640×480',
    'webrtcResHd': 'HD 1280×720',
    'webrtcResFhd': 'Full HD 1920×1080',
    'webrtcFacing': 'Камера',
    'webrtcFacingUser': 'Передняя',
    'webrtcFacingEnv': 'Задняя',
    'webrtcBundle': 'Политика bundle',
    'webrtcBundleBalanced': 'balanced',
    'webrtcBundleMaxBundle': 'max-bundle (рекомендуется)',
    'webrtcBundleMaxCompat': 'max-compat',
    'webrtcMux': 'Политика RTCP mux',
    'webrtcMuxReq': 'require (рекомендуется)',
    'webrtcMuxNeg': 'negotiate',
    'wizStep': 'Шаг',
    'wizOf': 'из',
    'wizNext': 'Далее',
    'wizBack': 'Назад',
    'wiz1Title': 'Общие',
    'wiz2Title': 'Язык и уведомления',
    'wiz3Title': 'Звонки и медиа',
    'wiz4Title': 'Аккаунт и план',
    'wiz5Title': 'Безопасность',
  },
};

String _t(String code, String key) =>
    (_i18n[code] ?? _i18n['en']!)[key] ?? key;

String _webrtcVideoPreset(WebRtcUserSettings w) {
  if (w.videoWidth >= 1920 && w.videoHeight >= 1000) return 'fhd';
  if (w.videoWidth <= 854 && w.videoHeight <= 520) return 'sd';
  return 'hd';
}

// ── Screen ────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();

  String _role = 'user';
  String _plan = 'free';
  bool _loading = true;
  bool _saving = false;

  // Profile
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;

  // Notifications
  bool _notifyEmergency = true;
  bool _notifyUpdates = true;
  bool _notifySms = false;

  // Lawyer-specific
  bool _isAvailable = true;
  final List<String> _specializations = [];
  late TextEditingController _whatsappCtrl;
  late TextEditingController _telegramCtrl;

  // Admin-specific
  late TextEditingController _systemEmailCtrl;
  bool _maintenanceMode = false;
  late TextEditingController _maxFileSizeCtrl;
  late TextEditingController _defaultQuotaCtrl;

  // WebRTC (local prefs — not sent to API)
  WebRtcUserSettings _webrtc = WebRtcUserSettings.defaults();

  /// Wizard: 0 general → 1 WebRTC → 2 account & safety
  late TabController _wizardTab;

  @override
  void initState() {
    super.initState();
    _wizardTab = TabController(length: 3, vsync: this);
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _whatsappCtrl = TextEditingController();
    _telegramCtrl = TextEditingController();
    _systemEmailCtrl = TextEditingController();
    _maxFileSizeCtrl = TextEditingController(text: '50');
    _defaultQuotaCtrl = TextEditingController(text: '100');
    _loadSettings();
  }

  @override
  void dispose() {
    _wizardTab.dispose();
    for (final c in [
      _nameCtrl, _phoneCtrl, _emailCtrl,
      _whatsappCtrl, _telegramCtrl,
      _systemEmailCtrl, _maxFileSizeCtrl, _defaultQuotaCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final tok = await _auth.getToken();
      final role = await _auth.getStoredRole() ?? 'user';
      final name = await _auth.getStoredName() ?? '';
      final phone = await _auth.getStoredPhone() ?? '';

      _nameCtrl.text = name;
      _phoneCtrl.text = phone;
      _role = role;

      if (tok != null) {
        // Fetch full profile
        final res = await http.get(
          Uri.parse(_role == 'lawyer' ? '${AppConfig.baseUrl}/lawyers/me' : '${AppConfig.baseUrl}/users/me'),
          headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
        ).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final raw = jsonDecode(res.body) as Map<String, dynamic>;
          // Backend returns { user: {...} } or flat object
          final d = (raw['user'] ?? raw) as Map<String, dynamic>;
          _emailCtrl.text = d['email'] ?? '';
          _nameCtrl.text = d['full_name'] ?? d['name'] ?? name;
          _phoneCtrl.text = d['phone'] ?? phone;
          _plan = d['plan'] ?? d['subscription']?['plan'] ?? 'free';
          _notifyEmergency = d['settings']?['notifyEmergency'] ?? true;
          _notifyUpdates = d['settings']?['notifyUpdates'] ?? true;
          _notifySms = d['settings']?['notifySms'] ?? false;
          if (role == 'lawyer') {
            _isAvailable = d['is_available'] ?? d['isAvailable'] ?? true;
            _whatsappCtrl.text = d['whatsapp_number'] ?? d['whatsapp'] ?? '';
            _telegramCtrl.text = d['telegram_username'] ?? d['telegram'] ?? '';
            final specs = d['specializations'];
            if (specs is List) {
              _specializations.clear();
              _specializations.addAll(specs.cast<String>());
            }
          }
          if (role == 'admin') {
            // Fetch admin settings
            final aRes = await http.get(
              Uri.parse('${AppConfig.baseUrl}/admin/settings'),
              headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
            ).timeout(const Duration(seconds: 10));
            if (aRes.statusCode == 200) {
              final ad = jsonDecode(aRes.body) as Map<String, dynamic>;
              _systemEmailCtrl.text = ad['systemEmail'] ?? '';
              _maintenanceMode = ad['maintenanceMode'] ?? false;
              _maxFileSizeCtrl.text =
                  (ad['maxFileSizeMb'] ?? 50).toString();
              _defaultQuotaCtrl.text =
                  (ad['defaultQuotaMb'] ?? 100).toString();
            }
          }
        }
      }
    } catch (_) {}
    try {
      final w = await WebRtcSettingsStore.instance.load();
      if (mounted) setState(() => _webrtc = w);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save(String code) async {
    setState(() => _saving = true);
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      final headers = AppConfig.httpHeaders({'Authorization': 'Bearer $tok'});

      final body = <String, dynamic>{
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'settings': {
          'notifyEmergency': _notifyEmergency,
          'notifyUpdates': _notifyUpdates,
          'notifySms': _notifySms,
        },
      };
      if (_role == 'lawyer') {
        body['is_available'] = _isAvailable;
        body['whatsapp_number'] = _whatsappCtrl.text.trim();
        body['telegram_username'] = _telegramCtrl.text.trim();
        body['specializations'] = _specializations;
      }

      await http.put(
        Uri.parse('${AppConfig.baseUrl}/users/me'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (_role == 'admin') {
        await http.put(
          Uri.parse('${AppConfig.baseUrl}/admin/settings'),
          headers: headers,
          body: jsonEncode({
            'systemEmail': _systemEmailCtrl.text.trim(),
            'maintenanceMode': _maintenanceMode,
            'maxFileSizeMb': int.tryParse(_maxFileSizeCtrl.text) ?? 50,
            'defaultQuotaMb': int.tryParse(_defaultQuotaCtrl.text) ?? 100,
          }),
        ).timeout(const Duration(seconds: 10));
      }

      await WebRtcSettingsStore.instance.save(_webrtc);
      _snack(_t(code, 'saved'));
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _deleteAccount(String code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t(code, 'deleteAccount'),
            style: const TextStyle(
                color: VetoPalette.emergency, fontWeight: FontWeight.w700)),
        content: Text(_t(code, 'deleteConfirm'),
            style: const TextStyle(color: VetoPalette.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t(code, 'no'),
                style: const TextStyle(color: VetoPalette.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: VetoPalette.emergency),
            child: Text(_t(code, 'yes')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      await http.delete(
        Uri.parse('${AppConfig.baseUrl}/users/me'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      await _auth.logout(context);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (_) {}
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: VetoPalette.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          title: Text(
            _t(code, 'title'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: _t(code, 'save'),
              onPressed: _saving ? null : () => _save(code),
              icon: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VetoPalette.primary,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
            ),
          ],
          bottom: TabBar(
            controller: _wizardTab,
            indicatorColor: VetoPalette.primary,
            labelColor: VetoPalette.text,
            unselectedLabelColor: VetoPalette.textMuted,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12),
            isScrollable: true,
            tabs: [
              Tab(text: _t(code, 'wiz1Title')),
              Tab(text: _t(code, 'wiz3Title')),
              Tab(text: _t(code, 'wiz5Title')),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _wizardTab,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // ── Profile section ─────────────────────
                  _Section(
                    icon: Icons.person_rounded,
                    title: _t(code, 'profile'),
                    children: [
                      _FieldTile(
                        label: _t(code, 'name'),
                        controller: _nameCtrl,
                        icon: Icons.badge_outlined,
                      ),
                      _FieldTile(
                        label: _t(code, 'phone'),
                        controller: _phoneCtrl,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      _FieldTile(
                        label: _t(code, 'email'),
                        controller: _emailCtrl,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Language section ────────────────────
                  _Section(
                    icon: Icons.translate_rounded,
                    title: _t(code, 'language'),
                    children: [
                      _LanguagePicker(currentCode: code),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Notifications section ───────────────
                  _Section(
                    icon: Icons.notifications_rounded,
                    title: _t(code, 'notifications'),
                    children: [
                      _ToggleTile(
                        label: _t(code, 'notifyEmergency'),
                        icon: Icons.warning_amber_rounded,
                        color: VetoPalette.emergency,
                        value: _notifyEmergency,
                        onChanged: (v) => setState(() => _notifyEmergency = v),
                      ),
                      _ToggleTile(
                        label: _t(code, 'notifyUpdates'),
                        icon: Icons.update_rounded,
                        color: VetoPalette.primary,
                        value: _notifyUpdates,
                        onChanged: (v) => setState(() => _notifyUpdates = v),
                      ),
                      _ToggleTile(
                        label: _t(code, 'notifySms'),
                        icon: Icons.sms_outlined,
                        color: VetoPalette.success,
                        value: _notifySms,
                        onChanged: (v) => setState(() => _notifySms = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                    ],
                  ),
                ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // ── WebRTC (audio/video calls) ───────────
                  _Section(
                    icon: Icons.video_call_rounded,
                    title: _t(code, 'webrtcTitle'),
                    children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            _t(code, 'webrtcHint'),
                            style: const TextStyle(
                              color: VetoPalette.textMuted,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(code, 'webrtcIce'),
                                style: const TextStyle(
                                    color: VetoPalette.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              DropdownButton<WebRtcIcePreset>(
                                isExpanded: true,
                                value: _webrtc.icePreset,
                                borderRadius: BorderRadius.circular(10),
                                dropdownColor: VetoPalette.surface,
                                style: const TextStyle(
                                    color: VetoPalette.text, fontSize: 14),
                                items: [
                                  DropdownMenuItem(
                                    value: WebRtcIcePreset.minimal,
                                    child: Text(_t(code, 'webrtcIceMin')),
                                  ),
                                  DropdownMenuItem(
                                    value: WebRtcIcePreset.extended,
                                    child: Text(_t(code, 'webrtcIceExt')),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(
                                      () => _webrtc = _webrtc.copyWith(icePreset: v));
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_t(code, 'webrtcPool')}: ${_webrtc.iceCandidatePoolSize}',
                                style: const TextStyle(
                                    color: VetoPalette.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              Slider.adaptive(
                                value: _webrtc.iceCandidatePoolSize.toDouble(),
                                min: 0,
                                max: 30,
                                divisions: 30,
                                label: '${_webrtc.iceCandidatePoolSize}',
                                onChanged: (v) => setState(() => _webrtc =
                                    _webrtc.copyWith(
                                        iceCandidatePoolSize: v.round())),
                              ),
                            ],
                          ),
                        ),
                        _ToggleTile(
                          label: _t(code, 'webrtcEcho'),
                          icon: Icons.hearing_rounded,
                          color: VetoPalette.primary,
                          value: _webrtc.echoCancellation,
                          onChanged: (v) => setState(
                              () => _webrtc = _webrtc.copyWith(echoCancellation: v)),
                        ),
                        _ToggleTile(
                          label: _t(code, 'webrtcNoise'),
                          icon: Icons.graphic_eq_rounded,
                          color: VetoPalette.primary,
                          value: _webrtc.noiseSuppression,
                          onChanged: (v) => setState(
                              () => _webrtc = _webrtc.copyWith(noiseSuppression: v)),
                        ),
                        _ToggleTile(
                          label: _t(code, 'webrtcAgc'),
                          icon: Icons.trending_up_rounded,
                          color: VetoPalette.primary,
                          value: _webrtc.autoGainControl,
                          onChanged: (v) => setState(
                              () => _webrtc = _webrtc.copyWith(autoGainControl: v)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(code, 'webrtcRes'),
                                style: const TextStyle(
                                    color: VetoPalette.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              DropdownButton<String>(
                                isExpanded: true,
                                value: _webrtcVideoPreset(_webrtc),
                                borderRadius: BorderRadius.circular(10),
                                dropdownColor: VetoPalette.surface,
                                style: const TextStyle(
                                    color: VetoPalette.text, fontSize: 14),
                                items: [
                                  DropdownMenuItem(
                                    value: 'sd',
                                    child: Text(_t(code, 'webrtcResSd')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'hd',
                                    child: Text(_t(code, 'webrtcResHd')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fhd',
                                    child: Text(_t(code, 'webrtcResFhd')),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    switch (v) {
                                      case 'sd':
                                        _webrtc = _webrtc.copyWith(
                                            videoWidth: 640, videoHeight: 480);
                                        break;
                                      case 'fhd':
                                        _webrtc = _webrtc.copyWith(
                                            videoWidth: 1920,
                                            videoHeight: 1080);
                                        break;
                                      case 'hd':
                                        _webrtc = _webrtc.copyWith(
                                            videoWidth: 1280, videoHeight: 720);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(code, 'webrtcFacing'),
                                style: const TextStyle(
                                    color: VetoPalette.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              DropdownButton<String>(
                                isExpanded: true,
                                value: _webrtc.facingMode,
                                borderRadius: BorderRadius.circular(10),
                                dropdownColor: VetoPalette.surface,
                                style: const TextStyle(
                                    color: VetoPalette.text, fontSize: 14),
                                items: [
                                  DropdownMenuItem(
                                    value: 'user',
                                    child: Text(_t(code, 'webrtcFacingUser')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'environment',
                                    child: Text(_t(code, 'webrtcFacingEnv')),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() =>
                                      _webrtc = _webrtc.copyWith(facingMode: v));
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(code, 'webrtcBundle'),
                                style: const TextStyle(
                                    color: VetoPalette.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              DropdownButton<String>(
                                isExpanded: true,
                                value: _webrtc.bundlePolicy,
                                borderRadius: BorderRadius.circular(10),
                                dropdownColor: VetoPalette.surface,
                                style: const TextStyle(
                                    color: VetoPalette.text, fontSize: 14),
                                items: [
                                  DropdownMenuItem(
                                    value: 'balanced',
                                    child: Text(_t(code, 'webrtcBundleBalanced')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'max-bundle',
                                    child: Text(_t(code, 'webrtcBundleMaxBundle')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'max-compat',
                                    child: Text(_t(code, 'webrtcBundleMaxCompat')),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _webrtc =
                                      _webrtc.copyWith(bundlePolicy: v));
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(code, 'webrtcMux'),
                                style: const TextStyle(
                                    color: VetoPalette.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              DropdownButton<String>(
                                isExpanded: true,
                                value: _webrtc.rtcpMuxPolicy,
                                borderRadius: BorderRadius.circular(10),
                                dropdownColor: VetoPalette.surface,
                                style: const TextStyle(
                                    color: VetoPalette.text, fontSize: 14),
                                items: [
                                  DropdownMenuItem(
                                    value: 'require',
                                    child: Text(_t(code, 'webrtcMuxReq')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'negotiate',
                                    child: Text(_t(code, 'webrtcMuxNeg')),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _webrtc =
                                      _webrtc.copyWith(rtcpMuxPolicy: v));
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                    ],
                  ),
                ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // ── Subscription section (non-admin) ────
                  if (_role != 'admin') ...[
                    _Section(
                      icon: Icons.card_membership_rounded,
                      title: _t(code, 'subscription'),
                      children: [
                        _InfoRow(
                          label: _t(code, 'currentPlan'),
                          value: _plan == 'pro'
                              ? _t(code, 'planPro')
                              : _plan == 'basic'
                                  ? _t(code, 'planBasic')
                                  : _t(code, 'planFree'),
                          color: _plan == 'pro'
                              ? VetoPalette.accentSky
                              : _plan == 'basic'
                                  ? VetoPalette.primary
                                  : VetoPalette.textMuted,
                        ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.upgrade_rounded,
                              color: VetoPalette.primary, size: 20),
                          title: Text(_t(code, 'upgrade'),
                              style: const TextStyle(
                                  color: VetoPalette.primary,
                                  fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: VetoPalette.textMuted),
                          onTap: () => Navigator.pushNamed(
                              context, '/profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // ── Lawyer section ──────────────────────
                  if (_role == 'lawyer') ...[
                    _Section(
                      icon: Icons.balance_rounded,
                      title: _t(code, 'lawyerSettings'),
                      children: [
                        _ToggleTile(
                          label: _t(code, 'availability'),
                          icon: Icons.circle,
                          color: VetoPalette.success,
                          value: _isAvailable,
                          onChanged: (v) =>
                              setState(() => _isAvailable = v),
                        ),
                        _FieldTile(
                          label: _t(code, 'whatsapp'),
                          controller: _whatsappCtrl,
                          icon: Icons.chat_rounded,
                          keyboardType: TextInputType.url,
                        ),
                        _FieldTile(
                          label: _t(code, 'telegram'),
                          controller: _telegramCtrl,
                          icon: Icons.send_rounded,
                          keyboardType: TextInputType.url,
                        ),
                        _SpecializationChips(
                          label: _t(code, 'specializations'),
                          items: _specializations,
                          onChanged: (items) =>
                              setState(() {
                                _specializations.clear();
                                _specializations.addAll(items);
                              }),
                          addLabel: _t(code, 'addLink'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // ── Admin section ───────────────────────
                  if (_role == 'admin') ...[
                    _Section(
                      icon: Icons.admin_panel_settings_rounded,
                      title: _t(code, 'adminSettings'),
                      children: [
                        _FieldTile(
                          label: _t(code, 'systemEmail'),
                          controller: _systemEmailCtrl,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _ToggleTile(
                          label: _t(code, 'maintenanceMode'),
                          icon: Icons.build_rounded,
                          color: VetoPalette.warning,
                          value: _maintenanceMode,
                          onChanged: (v) =>
                              setState(() => _maintenanceMode = v),
                        ),
                        _FieldTile(
                          label: _t(code, 'maxFileSizeMb'),
                          controller: _maxFileSizeCtrl,
                          icon: Icons.storage_rounded,
                          keyboardType: TextInputType.number,
                        ),
                        _FieldTile(
                          label: _t(code, 'defaultQuotaMb'),
                          controller: _defaultQuotaCtrl,
                          icon: Icons.folder_open_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // ── Danger zone ─────────────────────────
                  _Section(
                    icon: Icons.warning_amber_rounded,
                    title: _t(code, 'danger'),
                    iconColor: VetoPalette.emergency,
                    borderColor: VetoPalette.emergency.withValues(alpha: 0.25),
                    children: [
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.logout_rounded,
                            color: VetoPalette.textMuted, size: 20),
                        title: Text(_t(code, 'logout'),
                            style: const TextStyle(
                                color: VetoPalette.text,
                                fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: VetoPalette.textMuted),
                        onTap: () async {
                          await _auth.logout(context);
                          if (!context.mounted) return;
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/', (_) => false);
                        },
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.delete_forever_rounded,
                            color: VetoPalette.emergency, size: 20),
                        title: Text(_t(code, 'deleteAccount'),
                            style: const TextStyle(
                                color: VetoPalette.emergency,
                                fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: VetoPalette.emergency),
                        onTap: () => _deleteAccount(code),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                    ],
                  ),
                ),
                ],
              ),
      ),
    );
  }
}

// ── Reusable widgets ─────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final Color? iconColor;
  final Color? borderColor;

  const _Section({
    required this.icon, required this.title, required this.children,
    this.iconColor, this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? VetoPalette.primary;
    return Container(
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? VetoPalette.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Icon(icon, size: 18, color: ic),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(
                color: ic, fontWeight: FontWeight.w700, fontSize: 13,
                letterSpacing: 0.5)),
          ]),
        ),
        const Divider(height: 1, color: VetoPalette.border),
        ...children,
      ]),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  const _FieldTile({
    required this.label, required this.controller, required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: VetoPalette.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: VetoPalette.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: VetoPalette.textMuted, size: 18),
        filled: true,
        fillColor: VetoPalette.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: VetoPalette.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: VetoPalette.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: VetoPalette.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    ),
  );
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label, required this.icon, required this.color,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    dense: true,
    secondary: Icon(icon, color: color, size: 20),
    title: Text(label, style: const TextStyle(
        color: VetoPalette.text, fontSize: 14, fontWeight: FontWeight.w500)),
    value: value,
    onChanged: onChanged,
    activeThumbColor: color,
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      Text(label, style: const TextStyle(
          color: VetoPalette.textMuted, fontSize: 14)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(value, style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

class _LanguagePicker extends StatelessWidget {
  final String currentCode;
  const _LanguagePicker({required this.currentCode});

  @override
  Widget build(BuildContext context) {
    final langs = [
      ('he', 'עברית', '🇮🇱'),
      ('en', 'English', '🇺🇸'),
      ('ru', 'Русский', '🇷🇺'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: langs.map((lang) {
        final (code, label, flag) = lang;
        final selected = code == currentCode;
        return GestureDetector(
          onTap: () => context.read<AppLanguageController>().setLanguage(code),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? VetoPalette.primary.withValues(alpha: 0.10)
                  : VetoPalette.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? VetoPalette.primary : VetoPalette.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text('$flag  $label',
                style: TextStyle(
                    color: selected ? VetoPalette.primary : VetoPalette.text,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13)),
          ),
        );
      }).toList()),
    );
  }
}

class _SpecializationChips extends StatelessWidget {
  final String label, addLabel;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;

  const _SpecializationChips({
    required this.label, required this.items,
    required this.onChanged, required this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            color: VetoPalette.textMuted, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          ...items.map((s) => Chip(
            label: Text(s, style: const TextStyle(fontSize: 12)),
            backgroundColor: VetoPalette.primary.withValues(alpha: 0.08),
            side: BorderSide(color: VetoPalette.primary.withValues(alpha: 0.25)),
            deleteIconColor: VetoPalette.textMuted,
            onDeleted: () {
              final updated = List<String>.from(items)..remove(s);
              onChanged(updated);
            },
          )),
          ActionChip(
            label: Text(addLabel, style: const TextStyle(
                color: VetoPalette.primary, fontSize: 12,
                fontWeight: FontWeight.w600)),
            avatar: const Icon(Icons.add, size: 14, color: VetoPalette.primary),
            backgroundColor: VetoPalette.primary.withValues(alpha: 0.08),
            side: BorderSide(color: VetoPalette.primary.withValues(alpha: 0.25)),
            onPressed: () async {
              final ctrl = TextEditingController();
              final result = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: VetoPalette.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  content: TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: const TextStyle(color: VetoPalette.text),
                    decoration: InputDecoration(
                      hintText: label,
                      hintStyle: const TextStyle(color: VetoPalette.textMuted),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',
                          style: TextStyle(color: VetoPalette.textMuted)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                      style: FilledButton.styleFrom(
                          backgroundColor: VetoPalette.primary),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
              if (result != null && result.isNotEmpty) {
                onChanged([...items, result]);
              }
            },
          ),
        ]),
      ]),
    );
  }
}
