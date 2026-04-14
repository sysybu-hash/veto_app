// ============================================================
//  AdminDashboard.dart — Full admin command center
//  KPI cards, activity feed, system health, quick links
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
    'title': 'לוח בקרה — מנהל',
    'users': 'משתמשים',
    'lawyers': 'עורכי דין',
    'events': 'אירועים',
    'eventsToday': 'אירועים היום',
    'eventsWeek': 'השבוע',
    'eventsMonth': 'החודש',
    'active': 'פעילים',
    'pending': 'ממתינים לאישור',
    'recentActivity': 'פעילות אחרונה',
    'systemHealth': 'מצב המערכת',
    'backend': 'שרת',
    'db': 'בסיס נתונים',
    'socket': 'חיבור Socket',
    'online': 'פעיל',
    'offline': 'לא זמין',
    'unknown': 'לא ידוע',
    'quickLinks': 'קיצורי דרך',
    'allUsers': 'כל המשתמשים',
    'allLawyers': 'כל עורכי הדין',
    'pendingLawyers': 'ממתינים לאישור',
    'emergencyLogs': 'יומן חירום',
    'subscriptions': 'מנויים',
    'refresh': 'רענן',
    'loading': 'טוען...',
    'noActivity': 'אין פעילות אחרונה',
    'resolvedStatus': 'נסגר',
    'openStatus': 'פתוח',
    'dispatchedStatus': 'בטיפול',
  },
  'en': {
    'title': 'Admin Dashboard',
    'users': 'Users',
    'lawyers': 'Lawyers',
    'events': 'Events',
    'eventsToday': 'Today',
    'eventsWeek': 'This Week',
    'eventsMonth': 'This Month',
    'active': 'Active',
    'pending': 'Pending Approval',
    'recentActivity': 'Recent Activity',
    'systemHealth': 'System Health',
    'backend': 'Backend',
    'db': 'Database',
    'socket': 'Socket',
    'online': 'Online',
    'offline': 'Offline',
    'unknown': 'Unknown',
    'quickLinks': 'Quick Links',
    'allUsers': 'All Users',
    'allLawyers': 'All Lawyers',
    'pendingLawyers': 'Pending Approval',
    'emergencyLogs': 'Emergency Logs',
    'subscriptions': 'Subscriptions',
    'refresh': 'Refresh',
    'loading': 'Loading...',
    'noActivity': 'No recent activity',
    'resolvedStatus': 'Resolved',
    'openStatus': 'Open',
    'dispatchedStatus': 'Dispatched',
  },
  'ru': {
    'title': 'Панель администратора',
    'users': 'Пользователи',
    'lawyers': 'Адвокаты',
    'events': 'События',
    'eventsToday': 'Сегодня',
    'eventsWeek': 'За неделю',
    'eventsMonth': 'За месяц',
    'active': 'Активные',
    'pending': 'Ожидают подтверждения',
    'recentActivity': 'Последняя активность',
    'systemHealth': 'Состояние системы',
    'backend': 'Сервер',
    'db': 'База данных',
    'socket': 'Socket',
    'online': 'В сети',
    'offline': 'Не в сети',
    'unknown': 'Неизвестно',
    'quickLinks': 'Быстрые ссылки',
    'allUsers': 'Все пользователи',
    'allLawyers': 'Все адвокаты',
    'pendingLawyers': 'Ожидают одобрения',
    'emergencyLogs': 'Журнал экстренных случаев',
    'subscriptions': 'Подписки',
    'refresh': 'Обновить',
    'loading': 'Загрузка...',
    'noActivity': 'Нет последней активности',
    'resolvedStatus': 'Решено',
    'openStatus': 'Открыто',
    'dispatchedStatus': 'В обработке',
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

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _auth = AuthService();

  // KPI data
  int _totalUsers = 0, _activeLawyers = 0, _pendingLawyers = 0;
  int _eventsToday = 0, _eventsWeek = 0, _eventsMonth = 0;
  List<Map<String, dynamic>> _recentEvents = [];

  // System health
  String _backendStatus = 'unknown';
  String _dbStatus = 'unknown';
  String _socketStatus = 'unknown';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadStats(), _checkHealth()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadStats() async {
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      final headers = AppConfig.httpHeaders({'Authorization': 'Bearer $tok'});

      final results = await Future.wait([
        http.get(Uri.parse('${AppConfig.baseUrl}/admin/stats'),
            headers: headers).timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('${AppConfig.baseUrl}/events/history?limit=10'),
            headers: headers).timeout(const Duration(seconds: 15)),
      ]);

      final statsRes = results[0];
      final eventsRes = results[1];

      if (statsRes.statusCode == 200) {
        final d = jsonDecode(statsRes.body) as Map<String, dynamic>;
        _totalUsers = (d['totalUsers'] ?? d['users'] ?? 0) as int;
        _activeLawyers = (d['activeLawyers'] ?? d['lawyers'] ?? 0) as int;
        _pendingLawyers = (d['pendingLawyers'] ?? 0) as int;
        _eventsToday = (d['eventsToday'] ?? 0) as int;
        _eventsWeek = (d['eventsWeek'] ?? 0) as int;
        _eventsMonth = (d['eventsMonth'] ?? 0) as int;
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
      final res = await http.get(
        Uri.parse(AppConfig.healthCheckUrl),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        _backendStatus = 'online';
        // server returns 'db' (alias for 'mongo') and 'socket' boolean
        final dbVal = d['db'] ?? d['mongo'] ?? '';
        _dbStatus = (dbVal == 'connected') ? 'online' : 'offline';
        _socketStatus = (d['socket'] == true) ? 'online' : 'offline';
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
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.darkBg,
          title: Text(_t(code, 'title'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () => Navigator.of(context).pushNamed('/landing'),
              tooltip: _t(code, 'title') == 'Admin Dashboard' ? 'Home' : 'דף הבית',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadAll,
              tooltip: _t(code, 'refresh'),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI grid
                      _sectionLabel(_t(code, 'events')),
                      const SizedBox(height: 8),
                      _buildKpiGrid(code),
                      const SizedBox(height: 20),
                      // User / Lawyer stats
                      _buildUserLawyerRow(code),
                      const SizedBox(height: 20),
                      // System health
                      _sectionLabel(_t(code, 'systemHealth')),
                      const SizedBox(height: 8),
                      _buildHealthCard(code),
                      const SizedBox(height: 20),
                      // Recent activity
                      _sectionLabel(_t(code, 'recentActivity')),
                      const SizedBox(height: 8),
                      _buildActivityFeed(code),
                      const SizedBox(height: 20),
                      // Quick links
                      _sectionLabel(_t(code, 'quickLinks')),
                      const SizedBox(height: 8),
                      _buildQuickLinks(code),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: VetoPalette.textMuted,
          fontSize: 12, fontWeight: FontWeight.w700,
          letterSpacing: 0.8));

  Widget _buildKpiGrid(String code) {
    return Row(children: [
      Expanded(child: _KpiCard(
        icon: Icons.today_rounded, color: VetoPalette.primary,
        label: _t(code, 'eventsToday'), value: _eventsToday.toString(),
      )),
      const SizedBox(width: 10),
      Expanded(child: _KpiCard(
        icon: Icons.date_range_rounded, color: VetoPalette.info,
        label: _t(code, 'eventsWeek'), value: _eventsWeek.toString(),
      )),
      const SizedBox(width: 10),
      Expanded(child: _KpiCard(
        icon: Icons.calendar_month_rounded, color: const Color(0xFFC9A050),
        label: _t(code, 'eventsMonth'), value: _eventsMonth.toString(),
      )),
    ]);
  }

  Widget _buildUserLawyerRow(String code) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _KpiCard(
        icon: Icons.people_alt_rounded, color: VetoPalette.success,
        label: _t(code, 'users'), value: _totalUsers.toString(),
        sublabel: _t(code, 'active'),
        large: true,
      )),
      const SizedBox(width: 10),
      Expanded(child: Column(children: [
        _KpiCard(
          icon: Icons.balance_rounded, color: const Color(0xFFC9A050),
          label: _t(code, 'active'), value: _activeLawyers.toString(),
          sublabel: _t(code, 'lawyers'),
        ),
        const SizedBox(height: 10),
        _KpiCard(
          icon: Icons.pending_actions_rounded, color: VetoPalette.warning,
          label: _t(code, 'pending'), value: _pendingLawyers.toString(),
          sublabel: _t(code, 'lawyers'),
        ),
      ])),
    ]);
  }

  Widget _buildHealthCard(String code) {
    Widget indicatorRow(String label, String status) {
      final good = status == 'online';
      final unknown = status == 'unknown';
      final color = good ? VetoPalette.success
          : unknown ? VetoPalette.warning
          : VetoPalette.emergency;
      final statusLabel = good ? _t(code, 'online')
          : unknown ? _t(code, 'unknown')
          : _t(code, 'offline');
      return Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
            style: const TextStyle(color: VetoPalette.text, fontSize: 14))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(statusLabel,
              style: TextStyle(color: color, fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        indicatorRow(_t(code, 'backend'), _backendStatus),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: VetoPalette.border)),
        indicatorRow(_t(code, 'db'), _dbStatus),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: VetoPalette.border)),
        indicatorRow(_t(code, 'socket'), _socketStatus),
      ]),
    );
  }

  Widget _buildActivityFeed(String code) {
    if (_recentEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: VetoPalette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VetoPalette.border)),
        child: Center(
          child: Text(_t(code, 'noActivity'),
              style: const TextStyle(color: VetoPalette.textMuted, fontSize: 14)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentEvents.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: VetoPalette.border),
        itemBuilder: (context, i) {
          final ev = _recentEvents[i];
          final status = ev['status'] ?? 'open';
          final statusColor = status == 'resolved'
              ? VetoPalette.success
              : status == 'dispatched'
                  ? const Color(0xFFC9A050)
                  : VetoPalette.emergency;
          final statusLabel = status == 'resolved'
              ? _t(code, 'resolvedStatus')
              : status == 'dispatched'
                  ? _t(code, 'dispatchedStatus')
                  : _t(code, 'openStatus');
          final ts = ev['createdAt'] ?? ev['timestamp'];
          final dt = ts != null ? DateTime.tryParse(ts as String) : null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: statusColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ev['scenario'] ?? ev['type'] ?? 'Emergency',
                      style: const TextStyle(
                          color: VetoPalette.text, fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (dt != null)
                    Text(
                      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: VetoPalette.textMuted, fontSize: 11),
                    ),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildQuickLinks(String code) {
    final links = [
      (Icons.people_rounded, VetoPalette.success, _t(code, 'allUsers'),
          '/admin_users'),
      (Icons.balance_rounded, const Color(0xFFC9A050), _t(code, 'allLawyers'),
          '/admin_lawyers'),
      (Icons.pending_actions_rounded, VetoPalette.warning,
          _t(code, 'pendingLawyers'), '/admin_pending'),
      (Icons.warning_amber_rounded, VetoPalette.emergency,
          _t(code, 'emergencyLogs'), '/admin_logs'),
      (Icons.subscriptions_rounded, const Color(0xFFC9A050),
          _t(code, 'subscriptions'), '/admin_subscriptions'),
      (Icons.settings_rounded, VetoPalette.textMuted,
          'Settings', '/admin_settings'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: links.length,
      itemBuilder: (ctx, i) {
        final (icon, color, label, route) = links[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(ctx, route),
          child: Container(
            decoration: BoxDecoration(
              color: VetoPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VetoPalette.border),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: VetoPalette.text, fontSize: 12,
                      fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      },
    );
  }
}

// ── KPI card ─────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final String? sublabel;
  final bool large;

  const _KpiCard({
    required this.icon, required this.color,
    required this.label, required this.value,
    this.sublabel, this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(large ? 18 : 14),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            if (sublabel != null)
              Text(sublabel!,
                  style: TextStyle(
                      color: color, fontSize: 10,
                      fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: VetoPalette.text,
                  fontWeight: FontWeight.w900,
                  fontSize: large ? 32 : 26)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: VetoPalette.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

