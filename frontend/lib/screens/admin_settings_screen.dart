// ============================================================
//  AdminSettingsScreen — VETO 2026
//  Tokens-aligned admin home: quick stats, system status, action tiles.
//  Behaviour preserved: AdminService.getAdminSettings + counts + fixed-OTP toggle.
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_tokens_2026.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';
import 'admin/admin_i18n.dart';
import 'admin/all_lawyers_screen.dart';
import 'admin/all_users_screen.dart';
import 'admin/emergency_logs_screen.dart';
import 'admin/pending_lawyers_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _enableFixedOtp = false;
  String _serverStatus = '';
  String _mongoDbStatus = '';
  String _appVersion = '';
  bool _loading = false;
  int _pendingLawyersCount = 0;
  int _totalUsers = 0;
  int _totalLawyers = 0;

  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  String _t(String code, String key) => AdminStrings.t(code, key);

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_fetchSettings(), _fetchCounts()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchSettings() async {
    final settings = await _adminService.getAdminSettings();
    if (mounted && settings != null) {
      setState(() {
        _enableFixedOtp = settings['enableFixedOtpForAdmins'] ?? false;
        _serverStatus = settings['serverStatus']?.toString() ?? '';
        _mongoDbStatus = settings['mongoDbStatus']?.toString() ?? '';
        _appVersion = settings['appVersion']?.toString() ?? '';
      });
    }
  }

  Future<void> _fetchCounts() async {
    final results = await Future.wait([
      _adminService.getPendingLawyers(),
      _adminService.getAllUsers(),
      _adminService.getAllLawyers(),
    ]);
    if (mounted) {
      setState(() {
        _pendingLawyersCount = results[0].length;
        _totalUsers = results[1].length;
        _totalLawyers = results[2].length;
      });
    }
  }

  Future<void> _toggleFixedOtp(bool value) async {
    setState(() { _enableFixedOtp = value; _loading = true; });
    final ok = await _adminService.updateFixedOtpSetting(value);
    if (mounted) {
      final code = context.read<AppLanguageController>().code;
      setState(() => _loading = false);
      if (!ok) {
        setState(() => _enableFixedOtp = !value);
        _snack(_t(code, 'settingUpdateError'), error: true);
      } else {
        _snack(_t(code, 'settingUpdated'));
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? VetoTokens.emerg : VetoTokens.ok,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    String t(String k) => _t(code, k);
    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoTokens.paper,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(t('adminPanel'), style: VetoTokens.titleLg),
          actions: [
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Center(child: AppLanguageMenu(compact: true))),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: VetoTokens.navy600)),
              ),
            IconButton(
              icon: const Icon(Icons.apps_rounded, size: 18),
              tooltip: t('openApp'),
              onPressed: () => Navigator.of(context).pushNamed('/veto_screen'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              tooltip: t('refresh'),
              onPressed: _loadAll,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 18, color: VetoTokens.emerg),
              tooltip: t('logout'),
              onPressed: () => AuthService().logout(context),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadAll,
          color: VetoTokens.navy600,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section(t('quickStats')),
                    Row(children: [
                      Expanded(child: _StatCard(label: t('users'), value: '$_totalUsers', icon: Icons.group_outlined, accent: VetoTokens.navy600)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: t('lawyers'), value: '$_totalLawyers', icon: Icons.gavel_rounded, accent: VetoTokens.ok)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(
                        label: t('pending'), value: '$_pendingLawyersCount',
                        icon: Icons.pending_actions_rounded,
                        accent: _pendingLawyersCount > 0 ? VetoTokens.emerg : VetoTokens.ink300,
                      )),
                    ]),
                    const SizedBox(height: 28),

                    if (_pendingLawyersCount > 0) ...[
                      _section(t('pendingApprovals')),
                      _ActionTile(
                        icon: Icons.how_to_reg_rounded,
                        accent: VetoTokens.emerg,
                        title: '${t('pendingApprovalsAction')} ($_pendingLawyersCount ${t('pending')})',
                        badge: _pendingLawyersCount,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingLawyersScreen()));
                          _loadAll();
                        },
                      ),
                      const SizedBox(height: 28),
                    ],

                    _section(t('systemOverview')),
                    _InfoTile(
                      label: t('serverStatus'),
                      value: _serverStatus.isEmpty ? t('loading') : _serverStatus,
                      statusColor: _serverStatus == 'Online' ? VetoTokens.ok : VetoTokens.emerg,
                    ),
                    _InfoTile(
                      label: t('database'),
                      value: _mongoDbStatus.isEmpty ? t('loading') : _mongoDbStatus,
                      statusColor: _mongoDbStatus == 'Connected' ? VetoTokens.ok : VetoTokens.emerg,
                    ),
                    _InfoTile(
                      label: t('appVersion'),
                      value: _appVersion.isEmpty ? t('unknown') : _appVersion,
                    ),
                    const SizedBox(height: 28),

                    _section(code == 'he' ? 'כלי ניהול' : code == 'ru' ? 'Инструменты' : 'Admin Tools'),
                    _ActionTile(
                      icon: Icons.shield_outlined, accent: VetoTokens.ok,
                      title: t('citizenApp'),
                      onTap: () => Navigator.of(context).pushNamed('/veto_screen'),
                    ),
                    _ActionTile(
                      icon: Icons.dashboard_rounded, accent: VetoTokens.navy600,
                      title: code == 'he' ? 'לוח בקרה ראשי' : code == 'ru' ? 'Главная панель' : 'Admin Dashboard',
                      onTap: () => Navigator.pushNamed(context, '/admin_dashboard'),
                    ),
                    _ActionTile(
                      icon: Icons.subscriptions_rounded, accent: VetoTokens.navy500,
                      title: code == 'he' ? 'ניהול מנויים' : code == 'ru' ? 'Подписки' : 'Subscription Management',
                      onTap: () => Navigator.pushNamed(context, '/admin_subscriptions'),
                    ),
                    _ActionTile(
                      icon: Icons.settings_rounded, accent: VetoTokens.ink500,
                      title: code == 'he' ? 'הגדרות מערכת' : code == 'ru' ? 'Настройки системы' : 'System Settings',
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                    ),
                    const SizedBox(height: 28),

                    _section(t('userManagement')),
                    _ActionTile(
                      icon: Icons.group_outlined, accent: VetoTokens.navy600,
                      title: '${t('allUsers')} ($_totalUsers)',
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AllUsersScreen()));
                        _loadAll();
                      },
                    ),
                    _ActionTile(
                      icon: Icons.gavel_rounded, accent: VetoTokens.navy600,
                      title: '${t('allLawyers')} ($_totalLawyers)',
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AllLawyersScreen()));
                        _loadAll();
                      },
                    ),
                    _ActionTile(
                      icon: Icons.history_rounded, accent: VetoTokens.navy600,
                      title: t('emergencyLogs'),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyLogsScreen())),
                    ),
                    const SizedBox(height: 28),

                    _section(t('systemSettings')),
                    _SwitchTile(
                      title: t('fixedOtp'),
                      subtitle: t('fixedOtpHint'),
                      value: _enableFixedOtp,
                      onChange: _toggleFixedOtp,
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 18, height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [VetoTokens.navy600, VetoTokens.navy500]),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: VetoTokens.kicker),
        ]),
      );
}

// ──────────────────────────────────────────────────────────
//  Sub-widgets
// ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.accent});
  final String label, value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: VetoTokens.cardDecoration(),
      child: Stack(
        children: [
          Column(children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 8),
            Text(value, style: VetoTokens.serif(26, FontWeight.w900, color: accent, height: 1.0)),
            const SizedBox(height: 4),
            Text(label, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
          ]),
          PositionedDirectional(start: -12, top: -18, bottom: -18, child: Container(width: 3, color: accent)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, this.statusColor});
  final String label, value;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
      child: Row(
        mainAxisAlignment: MainAxisOptions.spaceBetweenSafe(),
        children: [
          Text(label, style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500)),
          Row(children: [
            if (statusColor != null)
              Container(
                width: 7, height: 7,
                margin: const EdgeInsetsDirectional.only(start: 8, end: 6),
                decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
              ),
            Text(value, style: VetoTokens.titleSm.copyWith(color: statusColor ?? VetoTokens.ink900)),
          ]),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({required this.title, required this.subtitle, required this.value, required this.onChange});
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
              const SizedBox(height: 2),
              Text(subtitle, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
            ],
          ),
        ),
        Switch.adaptive(value: value, onChanged: onChange, activeThumbColor: Colors.white, activeTrackColor: VetoTokens.ok),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.title, required this.icon, required this.onTap, this.accent, this.badge});
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accent;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? VetoTokens.navy600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VetoTokens.rMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(VetoTokens.rSm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900))),
          if (badge != null && badge! > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: VetoTokens.emerg, borderRadius: BorderRadius.circular(99)),
              child: Text('$badge', style: VetoTokens.sans(11, FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(width: 6),
          ],
          Icon(Icons.chevron_left_rounded, size: 18, color: color),
        ]),
      ),
    );
  }
}

// Helper to keep MainAxisAlignment imports tidy in tight files
class MainAxisOptions {
  static MainAxisAlignment spaceBetweenSafe() => MainAxisAlignment.spaceBetween;
}
