// ============================================================
//  AdminDashboard.dart — Full admin command center
//  KPI cards, activity feed, system health, quick links
// ============================================================

import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_glass_system.dart';
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

    final navItems = [
      (Icons.home_rounded,             isRtl ? 'לוח בקרה' : 'Dashboard',     '/admin_dashboard'),
      (Icons.people_alt_rounded,       isRtl ? 'כל המשתמשים' : 'Users',       '/admin_users'),
      (Icons.balance_rounded,          isRtl ? 'עורכי דין' : 'Lawyers',       '/admin_lawyers'),
      (Icons.pending_actions_rounded,  isRtl ? 'ממתינים לאישור' : 'Pending',  '/admin_pending'),
      (Icons.warning_amber_rounded,    isRtl ? 'יומן חירום' : 'Emergencies',  '/admin_logs'),
      (Icons.credit_card_rounded,      isRtl ? 'מנויים' : 'Subscriptions',    '/admin_subscriptions'),
      (Icons.settings_rounded,         isRtl ? 'הגדרות' : 'Settings',         '/admin_settings'),
    ];

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoGlassTokens.bgBase,
        body: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: VetoFluidBackgroundPainter())),
            Row(
              children: [
            // ── RIGHT SIDEBAR (matches mockup) ─────────────────
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    color: VetoGlassTokens.glassFillStrong,
                    border: Border(
                      left: isRtl ? BorderSide.none : BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      right: isRtl ? BorderSide(color: Colors.white.withValues(alpha: 0.12)) : BorderSide.none,
                    ),
                    boxShadow: [
                      BoxShadow(color: VetoGlassTokens.neonBlue.withValues(alpha: 0.12), blurRadius: 16),
                    ],
                  ),
              child: Column(children: [
                // Logo header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        gradient: VetoGlassTokens.neonButton,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.35), blurRadius: 10),
                        ],
                      ),
                      child: const Icon(Icons.shield_rounded, color: VetoGlassTokens.onNeon, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('VETO', style: TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      Text(isRtl ? 'פאנל ניהול' : 'Admin Panel', style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 11)),
                    ]),
                  ]),
                ),
                // Nav section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(isRtl ? 'ניהול' : 'ADMIN', style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                ),
                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    children: navItems.map((item) {
                      final isDashboard = item.$3 == '/admin_dashboard';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: isDashboard ? VetoGlassTokens.neonCyan.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(item.$1, color: isDashboard ? VetoGlassTokens.neonCyan : VetoGlassTokens.textSecondary, size: 20),
                          title: Text(item.$2, style: TextStyle(
                            color: isDashboard ? VetoGlassTokens.neonCyan : VetoGlassTokens.textSecondary,
                            fontSize: 14, fontWeight: isDashboard ? FontWeight.w700 : FontWeight.w500,
                          )),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onTap: () { if (!isDashboard) Navigator.pushNamed(context, item.$3); },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
                ),
              ),
            ),

            // ── MAIN CONTENT ───────────────────────────────────
            Expanded(
              child: Column(children: [
                // Top bar
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: VetoGlassTokens.glassFillStrong,
                    border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    boxShadow: [BoxShadow(color: VetoGlassTokens.neonBlue.withValues(alpha: 0.1), blurRadius: 12)],
                  ),
                  child: Row(children: [
                    // Bell + Admin info
                    const Icon(Icons.notifications_outlined, color: VetoGlassTokens.textMuted, size: 22),
                    const SizedBox(width: 8),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.person_outline, color: VetoGlassTokens.textPrimary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(isRtl ? 'מנהל' : 'Admin', style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    // Search bar
                    SizedBox(
                      width: 220,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: isRtl ? 'חיפוש...' : 'Search...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
                          filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(icon: const Icon(Icons.refresh_rounded, color: VetoGlassTokens.textMuted), onPressed: _loadAll, tooltip: _t(code,'refresh')),
                  ]),
                    ),
                  ),
                ),

                // Body
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: VetoGlassTokens.neonCyan))
                      : RefreshIndicator(
                          onRefresh: _loadAll,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              // 4 KPI cards
                              LayoutBuilder(builder: (ctx, bc) {
                                final cols = bc.maxWidth > 700 ? 4 : bc.maxWidth > 480 ? 2 : 2;
                                return GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: cols,
                                  childAspectRatio: bc.maxWidth > 700 ? 1.9 : 1.6,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  children: [
                                    _KpiCard(icon: Icons.trending_up_rounded, color: const Color(0xFF22C55E),
                                      label: isRtl ? 'הכנסות החודש' : 'Monthly Revenue', value: '₪45,230',
                                      badge: '+12%', badgeColor: const Color(0xFF22C55E)),
                                    _KpiCard(icon: Icons.people_alt_rounded, color: VetoGlassTokens.neonCyan,
                                      label: isRtl ? 'משתמשים רשומים' : 'Registered Users', value: _totalUsers.toString()),
                                    _KpiCard(icon: Icons.balance_rounded, color: const Color(0xFF38BDF8),
                                      label: isRtl ? 'עורכי דין פעילים' : 'Active Lawyers', value: _activeLawyers.toString()),
                                    _KpiCard(icon: Icons.pending_actions_rounded, color: const Color(0xFFF59E0B),
                                      label: isRtl ? 'ממתינים לאישור' : 'Pending Approval', value: _pendingLawyers.toString()),
                                  ],
                                );
                              }),
                              const SizedBox(height: 20),

                              // Recent activity + health side by side
                              LayoutBuilder(builder: (ctx, bc) {
                                if (bc.maxWidth > 640) {
                                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(flex: 3, child: _buildActivityPanel(code, isRtl)),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 2, child: _buildHealthPanel(code, isRtl)),
                                  ]);
                                }
                                return Column(children: [
                                  _buildActivityPanel(code, isRtl),
                                  const SizedBox(height: 16),
                                  _buildHealthPanel(code, isRtl),
                                ]);
                              }),
                            ]),
                          ),
                        ),
                ),
              ]),
            ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityPanel(String code, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VetoGlassTokens.glassFillStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: VetoGlassTokens.glassBorder),
        boxShadow: [
          BoxShadow(color: VetoGlassTokens.neonBlue.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isRtl ? 'פעילות אחרונה' : 'Recent Activity',
          style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _buildActivityFeed(code),
      ]),
    );
  }

  Widget _buildHealthPanel(String code, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VetoGlassTokens.glassFillStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: VetoGlassTokens.glassBorder),
        boxShadow: [
          BoxShadow(color: VetoGlassTokens.neonBlue.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isRtl ? 'בריאות המערכת' : 'System Health',
          style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _buildHealthBar('API', _backendStatus),
        const SizedBox(height: 10),
        _buildHealthBar('DB', _dbStatus),
        const SizedBox(height: 10),
        _buildHealthBar('Socket', _socketStatus),
      ]),
    );
  }

  Widget _buildHealthBar(String label, String status) {
    final good = status == 'online';
    final pct = good ? 0.95 : 0.1;
    final color = good ? const Color(0xFF22C55E) : const Color(0xFFFF3B3B);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 13, fontWeight: FontWeight.w600))),
        Text(good ? 'Online' : 'Offline', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: const Color(0xFF0F1A24),
          color: color,
          minHeight: 7,
        ),
      ),
    ]);
  }

  Widget _buildActivityFeed(String code) {
    if (_recentEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: VetoGlassTokens.glassFillStrong,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VetoGlassTokens.glassBorder)),
        child: Center(
          child: Text(_t(code, 'noActivity'),
              style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 14)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: VetoGlassTokens.glassFillStrong,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoGlassTokens.glassBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentEvents.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: VetoGlassTokens.glassBorder),
        itemBuilder: (context, i) {
          final ev = _recentEvents[i];
          final status = ev['status'] ?? 'open';
          final statusColor = status == 'resolved'
              ? VetoPalette.success
              : status == 'dispatched'
                  ? VetoPalette.accentSky
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
                          color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (dt != null)
                    Text(
                      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: VetoGlassTokens.textMuted, fontSize: 11),
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
}

// ── KPI card ─────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final String? badge;
  final Color? badgeColor;

  const _KpiCard({
    required this.icon, required this.color,
    required this.label, required this.value,
    this.badge, this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VetoGlassTokens.glassFillStrong,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VetoGlassTokens.glassBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge!, style: TextStyle(color: badgeColor ?? color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: VetoGlassTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: VetoGlassTokens.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

