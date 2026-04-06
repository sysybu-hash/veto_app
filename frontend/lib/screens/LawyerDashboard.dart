import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../widgets/app_language_menu.dart';

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
  StreamSubscription<Map<String, dynamic>>? _alertSub;

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

    if (role == 'admin') {
      Navigator.of(context).pushReplacementNamed('/admin_settings');
      return;
    }
    if (role != 'lawyer') {
      Navigator.of(context).pushReplacementNamed('/veto_screen');
      return;
    }

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

    _alertSub = SocketService().onNewEmergencyAlert.listen((data) {
      if (!mounted) return;
      setState(() => _alerts.insert(0, data));
      _showAlertDialog(data);
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel();
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

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        body: _isBooting
            ? const Center(
                child: CircularProgressIndicator(color: VetoPalette.primary),
              )
            : SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: _HeroHeader(
                          eyebrow: _t(code, 'eyebrow'),
                          title: _t(code, 'title'),
                          subtitle: _t(code, 'subtitle'),
                          name: _lawyerName,
                          phone: _phone,
                          isAvailable: _isAvailable,
                          profileLabel: _t(code, 'profile'),
                          logoutLabel: _t(code, 'logout'),
                          settingsLabel: code == 'he' ? 'הגדרות' : code == 'ru' ? 'Настройки' : 'Settings',
                          onProfile: () => Navigator.pushNamed(context, '/profile'),
                          onLogout: () => AuthService().logout(context),
                          onSettings: () => Navigator.pushNamed(context, '/lawyer_settings'),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: _t(code, 'status'),
                                value: _isAvailable
                                    ? _t(code, 'statusOnline')
                                    : _t(code, 'statusOffline'),
                                icon: Icons.toggle_on_rounded,
                                color: _isAvailable
                                    ? VetoPalette.success
                                    : VetoPalette.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                label: _t(code, 'queue'),
                                value: '${_alerts.length}',
                                icon: Icons.mark_email_unread_outlined,
                                color: _alerts.isEmpty
                                    ? VetoPalette.info
                                    : VetoPalette.emergency,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                label: _t(code, 'response'),
                                value: _t(code, 'responseValue'),
                                icon: Icons.timer_outlined,
                                color: VetoPalette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: VetoPalette.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: VetoPalette.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _t(code, 'shift').toUpperCase(),
                                          style: const TextStyle(
                                            color: VetoPalette.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _t(code, 'shiftTitle'),
                                          style: const TextStyle(
                                            color: VetoPalette.text,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const AppLanguageMenu(compact: true),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _t(code, 'shiftBody'),
                                style: const TextStyle(
                                  color: VetoPalette.textMuted,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: VetoPalette.bg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: (_isAvailable
                                            ? VetoPalette.success
                                            : VetoPalette.border)
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isAvailable
                                            ? VetoPalette.success
                                            : VetoPalette.textSubtle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isAvailable
                                                ? _t(code, 'statusOnline')
                                                : _t(code, 'statusOffline'),
                                            style: TextStyle(
                                              color: _isAvailable
                                                  ? VetoPalette.success
                                                  : VetoPalette.textMuted,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _t(code, 'statusHelp'),
                                            style: const TextStyle(
                                              color: VetoPalette.textSubtle,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _isAvailable,
                                      onChanged: _toggleAvailability,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t(code, 'activity').toUpperCase(),
                              style: const TextStyle(
                                color: VetoPalette.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _t(code, 'activityTitle'),
                              style: const TextStyle(
                                color: VetoPalette.text,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _t(code, 'activitySubtitle'),
                              style: const TextStyle(
                                color: VetoPalette.textMuted,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_alerts.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          child: _EmptyQueue(
                            title: _t(code, 'emptyTitle'),
                            body: _t(code, 'emptyBody'),
                            hint: _t(code, 'emptyHint'),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        sliver: SliverList.separated(
                          itemCount: _alerts.length,
                          itemBuilder: (context, index) {
                            final alert = _alerts[index];
                            return _RequestCard(
                              code: code,
                              title: _t(code, 'request'),
                              requestFrom: _t(code, 'requestFrom'),
                              requestDetails: _t(code, 'requestDetails'),
                              fallbackText: _t(code, 'requestUnknown'),
                              acceptLabel: _t(code, 'accept'),
                              rejectLabel: _t(code, 'reject'),
                              data: alert,
                              onAccept: () => _acceptCase(alert),
                              onReject: () => _rejectCase(alert),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                        ),
                      ),
                  ],
                ),
              ),
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
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final VoidCallback onSettings;

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
    required this.onProfile,
    required this.onLogout,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF14213A),
            VetoPalette.surface,
            Color(0xFF10284B),
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
                icon: Icons.person_outline_rounded,
                tooltip: profileLabel,
                onTap: onProfile,
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
          top: BorderSide(color: VetoPalette.border),
          right: BorderSide(color: VetoPalette.border),
          bottom: BorderSide(color: VetoPalette.border),
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