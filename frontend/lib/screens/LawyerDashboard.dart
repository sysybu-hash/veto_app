// ============================================================
//  LawyerDashboard.dart — Lawyer Command Center
//  New luxury design with WebRTC call support
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({super.key});
  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────
  bool   _available   = false;
  bool   _loading     = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _pendingAlert;
  String? _pendingEventId;

  // ── Socket ────────────────────────────────────────────────
  late SocketService _socket;

  // ── Animations ────────────────────────────────────────────
  late AnimationController _alertCtrl;
  late Animation<double>   _alertAnim;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    _alertCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _alertAnim = CurvedAnimation(parent: _alertCtrl, curve: Curves.easeOutBack);

    _pulseCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final auth    = AuthService();
      final profile = await auth.fetchProfile();
      if (mounted) {
        setState(() {
          _profile   = profile;
          _available = profile?['is_available'] == true;
          _loading   = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    // Connect socket and register listeners
    if (!mounted) return;
    _socket = context.read<SocketService>();
    if (!_socket.isConnected) await _socket.connect(role: 'lawyer');
    _registerSocketListeners();
  }

  void _registerSocketListeners() {
    _socket.on('new_emergency_alert', (data) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _pendingAlert = Map<String, dynamic>.from(data));
      _alertCtrl.forward(from: 0);

      // Auto-dismiss after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _pendingAlert != null) {
          setState(() { _pendingAlert = null; _pendingEventId = null; });
          _alertCtrl.reverse();
        }
      });
    });

    _socket.on('case_taken', (data) {
      if (mounted) {
        setState(() { _pendingAlert = null; _pendingEventId = null; });
        _alertCtrl.reverse();
      }
    });

    _socket.on('case_accepted_confirmed', (data) {
      if (!mounted) return;
      final roomId = data['roomId']?.toString();
      if (roomId == null) return;
      setState(() { _pendingAlert = null; });

      // Navigate to call
      Navigator.of(context).pushNamed('/call', arguments: {
        'roomId':   roomId,
        'callType': 'video',
        'peerName': 'לקוח',
        'role':     'lawyer',
      });
    });
  }

  Future<void> _toggleAvailability(bool val) async {
    setState(() => _available = val);
    _socket.emit('lawyer_availability', {'available': val});
  }

  void _acceptCase() {
    if (_pendingAlert == null) return;
    final eventId = _pendingAlert!['eventId'];
    _pendingEventId = eventId;
    _socket.emit('accept_case', {'eventId': eventId});
  }

  void _rejectCase() {
    if (_pendingAlert == null) return;
    _socket.emit('reject_case', {'eventId': _pendingAlert!['eventId']});
    setState(() { _pendingAlert = null; });
    _alertCtrl.reverse();
  }

  @override
  void dispose() {
    _alertCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VetoColors.background,
      body: Container(
        decoration: VetoDecorations.gradientBg(),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Main content ─────────────────────────────────
              Column(
                children: [
                  _buildAppBar(),
                  if (_loading)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: VetoColors.accent)))
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            _buildAvailabilityCard(),
                            const SizedBox(height: 20),
                            _buildStatsRow(),
                            const SizedBox(height: 20),
                            _buildQuickLinks(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // ── Emergency alert overlay ───────────────────────
              if (_pendingAlert != null)
                Positioned(
                  top: 0, bottom: 0, left: 0, right: 0,
                  child: _buildAlertOverlay(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  App bar
  // ─────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final name = _profile?['full_name']?.toString().split(' ').first ?? 'עורך דין';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.w800),
              children: [
                TextSpan(text: 'VE', style: TextStyle(color: VetoColors.white)),
                TextSpan(text: 'TO', style: TextStyle(color: VetoColors.vetoRed)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: VetoColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'עורך דין',
              style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: VetoColors.accent, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          Text(
            'שלום, $name',
            style: const TextStyle(fontFamily: 'Heebo', fontSize: 13, color: VetoColors.silver),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: VetoColors.silver),
            onPressed: () => Navigator.pushNamed(context, '/lawyer_settings'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Availability card
  // ─────────────────────────────────────────────────────────
  Widget _buildAvailabilityCard() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _available ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _available
                ? [VetoColors.success.withOpacity(0.15), VetoColors.accent.withOpacity(0.08)]
                : [VetoColors.surface, VetoColors.surfaceHigh.withOpacity(0.5)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _available ? VetoColors.success.withOpacity(0.4) : VetoColors.border,
            width: _available ? 1.5 : 1,
          ),
          boxShadow: _available
              ? [BoxShadow(color: VetoColors.success.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)]
              : [],
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _available ? VetoColors.success.withOpacity(0.2) : VetoColors.textMuted.withOpacity(0.2),
              ),
              child: Icon(
                _available ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                color: _available ? VetoColors.success : VetoColors.textMuted,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _available ? 'זמין לקריאות' : 'לא זמין',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _available ? VetoColors.success : VetoColors.silver,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _available ? 'לקוחות יכולים לקרוא לך' : 'לא תופיע בחיפוש',
                    style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, color: VetoColors.silver),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 1.2,
              child: Switch(
                value: _available,
                onChanged: _toggleAvailability,
                activeColor: VetoColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Stats row
  // ─────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      {'label': 'תיקים', 'value': _profile?['total_cases']?.toString() ?? '—', 'icon': Icons.work_outline, 'color': VetoColors.accent},
      {'label': 'דירוג', 'value': '${(_profile?['rating']?['average'] ?? 0.0).toStringAsFixed(1)} ★', 'icon': Icons.star_outline, 'color': VetoColors.warning},
      {'label': 'זמינות', 'value': _available ? 'פעיל' : 'כבוי', 'icon': Icons.access_time, 'color': _available ? VetoColors.success : VetoColors.textMuted},
    ];

    return Row(
      children: stats.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: i < stats.length - 1 ? 8 : 0,
              right: i > 0 ? 8 : 0,
            ),
            padding: const EdgeInsets.all(16),
            decoration: VetoDecorations.surfaceCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                const SizedBox(height: 8),
                Text(
                  s['value'] as String,
                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.w700, color: VetoColors.white),
                ),
                const SizedBox(height: 2),
                Text(s['label'] as String, style: const TextStyle(fontFamily: 'Heebo', fontSize: 11, color: VetoColors.silver)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Quick links
  // ─────────────────────────────────────────────────────────
  Widget _buildQuickLinks() {
    final links = [
      {'icon': Icons.chat_bubble_outline,  'label': 'הודעות',          'route': '/chat'},
      {'icon': Icons.folder_outlined,      'label': 'כספת מסמכים',     'route': '/files_vault'},
      {'icon': Icons.settings_outlined,    'label': 'הגדרות',           'route': '/lawyer_settings'},
      {'icon': Icons.person_outline,       'label': 'פרופיל',           'route': '/profile'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'כלים מהירים',
          style: TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: VetoColors.silver),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: links.map((l) => GestureDetector(
            onTap: () => Navigator.pushNamed(context, l['route'] as String),
            child: Container(
              decoration: VetoDecorations.surfaceCard(radius: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(l['icon'] as IconData, color: VetoColors.accent, size: 24),
                  const SizedBox(height: 6),
                  Text(l['label'] as String, textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Heebo', fontSize: 11, color: VetoColors.silver)),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Emergency alert overlay
  // ─────────────────────────────────────────────────────────
  Widget _buildAlertOverlay() {
    final alert = _pendingAlert!;
    return ScaleTransition(
      scale: _alertAnim,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: VetoColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: VetoColors.vetoRed.withOpacity(0.5), width: 2),
                boxShadow: VetoDecorations.vetoGlow(intensity: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing red indicator
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 800),
                    builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                    onEnd: () => setState(() {}),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VetoColors.vetoRedSoft,
                        border: Border.all(color: VetoColors.vetoRed, width: 2),
                      ),
                      child: const Icon(Icons.notification_important, color: VetoColors.vetoRed, size: 32),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    '🚨 התראת חירום',
                    style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.w800, color: VetoColors.white),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    '${alert['userName'] ?? 'לקוח'} זקוק לייעוץ משפטי דחוף',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Heebo', fontSize: 15, color: VetoColors.silver),
                  ),
                  const SizedBox(height: 8),

                  if (alert['language'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: VetoColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'שפה: ${alert['language']}',
                        style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, color: VetoColors.accent),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _rejectCase,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VetoColors.silver,
                            side: const BorderSide(color: VetoColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('דחה', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _acceptCase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VetoColors.success,
                            foregroundColor: VetoColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, size: 20),
                              SizedBox(width: 8),
                              Text('קבל את התיק', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
