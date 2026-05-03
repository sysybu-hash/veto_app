// ============================================================
//  AdminSettingsScreen.dart — Full Admin Dashboard
//  VETO Legal Emergency App
// ============================================================

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'admin/_shell.dart';
import 'admin/all_users_screen.dart';
import 'admin/all_lawyers_screen.dart';
import 'admin/emergency_logs_screen.dart';
import 'admin/pending_lawyers_screen.dart';
import 'admin/admin_i18n.dart';

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

  double _dispatchTimeoutSec = 45;
  double _dispatchRadiusKm = 15;
  double _dispatchMaxLawyers = 4;
  bool _maintenanceMode = false;

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
      backgroundColor: error ? V26.emerg : V26.ok,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: AdminShell(
        active: AdminSection.settings,
        title: _t(code, 'adminPanel'),
        onRefresh: _loadAll,
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: V26.navy600),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.apps_rounded, color: V26.ink700),
            tooltip: _t(code, 'openApp'),
            onPressed: () => Navigator.of(context).pushNamed('/veto_screen'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: V26.emerg),
            tooltip: _t(code, 'logout'),
            onPressed: () => AuthService().logout(context),
          ),
        ],
        body: V26Backdrop(
          child: RefreshIndicator(
          onRefresh: _loadAll,
          color: V26.navy600,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader(_t(code, 'quickStats')),
                    Row(children: [
                      Expanded(
                        child: _statCard(_t(code, 'users'), '$_totalUsers',
                            Icons.group_outlined, V26.navy600),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(_t(code, 'lawyers'), '$_totalLawyers',
                            Icons.gavel_rounded, V26.ok),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          _t(code, 'pending'),
                          '$_pendingLawyersCount',
                          Icons.pending_actions_rounded,
                          _pendingLawyersCount > 0
                              ? V26.emerg
                              : V26.ink500,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    if (_pendingLawyersCount > 0) ...[
                      _sectionHeader(_t(code, 'pendingApprovals')),
                      _actionCard(
                        '${_t(code, 'pendingApprovalsAction')} ($_pendingLawyersCount ${_t(code, 'pending')})',
                        Icons.how_to_reg_rounded,
                        color: V26.emerg,
                        badge: _pendingLawyersCount,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PendingLawyersScreen()),
                          );
                          _loadAll();
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                    LayoutBuilder(
                      builder: (ctx, c) {
                        final wide = c.maxWidth >= 900;
                        final dispatch = _dispatchCard(code);
                        final comm = _communicationCard(code);
                        final row = wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: dispatch),
                                  const SizedBox(width: 16),
                                  Expanded(child: comm),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  dispatch,
                                  const SizedBox(height: 12),
                                  comm,
                                ],
                              );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            row,
                            const SizedBox(height: 12),
                            _maintenanceCard(code),
                            const SizedBox(height: 32),
                          ],
                        );
                      },
                    ),
                    _sectionHeader(_t(code, 'systemOverview')),
                    _infoCard(
                        _t(code, 'serverStatus'),
                        _serverStatus.isEmpty ? _t(code, 'loading') : _serverStatus,
                        statusColor: _serverStatus == 'Online'
                            ? V26.ok
                            : V26.emerg),
                    _infoCard(
                        _t(code, 'database'),
                        _mongoDbStatus.isEmpty ? _t(code, 'loading') : _mongoDbStatus,
                        statusColor: _mongoDbStatus == 'Connected'
                            ? V26.ok
                            : V26.emerg),
                    _infoCard(
                      _t(code, 'appVersion'),
                      _appVersion.isEmpty ? _t(code, 'unknown') : _appVersion,
                    ),
                    const SizedBox(height: 32),
                    _sectionHeader(
                      code == 'he' ? 'כלי ניהול' : code == 'ru' ? 'Инструменты' : 'Admin Tools'
                    ),
                    _actionCard(
                      _t(code, 'citizenApp'),
                      Icons.shield_outlined,
                      color: V26.ok,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/veto_screen'),
                    ),
                    _actionCard(
                      code == 'he' ? 'לוח בקרה ראשי' : code == 'ru' ? 'Главная панель' : 'Admin Dashboard',
                      Icons.dashboard_rounded,
                      color: V26.navy600,
                      onTap: () => Navigator.pushNamed(context, '/admin_dashboard'),
                    ),
                    _actionCard(
                      code == 'he' ? 'ניהול מנויים' : code == 'ru' ? 'Подписки' : 'Subscription Management',
                      Icons.subscriptions_rounded,
                      color: V26.navy500,
                      onTap: () => Navigator.pushNamed(context, '/admin_subscriptions'),
                    ),
                    const SizedBox(height: 32),
                    _sectionHeader(_t(code, 'userManagement')),
                    _actionCard(
                      '${_t(code, 'allUsers')} ($_totalUsers)',
                      Icons.group_outlined,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AllUsersScreen()),
                        );
                        _loadAll();
                      },
                    ),
                    _actionCard(
                      '${_t(code, 'allLawyers')} ($_totalLawyers)',
                      Icons.gavel_rounded,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AllLawyersScreen()),
                        );
                        _loadAll();
                      },
                    ),
                    _actionCard(
                      _t(code, 'emergencyLogs'),
                      Icons.history_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EmergencyLogsScreen()),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _sectionHeader(_t(code, 'systemSettings')),
                    _switchCard(
                      _t(code, 'fixedOtp'),
                      _enableFixedOtp,
                      _t(code, 'fixedOtpHint'),
                      _toggleFixedOtp,
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _dispatchCard(String code) {
    return V26Card(
      lift: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t(code, 'dispatchingTitle'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: V26.ink900,
            ),
          ),
          const SizedBox(height: 12),
          Text(_t(code, 'dispatchTimeoutSec'),
              style: const TextStyle(color: V26.ink500, fontSize: 12)),
          Slider(
            value: _dispatchTimeoutSec,
            min: 15,
            max: 180,
            divisions: 33,
            label: '${_dispatchTimeoutSec.round()}s',
            activeColor: V26.navy600,
            onChanged: (v) => setState(() => _dispatchTimeoutSec = v),
          ),
          Text(_t(code, 'dispatchRadiusKm'),
              style: const TextStyle(color: V26.ink500, fontSize: 12)),
          Slider(
            value: _dispatchRadiusKm,
            min: 3,
            max: 60,
            divisions: 19,
            label: '${_dispatchRadiusKm.round()} km',
            activeColor: V26.navy600,
            onChanged: (v) => setState(() => _dispatchRadiusKm = v),
          ),
          Text(_t(code, 'dispatchMaxLawyers'),
              style: const TextStyle(color: V26.ink500, fontSize: 12)),
          Slider(
            value: _dispatchMaxLawyers,
            min: 1,
            max: 12,
            divisions: 11,
            label: '${_dispatchMaxLawyers.round()}',
            activeColor: V26.navy600,
            onChanged: (v) => setState(() => _dispatchMaxLawyers = v),
          ),
        ],
      ),
    );
  }

  Widget _communicationCard(String code) {
    Widget row(String labelKey) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _t(code, labelKey),
                  style: const TextStyle(
                    color: V26.ink900,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              V26Badge(_t(code, 'badgeActive'), tone: V26BadgeTone.ok),
            ],
          ),
        );
    return V26Card(
      lift: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t(code, 'commTitle'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: V26.ink900,
            ),
          ),
          const SizedBox(height: 8),
          row('commTwilio'),
          row('commAgora'),
          row('commFcm'),
          row('commGemini'),
        ],
      ),
    );
  }

  Widget _maintenanceCard(String code) {
    return V26Card(
      lift: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t(code, 'maintenanceTitle'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: V26.ink900,
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t(code, 'maintenanceMode'),
                style: const TextStyle(
                    color: V26.ink900, fontWeight: FontWeight.w600)),
            subtitle: Text(_t(code, 'maintenanceHint'),
                style: const TextStyle(color: V26.ink500, fontSize: 12)),
            value: _maintenanceMode,
            onChanged: (v) => setState(() => _maintenanceMode = v),
            activeThumbColor: V26.navy600,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => _snack(_t(code, 'cacheResetSnack')),
              icon: const Icon(Icons.cleaning_services_outlined, size: 18),
              label: Text(_t(code, 'cacheReset')),
              style: OutlinedButton.styleFrom(
                foregroundColor: V26.navy700,
                side: const BorderSide(color: V26.hairline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  V26.navy500,
                  V26.ok,
                ]),
                borderRadius: BorderRadius.circular(1),
              )),
          const SizedBox(width: 8),
          Text(title.toUpperCase(),
              style: const TextStyle(
                  color: V26.navy600,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5)),
        ]),
      );

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            V26Card(
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              lift: false,
              child: Column(children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 8),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(label,
                    style: const TextStyle(color: V26.ink500, fontSize: 11)),
              ]),
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: color),
            ),
          ],
        ),
      );

  Widget _infoCard(String label, String value, {Color? statusColor}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: V26Card(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: V26.ink500, fontSize: 13)),
              Row(children: [
                if (statusColor != null)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsetsDirectional.only(start: 8, end: 6),
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: statusColor),
                  ),
                Text(value,
                    style: TextStyle(
                        color: statusColor ?? V26.ink900,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ]),
            ],
          ),
        ),
      );

  Widget _switchCard(String title, bool value, String subtitle, ValueChanged<bool> onChange) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: V26Card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: V26.ink900,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: V26.ink500, fontSize: 12)),
                  ]),
            ),
            Switch(
                value: value,
                onChanged: onChange,
                activeThumbColor: V26.navy600),
          ]),
        ),
      );

  Widget _actionCard(String title, IconData icon,
          {required VoidCallback onTap, Color? color, int? badge}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(V26.rLg),
            onTap: onTap,
            child: V26Card(
              onTap: null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderColor: color?.withValues(alpha: 0.35) ?? V26.hairline,
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (color ?? V26.navy500).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color ?? V26.navy500, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: V26.ink900,
                            fontSize: 14,
                            fontWeight: FontWeight.w500))),
                if (badge != null && badge > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: V26.emerg,
                        borderRadius: BorderRadius.circular(99)),
                    child: Text('$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(Icons.arrow_forward_ios_rounded,
                    color: color ?? V26.ink300, size: 14),
              ]),
            ),
          ),
        ),
      );
}
