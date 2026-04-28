import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/future_surface.dart';
import '../../core/theme/veto_glass_system.dart';
import '../../core/theme/veto_theme.dart';
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
    final lang = AppLanguage.normalize(
      await auth.getStoredPreferredLanguage(),
    );

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
          (_langCode == 'ru'
              ? 'Адвокат'
              : _langCode == 'en'
                  ? 'Lawyer'
                  : 'עורך דין');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_langCode == 'ru'
              ? 'Адвокат подключен: $foundName'
              : _langCode == 'en'
                  ? 'Lawyer connected: $foundName'
                  : 'עורך דין התחבר: $foundName'),
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
          'peerName': data['peerName']?.toString() ??
              (_langCode == 'he' ? 'עורך דין' : 'Lawyer'),
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
          content: Text(_langCode == 'ru'
              ? 'Сейчас нет доступных адвокатов. Попробуйте снова чуть позже.'
              : _langCode == 'en'
                  ? 'No lawyers are available right now. Please try again shortly.'
                  : 'אין כרגע עורכי דין זמינים. נסה שוב בעוד רגע.'),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: VetoGlassBlur(
          borderRadius: 20,
          sigma: 20,
          fill: VetoGlassTokens.glassFillStrong,
          borderColor: VetoGlassTokens.glassBorderBright,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang == 'he'
                    ? '$lawyerName קיבל את הקריאה'
                    : '$lawyerName accepted',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: VetoGlassTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, 'audio'),
                      child: Text(lang == 'he' ? 'אודיו' : 'Audio'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, 'video'),
                      child: Text(lang == 'he' ? 'וידאו' : 'Video'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, 'chat'),
                      child: Text(lang == 'he' ? 'צ\'ט' : 'Chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
    if (chosen != null && mounted) {
      _socket.emitCitizenChoseSession(eventId: eventId, callType: chosen);
    }
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLanguage.directionOf(_langCode),
      child: Scaffold(
        backgroundColor: VetoGlassTokens.bgBase,
        body: VetoGlassAuroraBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 820;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: Column(
                    children: [
                      _topBar(compact),
                      const SizedBox(height: 10),
                      _wizardHeader(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: _role == 'lawyer'
                              ? _lawyerWizard(compact)
                              : _userWizard(compact),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(bool compact) {
    final displayName =
      _name.isNotEmpty
        ? _name
        : (_role == 'lawyer'
          ? (_langCode == 'ru'
            ? 'Адвокат'
            : _langCode == 'en'
              ? 'Lawyer'
              : 'עורך דין')
          : (_langCode == 'ru'
            ? 'Пользователь'
            : _langCode == 'en'
              ? 'User'
              : 'משתמש'));

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: VetoGlassTokens.neonCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: VetoGlassTokens.neonCyan.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.gavel_rounded,
                color: VetoGlassTokens.neonCyan, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VETO',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: VetoGlassTokens.textPrimary),
                ),
                Text(
                  _phone.isEmpty ? displayName : '$displayName | $_phone',
                  style: const TextStyle(
                      color: VetoGlassTokens.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!compact) ...[
            NeonBadge(label: _role.toUpperCase(), color: VetoPalette.cyan),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: 'פרופיל',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.account_circle_outlined, color: VetoGlassTokens.textPrimary),
          ),
          if (_role == 'admin')
            IconButton(
              tooltip: 'ניהול',
              onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
              icon: const Icon(Icons.admin_panel_settings_outlined, color: VetoGlassTokens.textPrimary),
            ),
          IconButton(
            tooltip: 'התנתק',
            onPressed: () => AuthService().logout(context),
            icon: const Icon(Icons.logout_rounded, color: VetoGlassTokens.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _wizardHeader() {
    final labels = _role == 'lawyer'
        ? const ['זמינות', 'התראות', 'טיפול', 'סגירה']
        : const ['הגנה', 'שידור', 'התאמה', 'ניהול'];

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= _wizardIndex;
          final isCurrent = index == _wizardIndex;

          return Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(left: index == labels.length - 1 ? 0 : 8),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 3,
                    decoration: BoxDecoration(
                      color: active
                          ? (isCurrent
                              ? VetoGlassTokens.neonCyan
                              : VetoGlassTokens.accentSoft)
                          : VetoGlassTokens.glassBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active
                          ? VetoGlassTokens.textPrimary
                          : VetoGlassTokens.textSubtle,
                      fontSize: 11,
                      fontWeight: active
                          ? FontWeight.w600
                          : FontWeight.w400,
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

  Widget _userWizard(bool compact) {
    return ListView(
      key: const ValueKey('userWizard2050'),
      children: [
        _panel(
          title: 'שלב 1 | מצב הגנה',
          subtitle: 'מבט מהיר על סטטוס המערכת שלך',
          child: Row(
            children: [
              NeonBadge(
                label: _isBusy ? 'שידור פעיל' : 'מוגן',
                color: _isBusy ? VetoPalette.warning : VetoPalette.success,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isBusy
                      ? 'קריאה כבר בתהליך, המערכת עוקבת אחרי תגובת עורכי דין.'
                      : 'מוכן להפעלה. בלחיצה אחת תצא קריאת חירום מלאה.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          title: 'שלב 2 | שידור חירום',
          subtitle: 'כפתור אחד, פעולה אחת, אפס בלבול',
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isBusy ? null : _triggerEmergency,
              style: FilledButton.styleFrom(
                backgroundColor: VetoPalette.coral,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: compact ? 13 : 16),
              ),
              icon: const Icon(Icons.shield_outlined),
              label: Text(_isBusy ? 'שידור פעיל...' : 'הפעל VETO עכשיו'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          title: 'שלב 3 | תיעוד מתקדם',
          subtitle: 'גישה מהירה למסך התיעוד הקיים',
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/veto_screen'),
            icon: const Icon(Icons.perm_camera_mic_outlined),
            label: const Text('פתח סביבת חירום'),
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          title: 'שלב 4 | פעולות חשבון',
          subtitle: 'פרופיל, ניהול, ויציאה בטוחה',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                child: const Text('פרופיל'),
              ),
              if (_role == 'admin')
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/admin_settings'),
                  child: const Text('ניהול מערכת'),
                ),
              OutlinedButton(
                onPressed: () => AuthService().logout(context),
                child: const Text('התנתק'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lawyerWizard(bool compact) {
    return ListView(
      key: const ValueKey('lawyerWizard2050'),
      children: [
        _panel(
          title: 'שלב 1 | זמינות',
          subtitle: 'שליטה מלאה בזרימת תיקים נכנסים',
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(_isAvailable ? 'זמין לקריאות' : 'לא זמין כרגע'),
            subtitle: Text(_isAvailable ? 'On-call active' : 'Standby mode'),
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
        _panel(
          title: 'שלב 2 | התראות פעילות',
          subtitle: 'קבל או דחה תיקים בלחיצה מהירה',
          child: _alerts.isEmpty
              ? const Text('אין כרגע התראות פעילות')
              : Column(
                  children: _alerts
                      .map(
                        (alert) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(
                              left: BorderSide(
                                  color: VetoPalette.warning, width: 3),
                              top: BorderSide(color: VetoGlassTokens.glassBorder),
                              right: BorderSide(color: VetoGlassTokens.glassBorder),
                              bottom: BorderSide(color: VetoGlassTokens.glassBorder),
                            ),
                            color: VetoGlassTokens.glassFillStrong,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notification_important_outlined,
                                  color: VetoPalette.warning, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                    'קריאה #${alert['eventId'] ?? 'N/A'}',
                                    style: const TextStyle(
                                        color: VetoGlassTokens.textPrimary,
                                        fontWeight: FontWeight.w600)),
                              ),
                              IconButton(
                                tooltip: 'דחה',
                                onPressed: () => _rejectAlert(alert),
                                icon: const Icon(Icons.close_rounded,
                                    color: VetoPalette.emergency, size: 20),
                              ),
                              FilledButton.icon(
                                onPressed: () => _acceptAlert(alert),
                                style: FilledButton.styleFrom(
                                  backgroundColor: VetoPalette.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('קבל',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 12),
        _panel(
          title: 'שלב 3 | טיפול בתיק',
          subtitle: 'מעבר אוטומטי לסטטוס עסוק לאחר קבלה',
          child: Text(
            _isAvailable ? 'אין תיק פעיל כרגע' : 'סטטוס עסוק - תיק בטיפול',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          title: 'שלב 4 | פעולות חשבון',
          subtitle: 'גישה מהירה לכלי הפרופיל והניהול',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                child: const Text('פרופיל'),
              ),
              if (_role == 'admin')
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/admin_settings'),
                  child: const Text('ניהול מערכת'),
                ),
              OutlinedButton(
                onPressed: () => AuthService().logout(context),
                child: const Text('התנתק'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: VetoGlassTokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: VetoGlassTokens.textMuted, fontSize: 13)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
