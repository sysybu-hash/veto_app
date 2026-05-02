// ============================================================
//  LawyerDashboard — VETO 2026
//  Pixel-aligned with design_mockups/2026/lawyer.html.
//
//  Layout (mobile/desktop adaptive):
//    Header  : greeting + availability switch + bell + role badge
//    Stats   : 4 cards — pending / response target / active cases / rating
//    Section : "Active alerts" with case-cards (LIVE red / pending warn)
//    Empty   : when no alerts
//    Footer  : 4-tab bottom nav (mobile)
//
//  Behaviour preserved from legacy:
//    - SocketService subs (alert / caseAccepted / caseTaken / sessionReady)
//    - Push registration (PushService.registerLawyerPush + FCM on native)
//    - Accept/Reject via socket emit
//    - Auth gate: non-lawyer/non-admin → redirect /veto_screen
//    - Live alert dialog on inbound emergency
// ============================================================
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_tokens_2026.dart';
import '../services/auth_service.dart';
import '../services/fcm_user_service.dart';
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
      'greetingMorning': 'בוקר טוב',
      'greetingEvening': 'ערב טוב',
      'greetingDay': 'שלום',
      'statusOnline': 'זמין לקריאות',
      'statusOffline': 'לא זמין',
      'pendingLabel': 'קריאות ממתינות',
      'responseLabel': 'יעד תגובה',
      'responseValue': '2:00',
      'activeLabel': 'תיקים פעילים',
      'ratingLabel': 'דירוג',
      'sectionTitle': 'קריאות פעילות',
      'sectionSub': 'פרטי האירוע מתעדכנים בזמן אמת מהאפליקציה של האזרח.',
      'emptyTitle': 'אין כעת קריאות פעילות',
      'emptyBody': 'ברגע שמשתמש יפעיל SOS ותהיה מוגדר כזמין, הקריאה תופיע כאן.',
      'enableAvailability': 'הפעל זמינות',
      'badgeLive': 'LIVE',
      'badgeWaiting': 'ממתין',
      'accept': 'קבל תיק',
      'reject': 'דלג',
      'viewCase': 'צפה בתיק',
      'closeCase': 'סגור',
      'accepted': 'התיק הוקצה אליך בהצלחה.',
      'rejected': 'הקריאה הוסרה מהתור שלך.',
      'liveDialog': 'קריאת חירום נכנסת',
      'requestFrom': 'פנייה ממשתמש',
      'requestDetails': 'פרטי האירוע',
      'requestUnknown': 'לא נמסרו פרטים נוספים.',
      'navHome': 'בית', 'navCases': 'תיקים', 'navChat': 'צ׳אט', 'navProfile': 'פרופיל',
      'noNetwork': 'אין חיבור לשרת — בדוק רשת ונסה לרענן.',
      'noPendingAlerts': 'אין קריאות ממתינות',
      'pickCase': 'קבל תיק או בחר תיק פעיל לפני צפייה בקבצים',
    },
    'en': {
      'eyebrow': 'Legal response centre',
      'greetingMorning': 'Good morning',
      'greetingEvening': 'Good evening',
      'greetingDay': 'Hello',
      'statusOnline': 'Available',
      'statusOffline': 'Unavailable',
      'pendingLabel': 'Pending alerts',
      'responseLabel': 'Response target',
      'responseValue': '2:00',
      'activeLabel': 'Active cases',
      'ratingLabel': 'Rating',
      'sectionTitle': 'Active alerts',
      'sectionSub': 'Each alert is updated live from the citizen app.',
      'emptyTitle': 'No active alerts right now',
      'emptyBody': 'As soon as a user triggers SOS and you are available, it will appear here.',
      'enableAvailability': 'Turn on availability',
      'badgeLive': 'LIVE',
      'badgeWaiting': 'Pending',
      'accept': 'Accept',
      'reject': 'Skip',
      'viewCase': 'View case',
      'closeCase': 'Close',
      'accepted': 'Case assigned to you.',
      'rejected': 'Alert removed from your queue.',
      'liveDialog': 'Incoming emergency',
      'requestFrom': 'Request from user',
      'requestDetails': 'Event details',
      'requestUnknown': 'No additional details were sent.',
      'navHome': 'Home', 'navCases': 'Cases', 'navChat': 'Chat', 'navProfile': 'Profile',
      'noNetwork': 'Cannot reach the server. Check your connection.',
      'noPendingAlerts': 'No pending alerts',
      'pickCase': 'Accept or pick an active case to view files',
    },
    'ru': {
      'eyebrow': 'Юридический центр реагирования',
      'greetingMorning': 'Доброе утро',
      'greetingEvening': 'Добрый вечер',
      'greetingDay': 'Здравствуйте',
      'statusOnline': 'На связи',
      'statusOffline': 'Не на связи',
      'pendingLabel': 'Ожидающие',
      'responseLabel': 'Цель ответа',
      'responseValue': '2:00',
      'activeLabel': 'Активные дела',
      'ratingLabel': 'Рейтинг',
      'sectionTitle': 'Активные запросы',
      'sectionSub': 'Каждый запрос обновляется в реальном времени.',
      'emptyTitle': 'Сейчас нет активных запросов',
      'emptyBody': 'Как только пользователь нажмёт SOS и вы будете доступны.',
      'enableAvailability': 'Включить доступность',
      'badgeLive': 'LIVE',
      'badgeWaiting': 'Ожидает',
      'accept': 'Принять',
      'reject': 'Пропустить',
      'viewCase': 'Открыть',
      'closeCase': 'Закрыть',
      'accepted': 'Дело успешно закреплено.',
      'rejected': 'Запрос удалён из очереди.',
      'liveDialog': 'Новый экстренный запрос',
      'requestFrom': 'Запрос от пользователя',
      'requestDetails': 'Детали события',
      'requestUnknown': 'Дополнительные детали не переданы.',
      'navHome': 'Главная', 'navCases': 'Дела', 'navChat': 'Чат', 'navProfile': 'Профиль',
      'noNetwork': 'Нет связи с сервером.',
      'noPendingAlerts': 'Нет ожидающих запросов',
      'pickCase': 'Примите или выберите дело, чтобы открыть файлы',
    },
  };

  String _t(String code, String key) =>
      _copy[AppLanguage.normalize(code)]?[key] ?? _copy[AppLanguage.hebrew]![key] ?? key;

  String _greeting(String code) {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return _t(code, 'greetingMorning');
    if (h >= 17 || h < 5) return _t(code, 'greetingEvening');
    return _t(code, 'greetingDay');
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _caseAcceptedSub?.cancel();
    _caseTakenSub?.cancel();
    _sessionReadySub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final auth = AuthService();
    final role = await auth.getStoredRole() ?? 'user';
    final name = await auth.getStoredName() ?? '';
    final preferredLanguage = AppLanguage.normalize(await auth.getStoredPreferredLanguage());

    if (!mounted) return;
    if (role != 'lawyer' && role != 'admin') {
      Navigator.of(context).pushReplacementNamed('/veto_screen');
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t(preferredLanguage, 'noNetwork')),
        backgroundColor: VetoTokens.emerg,
      ));
    }
    SocketService().emit('lawyer_availability', {'available': _isAvailable});

    PushService().registerLawyerPush();
    if (!kIsWeb) {
      unawaited(registerFcmIfAvailable());
    }

    _alertSub = SocketService().onNewEmergencyAlert.listen((data) {
      if (!mounted) return;
      setState(() => _alerts.insert(0, data));
      _showAlertDialog(data);
    });

    _caseAcceptedSub = SocketService().onCaseAccepted.listen((data) {
      final awaiting = data['awaitingCitizenChoice'] == true;
      if (awaiting) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            preferredLanguage == 'he'
                ? 'ממתין שהלקוח יבחר סוג שיחה…'
                : preferredLanguage == 'ru'
                    ? 'Ожидаем выбор клиента…'
                    : 'Waiting for the client to choose session type…',
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: VetoTokens.navy600,
        ));
        return;
      }
      final roomId = data['roomId']?.toString();
      if (!mounted || roomId == null || roomId.isEmpty) return;
      Navigator.of(context).pushNamed(
        '/call',
        arguments: {
          'roomId': roomId,
          'callType': data['callType']?.toString() ?? 'video',
          'peerName': data['peerName']?.toString() ?? 'Client',
          'role': 'lawyer',
          'eventId': data['eventId']?.toString() ?? roomId,
          'language': data['language']?.toString() ?? preferredLanguage,
          'agoraToken': data['agoraToken']?.toString() ?? '',
          'agoraUid': data['agoraUid'],
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
          'callType': data['callType']?.toString() ?? 'video',
          'peerName': data['peerName']?.toString() ?? 'Client',
          'role': 'lawyer',
          'eventId': data['eventId']?.toString() ?? roomId,
          'language': data['language']?.toString() ?? preferredLanguage,
          'agoraToken': data['agoraToken']?.toString() ?? '',
          'agoraUid': data['agoraUid'],
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
    final code = context.read<AppLanguageController>().code;
    _snack(_t(code, 'accepted'), background: VetoTokens.ok);
  }

  void _rejectCase(Map<String, dynamic> alert) {
    final eventId = alert['eventId'];
    SocketService().emit('reject_case', {'eventId': eventId});
    setState(() => _alerts.removeWhere((item) => item['eventId'] == eventId));
    final code = context.read<AppLanguageController>().code;
    _snack(_t(code, 'rejected'));
  }

  void _snack(String message, {Color? background}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: VetoTokens.bodyMd.copyWith(color: Colors.white)),
      backgroundColor: background ?? VetoTokens.ink900,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rMd)),
    ));
  }

  void _openSharedVaultFromCases() {
    final code = context.read<AppLanguageController>().code;
    for (final c in _activeCases) {
      final uid = c['userId'];
      if (uid != null && uid.toString().isNotEmpty) {
        Navigator.pushNamed(context, '/shared_vault',
            arguments: {'userId': uid.toString(), 'userName': c['userName'] ?? 'User'});
        return;
      }
    }
    for (final a in _alerts) {
      final uid = a['userId'];
      if (uid != null && uid.toString().isNotEmpty) {
        Navigator.pushNamed(context, '/shared_vault',
            arguments: {'userId': uid.toString(), 'userName': a['userName'] ?? 'User'});
        return;
      }
    }
    _snack(_t(code, 'pickCase'));
  }

  void _showNotificationsPanel() {
    final code = context.read<AppLanguageController>().code;
    if (_alerts.isEmpty) {
      _snack(_t(code, 'noPendingAlerts'));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VetoTokens.r2Xl))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(color: VetoTokens.hairline2, borderRadius: BorderRadius.circular(2)))),
              Text(_t(code, 'pendingLabel'), style: VetoTokens.serif(18, FontWeight.w800, color: VetoTokens.ink900)),
              const SizedBox(height: 12),
              for (final a in _alerts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: VetoTokens.emergBg, borderRadius: BorderRadius.circular(VetoTokens.rSm)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.warning_amber_rounded, color: VetoTokens.emerg, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((a['userName'] ?? 'User').toString(),
                              style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
                          Text((a['eventId'] ?? '').toString(),
                              style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
                        ],
                      ),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDialog(Map<String, dynamic> alert) {
    final code = context.read<AppLanguageController>().code;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: VetoTokens.emergBg, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.notifications_active_rounded, color: VetoTokens.emerg, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(_t(code, 'liveDialog'), style: VetoTokens.titleLg)),
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
              onPressed: () { Navigator.of(context).pop(); _rejectCase(alert); },
              child: Text(_t(code, 'reject'), style: VetoTokens.labelMd.copyWith(color: VetoTokens.ink500)),
            ),
            FilledButton(
              onPressed: () { Navigator.of(context).pop(); _acceptCase(alert); },
              style: FilledButton.styleFrom(backgroundColor: VetoTokens.ok, foregroundColor: Colors.white),
              child: Text(_t(code, 'accept')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;
    String t(String k) => _t(code, k);

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoTokens.paper,
        body: _isBooting
            ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
            : SafeArea(
                child: Column(
                  children: [
                    _Header(
                      lawyerName: _lawyerName,
                      isAvailable: _isAvailable,
                      pendingCount: _alerts.length,
                      isRtl: isRtl,
                      greeting: _greeting(code),
                      onlineLabel: t('statusOnline'),
                      offlineLabel: t('statusOffline'),
                      eyebrow: t('eyebrow'),
                      onToggleAvailability: _toggleAvailability,
                      onBell: () { HapticFeedback.lightImpact(); _showNotificationsPanel(); },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StatsRow(
                                pending: _alerts.length,
                                response: t('responseValue'),
                                active: _activeCases.length,
                                rating: '4.93',
                                pendingLabel: t('pendingLabel'),
                                responseLabel: t('responseLabel'),
                                activeLabel: t('activeLabel'),
                                ratingLabel: t('ratingLabel'),
                              ),
                              const SizedBox(height: 24),
                              _SectionHeader(title: t('sectionTitle'), sub: t('sectionSub')),
                              const SizedBox(height: 12),
                              if (_alerts.isEmpty && _activeCases.isEmpty)
                                _EmptyState(
                                  title: t('emptyTitle'),
                                  body: t('emptyBody'),
                                  cta: _isAvailable ? null : t('enableAvailability'),
                                  onCta: _isAvailable ? null : () => _toggleAvailability(true),
                                )
                              else ...[
                                for (final alert in _alerts)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CaseCard(
                                      data: alert,
                                      isUrgent: true,
                                      isRtl: isRtl,
                                      liveLabel: t('badgeLive'),
                                      waitingLabel: t('badgeWaiting'),
                                      acceptLabel: t('accept'),
                                      rejectLabel: t('reject'),
                                      onAccept: () => _acceptCase(alert),
                                      onReject: () => _rejectCase(alert),
                                    ),
                                  ),
                                for (int i = 0; i < _activeCases.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CaseCard(
                                      data: _activeCases[i],
                                      isUrgent: false,
                                      isRtl: isRtl,
                                      liveLabel: t('badgeLive'),
                                      waitingLabel: t('badgeWaiting'),
                                      acceptLabel: t('viewCase'),
                                      rejectLabel: t('closeCase'),
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
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    _BottomNav(
                      labels: [t('navHome'), t('navCases'), t('navChat'), t('navProfile')],
                      onCases: _openSharedVaultFromCases,
                      onChat: () => Navigator.pushNamed(context, '/chat'),
                      onProfile: () => Navigator.pushNamed(context, '/lawyer_settings'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Sub-widgets
// ──────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({
    required this.lawyerName,
    required this.isAvailable,
    required this.pendingCount,
    required this.isRtl,
    required this.greeting,
    required this.onlineLabel,
    required this.offlineLabel,
    required this.eyebrow,
    required this.onToggleAvailability,
    required this.onBell,
  });
  final String lawyerName;
  final bool isAvailable;
  final int pendingCount;
  final bool isRtl;
  final String greeting, onlineLabel, offlineLabel, eyebrow;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: VetoTokens.hairline, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(), style: VetoTokens.kicker),
                const SizedBox(height: 2),
                Text(
                  '$greeting, $lawyerName',
                  style: VetoTokens.serif(20, FontWeight.w800, color: VetoTokens.ink900),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _AvailabilityPill(
            isOn: isAvailable,
            onChanged: onToggleAvailability,
            onLabel: onlineLabel,
            offLabel: offlineLabel,
          ),
          const SizedBox(width: 8),
          _BellButton(badge: pendingCount, onTap: onBell),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.isOn, required this.onChanged, required this.onLabel, required this.offLabel});
  final bool isOn;
  final ValueChanged<bool> onChanged;
  final String onLabel, offLabel;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 460;
    return InkWell(
      onTap: () => onChanged(!isOn),
      borderRadius: BorderRadius.circular(VetoTokens.rPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(VetoTokens.rPill),
          border: Border.all(color: VetoTokens.hairline, width: 1),
          boxShadow: VetoTokens.shadow1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9, height: 9,
              decoration: BoxDecoration(
                color: isOn ? VetoTokens.ok : VetoTokens.ink300,
                shape: BoxShape.circle,
                boxShadow: isOn ? const [BoxShadow(color: Color(0x4D2BA374), blurRadius: 0, spreadRadius: 4)] : null,
              ),
            ),
            const SizedBox(width: 8),
            if (!compact) ...[
              Text(isOn ? onLabel : offLabel,
                  style: VetoTokens.sans(12, FontWeight.w700, color: VetoTokens.ink700)),
              const SizedBox(width: 8),
            ],
            // Mini switch graphic
            Container(
              width: 36, height: 20,
              decoration: BoxDecoration(
                color: isOn ? VetoTokens.ok : VetoTokens.ink200,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
              padding: const EdgeInsets.all(2),
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4)]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.badge, required this.onTap});
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.notifications_outlined, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: VetoTokens.ink700,
            minimumSize: const Size(40, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VetoTokens.rSm),
              side: const BorderSide(color: VetoTokens.hairline, width: 1),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            top: -2, right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: VetoTokens.emerg,
                borderRadius: BorderRadius.circular(VetoTokens.rPill),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text('$badge',
                  style: VetoTokens.sans(10, FontWeight.w800, color: Colors.white)),
            ),
          ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.pending, required this.response,
    required this.active, required this.rating,
    required this.pendingLabel, required this.responseLabel,
    required this.activeLabel, required this.ratingLabel,
  });
  final int pending, active;
  final String response, rating;
  final String pendingLabel, responseLabel, activeLabel, ratingLabel;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 600;
    final cells = [
      _StatCell(icon: Icons.notifications_active_outlined, value: '$pending', label: pendingLabel, accent: VetoTokens.navy600),
      _StatCell(icon: Icons.timer_outlined, value: response, label: responseLabel, accent: VetoTokens.navy500),
      _StatCell(icon: Icons.folder_open_rounded, value: '$active', label: activeLabel, accent: VetoTokens.ok),
      _StatCell(icon: Icons.star_rounded, value: rating, label: ratingLabel, accent: VetoTokens.gold),
    ];
    if (compact) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 1.7,
        children: cells,
      );
    }
    return Row(
      children: [
        for (int i = 0; i < cells.length; i++) ...[
          Expanded(child: cells[i]),
          if (i < cells.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.icon, required this.value, required this.label, required this.accent});
  final IconData icon;
  final String value, label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: VetoTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(VetoTokens.rSm)),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 12),
          Text(label.toUpperCase(), style: VetoTokens.kicker.copyWith(color: VetoTokens.ink500, letterSpacing: 1.32)),
          const SizedBox(height: 4),
          Text(value, style: VetoTokens.serif(28, FontWeight.w800, color: VetoTokens.ink900, height: 1.0)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.sub});
  final String title, sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: VetoTokens.serif(20, FontWeight.w800, color: VetoTokens.ink900)),
        const SizedBox(height: 4),
        Text(sub, style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body, this.cta, this.onCta});
  final String title, body;
  final String? cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: VetoTokens.cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: VetoTokens.paper2, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: const Icon(Icons.notifications_off_outlined, size: 32, color: VetoTokens.ink300),
          ),
          const SizedBox(height: 14),
          Text(title, style: VetoTokens.serif(18, FontWeight.w700, color: VetoTokens.ink900), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(body, style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500), textAlign: TextAlign.center),
          if (cta != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                backgroundColor: VetoTokens.navy600, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                textStyle: VetoTokens.labelMd,
              ),
              child: Text(cta!),
            ),
          ],
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.data, required this.isUrgent, required this.isRtl,
    required this.liveLabel, required this.waitingLabel,
    required this.acceptLabel, required this.rejectLabel,
    required this.onAccept, required this.onReject,
  });
  final Map<String, dynamic> data;
  final bool isUrgent, isRtl;
  final String liveLabel, waitingLabel, acceptLabel, rejectLabel;
  final VoidCallback onAccept, onReject;

  @override
  Widget build(BuildContext context) {
    final accent = isUrgent ? VetoTokens.emerg : VetoTokens.warn;
    final softBg = isUrgent ? VetoTokens.emergBg : VetoTokens.warnSoft;
    final softBorder = isUrgent ? VetoTokens.emergBorder : const Color(0xFFF2D58E);
    final name = (data['userName'] ?? data['name'] ?? (isRtl ? 'משתמש' : 'User')).toString();
    final scenario = (data['scenario'] ?? data['type'] ?? '').toString();
    final eventId = (data['eventId'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(VetoTokens.rLg),
        border: Border.all(color: VetoTokens.hairline, width: 1),
        boxShadow: VetoTokens.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top — soft tint stripe
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(VetoTokens.rLg)),
              border: Border(bottom: BorderSide(color: softBorder, width: 1)),
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(VetoTokens.rMd),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: isUrgent
                        ? const [Color(0xFFE5354C), Color(0xFFB81B30)]
                        : const [Color(0xFFFFB74D), Color(0xFFC58B12)],
                  ),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(VetoTokens.rPill),
                          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Text(isUrgent ? liveLabel : waitingLabel,
                            style: VetoTokens.sans(10, FontWeight.w800, color: accent, letterSpacing: 0.6)),
                      ),
                      if (eventId.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text('#$eventId', style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      isRtl ? 'אזרח: $name' : 'Client: $name',
                      style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scenario.isNotEmpty) ...[
                  Text(
                    scenario,
                    style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink700, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAccept,
                      icon: Icon(isUrgent ? Icons.call_rounded : Icons.folder_open_rounded, size: 16),
                      label: Text(acceptLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: isUrgent ? VetoTokens.emerg : VetoTokens.navy600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rSm)),
                        textStyle: VetoTokens.labelMd,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: VetoTokens.ink700,
                        side: const BorderSide(color: VetoTokens.hairline, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rSm)),
                        textStyle: VetoTokens.labelMd,
                      ),
                      child: Text(rejectLabel),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.labels, required this.onCases, required this.onChat, required this.onProfile});
  final List<String> labels;
  final VoidCallback onCases, onChat, onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: VetoTokens.hairline, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: labels[0], selected: true, onTap: () {}),
              _NavItem(icon: Icons.folder_outlined, label: labels[1], selected: false, onTap: onCases),
              _NavItem(icon: Icons.chat_bubble_outline_rounded, label: labels[2], selected: false, onTap: onChat),
              _NavItem(icon: Icons.person_outline_rounded, label: labels[3], selected: false, onTap: onProfile),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? VetoTokens.navy600 : VetoTokens.ink300;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(label, style: VetoTokens.sans(11, selected ? FontWeight.w800 : FontWeight.w600, color: color)),
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: selected ? 22 : 4,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? VetoTokens.navy600 : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({required this.title, required this.fromLabel, required this.fallbackText, required this.data});
  final String title, fromLabel, fallbackText;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final details = data['details']?.toString().trim();
    final userId = data['userId']?.toString() ?? '—';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$fromLabel: $userId',
            style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900),
            textDirection: TextDirection.ltr),
        const SizedBox(height: 10),
        Text(title.toUpperCase(),
            style: VetoTokens.kicker.copyWith(color: VetoTokens.ink500, letterSpacing: 1.32)),
        const SizedBox(height: 6),
        Text((details == null || details.isEmpty) ? fallbackText : details,
            style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink700, height: 1.6)),
      ],
    );
  }
}
