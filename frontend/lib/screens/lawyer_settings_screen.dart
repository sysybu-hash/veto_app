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
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

String _lsetDayShort(AppLocalizations l, String key) {
  switch (key) {
    case 'sun':
      return l.lsetSun;
    case 'mon':
      return l.lsetMon;
    case 'tue':
      return l.lsetTue;
    case 'wed':
      return l.lsetWed;
    case 'thu':
      return l.lsetThu;
    case 'fri':
      return l.lsetFri;
    case 'sat':
      return l.lsetSat;
    default:
      return key;
  }
}

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

  Future<void> _save() async {
    if (!mounted) return;
    final savedMsg = AppLocalizations.of(context)!.lsetSaved;
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
      _snack(savedMsg);
    } catch (_) {}
    finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: V26.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline)),
        title: Text(loc.lsetDeleteAccount,
            style: const TextStyle(color: V26.emerg, fontWeight: FontWeight.w700)),
        content: Text(loc.lsetDeleteConfirm,
            style: const TextStyle(color: V26.ink900)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.lsetNo,
                style: const TextStyle(color: V26.ink500)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: V26.emerg, foregroundColor: Colors.white),
            child: Text(loc.lsetYes),
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

  void _addSpec() {
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
      backgroundColor: V26.ok,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final l10n = AppLocalizations.of(context)!;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: V26.paper,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: V26.ink900, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(l10n.lsetTitle, style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w800, fontSize: 18)),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: VetoMockup.primaryCta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_saving ? '...' : l10n.lsetSave, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: V26.hairline),
          ),
        ),
        body: V26Backdrop(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoMockup.primaryCta))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Availability ──────────────────────────
                  _Section(
                    icon: Icons.toggle_on_rounded,
                    title: l10n.lsetAvailability,
                    children: [
                      _ToggleTile(
                        label: l10n.lsetAvailableNow,
                        subtitle: l10n.lsetAvailableDesc,
                        icon: Icons.wifi_tethering_rounded,
                        color: V26.ok,
                        value: _isAvailable,
                        onChanged: (v) => setState(() => _isAvailable = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Working Hours ─────────────────────────
                  _Section(
                    icon: Icons.schedule_rounded,
                    title: l10n.lsetSchedule,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(l10n.lsetScheduleDesc,
                            style: const TextStyle(color: V26.ink500, fontSize: 13)),
                      ),
                      ..._schedule.map((day) => _ScheduleRow(
                            dayLabel: _lsetDayShort(l10n, day.key),
                            fromLabel: l10n.lsetFrom,
                            toLabel: l10n.lsetTo,
                            closedLabel: l10n.lsetClosed,
                            schedule: day,
                            onChanged: () => setState(() {}),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Specializations ───────────────────────
                  _Section(
                    icon: Icons.workspace_premium_rounded,
                    title: l10n.lsetSpecializations,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(l10n.lsetSpecDesc,
                            style: const TextStyle(color: V26.ink500, fontSize: 13)),
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
                            style: const TextStyle(color: V26.ink900, fontSize: 14),
                            cursorColor: VetoMockup.primaryCta,
                            decoration: InputDecoration(
                              hintText: l10n.lsetAddSpecHint,
                              hintStyle: const TextStyle(color: V26.ink500),
                              filled: true,
                              fillColor: const Color(0xFF0F1A24),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: V26.hairline)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: V26.hairline)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  borderSide: BorderSide(
                                      color: VetoMockup.primaryCta, width: 1.5)),
                            ),
                            onSubmitted: (_) => _addSpec(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _addSpec,
                          style: FilledButton.styleFrom(
                            backgroundColor: VetoMockup.primaryCta,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.lsetAdd),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Contact Links ─────────────────────────
                  _Section(
                    icon: Icons.contact_phone_rounded,
                    title: l10n.lsetContact,
                    children: [
                      _FieldTile(
                        label: l10n.lsetWhatsapp,
                        hint: l10n.lsetWhatsappHint,
                        controller: _whatsappCtrl,
                        icon: Icons.chat_bubble_outline_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      _FieldTile(
                        label: l10n.lsetTelegram,
                        hint: l10n.lsetTelegramHint,
                        controller: _telegramCtrl,
                        icon: Icons.send_outlined,
                      ),
                      _SliderTile(
                        label: l10n.lsetResponseTime,
                        unit: l10n.lsetMinutes,
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
                    title: l10n.lsetLanguages,
                    children: [
                      _ToggleTile(
                        label: l10n.csetHebrew,
                        icon: Icons.language_rounded,
                        color: VetoMockup.primaryCta,
                        value: _langHe,
                        onChanged: (v) => setState(() => _langHe = v),
                      ),
                      _ToggleTile(
                        label: l10n.csetEnglish,
                        icon: Icons.language_rounded,
                        color: VetoMockup.primaryCta,
                        value: _langEn,
                        onChanged: (v) => setState(() => _langEn = v),
                      ),
                      _ToggleTile(
                        label: l10n.csetRussian,
                        icon: Icons.language_rounded,
                        color: VetoMockup.primaryCta,
                        value: _langRu,
                        onChanged: (v) => setState(() => _langRu = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Notifications ─────────────────────────
                  _Section(
                    icon: Icons.notifications_rounded,
                    title: l10n.lsetNotifications,
                    children: [
                      _ToggleTile(
                        label: l10n.lsetNotifyEmergency,
                        icon: Icons.warning_amber_rounded,
                        color: V26.emerg,
                        value: _notifyEmergency,
                        onChanged: (v) => setState(() => _notifyEmergency = v),
                      ),
                      _ToggleTile(
                        label: l10n.lsetNotifyNewCase,
                        icon: Icons.folder_open_rounded,
                        color: V26.ok,
                        value: _notifyNewCase,
                        onChanged: (v) => setState(() => _notifyNewCase = v),
                      ),
                      _ToggleTile(
                        label: l10n.lsetNotifyUpdates,
                        icon: Icons.update_rounded,
                        color: VetoMockup.primaryCta,
                        value: _notifyUpdates,
                        onChanged: (v) => setState(() => _notifyUpdates = v),
                      ),
                      _ToggleTile(
                        label: l10n.lsetNotifySms,
                        icon: Icons.sms_outlined,
                        color: VetoMockup.primaryCta,
                        value: _notifySms,
                        onChanged: (v) => setState(() => _notifySms = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── License ───────────────────────────────
                  _Section(
                    icon: Icons.verified_rounded,
                    title: l10n.lsetLicense,
                    children: [
                      _FieldTile(
                        label: l10n.lsetLicenseNumber,
                        controller: _licenseCtrl,
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      _FieldTile(
                        label: l10n.lsetBarAssociation,
                        controller: _barCtrl,
                        icon: Icons.account_balance_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Account ───────────────────────────────
                  _Section(
                    icon: Icons.manage_accounts_rounded,
                    title: l10n.lsetAccount,
                    children: [
                      _ActionTile(
                        label: l10n.lsetLogout,
                        icon: Icons.logout_rounded,
                        color: V26.ink500,
                        onTap: () => _auth.logout(context),
                      ),
                      _ActionTile(
                        label: l10n.lsetDeleteAccount,
                        icon: Icons.delete_forever_rounded,
                        color: V26.emerg,
                        onTap: _deleteAccount,
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
        color: V26.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: V26.hairline),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
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
                  color: VetoMockup.primaryCta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: VetoMockup.primaryCta, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: V26.ink900, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
          const Divider(height: 1, color: V26.hairline),
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
            Text(label, style: const TextStyle(color: V26.ink900,
                fontSize: 14, fontWeight: FontWeight.w500)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(color: V26.ink500, fontSize: 11)),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: VetoMockup.primaryCta,
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
          Icon(icon, color: V26.ink500, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: V26.ink500,
              fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          cursorColor: VetoMockup.primaryCta,
          style: const TextStyle(color: V26.ink900, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: V26.ink300),
            filled: true,
            fillColor: const Color(0xFF0F1A24),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: V26.hairline)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: V26.hairline)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(
                    color: VetoMockup.primaryCta, width: 1.5)),
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
          Text(label, style: const TextStyle(color: V26.ink500,
              fontSize: 13, fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: VetoMockup.primaryCta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$value $unit', style: const TextStyle(
                color: VetoMockup.primaryCta, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ]),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          activeColor: VetoMockup.primaryCta,
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
        color: VetoMockup.primaryCta.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VetoMockup.primaryCta.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(
            color: VetoMockup.primaryCta, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 14, color: VetoMockup.primaryCta),
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
              color: V26.ink900, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Switch(
          value: schedule.open,
          onChanged: (v) { schedule.open = v; onChanged(); },
          activeThumbColor: V26.ok,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        if (!schedule.open)
          Expanded(
            child: Text(closedLabel, style: const TextStyle(
                color: V26.ink500, fontSize: 12)),
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
            child: Text('–', style: TextStyle(color: V26.ink500)),
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
      dropdownColor: V26.surface,
      style: const TextStyle(color: V26.ink900, fontSize: 13),
      underline: const SizedBox(),
      items: _slots.map((t) => DropdownMenuItem(
        value: t,
        child: Text(t),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
