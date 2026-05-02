// ============================================================
//  LawyerSettingsScreen — VETO 2026
//  Tokens-aligned. Mockup reference: design_mockups/2026/lawyer.html
//  (settings section).
//
//  Sections:
//    Availability · Working hours · Specializations · Languages
//    Contact links · Notifications · License · Account
//
//  Behaviour preserved: GET/PUT /users/me with full schedule/spec/languages map.
// ============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_tokens_2026.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';

const _i18n = {
  'he': {
    'title': 'הגדרות עורך דין',
    'eyebrow': 'פרופיל מקצועי',
    'availability': 'זמינות',
    'availableNow': 'זמין לקבלת תיקים',
    'availableDesc': 'כשהוא פעיל, הלקוחות יוכלו לראות אותך ולשלוח בקשות',
    'schedule': 'שעות פעילות',
    'scheduleDesc': 'הגדר את שעות העבודה שלך לכל יום',
    'mon': 'שני', 'tue': 'שלישי', 'wed': 'רביעי', 'thu': 'חמישי', 'fri': 'שישי', 'sat': 'שבת', 'sun': 'ראשון',
    'from': 'מ', 'to': 'עד', 'closed': 'סגור', 'open': 'פתוח',
    'specializations': 'תחומי התמחות',
    'specDesc': 'הוסף עד 6 תחומי התמחות',
    'addSpec': 'הוסף התמחות',
    'addSpecHint': 'לדוגמה: דיני עבודה',
    'contact': 'קישורי יצירת קשר',
    'whatsapp': 'מספר WhatsApp', 'whatsappHint': '+972501234567',
    'telegram': 'שם משתמש Telegram', 'telegramHint': '@username',
    'responseTime': 'זמן מענה ממוצע',
    'minutes': 'דקות',
    'notifications': 'התראות',
    'notifyEmergency': 'התראות חירום (Push)',
    'notifyEmergencyDesc': 'בולט גם במצב מושתק',
    'notifyNewCase': 'תיק חדש',
    'notifyNewCaseDesc': 'התראה רכה לפני שאתה לוקח תיק',
    'notifyUpdates': 'עדכוני מערכת',
    'notifyUpdatesDesc': 'תחזוקה, עדכוני גרסה',
    'notifySms': 'SMS גיבוי',
    'notifySmsDesc': 'אם Push לא הגיע תוך 5 שניות',
    'license': 'פרטי רישיון',
    'licenseNumber': 'מספר רישיון',
    'barAssociation': 'לשכת עורכי הדין',
    'languages': 'שפות טיפול',
    'account': 'חשבון',
    'logout': 'התנתק',
    'deleteAccount': 'מחק חשבון לצמיתות',
    'deleteConfirm': 'מחיקת חשבון היא בלתי הפיכה.',
    'save': 'שמור שינויים',
    'saved': 'ההגדרות נשמרו',
    'cancel': 'ביטול', 'yes': 'כן', 'no': 'לא', 'add': 'הוסף',
    'badgeOn': 'פעיל', 'specsLeft': 'נותרו',
    'edit': 'ערוך',
    'editingFor': 'עריכת שעות',
  },
  'en': {
    'title': 'Lawyer Settings',
    'eyebrow': 'Professional profile',
    'availability': 'Availability',
    'availableNow': 'Available for cases',
    'availableDesc': 'When active, clients can find you and send requests',
    'schedule': 'Working hours',
    'scheduleDesc': 'Set your working hours per day',
    'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu', 'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun',
    'from': 'From', 'to': 'To', 'closed': 'Closed', 'open': 'Open',
    'specializations': 'Specializations',
    'specDesc': 'Add up to 6 areas of expertise',
    'addSpec': 'Add specialization',
    'addSpecHint': 'e.g. Labour law',
    'contact': 'Contact links',
    'whatsapp': 'WhatsApp number', 'whatsappHint': '+972501234567',
    'telegram': 'Telegram username', 'telegramHint': '@username',
    'responseTime': 'Avg. response time',
    'minutes': 'minutes',
    'notifications': 'Notifications',
    'notifyEmergency': 'Emergency push',
    'notifyEmergencyDesc': 'Visible even when muted',
    'notifyNewCase': 'New case',
    'notifyNewCaseDesc': 'Soft alert before accepting',
    'notifyUpdates': 'System updates',
    'notifyUpdatesDesc': 'Maintenance, releases',
    'notifySms': 'SMS backup',
    'notifySmsDesc': 'If push doesn\'t arrive within 5 seconds',
    'license': 'License',
    'licenseNumber': 'License number',
    'barAssociation': 'Bar association',
    'languages': 'Working languages',
    'account': 'Account',
    'logout': 'Sign out',
    'deleteAccount': 'Delete account permanently',
    'deleteConfirm': 'This action is irreversible.',
    'save': 'Save changes',
    'saved': 'Settings saved',
    'cancel': 'Cancel', 'yes': 'Yes', 'no': 'No', 'add': 'Add',
    'badgeOn': 'On', 'specsLeft': 'left',
    'edit': 'Edit',
    'editingFor': 'Edit hours',
  },
  'ru': {
    'title': 'Настройки адвоката',
    'eyebrow': 'Профессиональный профиль',
    'availability': 'Доступность',
    'availableNow': 'Готов принимать дела',
    'availableDesc': 'Когда включено, клиенты могут видеть вас и отправлять запросы',
    'schedule': 'Рабочие часы',
    'scheduleDesc': 'Установите часы по дням недели',
    'mon': 'Пн', 'tue': 'Вт', 'wed': 'Ср', 'thu': 'Чт', 'fri': 'Пт', 'sat': 'Сб', 'sun': 'Вс',
    'from': 'С', 'to': 'до', 'closed': 'Закрыто', 'open': 'Открыто',
    'specializations': 'Специализации',
    'specDesc': 'До 6 областей специализации',
    'addSpec': 'Добавить специализацию',
    'addSpecHint': 'напр. Трудовое право',
    'contact': 'Контактные ссылки',
    'whatsapp': 'Номер WhatsApp', 'whatsappHint': '+972501234567',
    'telegram': 'Telegram', 'telegramHint': '@username',
    'responseTime': 'Среднее время ответа',
    'minutes': 'минут',
    'notifications': 'Уведомления',
    'notifyEmergency': 'Экстренный Push',
    'notifyEmergencyDesc': 'Виден даже в беззвучном режиме',
    'notifyNewCase': 'Новое дело',
    'notifyNewCaseDesc': 'Мягкое уведомление',
    'notifyUpdates': 'Обновления системы',
    'notifyUpdatesDesc': 'Обслуживание, версии',
    'notifySms': 'Резервный SMS',
    'notifySmsDesc': 'Если push не пришёл за 5 секунд',
    'license': 'Лицензия',
    'licenseNumber': 'Номер лицензии',
    'barAssociation': 'Адвокатская палата',
    'languages': 'Рабочие языки',
    'account': 'Аккаунт',
    'logout': 'Выйти',
    'deleteAccount': 'Удалить аккаунт навсегда',
    'deleteConfirm': 'Это действие необратимо.',
    'save': 'Сохранить',
    'saved': 'Настройки сохранены',
    'cancel': 'Отмена', 'yes': 'Да', 'no': 'Нет', 'add': 'Добавить',
    'badgeOn': 'Вкл', 'specsLeft': 'осталось',
    'edit': 'Изменить',
    'editingFor': 'Изменить часы',
  },
};

String _t(String code, String key) => (_i18n[code] ?? _i18n['en']!)[key] ?? key;

// ── Model ─────────────────────────────────────────────────────
class _DaySchedule {
  final String key;
  bool open;
  String from;
  String to;
  _DaySchedule({required this.key, this.open = true, this.from = '09:00', this.to = '18:00'});
}

// ──────────────────────────────────────────────────────────
//  Screen
// ──────────────────────────────────────────────────────────
class LawyerSettingsScreen extends StatefulWidget {
  const LawyerSettingsScreen({super.key});

  @override
  State<LawyerSettingsScreen> createState() => _LawyerSettingsScreenState();
}

class _LawyerSettingsScreenState extends State<LawyerSettingsScreen> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  bool _saving = false;

  bool _isAvailable = true;

  final List<_DaySchedule> _schedule = [
    _DaySchedule(key: 'sun', open: true, from: '09:00', to: '18:00'),
    _DaySchedule(key: 'mon', open: true, from: '09:00', to: '18:00'),
    _DaySchedule(key: 'tue', open: true, from: '09:00', to: '18:00'),
    _DaySchedule(key: 'wed', open: true, from: '09:00', to: '18:00'),
    _DaySchedule(key: 'thu', open: true, from: '09:00', to: '18:00'),
    _DaySchedule(key: 'fri', open: false, from: '09:00', to: '14:00'),
    _DaySchedule(key: 'sat', open: false, from: '09:00', to: '14:00'),
  ];

  final List<String> _specializations = [];
  final _specCtrl = TextEditingController();

  bool _langHe = true;
  bool _langEn = false;
  bool _langRu = false;

  final _whatsappCtrl = TextEditingController();
  final _telegramCtrl = TextEditingController();
  int _responseMinutes = 30;

  bool _notifyEmergency = true;
  bool _notifyNewCase = true;
  bool _notifyUpdates = true;
  bool _notifySms = false;

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
              day.to = s['to'] ?? day.to;
            }
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save(String code) async {
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      final langs = [if (_langHe) 'he', if (_langEn) 'en', if (_langRu) 'ru'];
      final schedMap = {for (final d in _schedule) d.key: {'open': d.open, 'from': d.from, 'to': d.to}};
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
    finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount(String code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t(code, 'deleteAccount'), style: VetoTokens.titleLg.copyWith(color: VetoTokens.emerg)),
        content: Text(_t(code, 'deleteConfirm'), style: VetoTokens.bodyMd),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(code, 'no'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: VetoTokens.emerg, foregroundColor: Colors.white),
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
      ).timeout(const Duration(seconds: 12));
      if (mounted) await _auth.logout(context);
    } catch (_) {}
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: VetoTokens.bodyMd.copyWith(color: Colors.white)),
      backgroundColor: VetoTokens.ok,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _editTime(String code, _DaySchedule day) async {
    final from = await _pickTime(day.from);
    if (from == null || !mounted) return;
    final to = await _pickTime(day.to);
    if (to == null || !mounted) return;
    setState(() {
      day.from = from;
      day.to = to;
      day.open = true;
    });
  }

  Future<String?> _pickTime(String hhmm) async {
    final parts = hhmm.split(':');
    final initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  void _addSpec() {
    final v = _specCtrl.text.trim();
    if (v.isEmpty || _specializations.contains(v) || _specializations.length >= 6) return;
    setState(() {
      _specializations.add(v);
      _specCtrl.clear();
    });
  }

  void _removeSpec(String s) => setState(() => _specializations.remove(s));

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    String t(String k) => _t(code, k);

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoTokens.paper,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(t('title'), style: VetoTokens.titleLg),
          actions: [
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Center(child: AppLanguageMenu(compact: true))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: FilledButton(
                onPressed: _saving ? null : () => _save(code),
                style: FilledButton.styleFrom(
                  backgroundColor: VetoTokens.navy600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rSm)),
                  textStyle: VetoTokens.labelMd,
                ),
                child: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t('save')),
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t('eyebrow').toUpperCase(), style: VetoTokens.kicker),
                        const SizedBox(height: 4),
                        Text(t('title'), style: VetoTokens.headlineMd.copyWith(color: VetoTokens.ink900)),
                        const SizedBox(height: 24),

                        // Availability
                        _Section(
                          title: t('availability'),
                          sub: t('availableDesc'),
                          child: _RowToggle(
                            icon: Icons.power_settings_new_rounded,
                            title: t('availableNow'),
                            value: _isAvailable,
                            onChanged: (v) => setState(() => _isAvailable = v),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Schedule
                        _Section(
                          title: t('schedule'),
                          sub: t('scheduleDesc'),
                          child: _RowGroup(items: [
                            for (final day in _schedule) _ScheduleRow(
                              dayLabel: t(day.key),
                              from: day.from,
                              to: day.to,
                              isOpen: day.open,
                              closedLabel: t('closed'),
                              onToggle: (v) => setState(() => day.open = v),
                              onEdit: () => _editTime(code, day),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 22),

                        // Specializations
                        _Section(
                          title: t('specializations'),
                          sub: '${t('specDesc')} · ${6 - _specializations.length} ${t('specsLeft')}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_specializations.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: _specializations.map((s) => _Chip(label: s, onRemove: () => _removeSpec(s))).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(children: [
                                Expanded(
                                  child: TextField(
                                    controller: _specCtrl,
                                    decoration: InputDecoration(
                                      hintText: t('addSpecHint'),
                                      prefixIcon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: VetoTokens.ink500),
                                      filled: true,
                                      fillColor: VetoTokens.surface2,
                                    ),
                                    onSubmitted: (_) => _addSpec(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton(
                                  onPressed: _specializations.length >= 6 ? null : _addSpec,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: VetoTokens.navy600,
                                    minimumSize: const Size(0, 48),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rSm)),
                                    textStyle: VetoTokens.labelMd,
                                  ),
                                  child: Text(t('add')),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Languages
                        _Section(
                          title: t('languages'),
                          child: _RowGroup(items: [
                            _RowToggle(
                              icon: Icons.translate_rounded,
                              title: 'עברית · Hebrew',
                              value: _langHe,
                              onChanged: (v) => setState(() => _langHe = v),
                            ),
                            _RowToggle(
                              icon: Icons.translate_rounded,
                              title: 'English',
                              value: _langEn,
                              onChanged: (v) => setState(() => _langEn = v),
                            ),
                            _RowToggle(
                              icon: Icons.translate_rounded,
                              title: 'Русский',
                              value: _langRu,
                              onChanged: (v) => setState(() => _langRu = v),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 22),

                        // Contact links
                        _Section(
                          title: t('contact'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LabelledField(label: t('whatsapp'), hint: t('whatsappHint'), controller: _whatsappCtrl, icon: Icons.message_rounded, ltr: true),
                              const SizedBox(height: 12),
                              _LabelledField(label: t('telegram'), hint: t('telegramHint'), controller: _telegramCtrl, icon: Icons.send_rounded, ltr: true),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
                                child: Row(children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(color: VetoTokens.paper2, border: Border.all(color: VetoTokens.hairline), borderRadius: BorderRadius.circular(10)),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.timer_outlined, size: 16, color: VetoTokens.navy600),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(t('responseTime'), style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900))),
                                  IconButton(onPressed: _responseMinutes <= 5 ? null : () => setState(() => _responseMinutes -= 5), icon: const Icon(Icons.remove_rounded, size: 16)),
                                  Text('$_responseMinutes ${t('minutes')}', style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
                                  IconButton(onPressed: _responseMinutes >= 120 ? null : () => setState(() => _responseMinutes += 5), icon: const Icon(Icons.add_rounded, size: 16)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Notifications
                        _Section(
                          title: t('notifications'),
                          child: _RowGroup(items: [
                            _RowToggle(icon: Icons.notifications_active_outlined, title: t('notifyEmergency'), desc: t('notifyEmergencyDesc'), value: _notifyEmergency, onChanged: (v) => setState(() => _notifyEmergency = v)),
                            _RowToggle(icon: Icons.add_alert_outlined, title: t('notifyNewCase'), desc: t('notifyNewCaseDesc'), value: _notifyNewCase, onChanged: (v) => setState(() => _notifyNewCase = v)),
                            _RowToggle(icon: Icons.system_update_alt_rounded, title: t('notifyUpdates'), desc: t('notifyUpdatesDesc'), value: _notifyUpdates, onChanged: (v) => setState(() => _notifyUpdates = v)),
                            _RowToggle(icon: Icons.sms_outlined, title: t('notifySms'), desc: t('notifySmsDesc'), value: _notifySms, onChanged: (v) => setState(() => _notifySms = v)),
                          ]),
                        ),
                        const SizedBox(height: 22),

                        // License
                        _Section(
                          title: t('license'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LabelledField(label: t('licenseNumber'), controller: _licenseCtrl, icon: Icons.numbers_rounded),
                              const SizedBox(height: 12),
                              _LabelledField(label: t('barAssociation'), controller: _barCtrl, icon: Icons.account_balance_rounded),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Account
                        _Section(
                          title: t('account'),
                          child: Wrap(
                            spacing: 10, runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _auth.logout(context),
                                icon: const Icon(Icons.logout_rounded, size: 14),
                                label: Text(t('logout')),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: VetoTokens.ink700,
                                  side: const BorderSide(color: VetoTokens.hairline, width: 1),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rSm)),
                                  textStyle: VetoTokens.labelMd,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _deleteAccount(code),
                                icon: const Icon(Icons.delete_outline_rounded, size: 14),
                                label: Text(t('deleteAccount')),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: VetoTokens.emerg,
                                  side: const BorderSide(color: Color(0xFFF4C7BD), width: 1),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rSm)),
                                  textStyle: VetoTokens.labelMd,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Sub-widgets
// ──────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  const _Section({required this.title, this.sub, required this.child});
  final String title;
  final String? sub;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: VetoTokens.serif(20, FontWeight.w800, color: VetoTokens.ink900)),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub!, style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500)),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _RowGroup extends StatelessWidget {
  const _RowGroup({required this.items});
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VetoTokens.rMd),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              items[i],
              if (i < items.length - 1) const Divider(height: 1, thickness: 1, color: VetoTokens.hairline),
            ]
          ],
        ),
      ),
    );
  }
}

class _RowToggle extends StatelessWidget {
  const _RowToggle({required this.icon, required this.title, this.desc, required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final String? desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: VetoTokens.paper2, border: Border.all(color: VetoTokens.hairline), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: VetoTokens.navy600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
                if (desc != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(desc!, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500))),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: Colors.white, activeTrackColor: VetoTokens.ok),
        ]),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.dayLabel, required this.from, required this.to, required this.isOpen, required this.closedLabel, required this.onToggle, required this.onEdit});
  final String dayLabel, from, to, closedLabel;
  final bool isOpen;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(children: [
        SizedBox(
          width: 60,
          child: Text(dayLabel, style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isOpen ? '$from — $to' : closedLabel,
            style: VetoTokens.bodyMd.copyWith(color: isOpen ? VetoTokens.ink700 : VetoTokens.ink300, fontWeight: FontWeight.w600),
          ),
        ),
        Switch.adaptive(value: isOpen, onChanged: onToggle, activeThumbColor: Colors.white, activeTrackColor: VetoTokens.ok),
        IconButton(
          onPressed: isOpen ? onEdit : null,
          icon: const Icon(Icons.edit_outlined, size: 16),
          color: VetoTokens.navy600,
          style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
        ),
      ]),
    );
  }
}

class _LabelledField extends StatelessWidget {
  const _LabelledField({required this.label, this.hint, required this.controller, this.icon, this.ltr = false});
  final String label;
  final String? hint;
  final TextEditingController controller;
  final IconData? icon;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VetoTokens.sans(12, FontWeight.w700, color: VetoTokens.ink700, letterSpacing: 0.4)),
        const SizedBox(height: 6),
        Directionality(
          textDirection: ltr ? TextDirection.ltr : Directionality.of(context),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon == null ? null : Icon(icon, size: 16, color: VetoTokens.ink500),
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: VetoTokens.navy100,
        borderRadius: BorderRadius.circular(VetoTokens.rPill),
        border: Border.all(color: const Color(0xFFC4D4F4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: VetoTokens.sans(12, FontWeight.w700, color: VetoTokens.navy700)),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close_rounded, size: 14, color: VetoTokens.navy700),
            ),
          ),
        ],
      ),
    );
  }
}
