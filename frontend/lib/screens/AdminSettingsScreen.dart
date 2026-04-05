import 'package:flutter/material.dart';
import '../core/theme/veto_theme.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'admin/AllUsersScreen.dart';
import 'admin/AllLawyersScreen.dart';
import 'admin/EmergencyLogsScreen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenanceMode = false;
  bool _enableFixedOtp = true;
  String _serverStatus = 'טוען...';
  String _mongoDbStatus = 'טוען...';
  String _appVersion = 'טוען...';
  bool _loading = false;

  final AdminService _adminService = AdminService(); // NEW: AdminService instance

  @override
  void initState() {
    super.initState();
    _fetchAdminSettings(); // NEW: Fetch settings on init
  }

  // NEW: Fetch admin settings from backend
  Future<void> _fetchAdminSettings() async {
    setState(() => _loading = true);
    final settings = await _adminService.getAdminSettings();
    if (mounted && settings != null) {
      setState(() {
        _enableFixedOtp = settings['enableFixedOtpForAdmins'] ?? false;
        _serverStatus = settings['serverStatus'] ?? 'לא ידוע';
        _mongoDbStatus = settings['mongoDbStatus'] ?? 'לא ידוע';
        _appVersion = settings['appVersion'] ?? 'לא ידוע';
      });
    }
    setState(() => _loading = false);
  }

  // NEW: Handle toggle for Fixed OTP
  Future<void> _toggleFixedOtp(bool newValue) async {
    setState(() {
      _enableFixedOtp = newValue; // Optimistically update UI
      _loading = true;
    });
    final success = await _adminService.updateFixedOtpSetting(newValue);
    if (mounted) {
      setState(() {
        _loading = false;
        if (!success) {
          // Revert UI if update failed
          _enableFixedOtp = !_enableFixedOtp; 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('נכשל עדכון ההגדרה.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fixed OTP עבור אדמינים הוגדר ל-$newValue')),
          );
        }
      });
    }
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — בפיתוח')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          title: const Text('פאנל ניהול'),
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
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: VetoPalette.primary),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'יציאה',
              onPressed: () => AuthService().logout(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader('סקירת מערכת'),
                  _infoCard('סטטוס שרת', _serverStatus,
                      statusColor: _serverStatus == 'Online'
                          ? VetoPalette.success
                          : VetoPalette.emergency),
                  _infoCard('בסיס נתונים', _mongoDbStatus,
                      statusColor: _mongoDbStatus == 'Connected'
                          ? VetoPalette.success
                          : VetoPalette.emergency),
                  _infoCard('גרסת אפליקציה', _appVersion),
                  const SizedBox(height: 24),
                  _sectionHeader('הגדרות תפעול'),
                  _switchCard('מצב תחזוקה', _maintenanceMode,
                      'השרת לא יקבל בקשות חדשות',
                      (val) => setState(() => _maintenanceMode = val)),
                  _switchCard('OTP קבוע לאדמינים', _enableFixedOtp,
                      'קוד אימות קבוע לצרכי פיתוח', _toggleFixedOtp),
                  const SizedBox(height: 24),
                  _sectionHeader('ניהול משתמשים'),
                  _actionCard('כל המשתמשים', Icons.group_outlined,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllUsersScreen()))),
                  _actionCard('כל עורכי הדין', Icons.gavel_rounded,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllLawyersScreen()))),
                  _actionCard('יומני חירום', Icons.history_rounded,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyLogsScreen()))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: VetoPalette.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, {Color? statusColor}) {
    return Container(
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
              style: const TextStyle(
                  color: VetoPalette.textMuted, fontSize: 13)),
          Row(
            children: [
              if (statusColor != null)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
              Text(value,
                  style: TextStyle(
                    color: statusColor ?? VetoPalette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switchCard(
      String title, bool value, String subtitle, ValueChanged<bool> onChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Row(
        children: [
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
          Switch(value: value, onChanged: onChange),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VetoPalette.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: VetoPalette.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 14)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: VetoPalette.textSubtle, size: 14),
          ],
        ),
      ),
    );
  }
}