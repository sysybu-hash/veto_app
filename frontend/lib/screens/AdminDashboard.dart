// ============================================================
//  AdminDashboard.dart — Admin Command Center
//  VETO Legal Emergency App
//  Luxury · Minimalist · Deep Navy & Silver
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';

// ── i18n ──────────────────────────────────────────────────────
const _i18n = {
  'he': {
    'title': 'מרכז בקרה',
    'admin': 'מנהל',
    'users': 'משתמשים',
    'lawyers': 'עורכי דין',
    'events': 'אירועים',
    'eventsToday': 'היום',
    'eventsWeek': 'השבוע',
    'eventsMonth': 'החודש',
    'activeLawyers': 'פעילים',
    'pendingLawyers': 'ממתינים',
    'recentActivity': 'פעילות אחרונה',
    'systemHealth': 'מצב המערכת',
    'backend': 'שרת',
    'db': 'בסיס נתונים',
    'socket': 'חיבור',
    'online': 'פעיל',
    'offline': 'לא זמין',
    'unknown': 'לא ידוע',
    'quickLinks': 'ניווט מהיר',
    'allUsers': 'כל המשתמשים',
    'allLawyers': 'כל עורכי הדין',
    'pendingApproval': 'ממתינים לאישור',
    'emergencyLogs': 'יומן חירום',
    'subscriptions': 'מנויים',
    'settings': 'הגדרות',
    'refresh': 'רענן',
    'loading': 'טוען...',
    'noActivity': 'אין פעילות אחרונה',
    'resolved': 'נסגר',
    'open': 'פתוח',
    'dispatched': 'בטיפול',
    'completed': 'הושלם',
    'failed': 'נכשל',
    'welcome': 'ברוכים הבאים',
  },
  'en': {
    'title': 'Command Center',
    'admin': 'Admin',
    'users': 'Users',
    'lawyers': 'Lawyers',
    'events': 'Events',
    'eventsToday': 'Today',
    'eventsWeek': 'This Week',
    'eventsMonth': 'This Month',
    'activeLawyers': 'Active',
    'pendingLawyers': 'Pending',
    'recentActivity': 'Recent Activity',
    'systemHealth': 'System Health',
    'backend': 'Backend Server',
    'db': 'Database',
    'socket': 'Socket.io',
    'online': 'Online',
    'offline': 'Offline',
    'unknown': 'Unknown',
    'quickLinks': 'Quick Access',
    'allUsers': 'All Users',
    'allLawyers': 'All Lawyers',
    'pendingApproval': 'Pending Approval',
    'emergencyLogs': 'Emergency Logs',
    'subscriptions': 'Subscriptions',
    'settings': 'Settings',
    'refresh': 'Refresh',
    'loading': 'Loading...',
    'noActivity': 'No recent activity',
    'resolved': 'Resolved',
    'open': 'Open',
    'dispatched': 'Dispatched',
    'completed': 'Completed',
    'failed': 'Failed',
    'welcome': 'Welcome back',
  },
  'ru': {
    'title': 'Командный центр',
    'admin': 'Администратор',
    'users': 'Пользователи',
    'lawyers': 'Адвокаты',
    'events': 'События',
    'eventsToday': 'Сегодня',
    'eventsWeek': 'Неделя',
    'eventsMonth': 'Месяц',
    'activeLawyers': 'Активные',
    'pendingLawyers': 'Ожидают',
    'recentActivity': 'Последняя активность',
    'systemHealth': 'Состояние системы',
    'backend': 'Сервер',
    'db': 'База данных',
    'socket': 'Подключение',
    'online': 'В сети',
    'offline': 'Не в сети',
    'unknown': 'Неизвестно',
    'quickLinks': 'Быстрый доступ',
    'allUsers': 'Все пользователи',
    'allLawyers': 'Все адвокаты',
    'pendingApproval': 'Ожидают одобрения',
    'emergencyLogs': 'Журнал событий',
    'subscriptions': 'Подписки',
    'settings': 'Настройки',
    'refresh': 'Обновить',
    'loading': 'Загрузка...',
    'noActivity': 'Нет активности',
    'resolved': 'Решено',
    'open': 'Открыто',
    'dispatched': 'В обработке',
    'completed': 'Завершено',
    'failed': 'Провалено',
    'welcome': 'Добро пожаловать',
  },
};

String _t(String code, String key) =>
    (_i18n[code] ?? _i18n['en']!)[key] ?? key;

// ── Screen ────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  final AuthService _auth = AuthService();

  // KPI data
  int _totalUsers    = 0;
  int _activeLawyers = 0;
  int _pendingLawyers = 0;
  int _eventsToday   = 0;
  int _eventsWeek    = 0;
  int _eventsMonth   = 0;

  List<Map<String, dynamic>> _recentEvents = [];

  // System health
  String _backendStatus = 'unknown';
  String _dbStatus      = 'unknown';
  String _socketStatus  = 'unknown';

  bool _loading = true;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnim  = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _loadAll();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadStats(), _checkHealth()]);
    if (mounted) {
      setState(() => _loading = false);
      _fadeController.forward(from: 0);
    }
  }

  Future<void> _loadStats() async {
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      final headers = AppConfig.httpHeaders({'Authorization': 'Bearer $tok'});

      final results = await Future.wait([
        http.get(Uri.parse('${AppConfig.baseUrl}/admin/stats'),
            headers: headers).timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('${AppConfig.baseUrl}/events?limit=10'),
            headers: headers).timeout(const Duration(seconds: 15)),
      ]);

      final statsRes  = results[0];
      final eventsRes = results[1];

      if (statsRes.statusCode == 200) {
        final d = jsonDecode(statsRes.body) as Map<String, dynamic>;
        _totalUsers     = (d['totalUsers']     ?? d['users']   ?? 0) as int;
        _activeLawyers  = (d['activeLawyers']  ?? d['lawyers'] ?? 0) as int;
        _pendingLawyers = (d['pendingLawyers'] ?? 0) as int;
        _eventsToday    = (d['eventsToday']    ?? 0) as int;
        _eventsWeek     = (d['eventsWeek']     ?? 0) as int;
        _eventsMonth    = (d['eventsMonth']    ?? 0) as int;
      }

      if (eventsRes.statusCode == 200) {
        final data = jsonDecode(eventsRes.body);
        final list = data is List ? data : (data['events'] ?? data['data'] ?? []);
        _recentEvents = List<Map<String, dynamic>>.from(
            (list as List).take(8).map((e) => e as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  Future<void> _checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('${AppConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        _backendStatus = 'online';
        final dbVal = d['db'] ?? d['mongo'] ?? '';
        _dbStatus      = (dbVal == 'connected') ? 'online' : 'offline';
        _socketStatus  = (d['socket'] == true)  ? 'online' : 'offline';
      } else {
        _backendStatus = 'offline';
      }
    } catch (_) {
      _backendStatus = 'offline';
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final code  = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoColors.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF050D1A),
                Color(0xFF071022),
                Color(0xFF050D1A),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(children: [
              _buildTopBar(context, code),
              Expanded(
                child: _loading
                    ? _buildLoadingView(code)
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: RefreshIndicator(
                          onRefresh: _loadAll,
                          color: VetoColors.accent,
                          backgroundColor: VetoColors.surfaceHigh,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                _buildWelcomeBanner(code),
                                const SizedBox(height: 24),
                                _buildSectionLabel(_t(code, 'events')),
                                const SizedBox(height: 12),
                                _buildEventKpis(code),
                                const SizedBox(height: 24),
                                _buildUserLawyerRow(code),
                                const SizedBox(height: 24),
                                _buildSectionLabel(_t(code, 'systemHealth')),
                                const SizedBox(height: 12),
                                _buildHealthCard(code),
                                const SizedBox(height: 24),
                                _buildSectionLabel(_t(code, 'recentActivity')),
                                const SizedBox(height: 12),
                                _buildActivityFeed(code),
                                const SizedBox(height: 24),
                                _buildSectionLabel(_t(code, 'quickLinks')),
                                const SizedBox(height: 12),
                                _buildQuickLinks(code, context),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: VetoColors.border, width: 1),
        ),
      ),
      child: Row(children: [
        // Back + Title
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: VetoColors.silver, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        // Shield icon
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A5CCC), Color(0xFF4E9BFF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('VETO',
                style: TextStyle(
                    color: VetoColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3)),
            Text(_t(code, 'title'),
                style: const TextStyle(
                    color: VetoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        // Refresh
        GestureDetector(
          onTap: _loadAll,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: VetoColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VetoColors.border),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: VetoColors.silver, size: 18),
          ),
        ),
      ]),
    );
  }

  // ── Loading ──────────────────────────────────────────────────
  Widget _buildLoadingView(String code) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: VetoColors.accentGlow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.shield_rounded,
                color: VetoColors.accent, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(_t(code, 'loading'),
            style: const TextStyle(color: VetoColors.silver, fontSize: 14)),
      ]),
    );
  }

  // ── Welcome banner ───────────────────────────────────────────
  Widget _buildWelcomeBanner(String code) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1E3D), Color(0xFF0D1F3C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VetoColors.borderLight),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t(code, 'welcome'),
                style: const TextStyle(
                    color: VetoColors.silver, fontSize: 13)),
            const SizedBox(height: 4),
            Text(_t(code, 'admin'),
                style: const TextStyle(
                    color: VetoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              _StatusPill(
                  color: _backendStatus == 'online'
                      ? VetoColors.success
                      : VetoColors.error,
                  label: _backendStatus == 'online'
                      ? _t(code, 'online')
                      : _t(code, 'offline')),
            ]),
          ]),
        ),
        const SizedBox(width: 16),
        // Live summary
        Column(children: [
          _MiniStat(value: _totalUsers.toString(),   label: _t(code, 'users')),
          const SizedBox(height: 8),
          _MiniStat(value: _activeLawyers.toString(), label: _t(code, 'lawyers')),
        ]),
      ]),
    );
  }

  // ── Event KPI row ────────────────────────────────────────────
  Widget _buildEventKpis(String code) {
    return Row(children: [
      Expanded(child: _KpiCard(
        icon: Icons.today_rounded,
        color: VetoColors.accent,
        label: _t(code, 'eventsToday'),
        value: _eventsToday.toString(),
      )),
      const SizedBox(width: 10),
      Expanded(child: _KpiCard(
        icon: Icons.date_range_rounded,
        color: const Color(0xFF00BCD4),
        label: _t(code, 'eventsWeek'),
        value: _eventsWeek.toString(),
      )),
      const SizedBox(width: 10),
      Expanded(child: _KpiCard(
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF9C27B0),
        label: _t(code, 'eventsMonth'),
        value: _eventsMonth.toString(),
      )),
    ]);
  }

  // ── Users & Lawyers row ──────────────────────────────────────
  Widget _buildUserLawyerRow(String code) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _KpiCard(
        icon: Icons.people_alt_rounded,
        color: VetoColors.success,
        label: _t(code, 'users'),
        value: _totalUsers.toString(),
        large: true,
      )),
      const SizedBox(width: 10),
      Expanded(child: Column(children: [
        _KpiCard(
          icon: Icons.balance_rounded,
          color: const Color(0xFF0EA5E9),
          label: _t(code, 'activeLawyers'),
          value: _activeLawyers.toString(),
        ),
        const SizedBox(height: 10),
        _KpiCard(
          icon: Icons.pending_actions_rounded,
          color: VetoColors.warning,
          label: _t(code, 'pendingLawyers'),
          value: _pendingLawyers.toString(),
        ),
      ])),
    ]);
  }

  // ── System health card ───────────────────────────────────────
  Widget _buildHealthCard(String code) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VetoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetoColors.border),
      ),
      child: Column(children: [
        _HealthRow(
            label: _t(code, 'backend'),
            status: _backendStatus,
            onlineLabel:  _t(code, 'online'),
            offlineLabel: _t(code, 'offline'),
            unknownLabel: _t(code, 'unknown')),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: VetoColors.border),
        ),
        _HealthRow(
            label: _t(code, 'db'),
            status: _dbStatus,
            onlineLabel:  _t(code, 'online'),
            offlineLabel: _t(code, 'offline'),
            unknownLabel: _t(code, 'unknown')),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: VetoColors.border),
        ),
        _HealthRow(
            label: _t(code, 'socket'),
            status: _socketStatus,
            onlineLabel:  _t(code, 'online'),
            offlineLabel: _t(code, 'offline'),
            unknownLabel: _t(code, 'unknown')),
      ]),
    );
  }

  // ── Activity feed ────────────────────────────────────────────
  Widget _buildActivityFeed(String code) {
    if (_recentEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: VetoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VetoColors.border),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox_rounded, color: VetoColors.silverDim, size: 40),
            const SizedBox(height: 8),
            Text(_t(code, 'noActivity'),
                style: const TextStyle(
                    color: VetoColors.silverDim, fontSize: 14)),
          ]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: VetoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetoColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentEvents.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: VetoColors.border),
        itemBuilder: (context, i) =>
            _ActivityTile(event: _recentEvents[i], code: code),
      ),
    );
  }

  // ── Quick links grid ─────────────────────────────────────────
  Widget _buildQuickLinks(String code, BuildContext context) {
    final links = [
      (Icons.people_rounded,           VetoColors.success,               _t(code, 'allUsers'),        '/admin_users'),
      (Icons.balance_rounded,          const Color(0xFF0EA5E9),           _t(code, 'allLawyers'),      '/admin_lawyers'),
      (Icons.pending_actions_rounded,  VetoColors.warning,               _t(code, 'pendingApproval'), '/admin_pending'),
      (Icons.warning_amber_rounded,    VetoColors.vetoRed,               _t(code, 'emergencyLogs'),   '/admin_logs'),
      (Icons.subscriptions_rounded,    const Color(0xFF9C27B0),           _t(code, 'subscriptions'),   '/admin_subscriptions'),
      (Icons.settings_rounded,         VetoColors.silverDim,             _t(code, 'settings'),        '/admin_settings'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.05,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: links.length,
      itemBuilder: (ctx, i) {
        final (icon, color, label, route) = links[i];
        return _QuickLinkTile(
          icon: icon, color: color, label: label,
          onTap: () => Navigator.pushNamed(ctx, route),
        );
      },
    );
  }

  // ── Section label ────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Row(children: [
      Container(
        width: 3, height: 14,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: VetoColors.accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      Text(text.toUpperCase(),
          style: const TextStyle(
              color: VetoColors.silver,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  Sub-widgets
// ══════════════════════════════════════════════════════════════

class _StatusPill extends StatelessWidget {
  final Color  color;
  final String label;
  const _StatusPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11,
            fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: VetoColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VetoColors.border),
      ),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                color: VetoColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: VetoColors.silver, fontSize: 10)),
      ]),
    );
  }
}

// ── KPI card ─────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label, value;
  final bool     large;

  const _KpiCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(large ? 18 : 14),
      decoration: BoxDecoration(
        color: VetoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: VetoColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: large ? 34 : 26)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: VetoColors.silver, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Health row ───────────────────────────────────────────────
class _HealthRow extends StatelessWidget {
  final String label, status;
  final String onlineLabel, offlineLabel, unknownLabel;

  const _HealthRow({
    required this.label,
    required this.status,
    required this.onlineLabel,
    required this.offlineLabel,
    required this.unknownLabel,
  });

  @override
  Widget build(BuildContext context) {
    final good    = status == 'online';
    final unknown = status == 'unknown';
    final color   = good    ? VetoColors.success
        : unknown ? VetoColors.warning
        : VetoColors.error;
    final statusLabel = good    ? onlineLabel
        : unknown ? unknownLabel
        : offlineLabel;

    return Row(children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 10),
      Expanded(child: Text(label,
          style: const TextStyle(
              color: VetoColors.white, fontSize: 14))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(statusLabel,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}

// ── Activity tile ─────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final String code;

  const _ActivityTile({required this.event, required this.code});

  static const _statusColors = {
    'completed': VetoColors.success,
    'resolved':  VetoColors.success,
    'accepted':  Color(0xFF0EA5E9),
    'dispatching': Color(0xFF0EA5E9),
    'dispatched':  Color(0xFF0EA5E9),
    'in_progress': VetoColors.warning,
    'failed':    VetoColors.error,
    'cancelled': VetoColors.silverDim,
  };

  @override
  Widget build(BuildContext context) {
    final status = (event['status'] ?? 'open') as String;
    final color  = _statusColors[status] ?? VetoColors.vetoRed;

    final Map<String, String> labels = {
      'completed':   _t(code, 'completed'),
      'resolved':    _t(code, 'resolved'),
      'accepted':    _t(code, 'dispatched'),
      'dispatching': _t(code, 'dispatched'),
      'dispatched':  _t(code, 'dispatched'),
      'in_progress': _t(code, 'dispatched'),
      'failed':      _t(code, 'failed'),
      'cancelled':   _t(code, 'failed'),
    };
    final statusLabel = labels[status] ?? _t(code, 'open');

    final ts = event['createdAt'] ?? event['triggered_at'] ?? event['timestamp'];
    final dt = ts != null ? DateTime.tryParse(ts as String) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning_amber_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event['scenario'] ?? event['type'] ?? 'Emergency',
                style: const TextStyle(
                    color: VetoColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (dt != null)
              Text(
                '${dt.day}/${dt.month}/${dt.year}  '
                    '${dt.hour.toString().padLeft(2, '0')}:'
                    '${dt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    color: VetoColors.silverDim, fontSize: 11),
              ),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(statusLabel,
              style: TextStyle(
                  color: color, fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ── Quick link tile ───────────────────────────────────────────
class _QuickLinkTile extends StatefulWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickLinkTile> createState() => _QuickLinkTileState();
}

class _QuickLinkTileState extends State<_QuickLinkTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: VetoColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VetoColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: VetoColors.silver,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
