// ============================================================
//  LawyerSettingsScreen.dart — Dedicated settings for lawyers
//  Sections: availability, schedule, specializations, contact,
//            notifications, license, account
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_glass_system.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';

// ── i18n ──────────────────────────────────────────────────────
const _i18n = {
  'he': {
    'title': 'הגדרות עורך דין',
    'availability': 'זמינות',
    'availableNow': 'זמין לקבלת תיקים',
    'availableDesc': 'כשהוא פעיל, הלקוחות יוכלו לראות אותך ולשלוח בקשות',
    'schedule': 'שעות פעילות',
    'scheduleDesc': 'הגדר את שעות העבודה שלך לכל יום',
    'mon': 'שני',
    'tue': 'שלישי',
    'wed': 'רביעי',
    'thu': 'חמישי',
    'fri': 'שישי',
    'sat': 'שבת',
    'sun': 'ראשון',
    'from': 'מ',
    'to': 'עד',
    'closed': 'סגור',
    'specializations': 'תחומי התמחות',
    'specDesc': 'הוסף את תחומי ההתמחות שלך',
    'addSpec': 'הוסף התמחות',
    'addSpecHint': 'לדוגמה: דיני עבודה',
    'contact': 'קישורי יצירת קשר',
    'whatsapp': 'מספר WhatsApp',
    'whatsappHint': '+972501234567',
    'telegram': 'שם משתמש Telegram',
    'telegramHint': '@username',
    'responseTime': 'זמן מענה ממוצע',
    'minutes': 'דקות',
    'notifications': 'התראות',
    'notifyEmergency': 'התראות חירום',
    'notifyNewCase': 'תיק חדש',
    'notifyUpdates': 'עדכוני מערכת',
    'notifySms': 'SMS',
    'license': 'פרטי רישיון',
    'licenseNumber': 'מספר רישיון',
    'barAssociation': 'לשכת עורכי הדין',
    'languages': 'שפות טיפול',
    'account': 'חשבון',
    'logout': 'התנתק',
    'deleteAccount': 'מחק חשבון',
    'deleteConfirm': 'מחיקת חשבון היא בלתי הפיכה. לאשר?',
    'save': 'שמור שינויים',
    'saved': 'ההגדרות נשמרו',
    'cancel': 'ביטול',
    'yes': 'כן',
    'no': 'לא',
    'add': 'הוסף',
  },
  'en': {
    'title': 'Lawyer Settings',
    'availability': 'Availability',
    'availableNow': 'Available for cases',
    'availableDesc': 'When active, clients can see and send requests to you',
    'schedule': 'Working Hours',
    'scheduleDesc': 'Set your working hours for each day',
    'mon': 'Mon',
    'tue': 'Tue',
    'wed': 'Wed',
    'thu': 'Thu',
    'fri': 'Fri',
    'sat': 'Sat',
    'sun': 'Sun',
    'from': 'From',
    'to': 'To',
    'closed': 'Closed',
    'specializations': 'Specializations',
    'specDesc': 'Add your areas of expertise',
    'addSpec': 'Add specialization',
    'addSpecHint': 'e.g. Labor law',
    'contact': 'Contact Links',
    'whatsapp': 'WhatsApp number',
    'whatsappHint': '+972501234567',
    'telegram': 'Telegram username',
    'telegramHint': '@username',
    'responseTime': 'Avg. response time',
    'minutes': 'minutes',
    'notifications': 'Notifications',
    'notifyEmergency': 'Emergency alerts',
    'notifyNewCase': 'New case alert',
    'notifyUpdates': 'System updates',
    'notifySms': 'SMS alerts',
    'license': 'License Details',
    'licenseNumber': 'License number',
    'barAssociation': 'Bar association',
    'languages': 'Languages handled',
    'account': 'Account',
    'logout': 'Sign out',
    'deleteAccount': 'Delete account',
    'deleteConfirm': 'This is irreversible. Confirm?',
    'save': 'Save changes',
    'saved': 'Settings saved',
    'cancel': 'Cancel',
    'yes': 'Yes',
    'no': 'No',
    'add': 'Add',
  },
  'ru': {
    'title': 'Настройки адвоката',
    'availability': 'Доступность',
    'availableNow': 'Доступен для дел',
    'availableDesc': 'Когда включено, клиенты могут видеть вас и отправлять запросы',
    'schedule': 'Рабочие часы',
    'scheduleDesc': 'Установите рабочие часы для каждого дня',
    'mon': 'Пн',
    'tue': 'Вт',
    'wed': 'Ср',
    'thu': 'Чт',
    'fri': 'Пт',
    'sat': 'Сб',
    'sun': 'Вс',
    'from': 'С',
    'to': 'До',
    'closed': 'Закрыто',
    'specializations': 'Специализации',
    'specDesc': 'Добавьте ваши области экспертизы',
    'addSpec': 'Добавить специализацию',
    'addSpecHint': 'Например: трудовое право',
    'contact': 'Контакты',
    'whatsapp': 'Номер WhatsApp',
    'whatsappHint': '+972501234567',
    'telegram': 'Имя пользователя Telegram',
    'telegramHint': '@username',
    'responseTime': 'Среднее время ответа',
    'minutes': 'минут',
    'notifications': 'Уведомления',
    'notifyEmergency': 'Экстренные уведомления',
    'notifyNewCase': 'Новое дело',
    'notifyUpdates': 'Системные обновления',
    'notifySms': 'SMS-уведомления',
    'license': 'Данные лицензии',
    'licenseNumber': 'Номер лицензии',
    'barAssociation': 'Коллегия адвокатов',
    'languages': 'Языки обслуживания',
    'account': 'Аккаунт',
    'logout': 'Выйти',
    'deleteAccount': 'Удалить аккаунт',
    'deleteConfirm': 'Это необратимо. Подтвердить?',
    'save': 'Сохранить',
    'saved': 'Настройки сохранены',
    'cancel': 'Отмена',
    'yes': 'Да',
    'no': 'Нет',
    'add': 'Добавить',
  },
};

String _t(String code, String key) =>
    (_i18n[code] ?? _i18n['en']!)[key] ?? key;

// ── Model ─────────────────────────────────────────────────────
class _DaySchedule {
  final String key;
  bool open;
  String from;
  String to;
  _DaySchedule({required this.key, this.open = true,
      this.from = '09:00', this.to = '18:00'});
}

// ── Screen ────────────────────────────────────────────────────
class LawyerSettingsScreen extends StatefulWidget {
  const LawyerSettingsScreen({super.key});

  @override
  State<LawyerSettingsScreen> createState() => _LawyerSettingsScreenState();
}

class _LawyerSettingsScreenState extends State<LawyerSettingsScreen> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  bool _saving = false;

  // Availability
  bool _isAvailable = true;

  // Schedule
  final List<_DaySchedule> _schedule = [
    _DaySchedule(key: 'sun', open: true, from: '09:00', to: '18:00'),
    _DaySchedule(key: 'mon', open: true, from: '09:00', to: '18:00'),
    _DaySchedule(key: 'tue', open: true, from: '09:00', to: '18:00'),
    _DaySchedule(key: 'wed', open: true, from: '09:00', to: '18:00'),
    _DaySchedule(key: 'thu', open: true, from: '09:00', to: '18:00'),
    _DaySchedule(key: 'fri', open: false, from: '09:00', to: '14:00'),
    _DaySchedule(key: 'sat', open: false, from: '09:00', to: '14:00'),
  ];

  // Specializations
  final List<String> _specializations = [];
  final _specCtrl = TextEditingController();

  // Languages
  bool _langHe = true;
  bool _langEn = false;
  bool _langRu = false;

  // Contact
  final _whatsappCtrl = TextEditingController();
  final _telegramCtrl = TextEditingController();
  int _responseMinutes = 30;

  // Notifications
  bool _notifyEmergency = true;
  bool _notifyNewCase = true;
  bool _notifyUpdates = true;
  bool _notifySms = false;

  // License
  final _licenseCtrl = TextEditingController();
  final _barCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _specCtrl.dispose();
    _whatsappCtrl.dispose();
    _telegramCtrl.dispose();
    _licenseCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final tok = await _auth.getToken();
      if (tok == null) { if (mounted) setState(() => _loading = false); return; }
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/me'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body) as Map<String, dynamic>;
        final d = (raw['user'] ?? raw) as Map<String, dynamic>;
        _isAvailable = d['is_available'] ?? true;
        _whatsappCtrl.text = d['whatsapp_number'] ?? '';
        _telegramCtrl.text = d['telegram_username'] ?? '';
        _licenseCtrl.text = d['license_number'] ?? '';
        _barCtrl.text = d['bar_association'] ?? '';
        _responseMinutes = d['response_minutes'] ?? 30;
        _notifyEmergency = d['settings']?['notifyEmergency'] ?? true;
        _notifyNewCase = d['settings']?['notifyNewCase'] ?? true;
        _notifyUpdates = d['settings']?['notifyUpdates'] ?? true;
        _notifySms = d['settings']?['notifySms'] ?? false;
        final langs = d['languages_spoken'];
        if (langs is List) {
          _langHe = langs.contains('he');
          _langEn = langs.contains('en');
          _langRu = langs.contains('ru');
        }
        final specs = d['specializations'];
        if (specs is List) {
          _specializations
            ..clear()
            ..addAll(specs.cast<String>());
        }
        final sched = d['schedule'];
        if (sched is Map) {
          for (final day in _schedule) {
            final s = sched[day.key];
            if (s is Map) {
              day.open = s['open'] ?? day.open;
              day.from = s['from'] ?? day.from;
              day.to   = s['to']   ?? day.to;
            }
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save(String code) async {
    setState(() => _saving = true);
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      final langs = [
        if (_langHe) 'he',
        if (_langEn) 'en',
        if (_langRu) 'ru',
      ];
      final schedMap = { for (final d in _schedule) d.key: {
        'open': d.open, 'from': d.from, 'to': d.to,
      }};
      await http.put(
        Uri.parse('${AppConfig.baseUrl}/users/me'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
        body: jsonEncode({
          'is_available': _isAvailable,
          'whatsapp_number': _whatsappCtrl.text.trim(),
          'telegram_username': _telegramCtrl.text.trim(),
          'license_number': _licenseCtrl.text.trim(),
          'bar_association': _barCtrl.text.trim(),
          'response_minutes': _responseMinutes,
          'specializations': _specializations,
          'languages_spoken': langs,
          'schedule': schedMap,
          'settings': {
            'notifyEmergency': _notifyEmergency,
            'notifyNewCase': _notifyNewCase,
            'notifyUpdates': _notifyUpdates,
            'notifySms': _notifySms,
          },
        }),
      ).timeout(const Duration(seconds: 12));
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
            style: const TextStyle(color: VetoPalette.emergency, fontWeight: FontWeight.w700)),
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
            style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency),
            child: Text(_t(code, 'yes')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
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

  void _addSpec(String code) {
    final text = _specCtrl.text.trim();
    if (text.isEmpty || _specializations.contains(text)) return;
    setState(() {
      _specializations.add(text);
      _specCtrl.clear();
    });
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
        backgroundColor: VetoGlassTokens.bgBase,
        appBar: AppBar(
          backgroundColor: const Color(0x18FFFFFF),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: VetoGlassTokens.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_t(code, 'title'), style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _saving ? null : () => _save(code),
                style: FilledButton.styleFrom(
                  backgroundColor: VetoGlassTokens.neonBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_saving ? '...' : _t(code, 'save'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: VetoGlassTokens.glassBorder),
          ),
        ),
        body: VetoGlassAuroraBackground(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoGlassTokens.neonCyan))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Availability ──────────────────────────
                  _Section(
                    icon: Icons.toggle_on_rounded,
                    title: _t(code, 'availability'),
                    children: [
                      _ToggleTile(
                        label: _t(code, 'availableNow'),
                        subtitle: _t(code, 'availableDesc'),
                        icon: Icons.wifi_tethering_rounded,
                        color: VetoPalette.success,
                        value: _isAvailable,
                        onChanged: (v) => setState(() => _isAvailable = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Working Hours ─────────────────────────
                  _Section(
                    icon: Icons.schedule_rounded,
                    title: _t(code, 'schedule'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(_t(code, 'scheduleDesc'),
                            style: const TextStyle(color: VetoPalette.textMuted, fontSize: 13)),
                      ),
                      ..._schedule.map((day) => _ScheduleRow(
                            dayLabel: _t(code, day.key),
                            fromLabel: _t(code, 'from'),
                            toLabel: _t(code, 'to'),
                            closedLabel: _t(code, 'closed'),
                            schedule: day,
                            onChanged: () => setState(() {}),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Specializations ───────────────────────
                  _Section(
                    icon: Icons.workspace_premium_rounded,
                    title: _t(code, 'specializations'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(_t(code, 'specDesc'),
                            style: const TextStyle(color: VetoPalette.textMuted, fontSize: 13)),
                      ),
                      if (_specializations.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _specializations.map((s) => _SpecChip(
                              label: s,
                              onRemove: () => setState(() => _specializations.remove(s)),
                            )).toList(),
                          ),
                        ),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _specCtrl,
                            style: const TextStyle(color: VetoPalette.text, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: _t(code, 'addSpecHint'),
                              hintStyle: const TextStyle(color: VetoPalette.textMuted),
                              filled: true,
                              fillColor: VetoPalette.bg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: VetoPalette.border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: VetoPalette.border)),
                            ),
                            onSubmitted: (_) => _addSpec(code),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _addSpec(code),
                          style: FilledButton.styleFrom(backgroundColor: VetoPalette.primary),
                          child: Text(_t(code, 'add')),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Contact Links ─────────────────────────
                  _Section(
                    icon: Icons.contact_phone_rounded,
                    title: _t(code, 'contact'),
                    children: [
                      _FieldTile(
                        label: _t(code, 'whatsapp'),
                        hint: _t(code, 'whatsappHint'),
                        controller: _whatsappCtrl,
                        icon: Icons.chat_bubble_outline_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      _FieldTile(
                        label: _t(code, 'telegram'),
                        hint: _t(code, 'telegramHint'),
                        controller: _telegramCtrl,
                        icon: Icons.send_outlined,
                      ),
                      _SliderTile(
                        label: _t(code, 'responseTime'),
                        unit: _t(code, 'minutes'),
                        value: _responseMinutes,
                        min: 5, max: 120, divisions: 23,
                        onChanged: (v) => setState(() => _responseMinutes = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Languages ─────────────────────────────
                  _Section(
                    icon: Icons.translate_rounded,
                    title: _t(code, 'languages'),
                    children: [
                      _ToggleTile(
                        label: 'עברית',
                        icon: Icons.language_rounded,
                        color: VetoPalette.primary,
                        value: _langHe,
                        onChanged: (v) => setState(() => _langHe = v),
                      ),
                      _ToggleTile(
                        label: 'English',
                        icon: Icons.language_rounded,
                        color: VetoPalette.primary,
                        value: _langEn,
                        onChanged: (v) => setState(() => _langEn = v),
                      ),
                      _ToggleTile(
                        label: 'Русский',
                        icon: Icons.language_rounded,
                        color: VetoPalette.primary,
                        value: _langRu,
                        onChanged: (v) => setState(() => _langRu = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Notifications ─────────────────────────
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
                        label: _t(code, 'notifyNewCase'),
                        icon: Icons.folder_open_rounded,
                        color: VetoPalette.success,
                        value: _notifyNewCase,
                        onChanged: (v) => setState(() => _notifyNewCase = v),
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
                        color: VetoPalette.info,
                        value: _notifySms,
                        onChanged: (v) => setState(() => _notifySms = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── License ───────────────────────────────
                  _Section(
                    icon: Icons.verified_rounded,
                    title: _t(code, 'license'),
                    children: [
                      _FieldTile(
                        label: _t(code, 'licenseNumber'),
                        controller: _licenseCtrl,
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      _FieldTile(
                        label: _t(code, 'barAssociation'),
                        controller: _barCtrl,
                        icon: Icons.account_balance_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Account ───────────────────────────────
                  _Section(
                    icon: Icons.manage_accounts_rounded,
                    title: _t(code, 'account'),
                    children: [
                      _ActionTile(
                        label: _t(code, 'logout'),
                        icon: Icons.logout_rounded,
                        color: VetoPalette.textMuted,
                        onTap: () => _auth.logout(context),
                      ),
                      _ActionTile(
                        label: _t(code, 'deleteAccount'),
                        icon: Icons.delete_forever_rounded,
                        color: VetoPalette.emergency,
                        onTap: () => _deleteAccount(code),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _Section({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B8FFF).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF5B8FFF), size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.label, this.subtitle, required this.icon,
    required this.color, required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: VetoPalette.text,
                fontSize: 14, fontWeight: FontWeight.w500)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(color: VetoPalette.textMuted, fontSize: 11)),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: VetoPalette.primary,
        ),
      ]),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  const _FieldTile({
    required this.label, this.hint, required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: VetoPalette.textMuted, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: VetoPalette.textMuted,
              fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: VetoPalette.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: VetoPalette.textSubtle),
            filled: true,
            fillColor: VetoPalette.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoPalette.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoPalette.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoPalette.primary)),
          ),
        ),
      ]),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final String unit;
  final int value;
  final int min, max, divisions;
  final ValueChanged<int> onChanged;
  const _SliderTile({
    required this.label, required this.unit, required this.value,
    required this.min, required this.max, required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: VetoPalette.textMuted,
              fontSize: 13, fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: VetoPalette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$value $unit', style: const TextStyle(
                color: VetoPalette.primary, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ]),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          activeColor: VetoPalette.primary,
          onChanged: (v) => onChanged(v.round()),
        ),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _SpecChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: VetoPalette.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(
            color: VetoPalette.primary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 14, color: VetoPalette.primary),
        ),
      ]),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String dayLabel;
  final String fromLabel;
  final String toLabel;
  final String closedLabel;
  final _DaySchedule schedule;
  final VoidCallback onChanged;
  const _ScheduleRow({
    required this.dayLabel, required this.fromLabel,
    required this.toLabel, required this.closedLabel,
    required this.schedule, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 48,
          child: Text(dayLabel, style: const TextStyle(
              color: VetoPalette.text, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Switch(
          value: schedule.open,
          onChanged: (v) { schedule.open = v; onChanged(); },
          activeThumbColor: VetoPalette.success,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        if (!schedule.open)
          Expanded(
            child: Text(closedLabel, style: const TextStyle(
                color: VetoPalette.textMuted, fontSize: 12)),
          )
        else ...[
          const SizedBox(width: 4),
          _TimeDropdown(
            label: fromLabel,
            value: schedule.from,
            onChanged: (v) { schedule.from = v; onChanged(); },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('–', style: TextStyle(color: VetoPalette.textMuted)),
          ),
          _TimeDropdown(
            label: toLabel,
            value: schedule.to,
            onChanged: (v) { schedule.to = v; onChanged(); },
          ),
        ],
      ]),
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  static const _slots = [
    '06:00','07:00','08:00','09:00','10:00','11:00','12:00',
    '13:00','14:00','15:00','16:00','17:00','18:00','19:00',
    '20:00','21:00','22:00','23:00',
  ];

  const _TimeDropdown({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _slots.contains(value) ? value : _slots.first,
      dropdownColor: VetoPalette.surface,
      style: const TextStyle(color: VetoPalette.text, fontSize: 13),
      underline: const SizedBox(),
      items: _slots.map((t) => DropdownMenuItem(
        value: t,
        child: Text(t),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
