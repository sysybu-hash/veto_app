// ============================================================
//  WizardShellScreen — VETO 2026
//  Tokens-aligned with design_mockups/2026/_veto-2026.css.
//
//  This screen is the live "4-stage" wizard (NOT the onboarding wizard from
//  the mockup index — that route name belongs here historically). It hosts:
//    • Citizen variant: protect status → emergency trigger → evidence → account
//    • Lawyer  variant: availability → incoming alerts → handling → account
//
//  Behaviour preserved verbatim from legacy:
//    - SocketService subscriptions (alert / dispatched / lawyerFound /
//      sessionReady / noLawyers / caseTaken)
//    - Geolocator-based emergency trigger
//    - Citizen-choice session picker (audio / video / chat) via bottom sheet
// ============================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_tokens_2026.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';

class WizardShellScreen extends StatefulWidget {
  const WizardShellScreen({super.key});

  @override
  State<WizardShellScreen> createState() => _WizardShellScreenState();
}

class _WizardShellScreenState extends State<WizardShellScreen> {
  final SocketService _socket = SocketService();

  String _role = 'user';
  String _name = '';
  String _phone = '';
  String _langCode = 'he';
  bool _isBusy = false;
  bool _isAvailable = true;
  int _wizardIndex = 0;
  final List<Map<String, dynamic>> _alerts = [];

  StreamSubscription<Map<String, dynamic>>? _alertSub;
  StreamSubscription<Map<String, dynamic>>? _dispatchSub;
  StreamSubscription<Map<String, dynamic>>? _lawyerFoundSub;
  StreamSubscription<Map<String, dynamic>>? _noLawyersSub;
  StreamSubscription<Map<String, dynamic>>? _caseTakenSub;
  StreamSubscription<Map<String, dynamic>>? _sessionReadySub;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = AuthService();
    final role = await auth.getStoredRole() ?? 'user';
    final name = await auth.getStoredName() ?? '';
    final phone = await auth.getStoredPhone() ?? '';
    final lang = AppLanguage.normalize(await auth.getStoredPreferredLanguage());

    if (!mounted) return;
    final controller = context.read<AppLanguageController>();
    if (controller.code != lang) {
      await controller.setLanguage(lang, persist: false);
    }

    setState(() {
      _role = role;
      _name = name;
      _phone = phone;
      _langCode = lang;
    });

    await _socket.connect(role: role);
    _socket.emit('lawyer_availability', {'available': _isAvailable});

    _alertSub = _socket.onNewEmergencyAlert.listen((data) {
      if (!mounted) return;
      setState(() => _alerts.add(data));
    });

    _dispatchSub = _socket.onVetoDispatched.listen((_) {
      if (!mounted) return;
      setState(() {
        _isBusy = true;
        _wizardIndex = 1;
      });
    });

    _lawyerFoundSub = _socket.onLawyerFound.listen((data) {
      if (!mounted) return;
      final awaiting = data['awaitingCitizenChoice'] == true;
      if (awaiting) {
        unawaited(_showWizardSessionPicker(data));
        return;
      }
      setState(() {
        _isBusy = false;
        _wizardIndex = 2;
      });
      final foundName = data['lawyerName']?.toString() ??
          (_langCode == 'ru' ? 'Адвокат' : _langCode == 'en' ? 'Lawyer' : 'עורך דין');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _langCode == 'ru' ? 'Адвокат подключен: $foundName'
                : _langCode == 'en' ? 'Lawyer connected: $foundName'
                : 'עורך דין התחבר: $foundName',
          ),
        ),
      );
    });

    _sessionReadySub = _socket.onSessionReady.listen((data) {
      final roomId = data['roomId']?.toString();
      if (!mounted || roomId == null || roomId.isEmpty) return;
      setState(() {
        _isBusy = false;
        _wizardIndex = 2;
      });
      Navigator.of(context).pushNamed(
        '/call',
        arguments: {
          'roomId': roomId,
          'callType': data['callType']?.toString() ?? 'video',
          'peerName': data['peerName']?.toString() ?? (_langCode == 'he' ? 'עורך דין' : 'Lawyer'),
          'role': _role == 'admin' ? 'admin' : 'user',
          'eventId': data['eventId']?.toString() ?? roomId,
          'language': _langCode,
          'agoraToken': data['agoraToken']?.toString() ?? '',
          'agoraUid': data['agoraUid'],
        },
      );
    });

    _noLawyersSub = _socket.onNoLawyersAvailable.listen((_) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _wizardIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _langCode == 'ru' ? 'Сейчас нет доступных адвокатов. Попробуйте снова чуть позже.'
                : _langCode == 'en' ? 'No lawyers are available right now. Please try again shortly.'
                : 'אין כרגע עורכי דין זמינים. נסה שוב בעוד רגע.',
          ),
        ),
      );
    });

    if (role == 'lawyer') {
      _caseTakenSub = _socket.onCaseTaken.listen((data) {
        final eventId = data['eventId']?.toString();
        if (!mounted || eventId == null) return;
        setState(() => _alerts.removeWhere((a) => a['eventId']?.toString() == eventId));
      });
    }
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _dispatchSub?.cancel();
    _lawyerFoundSub?.cancel();
    _noLawyersSub?.cancel();
    _caseTakenSub?.cancel();
    _sessionReadySub?.cancel();
    super.dispose();
  }

  Future<void> _showWizardSessionPicker(Map<String, dynamic> data) async {
    final eventId = data['eventId']?.toString();
    final lawyerName = data['lawyerName']?.toString() ??
        (_langCode == 'ru' ? 'Адвокат' : _langCode == 'en' ? 'Lawyer' : 'עורך דין');
    if (eventId == null || eventId.isEmpty) return;

    final lang = _langCode;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(VetoTokens.r2Xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: VetoTokens.hairline2, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            Text(
              lang == 'he' ? '$lawyerName קיבל את הקריאה' : '$lawyerName accepted',
              style: VetoTokens.titleLg.copyWith(color: VetoTokens.ink900),
            ),
            const SizedBox(height: 6),
            Text(
              lang == 'he' ? 'בחר מצב שיחה' : 'Choose a session mode',
              style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _modeBtn(ctx, Icons.mic_rounded, lang == 'he' ? 'אודיו' : 'Audio', 'audio')),
                const SizedBox(width: 8),
                Expanded(child: _modeBtn(ctx, Icons.videocam_rounded, lang == 'he' ? 'וידאו' : 'Video', 'video')),
                const SizedBox(width: 8),
                Expanded(child: _modeBtn(ctx, Icons.chat_outlined, lang == 'he' ? 'צ\'אט' : 'Chat', 'chat')),
              ],
            ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      _socket.emitCitizenChoseSession(eventId: eventId, callType: chosen);
    }
  }

  Widget _modeBtn(BuildContext ctx, IconData icon, String label, String value) {
    return OutlinedButton(
      onPressed: () => Navigator.pop(ctx, value),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: VetoTokens.hairline, width: 1),
        backgroundColor: Colors.white,
        foregroundColor: VetoTokens.navy700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rMd)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: VetoTokens.navy600),
          const SizedBox(height: 6),
          Text(label, style: VetoTokens.labelMd),
        ],
      ),
    );
  }

  Future<void> _triggerEmergency() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _wizardIndex = 1;
    });

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {
      // Location failure keeps fallback coordinates for uninterrupted flow.
    }

    _socket.emitStartVeto(
      lat: pos?.latitude ?? 32.08088,
      lng: pos?.longitude ?? 34.78057,
      preferredLanguage: _langCode,
    );
  }

  void _acceptAlert(Map<String, dynamic> alert) {
    final eventId = alert['eventId']?.toString();
    if (eventId == null || eventId.isEmpty) return;
    _socket.emit('accept_case', {'eventId': eventId});
    setState(() {
      _alerts.removeWhere((a) => a['eventId'] == eventId);
      _isAvailable = false;
      _wizardIndex = 2;
    });
    _socket.emit('lawyer_availability', {'available': false});
  }

  void _rejectAlert(Map<String, dynamic> alert) {
    final eventId = alert['eventId']?.toString();
    if (eventId == null || eventId.isEmpty) return;
    _socket.emit('reject_case', {'eventId': eventId});
    setState(() => _alerts.removeWhere((a) => a['eventId'] == eventId));
  }

  // ── Localised stage labels (preserved verbatim) ──
  List<String> _stageLabels() {
    if (_role == 'lawyer') {
      switch (_langCode) {
        case 'en': return const ['Availability', 'Alerts', 'Handling', 'Closure'];
        case 'ru': return const ['Доступность', 'Запросы', 'Работа', 'Закрытие'];
        default:   return const ['זמינות', 'התראות', 'טיפול', 'סגירה'];
      }
    }
    switch (_langCode) {
      case 'en': return const ['Protection', 'Dispatch', 'Match', 'Manage'];
      case 'ru': return const ['Защита', 'Вызов', 'Совпадение', 'Управление'];
      default:   return const ['הגנה', 'שידור', 'התאמה', 'ניהול'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLanguage.directionOf(_langCode),
      child: Scaffold(
        backgroundColor: VetoTokens.paper,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 820;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 16, compact ? 16 : 28, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _topBar(compact),
                      const SizedBox(height: 14),
                      _stageBar(),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: VetoTokens.durBase,
                        child: _role == 'lawyer' ? _lawyerView(compact) : _citizenView(compact),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Topbar ───────────────────────────────────────────
  Widget _topBar(bool compact) {
    final displayName = _name.isNotEmpty
        ? _name
        : (_role == 'lawyer'
            ? (_langCode == 'ru' ? 'Адвокат' : _langCode == 'en' ? 'Lawyer' : 'עורך דין')
            : (_langCode == 'ru' ? 'Пользователь' : _langCode == 'en' ? 'User' : 'משתמש'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: VetoTokens.cardDecoration(),
      child: Row(
        children: [
          // Crest
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: VetoTokens.crestGradient,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0x1FFFFFFF), width: 1),
            ),
            alignment: Alignment.center,
            child: Text('V', style: VetoTokens.serif(18, FontWeight.w900, color: Colors.white, height: 1.0)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VETO',
                    style: VetoTokens.serif(16, FontWeight.w900, color: VetoTokens.ink900, letterSpacing: 1.6)),
                Text(
                  _phone.isEmpty ? displayName : '$displayName · $_phone',
                  style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!compact) ...[
            _RoleBadge(role: _role),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: _langCode == 'he' ? 'פרופיל' : 'Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.account_circle_outlined, size: 20, color: VetoTokens.ink700),
          ),
          if (_role == 'admin')
            IconButton(
              tooltip: _langCode == 'he' ? 'ניהול' : 'Admin',
              onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 20, color: VetoTokens.ink700),
            ),
          IconButton(
            tooltip: _langCode == 'he' ? 'התנתק' : 'Log out',
            onPressed: () => AuthService().logout(context),
            icon: const Icon(Icons.logout_rounded, size: 20, color: VetoTokens.emerg),
          ),
        ],
      ),
    );
  }

  // ── Stage bar (4 cells with progress accents) ───────
  Widget _stageBar() {
    final labels = _stageLabels();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: VetoTokens.cardDecoration(),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= _wizardIndex;
          final isCurrent = index == _wizardIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: index == labels.length - 1 ? 0 : 8),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 3,
                    decoration: BoxDecoration(
                      color: active
                          ? (isCurrent ? VetoTokens.navy600 : VetoTokens.navy300)
                          : VetoTokens.hairline,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: VetoTokens.sans(
                      11,
                      active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? VetoTokens.ink900 : VetoTokens.ink300,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Citizen view ─────────────────────────────────────
  Widget _citizenView(bool compact) {
    final isHe = _langCode == 'he';
    return Column(
      key: const ValueKey('citizen'),
      children: [
        _Panel(
          step: '01',
          title: isHe ? 'מצב הגנה' : (_langCode == 'ru' ? 'Состояние защиты' : 'Protection status'),
          subtitle: isHe ? 'מבט מהיר על סטטוס המערכת שלך' : (_langCode == 'ru' ? 'Быстрый обзор статуса системы' : 'Quick view of your system status'),
          child: Row(children: [
            _StatusBadge(busy: _isBusy, lang: _langCode),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isBusy
                    ? (isHe ? 'קריאה כבר בתהליך, המערכת עוקבת אחרי תגובת עורכי דין.'
                        : _langCode == 'ru' ? 'Запрос в процессе, система отслеживает ответ адвокатов.'
                        : 'A request is in progress; the system is tracking lawyer response.')
                    : (isHe ? 'מוכן להפעלה. בלחיצה אחת תצא קריאת חירום מלאה.'
                        : _langCode == 'ru' ? 'Готово. Одно нажатие — и запрос пойдёт.'
                        : 'Ready. One tap launches a full emergency request.'),
                style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink700),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _Panel(
          step: '02',
          title: isHe ? 'שידור חירום' : (_langCode == 'ru' ? 'Запуск экстренного' : 'Emergency dispatch'),
          subtitle: isHe ? 'כפתור אחד, פעולה אחת, אפס בלבול' : (_langCode == 'ru' ? 'Одна кнопка, одно действие.' : 'One button, one action, zero confusion.'),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isBusy ? null : _triggerEmergency,
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: Text(_isBusy
                  ? (isHe ? 'שידור פעיל...' : _langCode == 'ru' ? 'Запрос идёт...' : 'Dispatching...')
                  : (isHe ? 'הפעל VETO עכשיו' : _langCode == 'ru' ? 'Запустить VETO' : 'Trigger VETO now')),
              style: FilledButton.styleFrom(
                backgroundColor: VetoTokens.emerg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rMd)),
                textStyle: VetoTokens.labelLg,
              ).copyWith(elevation: WidgetStateProperty.all(0)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          step: '03',
          title: isHe ? 'תיעוד מתקדם' : (_langCode == 'ru' ? 'Расширенная фиксация' : 'Advanced documentation'),
          subtitle: isHe ? 'גישה מהירה למסך התיעוד הקיים' : (_langCode == 'ru' ? 'Быстрый доступ к экрану фиксации' : 'Quick access to the evidence surface'),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/veto_screen'),
              icon: const Icon(Icons.perm_camera_mic_outlined, size: 16),
              label: Text(isHe ? 'פתח סביבת חירום' : _langCode == 'ru' ? 'Открыть' : 'Open emergency surface'),
              style: OutlinedButton.styleFrom(
                foregroundColor: VetoTokens.navy600,
                side: const BorderSide(color: VetoTokens.navy300, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rMd)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: VetoTokens.labelMd,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _accountPanel(isHe),
      ],
    );
  }

  // ── Lawyer view ──────────────────────────────────────
  Widget _lawyerView(bool compact) {
    final isHe = _langCode == 'he';
    return Column(
      key: const ValueKey('lawyer'),
      children: [
        _Panel(
          step: '01',
          title: isHe ? 'זמינות' : (_langCode == 'ru' ? 'Доступность' : 'Availability'),
          subtitle: isHe ? 'שליטה מלאה בזרימת תיקים נכנסים' : (_langCode == 'ru' ? 'Полный контроль над входящими' : 'Full control over inbound cases'),
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.white,
            activeTrackColor: VetoTokens.ok,
            title: Text(
              _isAvailable
                  ? (isHe ? 'זמין לקריאות' : _langCode == 'ru' ? 'На связи' : 'On-call')
                  : (isHe ? 'לא זמין כרגע' : _langCode == 'ru' ? 'Пауза' : 'Standby'),
              style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900),
            ),
            subtitle: Text(
              _isAvailable ? 'On-call active' : 'Standby mode',
              style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500),
            ),
            value: _isAvailable,
            onChanged: (v) {
              setState(() {
                _isAvailable = v;
                _wizardIndex = 0;
              });
              _socket.emit('lawyer_availability', {'available': v});
            },
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          step: '02',
          title: isHe ? 'התראות פעילות' : (_langCode == 'ru' ? 'Активные запросы' : 'Active alerts'),
          subtitle: isHe ? 'קבל או דחה תיקים בלחיצה מהירה' : (_langCode == 'ru' ? 'Принимайте или отклоняйте' : 'Accept or reject in one tap'),
          child: _alerts.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: VetoTokens.surface2,
                    border: Border.all(color: VetoTokens.hairline, width: 1),
                    borderRadius: BorderRadius.circular(VetoTokens.rMd),
                  ),
                  child: Row(children: [
                    const Icon(Icons.inbox_outlined, color: VetoTokens.ink300, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(isHe ? 'אין כרגע התראות פעילות' : _langCode == 'ru' ? 'Активных запросов нет' : 'No active alerts',
                        style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500))),
                  ]),
                )
              : Column(children: _alerts.map((a) => _AlertCard(alert: a, onAccept: () => _acceptAlert(a), onReject: () => _rejectAlert(a), lang: _langCode)).toList()),
        ),
        const SizedBox(height: 12),
        _Panel(
          step: '03',
          title: isHe ? 'טיפול בתיק' : (_langCode == 'ru' ? 'Работа с делом' : 'Case handling'),
          subtitle: isHe ? 'מעבר אוטומטי לסטטוס עסוק לאחר קבלה' : (_langCode == 'ru' ? 'Авто-переход в "занят"' : 'Auto-busy after acceptance'),
          child: Text(
            _isAvailable
                ? (isHe ? 'אין תיק פעיל כרגע' : _langCode == 'ru' ? 'Нет активного дела' : 'No active case')
                : (isHe ? 'סטטוס עסוק - תיק בטיפול' : _langCode == 'ru' ? 'Занят — дело в работе' : 'Busy — case in handling'),
            style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink700),
          ),
        ),
        const SizedBox(height: 12),
        _accountPanel(isHe),
      ],
    );
  }

  Widget _accountPanel(bool isHe) {
    final lang = _langCode;
    return _Panel(
      step: '04',
      title: isHe ? 'פעולות חשבון' : (lang == 'ru' ? 'Действия аккаунта' : 'Account actions'),
      subtitle: isHe ? 'פרופיל, ניהול, ויציאה בטוחה' : (lang == 'ru' ? 'Профиль и выход' : 'Profile, admin, sign out'),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.person_outline_rounded, size: 14),
            label: Text(isHe ? 'פרופיל' : lang == 'ru' ? 'Профиль' : 'Profile'),
            style: _ghostStyle(),
          ),
          if (_role == 'admin')
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 14),
              label: Text(isHe ? 'ניהול מערכת' : lang == 'ru' ? 'Админ' : 'Admin'),
              style: _ghostStyle(),
            ),
          OutlinedButton.icon(
            onPressed: () => AuthService().logout(context),
            icon: const Icon(Icons.logout_rounded, size: 14),
            label: Text(isHe ? 'התנתק' : lang == 'ru' ? 'Выход' : 'Sign out'),
            style: _ghostStyle().copyWith(
              foregroundColor: WidgetStateProperty.all(VetoTokens.emerg),
              side: WidgetStateProperty.all(const BorderSide(color: Color(0xFFF4C7BD), width: 1)),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _ghostStyle() => OutlinedButton.styleFrom(
        foregroundColor: VetoTokens.ink700,
        side: const BorderSide(color: VetoTokens.hairline, width: 1),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rSm)),
        textStyle: VetoTokens.labelMd,
      );
}

// ──────────────────────────────────────────────────────────
//  Sub-widgets
// ──────────────────────────────────────────────────────────
class _Panel extends StatelessWidget {
  const _Panel({required this.step, required this.title, required this.subtitle, required this.child});
  final String step, title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: VetoTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(step, style: VetoTokens.serif(28, FontWeight.w900, color: VetoTokens.navy600.withValues(alpha: 0.18), height: 1.0)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: VetoTokens.serif(18, FontWeight.w700, color: VetoTokens.ink900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = role == 'lawyer'
        ? (VetoTokens.infoSoft, VetoTokens.navy700, const Color(0xFFC4D4F4))
        : role == 'admin'
            ? (VetoTokens.goldSoft, VetoTokens.goldDeep, const Color(0xFFD4BB99))
            : (VetoTokens.okSoft, const Color(0xFF16664B), const Color(0xFFB7DFCB));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(VetoTokens.rPill), border: Border.all(color: border, width: 1)),
      child: Text(role.toUpperCase(), style: VetoTokens.sans(11, FontWeight.w800, color: fg, letterSpacing: 0.4)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.busy, required this.lang});
  final bool busy;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final isHe = lang == 'he';
    final label = busy
        ? (isHe ? 'שידור פעיל' : lang == 'ru' ? 'Идёт' : 'Live')
        : (isHe ? 'מוגן' : lang == 'ru' ? 'Защищено' : 'Protected');
    final (bg, fg, border, dot) = busy
        ? (VetoTokens.warnSoft, const Color(0xFF7A5300), const Color(0xFFF2D58E), VetoTokens.warn)
        : (VetoTokens.okSoft, const Color(0xFF16664B), const Color(0xFFB7DFCB), VetoTokens.ok);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(VetoTokens.rPill),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: VetoTokens.sans(11, FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onAccept, required this.onReject, required this.lang});
  final Map<String, dynamic> alert;
  final VoidCallback onAccept, onReject;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final isHe = lang == 'he';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(VetoTokens.rMd),
        border: const Border(
          left: BorderSide(color: VetoTokens.warn, width: 3),
          top: BorderSide(color: VetoTokens.hairline),
          right: BorderSide(color: VetoTokens.hairline),
          bottom: BorderSide(color: VetoTokens.hairline),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: VetoTokens.warnSoft, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: const Icon(Icons.notification_important_outlined, size: 16, color: VetoTokens.warn),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isHe
                  ? 'קריאה #${alert['eventId'] ?? 'N/A'}'
                  : lang == 'ru'
                      ? 'Запрос #${alert['eventId'] ?? 'N/A'}'
                      : 'Request #${alert['eventId'] ?? 'N/A'}',
              style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900),
            ),
          ),
          IconButton(
            tooltip: isHe ? 'דחה' : 'Reject',
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded, color: VetoTokens.emerg, size: 18),
            style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check_rounded, size: 14),
            label: Text(isHe ? 'קבל' : lang == 'ru' ? 'Принять' : 'Accept'),
            style: FilledButton.styleFrom(
              backgroundColor: VetoTokens.ok,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rSm)),
              textStyle: VetoTokens.labelMd,
            ),
          ),
        ],
      ),
    );
  }
}
