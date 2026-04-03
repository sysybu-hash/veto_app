import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenanceMode = false;
  bool _enableFixedOtp = true;
  String _serverStatus = 'Online';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001220),
      appBar: AppBar(
        title: const Text('ADMIN CONSOLE', style: TextStyle(fontSize: 14, letterSpacing: 2.0)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('SYSTEM OVERVIEW'),
            _buildInfoCard('SERVER STATUS', _serverStatus, color: Colors.green),
            _buildInfoCard('MONGO DB', 'Connected', color: Colors.green),
            _buildInfoCard('VERSION', 'v1.2.4', color: Colors.white24),
            const SizedBox(height: 32),
            _buildSectionHeader('OPERATION CONTROLS'),
            _buildSwitchTile('MAINTENANCE MODE', _maintenanceMode, (val) => setState(() => _maintenanceMode = val)),
            _buildSwitchTile('FIXED OTP FOR ADMINS', _enableFixedOtp, (val) => setState(() => _enableFixedOtp = val)),
            const SizedBox(height: 32),
            _buildSectionHeader('USER MANAGEMENT'),
            _buildActionCard('VIEW ALL USERS', Icons.group_outlined, () {}),
            _buildActionCard('VIEW ALL LAWYERS', Icons.balance_outlined, () {}),
            _buildActionCard('EMERGENCY LOGS', Icons.history_rounded, () {}),
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
