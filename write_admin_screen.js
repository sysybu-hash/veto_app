const fs = require('fs');
const content = `// ============================================================
//  AdminSettingsScreen.dart \u2014 Full Admin Dashboard
//  VETO Legal Emergency App
// ============================================================

import 'package:flutter/material.dart';
import '../core/theme/veto_theme.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'admin/AllUsersScreen.dart';
import 'admin/AllLawyersScreen.dart';
import 'admin/EmergencyLogsScreen.dart';
import 'admin/PendingLawyersScreen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _enableFixedOtp = false;
  String _serverStatus = '\u05d8\u05d5\u05e2\u05df...';
  String _mongoDbStatus = '\u05d8\u05d5\u05e2\u05df...';
  String _appVersion = '\u05d8\u05d5\u05e2\u05df...';
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
        _serverStatus = settings['serverStatus'] ?? '\u05dc\u05d0 \u05d9\u05d3\u05d5\u05e2';
        _mongoDbStatus = settings['mongoDbStatus'] ?? '\u05dc\u05d0 \u05d9\u05d3\u05d5\u05e2';
        _appVersion = settings['appVersion'] ?? '\u05dc\u05d0 \u05d9\u05d3\u05d5\u05e2';
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
      setState(() => _loading = false);
      if (!ok) {
        setState(() => _enableFixedOtp = !value);
        _snack('\u05e9\u05d2\u05d9\u05d0\u05d4 \u05d1\u05e2\u05d3\u05db\u05d5\u05df \u05d4\u05d4\u05d2\u05d3\u05e8\u05d4', error: true);
      } else {
        _snack('\u05d4\u05d4\u05d2\u05d3\u05e8\u05d4 \u05e2\u05d5\u05d3\u05db\u05e0\u05d4 \u05d1\u05d4\u05e6\u05dc\u05d7\u05d4');
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          title: const Text('\u05e4\u05d0\u05e0\u05dc \u05e0\u05d9\u05d4\u05d5\u05dc'),
          backgroundColor: VetoPalette.surface,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: VetoPalette.border),
          ),
          actions: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: VetoPalette.primary),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.apps_rounded),
              tooltip: '\u05db\u05e0\u05d9\u05e1\u05d4 \u05dc\u05d0\u05e4\u05dc\u05d9\u05e7\u05e6\u05d9\u05d4',
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/veto_screen'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: '\u05e8\u05e2\u05e0\u05df',
              onPressed: _loadAll,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: '\u05d9\u05e6\u05d9\u05d0\u05d4',
              onPressed: () => AuthService().logout(context),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadAll,
          color: VetoPalette.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('\u05e1\u05d8\u05d8\u05d9\u05e1\u05d8\u05d9\u05e7\u05d4 \u05de\u05d4\u05d9\u05e8\u05d4'),
                    Row(children: [
                      Expanded(
                        child: _statCard('\u05de\u05e9\u05ea\u05de\u05e9\u05d9\u05dd', '\$_totalUsers',
                            Icons.group_outlined, VetoPalette.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard('\u05e2\u05d5".\u05d3', '\$_totalLawyers',
                            Icons.gavel_rounded, VetoPalette.success),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          '\u05de\u05de\u05ea\u05d9\u05e0\u05d9\u05dd',
                          '\$_pendingLawyersCount',
                          Icons.pending_actions_rounded,
                          _pendingLawyersCount > 0
                              ? VetoPalette.emergency
                              : VetoPalette.textMuted,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    if (_pendingLawyersCount > 0) ...[
                      _sectionHeader(
                          '\u26a0\ufe0f  \u05e2\u05d5\u05e8\u05db\u05d9 \u05d3\u05d9\u05df \u05de\u05de\u05ea\u05d9\u05e0\u05d9\u05dd \u05dc\u05d0\u05d9\u05e9\u05d5\u05e8'),
                      _actionCard(
                        '\u05d0\u05d9\u05e9\u05d5\u05e8 \u05e2\u05d5\u05e8\u05db\u05d9 \u05d3\u05d9\u05df (\$_pendingLawyersCount \u05de\u05de\u05ea\u05d9\u05e0\u05d9\u05dd)',
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
                      const SizedBox(height: 24),
                    ],
                    _sectionHeader('\u05e1\u05e7\u05d9\u05e8\u05ea \u05de\u05e2\u05e8\u05db\u05ea'),
                    _infoCard('\u05e1\u05d8\u05d8\u05d5\u05e1 \u05e9\u05e8\u05ea', _serverStatus,
                        statusColor: _serverStatus == 'Online'
                            ? VetoPalette.success
                            : VetoPalette.emergency),
                    _infoCard('\u05d1\u05e1\u05d9\u05e1 \u05e0\u05ea\u05d5\u05e0\u05d9\u05dd', _mongoDbStatus,
                        statusColor: _mongoDbStatus == 'Connected'
                            ? VetoPalette.success
                            : VetoPalette.emergency),
                    _infoCard('\u05d2\u05e8\u05e1\u05ea \u05d0\u05e4\u05dc\u05d9\u05e7\u05e6\u05d9\u05d4', _appVersion),
                    const SizedBox(height: 24),
                    _sectionHeader('\u05e0\u05d9\u05d4\u05d5\u05dc \u05de\u05e9\u05ea\u05de\u05e9\u05d9\u05dd'),
                    _actionCard(
                      '\u05db\u05dc \u05d4\u05de\u05e9\u05ea\u05de\u05e9\u05d9\u05dd (\$_totalUsers)',
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
                      '\u05db\u05dc \u05e2\u05d5\u05e8\u05db\u05d9 \u05d4\u05d3\u05d9\u05df (\$_totalLawyers)',
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
                      '\u05d9\u05d5\u05de\u05e0\u05d9 \u05d7\u05d9\u05e8\u05d5\u05dd',
                      Icons.history_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EmergencyLogsScreen()),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('\u05d4\u05d2\u05d3\u05e8\u05d5\u05ea \u05de\u05e2\u05e8\u05db\u05ea'),
                    _switchCard(
                      'OTP \u05e7\u05d1\u05d5\u05e2 \u05dc\u05d0\u05d3\u05de\u05d9\u05e0\u05d9\u05dd',
                      _enableFixedOtp,
                      '\u05e7\u05d5\u05d3 123456 \u05dc\u05e6\u05e8\u05db\u05d9 \u05e4\u05d9\u05ea\u05d5\u05d7 \u05d5\u05d1\u05d3\u05d9\u05e7\u05d5\u05ea',
                      _toggleFixedOtp,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title,
        style: const TextStyle(
            color: VetoPalette.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1)),
  );

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VetoPalette.border),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: VetoPalette.textMuted, fontSize: 11)),
        ]),
      );

  Widget _infoCard(String label, String value, {Color? statusColor}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VetoPalette.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(color: VetoPalette.textMuted, fontSize: 13)),
            Row(children: [
              if (statusColor != null)
                Container(
                  width: 7, height: 7,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: statusColor),
                ),
              Text(value,
                  style: TextStyle(
                    color: statusColor ?? VetoPalette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ]),
          ],
        ),
      );

  Widget _switchCard(String title, bool value, String subtitle,
          ValueChanged<bool> onChange) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VetoPalette.border),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: VetoPalette.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
              value: value, onChanged: onChange, activeColor: VetoPalette.primary),
        ]),
      );

  Widget _actionCard(
    String title,
    IconData icon, {
    required VoidCallback onTap,
    Color? color,
    int? badge,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: VetoPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: color?.withValues(alpha: 0.4) ?? VetoPalette.border),
          ),
          child: Row(children: [
            Icon(icon, color: color ?? VetoPalette.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title, style: const TextStyle(fontSize: 14))),
            if (badge != null && badge > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: VetoPalette.emergency,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('\$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.arrow_forward_ios_rounded,
                color: color ?? VetoPalette.textSubtle, size: 14),
          ]),
        ),
      );
}
`;

fs.writeFileSync(
  'C:/Users/User/Desktop/VETO_App/frontend/lib/screens/AdminSettingsScreen.dart',
  content,
  'utf8'
);
console.log('Written', content.length, 'chars');
