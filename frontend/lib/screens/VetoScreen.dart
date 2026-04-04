import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class VetoScreen extends StatefulWidget {
  const VetoScreen({super.key});
  @override
  State<VetoScreen> createState() => _VetoScreenState();
}

class _VetoScreenState extends State<VetoScreen>
    with TickerProviderStateMixin {
  String _role = '', _phone = '';
  bool _isSearching = false;
  late final AnimationController _ringCtrl;
  late Animation<double> _ringScale, _ringOpacity;

  @override
  void initState() {
    super.initState();
    _loadData();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _ringScale = Tween<double>(begin: 1.0, end: 2.0).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ringOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final r = await AuthService().getStoredRole();
    final p = await AuthService().getStoredPhone();
    if (mounted) setState(() {
      _role = r ?? '';
      _phone = p ?? '';
    });
  }

  Future<void> _trigger() async {
    if (_isSearching) return;
    HapticFeedback.heavyImpact();
    setState(() => _isSearching = true);
    _ringCtrl.repeat();
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}
    SocketService().emitStartVeto(
        lat: pos?.latitude ?? 32.08,
        lng: pos?.longitude ?? 34.78,
        preferredLanguage: 'he');
  }

  void _cancel() {
    _ringCtrl.stop();
    _ringCtrl.reset();
    setState(() => _isSearching = false);
  }

  void _openCamera() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('מצלמה - בפיתוח')),
    );
  }

  void _openRecording() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('הקלטה - בפיתוח')),
    );
  }

  void _showLocation() async {
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pos != null
            ? 'מיקום: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
            : 'לא ניתן למצוא מיקום'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _role.toLowerCase().contains('admin');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('VETO'),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin_settings'),
                tooltip: 'ניהול',
              ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              tooltip: 'פרופיל',
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => AuthService().logout(context),
              tooltip: 'התנתק',
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: VetoPalette.border),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return Column(
              children: [
                const SizedBox(height: 20),
                _statusBadge(),
                const SizedBox(height: 48),
                Expanded(
                  child: Center(
                    child: _sosButton(constraints.maxWidth),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _isSearching
                        ? 'מחפש עורך דין... הקש לביטול'
                        : 'לחץ והחזק כדי להפעיל חירום',
                    style: const TextStyle(
                        color: VetoPalette.textMuted, fontSize: 13),
                  ),
                ),
                _actionRow(),
                const SizedBox(height: 24),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isSearching
            ? VetoPalette.emergency.withValues(alpha: 0.12)
            : VetoPalette.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _isSearching
              ? VetoPalette.emergency.withValues(alpha: 0.3)
              : VetoPalette.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSearching ? VetoPalette.emergency : VetoPalette.success,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isSearching ? 'שידור פעיל' : 'מוגן',
            style: TextStyle(
              color: _isSearching ? VetoPalette.emergency : VetoPalette.success,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (_phone.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              _phone,
              style: const TextStyle(
                  color: VetoPalette.textSubtle, fontSize: 11),
              textDirection: TextDirection.ltr,
            ),
          ],
        ],
      ),
    );
  }

  Widget _sosButton(double screenWidth) {
    final size = (screenWidth * 0.55).clamp(160.0, 220.0);

    return GestureDetector(
      onLongPress: _trigger,
      onTap: _isSearching ? _cancel : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isSearching)
            AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => Opacity(
                opacity: _ringOpacity.value,
                child: Transform.scale(
                  scale: _ringScale.value,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: VetoPalette.emergency, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSearching
                  ? VetoPalette.emergency.withValues(alpha: 0.12)
                  : VetoPalette.surface,
              border: Border.all(
                color: _isSearching
                    ? VetoPalette.emergency
                    : VetoPalette.border,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSearching
                      ? Icons.wifi_tethering_rounded
                      : Icons.shield_outlined,
                  size: size * 0.25,
                  color: _isSearching
                      ? VetoPalette.emergency
                      : VetoPalette.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  _isSearching ? 'שידור\nפעיל' : 'VETO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isSearching
                        ? VetoPalette.emergency
                        : VetoPalette.text,
                    fontSize: size * 0.11,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionBtn(Icons.camera_alt_outlined, 'תיעוד', _openCamera),
          _actionBtn(Icons.mic_none_rounded, 'הקלטה', _openRecording),
          _actionBtn(Icons.location_on_outlined, 'מיקום', _showLocation),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: VetoPalette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: VetoPalette.border),
            ),
            child: Icon(icon, color: VetoPalette.textMuted, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: VetoPalette.textSubtle, fontSize: 11)),
        ],
      ),
    );
  }
}