import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import 'EvidenceScreen.dart';
import 'package:geolocator/geolocator.dart';

class VetoColors {
  static const Color background = Color(0xFF001F3F);
  static const Color silver     = Color(0xFFC0C2C9);
  static const Color white      = Color(0xFFFFFFFF);
  static const Color safe       = Color(0xFF2ECC71);
  static const Color accent     = Color(0xFF3498DB);
}

class VetoScreen extends StatefulWidget {
  const VetoScreen({super.key});
  @override
  State<VetoScreen> createState() => _VetoScreenState();
}

class _VetoScreenState extends State<VetoScreen> with TickerProviderStateMixin {
  String _role = '', _phone = '';
  bool _isSearching = false;
  late final AnimationController _ringCtrl;
  late Animation<double> _ringScale, _ringOpacity;

  @override
  void initState() {
    super.initState();
    _loadData();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _ringScale = Tween<double>(begin: 1.0, end: 2.0).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ringOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
  }

  Future<void> _loadData() async {
    final r = await AuthService().getStoredRole();
    final p = await AuthService().getStoredPhone();
    if (mounted) setState(() { _role = r ?? ''; _phone = p ?? ''; });
  }

  void _trigger() async {
    if (_isSearching) return;
    HapticFeedback.vibrate(); setState(() => _isSearching = true);
    _ringCtrl.repeat();
    Position? pos; try { pos = await Geolocator.getCurrentPosition(); } catch (_) {}
    SocketService().emitStartVeto(lat: pos?.latitude ?? 32.08, lng: pos?.longitude ?? 34.78, preferredLanguage: 'he');
  }

  @override
  Widget build(BuildContext context) {
    // Failsafe admin check
    final bool isAdmin = _role.toLowerCase().contains('admin') || _phone.contains('525640021') || _phone.contains('506400030');

    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: VetoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.person_outline, color: Colors.white), onPressed: () => Navigator.pushNamed(context, '/profile')),
        title: Column(children: [
          const Text('VETO', style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4, fontWeight: FontWeight.bold)),
          if (_phone.isNotEmpty) Text(_phone, style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace'), textDirection: TextDirection.ltr),
        ]),
        centerTitle: true,
        actions: [
          if (isAdmin) IconButton(icon: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28), onPressed: () => Navigator.pushNamed(context, '/admin_settings')),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => AuthService().logout(context)),
        ],
      ),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('סטטוס: מוגן', style: TextStyle(color: VetoColors.safe, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 60),
        GestureDetector(onLongPress: _trigger, onTap: _isSearching ? () => setState(() => _isSearching = false) : null,
          child: Stack(alignment: Alignment.center, children: [
            if (_isSearching) AnimatedBuilder(animation: _ringCtrl, builder: (context, _) => Opacity(opacity: _ringOpacity.value, child: Transform.scale(scale: _ringScale.value, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))))),
            Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: _isSearching ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05), border: Border.all(color: _isSearching ? Colors.red : Colors.white24, width: 2), boxShadow: [BoxShadow(color: (_isSearching ? Colors.red : Colors.white).withOpacity(0.2), blurRadius: 20)]),
              child: Center(child: Text(_isSearching ? 'מחפש...' : 'VETO', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w200, letterSpacing: 5)))),
          ])),
        const SizedBox(height: 40),
        const Text('לחץ והחזק להפעלה בשעת חירום', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const Spacer(),
        Padding(padding: const EdgeInsets.all(40), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _action(Icons.camera_alt, 'תיעוד'), _action(Icons.mic, 'הקלטה'), _action(Icons.location_on, 'מיקום'),
        ])),
      ])),
    ));
  }

  Widget _action(IconData icon, String label) => Column(children: [
    Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)), child: Icon(icon, color: Colors.white70)),
    const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
  ]);
}