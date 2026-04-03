import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart'; // NEW: Import AdminService

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001220),
      appBar: AppBar(
        title: const Text('פאנל ניהול', style: TextStyle(fontSize: 14, letterSpacing: 2.0)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading && _serverStatus == 'טוען...' // Show loading indicator only on initial load
          ? const Center(child: CircularProgressIndicator(color: Colors.white70))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('סקירת מערכת'),
                  _buildInfoCard('סטטוס שרת', _serverStatus, color: _serverStatus == 'Online' ? Colors.green : Colors.red),
                  _buildInfoCard('בסיס נתונים (MONGO DB)', _mongoDbStatus, color: _mongoDbStatus == 'Connected' ? Colors.green : Colors.red),
                  _buildInfoCard('גרסה', _appVersion, color: Colors.white24),
                  const SizedBox(height: 32),
                  _buildSectionHeader('פקדי תפעול'),
                  _buildSwitchTile('מצב תחזוקה', _maintenanceMode, (val) => setState(() => _maintenanceMode = val)),
                  _buildSwitchTile('OTP קבוע לאדמינים', _enableFixedOtp, _toggleFixedOtp), // NEW: Use _toggleFixedOtp
                  const SizedBox(height: 32),
                  _buildSectionHeader('ניהול משתמשים'),
                  _buildActionCard('צפה בכל המשתמשים', Icons.group_outlined, () { /* TODO: Implement navigation to user list */ }),
                  _buildActionCard('צפה בכל עורכי הדין', Icons.balance_outlined, () { /* TODO: Implement navigation to lawyer list */ }),
                  _buildActionCard('יומני חירום', Icons.history_rounded, () { /* TODO: Implement navigation to emergency logs */ }),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w300)),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF2ECC71)),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF012A52),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 0.5)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
