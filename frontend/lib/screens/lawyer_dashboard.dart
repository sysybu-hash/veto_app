import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_glass_system.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/push_service.dart';
import '../services/socket_service.dart';


class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({super.key});

  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard> {
  String _lawyerName = '';
  bool _isAvailable = true;
  bool _isBooting = true;
  final List<Map<String, dynamic>> _alerts = [];
  final List<Map<String, dynamic>> _activeCases = [];
  StreamSubscription<Map<String, dynamic>>? _alertSub;
  StreamSubscription<Map<String, dynamic>>? _caseAcceptedSub;
  StreamSubscription<Map<String, dynamic>>? _caseTakenSub;
  StreamSubscription<Map<String, dynamic>>? _sessionReadySub;

  static const Map<String, Map<String, String>> _copy = {
    'he': {
      'eyebrow': 'מרכז תגובה משפטי',
      'title': 'עמדת עורך הדין',
      'subtitle': 'כל קריאת חירום מגיעה לכאן עם שליטה מלאה על זמינות, תגובה וקבלת תיק.',
      'status': 'זמינות',
      'statusOnline': 'זמין לקבלת קריאות',
      'statusOffline': 'לא זמין כרגע',
      'statusHelp': 'כאשר המתג פעיל, משתמשים באזור שלך יוכלו להגיע אליך בשעת חירום.',
      'queue': 'קריאות ממתינות',
      'response': 'יעד תגובה',
      'responseValue': 'עד 2 דק׳',
      'shift': 'ניהול משמרת',
      'shiftTitle': 'שליטה חיה בזמינות',
      'shiftBody': 'הפעל זמינות כשאתה פנוי לקבל תיק. כשתאשר קריאה, המערכת תסמן אותך כעסוק כדי למנוע כפילויות.',
      'activity': 'תיבת חירום',
      'activityTitle': 'קריאות פעילות',
      'activitySubtitle': 'כל קריאה מציגה את פרטי האירוע כפי שהתקבלו בזמן אמת מהאפליקציה של האזרח.',
      'emptyTitle': 'אין כרגע קריאות פעילות',
      'emptyBody': 'ברגע שמשתמש יפעיל SOS ותהיה מוגדר כזמין, הקריאה תופיע כאן ותוכל להגיב מיד.',
      'emptyHint': 'השאר את הזמינות פעילה כדי להופיע ראשון בתיעדוף.',
      'request': 'קריאת חירום',
      'requestFrom': 'פנייה ממשתמש',
      'requestDetails': 'פרטי האירוע',
      'requestUnknown': 'לא נמסרו פרטים נוספים.',
      'accept': 'קבל תיק',
      'reject': 'דלג',
      'accepted': 'התיק הוקצה אליך בהצלחה.',
      'rejected': 'הקריאה הוסרה מהתור שלך.',
      'liveDialog': 'קריאה נכנסת',
      'profile': 'פרופיל',
      'logout': 'התנתק',
    },
    'en': {
      'eyebrow': 'Legal response center',
      'title': 'Lawyer console',
      'subtitle': 'Every emergency request lands here with full control over availability, response time, and case acceptance.',
      'status': 'Availability',
      'statusOnline': 'Available for emergency calls',
      'statusOffline': 'Unavailable right now',
      'statusHelp': 'When the switch is on, nearby users can be matched to you during emergencies.',
      'queue': 'Pending alerts',
      'response': 'Response target',
      'responseValue': 'Under 2 min',
      'shift': 'Shift control',
      'shiftTitle': 'Live availability control',
      'shiftBody': 'Turn availability on when you are ready to take a case. Once you accept a call, the system marks you busy to avoid duplicate assignments.',
      'activity': 'Emergency inbox',
      'activityTitle': 'Active requests',
      'activitySubtitle': 'Each request shows the live event details exactly as received from the citizen app.',
      'emptyTitle': 'No active requests right now',
      'emptyBody': 'As soon as a user triggers SOS and you are marked available, the request will appear here for immediate response.',
      'emptyHint': 'Keep availability on to stay high in dispatch priority.',
      'request': 'Emergency request',
      'requestFrom': 'Request from user',
      'requestDetails': 'Event details',
      'requestUnknown': 'No additional details were sent.',
      'accept': 'Accept case',
      'reject': 'Skip',
      'accepted': 'The case was assigned to you successfully.',
      'rejected': 'The request was removed from your queue.',
      'liveDialog': 'Incoming request',
      'profile': 'Profile',
      'logout': 'Log out',
    },
    'ru': {
      'eyebrow': 'Юридический центр реагирования',
      'title': 'Панель адвоката',
      'subtitle': 'Все экстренные запросы приходят сюда. Вы управляете доступностью, скоростью ответа и принятием дела.',
      'status': 'Доступность',
      'statusOnline': 'Готов принимать экстренные запросы',
      'statusOffline': 'Сейчас недоступен',
      'statusHelp': 'Когда переключатель включен, пользователи поблизости смогут найти вас в экстренной ситуации.',
      'queue': 'Ожидающие запросы',
      'response': 'Цель ответа',
      'responseValue': 'До 2 мин',
      'shift': 'Управление сменой',
      'shiftTitle': 'Живой контроль доступности',
      'shiftBody': 'Включайте доступность, когда готовы принять дело. После подтверждения система отметит вас занятым и исключит дубли.',
      'activity': 'Экстренный inbox',
      'activityTitle': 'Активные запросы',
      'activitySubtitle': 'Каждый запрос показывает детали события так, как они были получены из приложения пользователя.',
      'emptyTitle': 'Сейчас нет активных запросов',
      'emptyBody': 'Как только пользователь нажмет SOS и вы будете доступны, запрос появится здесь для немедленного ответа.',
      'emptyHint': 'Оставляйте доступность включенной, чтобы быть выше в приоритете распределения.',
      'request': 'Экстренный запрос',
      'requestFrom': 'Запрос от пользователя',
      'requestDetails': 'Детали события',
      'requestUnknown': 'Дополнительные детали не переданы.',
      'accept': 'Принять дело',
      'reject': 'Пропустить',
      'accepted': 'Дело успешно закреплено за вами.',
      'rejected': 'Запрос удален из вашей очереди.',
      'liveDialog': 'Новый запрос',
      'profile': 'Профиль',
      'logout': 'Выйти',
    },
  };

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  String _t(String code, String key) {
    return _copy[AppLanguage.normalize(code)]?[key] ??
        _copy[AppLanguage.hebrew]![key] ??
        key;
  }

  Future<void> _bootstrap() async {
    final auth = AuthService();
    final role = await auth.getStoredRole() ?? 'user';
    final name = await auth.getStoredName() ?? '';
    final preferredLanguage = AppLanguage.normalize(
      await auth.getStoredPreferredLanguage(),
    );

    if (!mounted) return;

    // Admins are allowed to be here
    if (role != 'lawyer' && role != 'admin') { Navigator.of(context).pushReplacementNamed('/veto_screen'); return; }

    final languageController = context.read<AppLanguageController>();
    if (languageController.code != preferredLanguage) {
      await languageController.setLanguage(preferredLanguage, persist: false);
    }

    setState(() {
      _lawyerName = name.isNotEmpty ? name : 'VETO';
      _isBooting = false;
    });

    final online = await SocketService().ensureConnected(role: role);
    if (!mounted) return;
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            preferredLanguage == 'he'
                ? 'אין חיבור לשרת — בדוק רשת ונסה לרענן.'
                : preferredLanguage == 'ru'
                    ? 'Нет связи с сервером. Проверьте сеть.'
                    : 'Cannot reach the server. Check your connection.',
          ),
          backgroundColor: VetoPalette.emergency,
        ),
      );
    }
    SocketService().emit('lawyer_availability', {'available': _isAvailable});

    // Register browser push subscription (fire-and-forget — non-blocking)
    PushService().registerLawyerPush();

    _alertSub = SocketService().onNewEmergencyAlert.listen((data) {
      if (!mounted) return;
      setState(() => _alerts.insert(0, data));
      _showAlertDialog(data);
    });

    _caseAcceptedSub = SocketService().onCaseAccepted.listen((data) {
      final awaiting = data['awaitingCitizenChoice'] == true;
      if (awaiting) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              preferredLanguage == 'he'
                  ? 'ממתין שהלקוח יבחר סוג שיחה…'
                  : preferredLanguage == 'ru'
                      ? 'Ожидаем выбор клиента…'
                      : 'Waiting for the client to choose session type…',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: VetoPalette.info,
          ),
        );
        return;
      }
      final roomId = data['roomId']?.toString();
      if (!mounted || roomId == null || roomId.isEmpty) return;
      Navigator.of(context).pushNamed(
        '/call',
        arguments: {
          'roomId': roomId,
          'callType': data['callType']?.toString() ?? 'audio',
          'peerName': data['peerName']?.toString() ?? 'Client',
          'role': 'lawyer',
          'eventId': data['eventId']?.toString() ?? roomId,
          'language': data['language']?.toString() ?? preferredLanguage,
        },
      );
    });

    _sessionReadySub = SocketService().onSessionReady.listen((data) {
      final roomId = data['roomId']?.toString();
      if (!mounted || roomId == null || roomId.isEmpty) return;
      Navigator.of(context).pushNamed(
        '/call',
        arguments: {
          'roomId': roomId,
          'callType': data['callType']?.toString() ?? 'audio',
          'peerName': data['peerName']?.toString() ?? 'Client',
          'role': 'lawyer',
          'eventId': data['eventId']?.toString() ?? roomId,
          'language': data['language']?.toString() ?? preferredLanguage,
        },
      );
    });

    _caseTakenSub = SocketService().onCaseTaken.listen((data) {
      final eventId = data['eventId']?.toString();
      if (!mounted || eventId == null) return;
      setState(() {
        _alerts.removeWhere((a) => a['eventId']?.toString() == eventId);
        _activeCases.removeWhere((c) => c['eventId']?.toString() == eventId);
      });
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _caseAcceptedSub?.cancel();
    _caseTakenSub?.cancel();
    _sessionReadySub?.cancel();
    super.dispose();
  }

  void _toggleAvailability(bool value) {
    setState(() => _isAvailable = value);
    SocketService().emit('lawyer_availability', {'available': value});
  }

  void _acceptCase(Map<String, dynamic> alert) {
    final eventId = alert['eventId'];
    SocketService().emit('accept_case', {'eventId': eventId});
    setState(() {
      _alerts.removeWhere((item) => item['eventId'] == eventId);
      _activeCases.insert(0, alert);
      _isAvailable = false;
    });
    SocketService().emit('lawyer_availability', {'available': false});
    _showSnack(_t(context.read<AppLanguageController>().code, 'accepted'),
        background: VetoPalette.success);
  }

  void _rejectCase(Map<String, dynamic> alert) {
    final eventId = alert['eventId'];
    SocketService().emit('reject_case', {'eventId': eventId});
    setState(() {
      _alerts.removeWhere((item) => item['eventId'] == eventId);
    });
    _showSnack(_t(context.read<AppLanguageController>().code, 'rejected'));
  }

  void _showNotificationsPanel() {
    final code = context.read<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;
    if (_alerts.isEmpty) {
      _showSnack(
        isRtl ? 'אין קריאות ממתינות' : 'No pending emergency alerts',
        background: VetoGlassTokens.menuPanel,
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: VetoGlassTokens.sheetPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: VetoGlassTokens.glassBorder),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: VetoGlassTokens.glassBorderBright,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _t(code, 'queue'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: VetoGlassTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              for (final a in _alerts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.emergency_rounded, color: Color(0xFFFF3B3B)),
                  title: Text(
                    a['userName']?.toString() ?? 'User',
                    style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    a['eventId']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: VetoGlassTokens.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSharedVaultFromCases(bool isRtl) {
    for (final c in _activeCases) {
      final uid = c['userId'];
      if (uid != null && uid.toString().isNotEmpty) {
        Navigator.pushNamed(context, '/shared_vault', arguments: {
          'userId': uid.toString(),
          'userName': c['userName'] ?? 'User',
        });
        return;
      }
    }
    for (final a in _alerts) {
      final uid = a['userId'];
      if (uid != null && uid.toString().isNotEmpty) {
        Navigator.pushNamed(context, '/shared_vault', arguments: {
          'userId': uid.toString(),
          'userName': a['userName'] ?? 'User',
        });
        return;
      }
    }
    _showSnack(
      isRtl ? 'קבל תיק או בחר תיק פעיל לפני צפיית קבצים' : 'Accept a case or pick an active case to view files',
      background: VetoGlassTokens.menuPanel,
    );
  }

  void _showSnack(String message, {Color background = VetoGlassTokens.menuPanel}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: VetoGlassTokens.textPrimary)),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: VetoGlassTokens.glassBorder),
        ),
      ),
    );
  }

  void _showAlertDialog(Map<String, dynamic> alert) {
    final code = context.read<AppLanguageController>().code;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: AppLanguage.directionOf(code),
          child: AlertDialog(
            backgroundColor: VetoGlassTokens.sheetPanel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: VetoGlassTokens.glassBorder),
            ),
            title: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: VetoPalette.emergency),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t(code, 'liveDialog'),
                    style: const TextStyle(
                      color: VetoGlassTokens.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: _AlertSummary(
              title: _t(code, 'requestDetails'),
              fromLabel: _t(code, 'requestFrom'),
              fallbackText: _t(code, 'requestUnknown'),
              data: alert,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _rejectCase(alert);
                },
                child: Text(
                  _t(code, 'reject'),
                  style: const TextStyle(color: VetoGlassTokens.textMuted),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _acceptCase(alert);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: VetoPalette.success,
                  foregroundColor: Colors.white,
                ),
                child: Text(_t(code, 'accept')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguageController>();
    final code = language.code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoGlassTokens.bgBase,
        body: _isBooting
            ? const VetoGlassAuroraBackground(
                child: Center(child: CircularProgressIndicator(color: VetoGlassTokens.neonCyan)),
              )
            : VetoGlassAuroraBackground(
                child: SafeArea(
                  child: Column(children: [
                    // ── Top bar ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(children: [
                        // Bell
                        Stack(children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: VetoGlassTokens.textPrimary),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showNotificationsPanel();
                            },
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                          if (_alerts.isNotEmpty)
                            Positioned(right: 8, top: 8, child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Color(0xFFFF3B3B), shape: BoxShape.circle),
                            )),
                        ]),
                        const Spacer(),
                        // Title
                        Text(
                          isRtl ? 'לוח בקרה — עורך דין' : 'Lawyer Dashboard',
                          style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        // Available badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: VetoGlassTokens.glassFillStrong,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isAvailable
                                  ? VetoGlassTokens.neonCyan.withValues(alpha: 0.35)
                                  : VetoGlassTokens.glassBorder,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isAvailable ? VetoGlassTokens.neonCyan : const Color(0xFFF59E0B),
                                boxShadow: _isAvailable
                                    ? [
                                        BoxShadow(
                                          color: VetoGlassTokens.neonCyan.withValues(alpha: 0.55),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isAvailable ? (isRtl ? 'מחובר' : 'Online') : (isRtl ? 'לא זמין' : 'Offline'),
                              style: TextStyle(
                                color: _isAvailable
                                    ? VetoGlassTokens.neonCyan
                                    : VetoGlassTokens.textMuted,
                                fontSize: 12, fontWeight: FontWeight.w700,
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    ),

                    // ── Scrollable content ───────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(children: [
                          const VetoCommandMapPanel(height: 176),
                          const SizedBox(height: 14),
                          // Greeting card
                          VetoGlassBlur(
                            borderRadius: 20,
                            sigma: 18,
                            fill: VetoGlassTokens.glassFillStrong,
                            borderColor: VetoGlassTokens.glassBorderBright,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRtl ? 'שלום, עו"ד $_lawyerName' : 'Hello, Adv. $_lawyerName',
                                        style: const TextStyle(
                                          color: VetoGlassTokens.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isRtl
                                            ? 'יש לך ${_activeCases.length} תיקים פעילים'
                                            : 'You have ${_activeCases.length} active cases',
                                        style: const TextStyle(
                                          color: VetoGlassTokens.textMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: VetoGlassTokens.glassFill,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: VetoGlassTokens.neonCyan.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: VetoGlassTokens.textPrimary,
                                    size: 28,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Stats row: 3 cards
                          Row(children: [
                            _LawyerStat(value: '${_activeCases.length}', label: isRtl ? 'תיקים פעילים' : 'Active cases', color: const Color(0xFF5B8FFF)),
                            const SizedBox(width: 10),
                            _LawyerStat(value: '${_alerts.length}', label: isRtl ? 'שיחות היום' : 'Today calls', color: const Color(0xFF334155)),
                            const SizedBox(width: 10),
                            _LawyerStat(
                              value: '4.8',
                              label: isRtl ? 'דירוג' : 'Rating',
                              color: const Color(0xFFF59E0B),
                              icon: Icons.star_rounded,
                            ),
                          ]),
                          const SizedBox(height: 14),

                          // Availability toggle
                          VetoGlassBlur(
                            borderRadius: 16,
                            sigma: 16,
                            fill: VetoGlassTokens.glassFillStrong,
                            borderColor: VetoGlassTokens.glassBorder,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(children: [
                                Icon(
                                  Icons.toggle_on_rounded,
                                  color: VetoGlassTokens.neonCyan,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _isAvailable
                                        ? (isRtl ? 'זמין לקריאות' : 'Available')
                                        : (isRtl ? 'לא זמין' : 'Unavailable'),
                                    style: TextStyle(
                                      color: _isAvailable
                                          ? VetoGlassTokens.neonCyan
                                          : VetoGlassTokens.textMuted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _isAvailable,
                                  onChanged: _toggleAvailability,
                                  activeThumbColor: VetoGlassTokens.neonCyan,
                                  activeTrackColor: VetoGlassTokens.neonCyan
                                      .withValues(alpha: 0.38),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Active cases section
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              isRtl ? 'תיקים פעילים' : 'Active Cases',
                              style: const TextStyle(
                                color: VetoGlassTokens.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (_alerts.isEmpty && _activeCases.isEmpty)
                            VetoGlassBlur(
                              borderRadius: 16,
                              sigma: 14,
                              fill: VetoGlassTokens.glassFill,
                              borderColor: VetoGlassTokens.glassBorder,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    _t(code, 'emptyTitle'),
                                    style: const TextStyle(
                                      color: VetoGlassTokens.textMuted,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),

                          // Alerts (incoming)
                          for (final alert in _alerts)
                            _LawyerCaseCard(
                              data: alert, isRtl: isRtl,
                              acceptLabel: _t(code, 'accept'),
                              rejectLabel: _t(code, 'reject'),
                              onAccept: () => _acceptCase(alert),
                              onReject: () => _rejectCase(alert),
                              urgency: 'urgent',
                            ),

                          // Active cases
                          for (int i = 0; i < _activeCases.length; i++)
                            _LawyerCaseCard(
                              data: _activeCases[i], isRtl: isRtl,
                              acceptLabel: isRtl ? 'קבל תיק' : 'View case',
                              rejectLabel: isRtl ? 'סגור' : 'Close',
                              onAccept: () {
                                final c = _activeCases[i];
                                final uid = c['userId'];
                                if (uid != null) {
                                  Navigator.pushNamed(context, '/shared_vault', arguments: {
                                    'userId': uid, 'userName': c['userName'] ?? 'User',
                                  });
                                }
                              },
                              onReject: () => setState(() => _activeCases.removeAt(i)),
                              urgency: 'moderate',
                            ),

                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),

                    // ── Bottom nav bar ──────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: VetoGlassTokens.glassFillStrong,
                        border: const Border(
                          top: BorderSide(color: VetoGlassTokens.glassBorder),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                          _BottomNavItem(
                            icon: Icons.home_rounded,
                            label: isRtl ? 'בית' : 'Home',
                            selected: true,
                            onTap: () => Navigator.pushReplacementNamed(context, '/lawyer_dashboard'),
                          ),
                          _BottomNavItem(
                            icon: Icons.folder_outlined,
                            label: isRtl ? 'תיקים' : 'Cases',
                            selected: false,
                            onTap: () => _openSharedVaultFromCases(isRtl),
                          ),
                          _BottomNavItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: isRtl ? 'צ׳אט' : 'Chat',
                            selected: false,
                            onTap: () => Navigator.pushNamed(context, '/chat'),
                          ),
                          _BottomNavItem(icon: Icons.person_outline_rounded, label: isRtl ? 'פרופיל' : 'Profile', selected: false,
                            onTap: () => Navigator.pushNamed(context, '/lawyer_settings')),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
      ),
    );
  }
}

// ── Lawyer stat tile ──────────────────────────────────────
class _LawyerStat extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData? icon;
  const _LawyerStat({required this.value, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: VetoGlassBlur(
        borderRadius: 14,
        sigma: 12,
        fill: VetoGlassTokens.glassFillStrong,
        borderColor: VetoGlassTokens.glassBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(children: [
            if (icon != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            else
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: VetoGlassTokens.textMuted,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Case card ─────────────────────────────────────────────
class _LawyerCaseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isRtl;
  final String acceptLabel, rejectLabel, urgency;
  final VoidCallback onAccept, onReject;
  const _LawyerCaseCard({
    required this.data, required this.isRtl,
    required this.acceptLabel, required this.rejectLabel,
    required this.onAccept, required this.onReject, required this.urgency,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = urgency == 'urgent';
    final chipColor = isUrgent ? const Color(0xFFFF3B3B) : const Color(0xFFF59E0B);
    final chipLabel = isUrgent ? (isRtl ? 'דחוף' : 'Urgent') : (isRtl ? 'ממתין' : 'Pending');
    final nameRaw = data['userName'] ?? data['name'] ?? (isRtl ? 'משתמש' : 'User');
    final scenario = data['scenario'] ?? data['type'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VetoGlassBlur(
        borderRadius: 16,
        sigma: 16,
        fill: VetoGlassTokens.glassFillStrong,
        borderColor: isUrgent
            ? const Color(0xFFFF3B3B).withValues(alpha: 0.4)
            : VetoGlassTokens.glassBorder,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: chipColor.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    chipLabel,
                    style: TextStyle(
                      color: chipColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isRtl ? 'אזרח: $nameRaw' : 'Client: $nameRaw',
              style: const TextStyle(
                color: VetoGlassTokens.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              scenario.isEmpty ? (isRtl ? 'אירוע חירום' : 'Emergency') : scenario,
              style: const TextStyle(
                color: VetoGlassTokens.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: VetoGlassTokens.neonBlue,
                      foregroundColor: VetoGlassTokens.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(acceptLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VetoGlassTokens.textSecondary,
                      side: const BorderSide(color: VetoGlassTokens.glassBorderBright),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(rejectLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ── Bottom nav item ───────────────────────────────────────
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BottomNavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            icon,
            color: selected
                ? VetoGlassTokens.neonCyan
                : VetoGlassTokens.textMuted,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? VetoGlassTokens.neonCyan
                  : VetoGlassTokens.textMuted,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}

class _AlertSummary extends StatelessWidget {
  final String title;
  final String fromLabel;
  final String fallbackText;
  final Map<String, dynamic> data;

  const _AlertSummary({
    required this.title,
    required this.fromLabel,
    required this.fallbackText,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final details = data['details']?.toString().trim();
    final userId = data['userId']?.toString() ?? '—';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$fromLabel: $userId',
          style: const TextStyle(
            color: VetoGlassTokens.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: VetoGlassTokens.textSubtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (details == null || details.isEmpty) ? fallbackText : details,
          style: const TextStyle(
            color: VetoGlassTokens.textMuted,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

