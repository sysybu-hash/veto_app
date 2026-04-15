import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
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
  String _phone = '';
  bool _isAvailable = true;
  bool _isBooting = true;
  final List<Map<String, dynamic>> _alerts = [];
  final List<Map<String, dynamic>> _activeCases = [];
  StreamSubscription<Map<String, dynamic>>? _alertSub;
  StreamSubscription<Map<String, dynamic>>? _caseAcceptedSub;
  StreamSubscription<Map<String, dynamic>>? _caseTakenSub;

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
    final phone = await auth.getStoredPhone() ?? '';
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
      _phone = phone;
      _isBooting = false;
    });

    await SocketService().connect(role: role);
    SocketService().emit('lawyer_availability', {'available': _isAvailable});

    // Register browser push subscription (fire-and-forget — non-blocking)
    PushService().registerLawyerPush();

    _alertSub = SocketService().onNewEmergencyAlert.listen((data) {
      if (!mounted) return;
      setState(() => _alerts.insert(0, data));
      _showAlertDialog(data);
    });

    _caseAcceptedSub = SocketService().onCaseAccepted.listen((data) {
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
        background: VetoPalette.surface2,
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t(code, 'queue'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              for (final a in _alerts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.emergency_rounded, color: Color(0xFFFF3B3B)),
                  title: Text(a['userName']?.toString() ?? 'User'),
                  subtitle: Text(
                    a['eventId']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
      background: VetoPalette.surface2,
    );
  }

  void _showSnack(String message, {Color background = VetoPalette.surface2}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
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
            backgroundColor: VetoPalette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
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
                      color: VetoPalette.text,
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
                  style: const TextStyle(color: VetoPalette.textMuted),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _acceptCase(alert);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: VetoPalette.success,
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
        backgroundColor: const Color(0xFFF0F4FF),
        body: _isBooting
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B8FFF)))
            : Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _LawyerAuroraPainter())),
                SafeArea(
                  child: Column(children: [
                    // ── Top bar ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(children: [
                        // Bell
                        Stack(children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF334155)),
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
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        // Available badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isAvailable ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isAvailable ? (isRtl ? 'מחובר' : 'Online') : (isRtl ? 'לא זמין' : 'Offline'),
                              style: TextStyle(
                                color: _isAvailable ? const Color(0xFF16A34A) : const Color(0xFFB45309),
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
                          // Greeting card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F8)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0,4))],
                            ),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  isRtl ? 'שלום, עו"ד $_lawyerName' : 'Hello, Adv. $_lawyerName',
                                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isRtl
                                    ? 'יש לך ${_activeCases.length} תיקים פעילים'
                                    : 'You have ${_activeCases.length} active cases',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                ),
                              ])),
                              // Avatar
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F8),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF5B8FFF).withValues(alpha: 0.3), width: 2),
                                ),
                                child: const Icon(Icons.person_rounded, color: Color(0xFF334155), size: 28),
                              ),
                            ]),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F8)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.toggle_on_rounded, color: Color(0xFF5B8FFF), size: 22),
                              const SizedBox(width: 10),
                              Expanded(child: Text(
                                _isAvailable ? (isRtl ? 'זמין לקריאות' : 'Available') : (isRtl ? 'לא זמין' : 'Unavailable'),
                                style: TextStyle(color: _isAvailable ? const Color(0xFF22C55E) : const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 15),
                              )),
                              Switch(
                                value: _isAvailable,
                                onChanged: _toggleAvailability,
                                activeThumbColor: const Color(0xFF5B8FFF),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 20),

                          // Active cases section
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              isRtl ? 'תיקים פעילים' : 'Active Cases',
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (_alerts.isEmpty && _activeCases.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F8)),
                              ),
                              child: Center(child: Text(
                                _t(code, 'emptyTitle'),
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                textAlign: TextAlign.center,
                              )),
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F8))),
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
              ]),
      ),
    );
  }
}

// ── Lawyer Aurora painter ─────────────────────────────────
class _LawyerAuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0,0,w,h), Paint()..color = const Color(0xFFF0F4FF));
    _b(canvas, Offset(w*0.85, h*0.05), w*0.55, const Color(0xFF38BDF8), 0.18);
    _b(canvas, Offset(w*0.10, h*0.92), w*0.55, const Color(0xFF00C9B1), 0.16);
  }
  void _b(Canvas c, Offset center, double r, Color color, double a) {
    c.drawCircle(center, r, Paint()..shader = RadialGradient(
      colors: [color.withValues(alpha: a), color.withValues(alpha: 0)],
    ).createShader(Rect.fromCircle(center: center, radius: r)));
  }
  @override bool shouldRepaint(_) => false;
}

// ── Lawyer stat tile ──────────────────────────────────────
class _LawyerStat extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData? icon;
  const _LawyerStat({required this.value, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: Column(children: [
        if (icon != null)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          ])
        else
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11), textAlign: TextAlign.center),
      ]),
    ));
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(chipLabel, style: TextStyle(color: chipColor, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          isRtl ? 'אזרח: $nameRaw' : 'Client: $nameRaw',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          scenario.isEmpty ? (isRtl ? 'אירוע חירום' : 'Emergency') : scenario,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: FilledButton(
            onPressed: onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A2340),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(acceptLabel),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFE2E8F8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(rejectLabel),
          )),
        ]),
      ]),
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
          Icon(icon, color: selected ? const Color(0xFF5B8FFF) : const Color(0xFF64748B), size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: selected ? const Color(0xFF5B8FFF) : const Color(0xFF64748B),
            fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          )),
        ]),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String name;
  final String phone;
  final bool isAvailable;
  final String profileLabel;
  final String logoutLabel;
  final String settingsLabel;
  final String homeLabel;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final VoidCallback onSettings;
  final VoidCallback onHome;

  const _HeroHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.name,
    required this.phone,
    required this.isAvailable,
    required this.profileLabel,
    required this.logoutLabel,
    required this.settingsLabel,
    required this.homeLabel,
    required this.onProfile,
    required this.onLogout,
    required this.onSettings,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF0F9FF),
            Color(0xFFFFFFFF),
            Color(0xFFECFDF5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: VetoPalette.border),
        boxShadow: [
          BoxShadow(
            color: VetoPalette.primary.withValues(alpha: 0.10),
            blurRadius: 34,
            spreadRadius: 2,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: VetoPalette.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: VetoPalette.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(Icons.gavel_rounded,
                    color: VetoPalette.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: VetoPalette.info,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: VetoPalette.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderAction(
                icon: Icons.home_outlined,
                tooltip: homeLabel,
                onTap: onHome,
              ),
              const SizedBox(width: 8),
              _HeaderAction(
                icon: Icons.person_outline_rounded,
                tooltip: profileLabel,
                onTap: onProfile,
              ),
              const SizedBox(width: 8),
              _HeaderAction(
                icon: Icons.map_outlined,
                tooltip: 'Google Maps',
                onTap: () => Navigator.pushNamed(context, '/maps'),
              ),
              const SizedBox(width: 8),
              _HeaderAction(
                icon: Icons.settings_outlined,
                tooltip: settingsLabel,
                onTap: onSettings,
              ),
              const SizedBox(width: 8),
              _HeaderAction(
                icon: Icons.logout_rounded,
                tooltip: logoutLabel,
                onTap: onLogout,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            subtitle,
            style: const TextStyle(
              color: VetoPalette.textMuted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusPill(
                icon: Icons.verified_user_outlined,
                label: name,
                color: VetoPalette.primary,
              ),
              if (phone.isNotEmpty)
                _StatusPill(
                  icon: Icons.phone_outlined,
                  label: phone,
                  color: VetoPalette.info,
                ),
              _StatusPill(
                icon: Icons.circle,
                label: isAvailable ? 'ONLINE' : 'OFFLINE',
                color:
                    isAvailable ? VetoPalette.success : VetoPalette.textSubtle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: VetoPalette.surface2.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VetoPalette.border),
          ),
          child: Icon(icon, color: VetoPalette.textMuted, size: 20),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: const BorderSide(color: VetoPalette.border),
          right: const BorderSide(color: VetoPalette.border),
          bottom: const BorderSide(color: VetoPalette.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: VetoPalette.textSubtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  final String title;
  final String body;
  final String hint;

  const _EmptyQueue({
    required this.title,
    required this.body,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VetoPalette.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.mark_email_read_outlined,
                color: VetoPalette.primary, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VetoPalette.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VetoPalette.textMuted,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VetoPalette.info,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String code;
  final String title;
  final String requestFrom;
  final String requestDetails;
  final String fallbackText;
  final String acceptLabel;
  final String rejectLabel;
  final Map<String, dynamic> data;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.code,
    required this.title,
    required this.requestFrom,
    required this.requestDetails,
    required this.fallbackText,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.data,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final details = data['details']?.toString().trim();
    final userId = data['userId']?.toString() ?? '—';
    final language = data['preferredLanguage']?.toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: VetoPalette.emergency.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: VetoPalette.emergency.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: VetoPalette.emergency.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: VetoPalette.emergency,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (language != null && language.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: VetoPalette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    language.toUpperCase(),
                    style: const TextStyle(
                      color: VetoPalette.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$requestFrom: $userId',
            style: const TextStyle(
              color: VetoPalette.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 10),
          Text(
            requestDetails,
            style: const TextStyle(
              color: VetoPalette.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (details == null || details.isEmpty) ? fallbackText : details,
            style: const TextStyle(
              color: VetoPalette.textMuted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: Text(rejectLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: VetoPalette.success,
                  ),
                  child: Text(acceptLabel),
                ),
              ),
            ],
          ),
        ],
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
            color: VetoPalette.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: VetoPalette.textSubtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (details == null || details.isEmpty) ? fallbackText : details,
          style: const TextStyle(
            color: VetoPalette.textMuted,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _ActiveCaseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onViewVault;
  final VoidCallback onComplete;

  const _ActiveCaseCard({
    required this.data,
    required this.onViewVault,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final userId = data['userId']?.toString() ?? '—';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VetoPalette.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, color: VetoPalette.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'User ID: $userId',
                  style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: VetoPalette.success),
                onPressed: onComplete,
                tooltip: 'Mark Complete',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onViewVault,
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: const Text('VIEW SHARED VAULT'),
                  style: FilledButton.styleFrom(
                    backgroundColor: VetoPalette.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
