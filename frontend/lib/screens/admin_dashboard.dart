// ============================================================
//  AdminDashboard — VETO 2026
//  Tokens-aligned. Sidebar + KPI cards + activity feed + system health.
//  Behaviour preserved: /admin/stats + /events/history + /health endpoints.
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
    'title': 'לוח בקרה — מנהל',
    'eyebrow': 'מרכז הניהול',
    'users': 'משתמשים',
    'lawyers': 'עורכי דין',
    'pending': 'ממתינים לאישור',
    'recentActivity': 'פעילות אחרונה',
    'systemHealth': 'בריאות המערכת',
    'online': 'פעיל',
    'offline': 'לא זמין',
    'refresh': 'רענן',
    'noActivity': 'אין פעילות אחרונה',
    'resolvedStatus': 'נסגר',
    'openStatus': 'פתוח',
    'dispatchedStatus': 'בטיפול',
    'monthlyRevenue': 'הכנסות החודש',
    'navAdmin': 'ניהול',
    'navDashboard': 'לוח בקרה',
    'navUsers': 'כל המשתמשים',
    'navLawyers': 'עורכי דין',
    'navPending': 'ממתינים לאישור',
    'navEmerg': 'יומן חירום',
    'navSubs': 'מנויים',
    'navSettings': 'הגדרות',
    'searchHint': 'חיפוש...',
    'admin': 'מנהל',
  },
  'en': {
    'title': 'Admin Dashboard',
    'eyebrow': 'Admin centre',
    'users': 'Users',
    'lawyers': 'Active Lawyers',
    'pending': 'Pending Approval',
    'recentActivity': 'Recent Activity',
    'systemHealth': 'System Health',
    'online': 'Online',
    'offline': 'Offline',
    'refresh': 'Refresh',
    'noActivity': 'No recent activity',
    'resolvedStatus': 'Resolved',
    'openStatus': 'Open',
    'dispatchedStatus': 'Dispatched',
    'monthlyRevenue': 'Monthly Revenue',
    'navAdmin': 'ADMIN',
    'navDashboard': 'Dashboard',
    'navUsers': 'Users',
    'navLawyers': 'Lawyers',
    'navPending': 'Pending',
    'navEmerg': 'Emergencies',
    'navSubs': 'Subscriptions',
    'navSettings': 'Settings',
    'searchHint': 'Search...',
    'admin': 'Admin',
  },
  'ru': {
    'title': 'Панель администратора',
    'eyebrow': 'Центр управления',
    'users': 'Пользователи',
    'lawyers': 'Адвокаты',
    'pending': 'Ожидают одобрения',
    'recentActivity': 'Последняя активность',
    'systemHealth': 'Состояние системы',
    'online': 'В сети',
    'offline': 'Не в сети',
    'refresh': 'Обновить',
    'noActivity': 'Нет активности',
    'resolvedStatus': 'Решено',
    'openStatus': 'Открыто',
    'dispatchedStatus': 'В обработке',
    'monthlyRevenue': 'Доход за месяц',
    'navAdmin': 'АДМИН',
    'navDashboard': 'Панель',
    'navUsers': 'Пользователи',
    'navLawyers': 'Адвокаты',
    'navPending': 'Ожидают',
    'navEmerg': 'Экстренные',
    'navSubs': 'Подписки',
    'navSettings': 'Настройки',
    'searchHint': 'Поиск...',
    'admin': 'Админ',
  },
};

String _t(String code, String key) => (_i18n[code] ?? _i18n['en']!)[key] ?? key;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _auth = AuthService();

  int _totalUsers = 0, _activeLawyers = 0, _pendingLawyers = 0;
  List<Map<String, dynamic>> _recentEvents = [];

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
        http
            .get(Uri.parse('${AppConfig.baseUrl}/admin/stats'),
                headers: headers)
            .timeout(const Duration(seconds: 15)),
        http
            .get(Uri.parse('${AppConfig.baseUrl}/events/history?limit=10'),
                headers: headers)
            .timeout(const Duration(seconds: 15)),
      ]);
      final statsRes = results[0];
      final eventsRes = results[1];
      if (statsRes.statusCode == 200) {
        final d = jsonDecode(statsRes.body) as Map<String, dynamic>;
        _totalUsers = (d['totalUsers'] ?? d['users'] ?? 0) as int;
        _activeLawyers = (d['activeLawyers'] ?? d['lawyers'] ?? 0) as int;
        _pendingLawyers = (d['pendingLawyers'] ?? 0) as int;
      }
      if (eventsRes.statusCode == 200) {
        final data = jsonDecode(eventsRes.body);
        final list =
            data is List ? data : (data['events'] ?? data['data'] ?? []);
        _recentEvents = List<Map<String, dynamic>>.from(
            (list as List).take(8).map((e) => e as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  Future<void> _checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse(AppConfig.healthCheckUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        _backendStatus = 'online';
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

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;
    String t(String k) => _t(code, k);
    final w = MediaQuery.of(context).size.width;
    final sidebarVisible = w >= 980;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoTokens.paper,
        drawer: sidebarVisible
            ? null
            : Drawer(
                backgroundColor: Colors.white,
                child: SafeArea(
                    child: _Sidebar(
                        t: t,
                        currentRoute: '/admin_dashboard',
                        onClose: () => Navigator.pop(context))),
              ),
        body: SafeArea(
          child: Row(
            children: [
              if (sidebarVisible)
                SizedBox(
                    width: 240,
                    child: _Sidebar(t: t, currentRoute: '/admin_dashboard')),
              Expanded(
                child: Column(
                  children: [
                    _topBar(context, t, sidebarVisible),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: VetoTokens.navy600))
                          : RefreshIndicator(
                              onRefresh: _loadAll,
                              color: VetoTokens.navy600,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LayoutBuilder(builder: (ctx, bc) {
                                      final cols = bc.maxWidth > 700 ? 4 : 2;
                                      return GridView.count(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        crossAxisCount: cols,
                                        childAspectRatio:
                                            bc.maxWidth > 700 ? 1.25 : 1.15,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        children: [
                                          _KpiCard(
                                              icon: Icons.trending_up_rounded,
                                              accent: VetoTokens.ok,
                                              label: t('monthlyRevenue'),
                                              value: '₪45,230',
                                              badge: '+12%'),
                                          _KpiCard(
                                              icon: Icons.people_alt_rounded,
                                              accent: VetoTokens.navy600,
                                              label: t('users'),
                                              value: _totalUsers.toString()),
                                          _KpiCard(
                                              icon: Icons.balance_rounded,
                                              accent: VetoTokens.navy500,
                                              label: t('lawyers'),
                                              value: _activeLawyers.toString()),
                                          _KpiCard(
                                              icon:
                                                  Icons.pending_actions_rounded,
                                              accent: VetoTokens.warn,
                                              label: t('pending'),
                                              value:
                                                  _pendingLawyers.toString()),
                                        ],
                                      );
                                    }),
                                    const SizedBox(height: 20),
                                    LayoutBuilder(builder: (ctx, bc) {
                                      final activity = _ActivityPanel(
                                          code: code,
                                          isRtl: isRtl,
                                          events: _recentEvents);
                                      final health = _HealthPanel(
                                        title: t('systemHealth'),
                                        labels: const ['API', 'DB', 'Socket'],
                                        statuses: [
                                          _backendStatus,
                                          _dbStatus,
                                          _socketStatus
                                        ],
                                        onlineLabel: t('online'),
                                        offlineLabel: t('offline'),
                                      );
                                      if (bc.maxWidth > 720) {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(flex: 3, child: activity),
                                            const SizedBox(width: 16),
                                            Expanded(flex: 2, child: health),
                                          ],
                                        );
                                      }
                                      return Column(children: [
                                        activity,
                                        const SizedBox(height: 16),
                                        health
                                      ]);
                                    }),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(
      BuildContext context, String Function(String) t, bool sidebarVisible) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 900;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border:
              Border(bottom: BorderSide(color: VetoTokens.hairline, width: 1)),
        ),
        child: Row(children: [
          if (!sidebarVisible)
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 20),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              t('title'),
              style: VetoTokens.titleLg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 220,
              child: TextField(
                decoration: InputDecoration(
                  hintText: t('searchHint'),
                  prefixIcon: const Icon(Icons.search_rounded, size: 16),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: t('refresh'),
            onPressed: _loadAll,
          ),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: AppLanguageMenu(compact: true)),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                gradient: VetoTokens.crestGradient,
                borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text('A',
                style:
                    VetoTokens.serif(15, FontWeight.w800, color: Colors.white)),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(t('admin'),
                style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
          ],
        ]),
      );
    });
  }
}

// ──────────────────────────────────────────────────────────
//  Sidebar (shared by drawer + side rail)
// ──────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.t, required this.currentRoute, this.onClose});
  final String Function(String) t;
  final String currentRoute;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.dashboard_rounded, t('navDashboard'), '/admin_dashboard'),
      (Icons.people_alt_rounded, t('navUsers'), '/admin_users'),
      (Icons.balance_rounded, t('navLawyers'), '/admin_lawyers'),
      (Icons.pending_actions_rounded, t('navPending'), '/admin_pending'),
      (Icons.warning_amber_rounded, t('navEmerg'), '/admin_logs'),
      (Icons.credit_card_rounded, t('navSubs'), '/admin_subscriptions'),
      (Icons.settings_rounded, t('navSettings'), '/admin_settings'),
    ];
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Logo header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: VetoTokens.hairline, width: 1)),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    gradient: VetoTokens.crestGradient,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text('V',
                    style: VetoTokens.serif(15, FontWeight.w900,
                        color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VETO',
                        style: VetoTokens.serif(15, FontWeight.w900,
                            color: VetoTokens.ink900, letterSpacing: 1.4)),
                    Text(t('navAdmin'),
                        style: VetoTokens.bodyXs
                            .copyWith(color: VetoTokens.ink500)),
                  ],
                ),
              ),
            ]),
          ),
          // Section label
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child:
                  Text(t('navAdmin').toUpperCase(), style: VetoTokens.kicker),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: items.map((it) {
                final isActive = it.$3 == currentRoute;
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isActive ? VetoTokens.navy100 : Colors.transparent,
                    borderRadius: BorderRadius.circular(VetoTokens.rSm),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(it.$1,
                        size: 18,
                        color:
                            isActive ? VetoTokens.navy700 : VetoTokens.ink500),
                    title: Text(it.$2,
                        style: VetoTokens.titleSm.copyWith(
                            color: isActive
                                ? VetoTokens.navy700
                                : VetoTokens.ink700)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VetoTokens.rSm)),
                    onTap: () {
                      if (onClose != null) onClose!();
                      if (!isActive) Navigator.pushNamed(context, it.$3);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  KPI card
// ──────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  const _KpiCard(
      {required this.icon,
      required this.accent,
      required this.label,
      required this.value,
      this.badge});
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: VetoTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(VetoTokens.rSm),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const Spacer(),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VetoTokens.rPill),
                ),
                child: Text(badge!,
                    style: VetoTokens.sans(11, FontWeight.w700, color: accent)),
              ),
          ]),
          const SizedBox(height: 12),
          Text(value,
              style: VetoTokens.serif(22, FontWeight.w900,
                  color: VetoTokens.ink900, height: 1.0)),
          const SizedBox(height: 4),
          Text(label,
              style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Activity panel
// ──────────────────────────────────────────────────────────
class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel(
      {required this.code, required this.isRtl, required this.events});
  final String code;
  final bool isRtl;
  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: VetoTokens.cardDecoration(radius: VetoTokens.rXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t(code, 'recentActivity'),
              style: VetoTokens.serif(16, FontWeight.w800,
                  color: VetoTokens.ink900)),
          const SizedBox(height: 14),
          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: VetoTokens.surface2,
                borderRadius: BorderRadius.circular(VetoTokens.rMd),
                border: Border.all(color: VetoTokens.hairline),
              ),
              child: Center(
                  child: Text(_t(code, 'noActivity'),
                      style: VetoTokens.bodyMd
                          .copyWith(color: VetoTokens.ink500))),
            )
          else
            Container(
              decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VetoTokens.rMd),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: VetoTokens.hairline),
                  itemBuilder: (context, i) {
                    final ev = events[i];
                    final status = ev['status'] ?? 'open';
                    final color = status == 'resolved'
                        ? VetoTokens.ok
                        : status == 'dispatched'
                            ? VetoTokens.navy500
                            : VetoTokens.emerg;
                    final label = status == 'resolved'
                        ? _t(code, 'resolvedStatus')
                        : status == 'dispatched'
                            ? _t(code, 'dispatchedStatus')
                            : _t(code, 'openStatus');
                    final ts = ev['createdAt'] ?? ev['timestamp'];
                    final dt =
                        ts != null ? DateTime.tryParse(ts as String) : null;
                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(Icons.warning_amber_rounded,
                              color: color, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  (ev['scenario'] ?? ev['type'] ?? 'Emergency')
                                      .toString(),
                                  style: VetoTokens.titleSm
                                      .copyWith(color: VetoTokens.ink900)),
                              if (dt != null)
                                Text(
                                  '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                  style: VetoTokens.bodyXs
                                      .copyWith(color: VetoTokens.ink500),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius:
                                  BorderRadius.circular(VetoTokens.rPill)),
                          child: Text(label,
                              style: VetoTokens.sans(11, FontWeight.w700,
                                  color: color)),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Health panel
// ──────────────────────────────────────────────────────────
class _HealthPanel extends StatelessWidget {
  const _HealthPanel({
    required this.title,
    required this.labels,
    required this.statuses,
    required this.onlineLabel,
    required this.offlineLabel,
  });
  final String title;
  final List<String> labels;
  final List<String> statuses;
  final String onlineLabel, offlineLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: VetoTokens.cardDecoration(radius: VetoTokens.rXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: VetoTokens.serif(16, FontWeight.w800,
                  color: VetoTokens.ink900)),
          const SizedBox(height: 14),
          for (int i = 0; i < labels.length; i++) ...[
            _bar(labels[i], statuses[i]),
            if (i < labels.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _bar(String label, String status) {
    final good = status == 'online';
    final pct = good ? 0.95 : 0.10;
    final color = good ? VetoTokens.ok : VetoTokens.emerg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(label,
                  style:
                      VetoTokens.titleSm.copyWith(color: VetoTokens.ink700))),
          Text(good ? onlineLabel : offlineLabel,
              style: VetoTokens.sans(12, FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: VetoTokens.paper2,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
