// ============================================================
//  LawyerDashboard.dart — Lawyer-side UI
//  VETO Legal Emergency App
//  Screens: Idle → Emergency Alert Overlay → Active Case View
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../services/socket_service.dart';

// ── Brand palette ──────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF001220); // Darker, slightly different blue for lawyer
  static const consoleBg = Color(0xFF001F3F); // Header navy
  static const silver    = Color(0xFFC0C2C9);
  static const silverDim = Color(0xFF8A8C93);
  static const white     = Color(0xFFFFFFFF);
  static const accept    = Color(0xFF2ECC71); // Green
  static const decline   = Color(0xFFE74C3C); // Red
  static const alert     = Color(0xFFE74C3C); // Emergency red
  static const cardBg    = Color(0xFF012A52); // Slightly lighter navy
}

// ── Session helper (replaces hardcoded _Session) ──
class _Session {
  static Future<String> getLawyerName() async {
    final name = await AuthService().getStoredName();
    return name ?? 'Lawyer / Admin';
  }
  static String get serverUrl => AppConfig.socketOrigin;
}

// ══════════════════════════════════════════════════════════════
//  LawyerDashboard
// ══════════════════════════════════════════════════════════════
class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({super.key});

  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────
  bool _isOnline      = false;
  bool _isConnected   = false;
  String _lawyerName  = 'Loading...';

  // Alert
  Map<String, dynamic>? _pendingAlert; // incoming emergency payload
  bool _alertVisible  = false;

  // Active case
  Map<String, dynamic>? _activeCase;  // case_accepted_confirmed payload
  bool _caseActive    = false;
  final List<Map<String, dynamic>> _evidenceItems = [];

  // Socket
  final _socket = SocketService();
  final List<StreamSubscription> _subs = [];

  // ── Animations ─────────────────────────────────────────────
  late final AnimationController _alertPulseCtrl;
  late Animation<double> _alertBorderWidth;
  late Animation<Color?> _alertBorderColor;

  @override
  void initState() {
    super.initState();
    _loadName();
    _buildAnimations();
    _connectSocket();
    _listenToSocket();
  }

  Future<void> _loadName() async {
    final name = await _Session.getLawyerName();
    if (mounted) setState(() => _lawyerName = name);
  }

  void _buildAnimations() {
    _alertPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _alertBorderWidth = Tween<double>(begin: 1.5, end: 4.0).animate(
      CurvedAnimation(parent: _alertPulseCtrl, curve: Curves.easeInOut),
    );

    _alertBorderColor = ColorTween(
      begin: _C.alert,
      end:   _C.silver,
    ).animate(CurvedAnimation(parent: _alertPulseCtrl, curve: Curves.easeInOut));
  }

  // ── Socket setup ───────────────────────────────────────────
  void _connectSocket() async {
    final token = await AuthService().getToken();
    _socket.connect(serverUrl: _Session.serverUrl, token: token);
  }

  void _listenToSocket() {
    _subs.add(_socket.onConnectionChange.listen((connected) {
      if (mounted) setState(() => _isConnected = connected);
    }));

    // Incoming emergency alert
    _subs.add(_socket.onEmergencyAlert.listen((data) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _pendingAlert = data;
        _alertVisible = true;
      });
      _alertPulseCtrl.repeat(reverse: true);
    }));

    // Another lawyer took the case
    _subs.add(_socket.onCaseTaken.listen((data) {
      if (!mounted) return;
      final eventId = data['eventId'];
      if (_pendingAlert?['eventId'] == eventId) {
        _dismissAlert();
        _showSnack('Case already taken by another lawyer.', isError: true);
      }
    }));

    // We won the race — case confirmed
    _subs.add(_socket.onCaseConfirmed.listen((data) {
      if (!mounted) return;
      _dismissAlert();
      setState(() {
        _activeCase = data;
        _caseActive = true;
      });
      HapticFeedback.heavyImpact();
    }));
  }

  // ── Online toggle ──────────────────────────────────────────
  void _toggleOnline(bool value) {
    HapticFeedback.selectionClick();
    setState(() => _isOnline = value);
    // The backend sets is_online via socket connect/disconnect.
    // Emit an explicit event so the server can update MongoDB.
    _socket.emit('lawyer_availability', {'isOnline': value});
  }

  // ── Alert actions ──────────────────────────────────────────
  void _acceptCase() {
    if (_pendingAlert == null) return;
    HapticFeedback.heavyImpact();
    _socket.acceptCase(_pendingAlert!['eventId']);
    // UI update will arrive via onCaseConfirmed stream
  }

  void _declineCase() {
    if (_pendingAlert == null) return;
    _socket.rejectCase(_pendingAlert!['eventId']);
    _dismissAlert();
  }

  void _dismissAlert() {
    _alertPulseCtrl.stop();
    _alertPulseCtrl.reset();
    if (mounted) {
      setState(() {
        _alertVisible = false;
        _pendingAlert = null;
      });
    }
  }

  // ── Deep link ──────────────────────────────────────────────
  Future<void> _openCallLink(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Cannot open call link.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor:
          isError ? _C.decline.withOpacity(0.85) : _C.accept.withOpacity(0.85),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(msg,
          style: const TextStyle(color: _C.white, fontSize: 13)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _alertPulseCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Base screen ────────────────────────────────
            _caseActive ? _buildActiveCaseView() : _buildIdleView(),

            // ── Emergency alert overlay ────────────────────
            if (_alertVisible && _pendingAlert != null)
              _buildEmergencyOverlay(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  IDLE VIEW
  // ══════════════════════════════════════════════════════════
  Widget _buildIdleView() {
    return Column(
      children: [
        _buildTopBar(),
        _buildQuickStats(),
        const Spacer(),
        _buildIdleCenter(),
        const Spacer(),
        _buildRecentCasesPlaceholder(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Quick Stats ───────────────────────────────────────────
  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: _C.consoleBg.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: _C.silver.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'TODAY', value: '0', icon: Icons.calendar_today_rounded),
          _StatItem(label: 'ACTIVE', value: '0', icon: Icons.bolt_rounded, color: _C.accept),
          _StatItem(label: 'RANK', value: 'Pro', icon: Icons.star_border_rounded),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 20),
      color: _C.consoleBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LAWYER CONSOLE',
                style: TextStyle(color: _C.silver.withOpacity(0.5), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: _isConnected ? _C.accept : _C.alert, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(_lawyerName, style: const TextStyle(color: _C.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isOnline ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      color: _isOnline ? _C.accept : _C.silverDim,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _VetoSwitch(value: _isOnline, onChanged: _toggleOnline),
                ],
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => AuthService().logout(context),
                icon: const Icon(Icons.logout_rounded, color: _C.white, size: 18),
                label: const Text('LOGOUT', style: TextStyle(color: _C.white, fontSize: 10, letterSpacing: 1.2)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: _C.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Idle Center ────────────────────────────────────────────
  Widget _buildIdleCenter() {
    return Column(
      children: [
        // Shield icon
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _C.silver.withOpacity(0.2), width: 1.5),
            color: _C.silver.withOpacity(0.05),
          ),
          child: Icon(
            Icons.shield_outlined,
            color: _isOnline ? _C.silver : _C.silverDim.withOpacity(0.4),
            size: 44,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isOnline ? 'Waiting for Emergency' : 'You are Offline',
          style: TextStyle(
            color: _isOnline ? _C.silver : _C.silverDim,
            fontSize: 18,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isOnline
              ? 'You will be alerted instantly\nwhen a client needs help.'
              : 'Toggle Online to start\nreceiving emergency alerts.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _C.silverDim.withOpacity(0.55),
            fontSize: 13,
            height: 1.6,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ── Recent Cases Placeholder ───────────────────────────────
  Widget _buildRecentCasesPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENT CASES',
            style: TextStyle(
              color: _C.silverDim.withOpacity(0.5),
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.silver.withOpacity(0.08)),
            ),
            child: Text(
              'No recent cases.',
              style: TextStyle(
                color: _C.silverDim.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  EMERGENCY ALERT OVERLAY
  // ══════════════════════════════════════════════════════════
  Widget _buildEmergencyOverlay() {
    final alert = _pendingAlert!;
    final userName = alert['userName'] ?? 'Client';
    final language = (alert['language'] ?? 'en').toString().toUpperCase();
    final location = alert['location'] as Map? ?? {};
    final lat = (location['lat'] as num?)?.toStringAsFixed(4) ?? '—';
    final lng = (location['lng'] as num?)?.toStringAsFixed(4) ?? '—';

    return AnimatedBuilder(
      animation: _alertPulseCtrl,
      builder: (context, _) {
        return Container(
          color: _C.bg.withOpacity(0.96),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // ── Pulsing badge ────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _alertBorderColor.value ?? _C.alert,
                        width: _alertBorderWidth.value,
                      ),
                      color: _C.alert.withOpacity(0.08),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: _alertBorderColor.value ?? _C.alert,
                            size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'EMERGENCY REQUEST',
                          style: TextStyle(
                            color: _C.white,
                            fontSize: 11,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Alert card ───────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _C.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _alertBorderColor.value?.withOpacity(0.5)
                            ?? _C.alert.withOpacity(0.5),
                        width: _alertBorderWidth.value * 0.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _C.alert.withOpacity(0.12),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client name
                        _AlertRow(
                          icon: Icons.person_outline,
                          label: 'CLIENT',
                          value: userName,
                          valueStyle: const TextStyle(
                            color: _C.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const _AlertDivider(),

                        // Language
                        _AlertRow(
                          icon: Icons.language_rounded,
                          label: 'LANGUAGE',
                          value: language,
                        ),
                        const _AlertDivider(),

                        // Location
                        _AlertRow(
                          icon: Icons.location_on_outlined,
                          label: 'LOCATION',
                          value: 'Lat $lat  ·  Lng $lng',
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Accept / Decline ─────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _AlertButton(
                          label: 'ACCEPT',
                          icon: Icons.check_rounded,
                          color: _C.accept,
                          onTap: _acceptCase,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _AlertButton(
                          label: 'DECLINE',
                          icon: Icons.close_rounded,
                          color: _C.decline,
                          onTap: _declineCase,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _declineCase,
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                          color: _C.silverDim.withOpacity(0.5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  //  ACTIVE CASE VIEW
  // ══════════════════════════════════════════════════════════
  Widget _buildActiveCaseView() {
    final caseData   = _activeCase ?? {};
    final callLink   = caseData['callLink']  as String?;
    final userCoords = caseData['userLocation'] as List?;
    final lat = userCoords != null ? (userCoords[1] as num).toStringAsFixed(4) : '—';
    final lng = userCoords != null ? (userCoords[0] as num).toStringAsFixed(4) : '—';

    return Column(
      children: [
        _buildActiveCaseHeader(callLink),
        const SizedBox(height: 4),

        // ── Case info card ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.accept.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: _C.accept.withOpacity(0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AlertRow(
                  icon: Icons.person_outline,
                  label: 'CLIENT',
                  value: _pendingAlert?['userName'] ?? 'Client',
                ),
                const _AlertDivider(),
                _AlertRow(
                  icon: Icons.location_on_outlined,
                  label: 'LOCATION',
                  value: 'Lat $lat  ·  Lng $lng',
                ),
                const _AlertDivider(),
                _AlertRow(
                  icon: Icons.language_rounded,
                  label: 'LANGUAGE',
                  value: (_pendingAlert?['language'] ?? 'EN').toString().toUpperCase(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Open call button ───────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _AlertButton(
            label: 'OPEN VIDEO CALL',
            icon: Icons.video_call_rounded,
            color: _C.accept,
            onTap: () => _openCallLink(callLink),
          ),
        ),

        const SizedBox(height: 28),

        // ── Evidence feed ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'LIVE EVIDENCE',
                style: TextStyle(
                  color: _C.silverDim.withOpacity(0.55),
                  fontSize: 10,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.alert,
                  boxShadow: [BoxShadow(color: _C.alert.withOpacity(0.7), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'UPLOADING',
                style: TextStyle(
                  color: _C.alert.withOpacity(0.7),
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: _evidenceItems.isEmpty
              ? _buildEvidenceEmpty()
              : _buildEvidenceList(),
        ),

        // ── End call ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(20),
          child: _AlertButton(
            label: 'COMPLETE CASE',
            icon: Icons.check_circle_outline,
            color: _C.silverDim,
            onTap: _completeCase,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCaseHeader(String? callLink) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.accept,
              boxShadow: [BoxShadow(color: _C.accept.withOpacity(0.7), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'ACTIVE CASE',
            style: TextStyle(
              color: _C.accept,
              fontSize: 12,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_upload_outlined,
              color: _C.silverDim.withOpacity(0.25), size: 36),
          const SizedBox(height: 10),
          Text(
            'Waiting for client to upload evidence...',
            style: TextStyle(
              color: _C.silverDim.withOpacity(0.35),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _evidenceItems.length,
      itemBuilder: (ctx, i) {
        final item = _evidenceItems[i];
        final type = item['type'] ?? 'photo';
        final IconData icon = type == 'video'
            ? Icons.videocam_outlined
            : type == 'audio'
                ? Icons.mic_none_rounded
                : Icons.image_outlined;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _C.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.silver.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Icon(icon, color: _C.silver, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['cloud_url'] ?? '—',
                  style: const TextStyle(color: _C.silverDim, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                item['timestamp'] ?? '',
                style: TextStyle(
                    color: _C.silverDim.withOpacity(0.4), fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  void _completeCase() {
    HapticFeedback.mediumImpact();
    setState(() {
      _caseActive   = false;
      _activeCase   = null;
      _pendingAlert = null;
      _evidenceItems.clear();
    });
    _socket.emit('complete_case', {'eventId': _activeCase?['eventId']});
  }
}

// ══════════════════════════════════════════════════════════════
//  Reusable Widgets
// ══════════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _StatItem({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? _C.silverDim, size: 16),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color ?? _C.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: _C.silverDim, fontSize: 8, letterSpacing: 1.0)),
      ],
    );
  }
}

// ── Custom luxury toggle switch ────────────────────────────
class _VetoSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _VetoSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value
              ? _C.accept.withOpacity(0.25)
              : _C.silverDim.withOpacity(0.15),
          border: Border.all(
            color: value ? _C.accept : _C.silverDim.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? _C.accept : _C.silverDim,
              boxShadow: [
                BoxShadow(
                  color: (value ? _C.accept : _C.silverDim).withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Alert info row ─────────────────────────────────────────
class _AlertRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _AlertRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _C.silverDim, size: 16),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _C.silverDim.withOpacity(0.5),
                fontSize: 9,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: valueStyle ??
                  const TextStyle(
                    color: _C.silver,
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.3,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Subtle divider ─────────────────────────────────────────
class _AlertDivider extends StatelessWidget {
  const _AlertDivider();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        height: 1,
        color: _C.silver.withOpacity(0.07),
      );
}

// ── Action button ──────────────────────────────────────────
class _AlertButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AlertButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.5), width: 1.2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 16),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
