// ============================================================
//  LawyerDashboard.dart - VETO
//  Main Screen for Lawyers
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class LawyerColors {
  static const Color background = Color(0xFF001220);
  static const Color primary    = Color(0xFFD4AF37);
  static const Color primaryDim = Color(0xFF8C7323);
  static const Color silver     = Color(0xFFC0C2C9);
  static const Color silverDim  = Color(0xFF8A8C93);
  static const Color white      = Color(0xFFFFFFFF);
  static const Color safe       = Color(0xFF2ECC71);
  static const Color cardBg     = Color(0xFF012A52);
}

class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({super.key});

  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard> {
  String _lawyerName = 'טוען...';
  bool _isAvailable = true;
  List<Map<String, dynamic>> _activeCases = [];
  String _role = 'lawyer';
  String _phone = '';

  StreamSubscription? _newAlertSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    AuthService().getStoredRole().then((r) {
      if (mounted && r != null) {
        setState(() => _role = r);
      }
      SocketService().connect(role: r ?? 'lawyer');
      SocketService().emit('lawyer_availability', {'available': _isAvailable});
    });

    try {
      _newAlertSub = SocketService().onNewEmergencyAlert.listen((data) {
        debugPrint('LawyerDashboard: New emergency alert received');
        if (mounted) {
          setState(() {
            _activeCases.add(data);
          });
          _showEmergencyDialog(data);
        }
      });
    } catch(e) {}
  }

  Future<void> _loadProfile() async {
    final auth = AuthService();
    final name = await auth.getStoredName();
    final phone = await auth.getStoredPhone();
    if (mounted) {
      setState(() {
        _lawyerName = (name != null && name.isNotEmpty) ? name : 'עורך דין (שם חסר)';
        _phone = phone ?? '';
      });
    }
  }

  @override
  void dispose() {
    _newAlertSub?.cancel();
    super.dispose();
  }

  void _toggleAvailability(bool value) {
    setState(() {
      _isAvailable = value;
    });
    SocketService().emit('lawyer_availability', {'available': value});
  }

  void _acceptCase(Map<String, dynamic> caseData) {
    debugPrint('Accepting case');
    SocketService().emit('accept_case', {'eventId': caseData['eventId']});
    
    setState(() {
      _activeCases.removeWhere((c) => c['eventId'] == caseData['eventId']);
      _isAvailable = false;
    });
    SocketService().emit('lawyer_availability', {'available': false});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('התיק התקבל בהצלחה. המשתמש עודכן.'),
        backgroundColor: LawyerColors.safe,
      ),
    );
  }

  void _rejectCase(Map<String, dynamic> caseData) {
    debugPrint('Rejecting case');
    try {
      SocketService().emit('reject_case', {'eventId': caseData['eventId']});
    } catch(e) {}
    setState(() {
      _activeCases.removeWhere((c) => c['eventId'] == caseData['eventId']);
    });
  }

  void _showEmergencyDialog(Map<String, dynamic> caseData) {
    final userId = caseData['userId']?.toString() ?? 'לא ידוע';
    final details = caseData['details']?.toString() ?? 'אין פרטים';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: LawyerColors.cardBg,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 12),
            const Text('קריאת חירום חדשה!', style: TextStyle(color: LawyerColors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('משתמש: ' + userId, style: const TextStyle(color: LawyerColors.silver)),
            const SizedBox(height: 8),
            Text('פרטים: ' + details, style: const TextStyle(color: LawyerColors.silver)),
            const SizedBox(height: 16),
            const Text('האם ברצונך לקבל את הטיפול?', style: TextStyle(color: LawyerColors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectCase(caseData);
            },
            child: const Text('דחה', style: TextStyle(color: LawyerColors.silverDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LawyerColors.primary),
            onPressed: () {
              Navigator.of(context).pop();
              _acceptCase(caseData);
            },
            child: const Text('קבל תיק', style: TextStyle(color: LawyerColors.background, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: LawyerColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              _buildStatusHeader(),
              const SizedBox(height: 24),
              _buildStatsRow(),
              const SizedBox(height: 32),
              Expanded(
                child: _buildCasesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LawyerColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.balance_rounded, color: LawyerColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('קונסולת עורך דין', style: TextStyle(color: LawyerColors.silverDim, fontSize: 10, letterSpacing: 1.5)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('עו"ד ' + _lawyerName, style: const TextStyle(color: LawyerColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        if (_phone.isNotEmpty)
                          Text(_phone, style: const TextStyle(color: LawyerColors.silverDim, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (_role == 'admin')
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: LawyerColors.silver),
                  onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
                  tooltip: 'פאנל ניהול',
                ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: LawyerColors.silverDim),
                onPressed: () => AuthService().logout(context),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: LawyerColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LawyerColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('סטטוס זמינות', style: TextStyle(color: LawyerColors.silver, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _isAvailable ? 'זמין לקריאות' : 'לא זמין',
                  style: TextStyle(
                    color: _isAvailable ? LawyerColors.safe : Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Switch(
              value: _isAvailable,
              onChanged: _toggleAvailability,
              activeColor: LawyerColors.safe,
              inactiveThumbColor: LawyerColors.silverDim,
              inactiveTrackColor: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('קריאות ממתינות', _activeCases.length.toString(), Icons.notification_important_rounded, Colors.orangeAccent)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('תיקים פעילים', '0', Icons.folder_open_rounded, LawyerColors.primary)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LawyerColors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: LawyerColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: LawyerColors.silverDim, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCasesList() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: LawyerColors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('קריאות חירום פעילות', style: TextStyle(color: LawyerColors.background, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _activeCases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: LawyerColors.silverDim.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('אין קריאות ממתינות כרגע', style: TextStyle(color: LawyerColors.silverDim, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _activeCases.length,
                    itemBuilder: (context, index) {
                      final c = _activeCases[index];
                      final eventIdStr = c['eventId']?.toString() ?? 'Unknown';
                      final locationStr = c['location']?.toString() ?? 'לא ידוע';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 8),
                                    Text('VETO #' + (eventIdStr.length > 6 ? eventIdStr.substring(0, 6) : eventIdStr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Text('עכשיו', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('מיקום: ' + locationStr, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _rejectCase(c),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade600, side: BorderSide(color: Colors.grey.shade300)),
                                    child: const Text('התעלם'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _acceptCase(c),
                                    style: ElevatedButton.styleFrom(backgroundColor: LawyerColors.background, foregroundColor: LawyerColors.white),
                                    child: const Text('קבל תיק'),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}