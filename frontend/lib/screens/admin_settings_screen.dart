// ============================================================
//  AdminSettingsScreen.dart — Full Admin Dashboard
//  VETO Legal Emergency App
// ============================================================

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_glass_system.dart';
import '../core/theme/veto_theme.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';
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
      backgroundColor: error ? VetoPalette.emergency : VetoPalette.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoGlassTokens.bgBase,
        appBar: AppBar(
          backgroundColor: const Color(0x18FFFFFF),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: VetoGlassTokens.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_t(code, 'adminPanel'),
              style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
          centerTitle: true,
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: AppLanguageMenu(compact: true)),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: VetoGlassTokens.neonCyan),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.apps_rounded, color: VetoGlassTokens.textPrimary),
              tooltip: _t(code, 'openApp'),
              onPressed: () => Navigator.of(context).pushNamed('/veto_screen'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: VetoGlassTokens.textPrimary),
              tooltip: _t(code, 'refresh'),
              onPressed: _loadAll,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFFF3B3B)),
              tooltip: _t(code, 'logout'),
              onPressed: () => AuthService().logout(context),
            ),
          ],
          bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: VetoGlassTokens.glassBorder)),
        ),
        body: VetoGlassAuroraBackground(
          child: RefreshIndicator(
          onRefresh: _loadAll,
          color: VetoGlassTokens.neonCyan,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader(_t(code, 'quickStats')),
                    Row(children: [
                      Expanded(
                        child: _statCard(_t(code, 'users'), '$_totalUsers',
                            Icons.group_outlined, VetoPalette.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(_t(code, 'lawyers'), '$_totalLawyers',
                            Icons.gavel_rounded, VetoPalette.success),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          _t(code, 'pending'),
                          '$_pendingLawyersCount',
                          Icons.pending_actions_rounded,
                          _pendingLawyersCount > 0
                              ? VetoPalette.emergency
                              : VetoPalette.textMuted,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    if (_pendingLawyersCount > 0) ...[
                      _sectionHeader(_t(code, 'pendingApprovals')),
                      _actionCard(
                        '${_t(code, 'pendingApprovalsAction')} ($_pendingLawyersCount ${_t(code, 'pending')})',
                        Icons.how_to_reg_rounded,
                        color: VetoPalette.emergency,
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
                    _sectionHeader(_t(code, 'systemOverview')),
                    _infoCard(
                        _t(code, 'serverStatus'),
                        _serverStatus.isEmpty ? _t(code, 'loading') : _serverStatus,
                        statusColor: _serverStatus == 'Online'
                            ? VetoPalette.success
                            : VetoPalette.emergency),
                    _infoCard(
                        _t(code, 'database'),
                        _mongoDbStatus.isEmpty ? _t(code, 'loading') : _mongoDbStatus,
                        statusColor: _mongoDbStatus == 'Connected'
                            ? VetoPalette.success
                            : VetoPalette.emergency),
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
                      color: VetoPalette.success,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/veto_screen'),
                    ),
                    _actionCard(
                      code == 'he' ? 'לוח בקרה ראשי' : code == 'ru' ? 'Главная панель' : 'Admin Dashboard',
                      Icons.dashboard_rounded,
                      color: VetoPalette.primary,
                      onTap: () => Navigator.pushNamed(context, '/admin_dashboard'),
                    ),
                    _actionCard(
                      code == 'he' ? 'ניהול מנויים' : code == 'ru' ? 'Подписки' : 'Subscription Management',
                      Icons.subscriptions_rounded,
                      color: VetoPalette.accentSky,
                      onTap: () => Navigator.pushNamed(context, '/admin_subscriptions'),
                    ),
                    _actionCard(
                      code == 'he' ? 'הגדרות מערכת' : code == 'ru' ? 'Настройки системы' : 'System Settings',
                      Icons.settings_rounded,
                      color: VetoPalette.textMuted,
                      onTap: () => Navigator.pushNamed(context, '/settings'),
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

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(width: 20, height: 2, decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF5B8FFF), Color(0xFF00C9B1)]),
        borderRadius: BorderRadius.circular(1),
      )),
      const SizedBox(width: 8),
      Text(title.toUpperCase(), style: const TextStyle(
          color: Color(0xFF5B8FFF), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.5)),
    ]),
  );

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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

  Widget _infoCard(String label, String value, {Color? statusColor}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F8)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            Row(children: [
              if (statusColor != null)
                Container(
                  width: 7, height: 7,
                  margin: const EdgeInsets.only(left: 8, right: 6),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                ),
              Text(value, style: TextStyle(
                  color: statusColor ?? const Color(0xFF0F172A),
                  fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ],
        ),
      );

  Widget _switchCard(String title, bool value, String subtitle, ValueChanged<bool> onChange) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F8)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ]),
          ),
          Switch(value: value, onChanged: onChange, activeThumbColor: const Color(0xFF5B8FFF)),
        ]),
      );

  Widget _actionCard(String title, IconData icon, {required VoidCallback onTap, Color? color, int? badge}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color?.withValues(alpha: 0.3) ?? const Color(0xFFE2E8F8)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFF5B8FFF)).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color ?? const Color(0xFF5B8FFF), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500))),
            if (badge != null && badge > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFF3B3B), borderRadius: BorderRadius.circular(99)),
                child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.arrow_forward_ios_rounded, color: color ?? const Color(0xFF94A3B8), size: 14),
          ]),
        ),
      );
}
