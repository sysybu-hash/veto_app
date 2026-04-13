// ============================================================
//  VetoScreen.dart — Main VETO Emergency Screen
//  New design: Luxury, Dark Navy, WebRTC calls
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/ai_service.dart';

// ── VETO States ───────────────────────────────────────────
enum VetoState { idle, analyzing, searching, lawyerFound, calling, error }

class VetoScreen extends StatefulWidget {
  const VetoScreen({super.key});
  @override
  State<VetoScreen> createState() => _VetoScreenState();
}

class _VetoScreenState extends State<VetoScreen>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────
  VetoState _vetoState = VetoState.idle;
  String?   _eventId;
  String?   _roomId;
  String    _statusMsg  = '';
  String?   _lawyerName;
  String    _selectedCallType = 'video'; // 'video' | 'audio'
  Map<String, dynamic>? _userProfile;
  bool _isSubscribed = false;

  // ── AI ────────────────────────────────────────────────────
  String _aiQuestion = '';
  String _aiAnswer   = '';
  bool   _aiLoading  = false;
  final TextEditingController _aiCtrl = TextEditingController();

  // ── Location ──────────────────────────────────────────────
  double? _lat, _lng;

  // ── Socket ────────────────────────────────────────────────
  late SocketService _socket;
  bool _socketListening = false;

  // ── Animations ────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _glowCtrl;
  late Animation<double>   _glowAnim;
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;
  late AnimationController _scaleCtrl;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();

    // Pulse animation (idle state)
    _pulseCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Glow animation
    _glowCtrl = AnimationController(duration: const Duration(seconds: 3), vsync: this)
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Shake animation (on press)
    _shakeCtrl = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    // Scale animation (on press)
    _scaleCtrl = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );

    _loadProfile();
    _getLocation();
  }

  Future<void> _loadProfile() async {
    try {
      final auth    = AuthService();
      final profile = await auth.fetchProfile();
      if (mounted) {
        setState(() {
          _userProfile  = profile;
          _isSubscribed = profile?['is_subscribed'] == true ||
              profile?['subscription_tier'] == 'premium';
        });
      }
    } catch (_) {}
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() { _lat = pos.latitude; _lng = pos.longitude; });
    } catch (_) {}
  }

  void _registerSocketListeners() {
    if (_socketListening) return;
    _socketListening = true;

    // Emergency created
    _socket.on('emergency_created', (data) {
      if (mounted) {
        setState(() {
          _eventId   = data['eventId'];
          _statusMsg = 'מחפש עורך דין זמין...';
          _vetoState = VetoState.searching;
        });
      }
    });

    // Dispatched
    _socket.on('veto_dispatched', (data) {
      if (mounted) {
        final count = data['lawyersNotified'] ?? 0;
        setState(() => _statusMsg = 'נשלח ל-$count עורכי דין');
      }
    });

    // Lawyer found — navigate to call
    _socket.on('lawyer_found', (data) {
      if (mounted) {
        setState(() {
          _vetoState  = VetoState.lawyerFound;
          _lawyerName = data['lawyerName'];
          _roomId     = data['roomId'];
          _statusMsg  = 'עורך דין נמצא!';
        });
        HapticFeedback.heavyImpact();
        // Auto-navigate to call after 2 seconds
        Future.delayed(const Duration(seconds: 2), _navigateToCall);
      }
    });

    // No lawyers
    _socket.on('no_lawyers_available', (data) {
      if (mounted) {
        setState(() {
          _vetoState = VetoState.error;
          _statusMsg = 'אין עורכי דין זמינים כעת. נסה שוב.';
        });
        Future.delayed(const Duration(seconds: 3), _resetToIdle);
      }
    });

    // Error
    _socket.on('veto_error', (data) {
      if (mounted) {
        setState(() {
          _vetoState = VetoState.error;
          _statusMsg = data['message'] ?? 'שגיאה. אנא נסה שוב.';
        });
        Future.delayed(const Duration(seconds: 3), _resetToIdle);
      }
    });
  }

  // ── VETO button pressed ───────────────────────────────────
  Future<void> _onVetoPressed() async {
    if (_vetoState != VetoState.idle) return;

    debugPrint('VetoScreen: VETO button pressed.');
    // Haptic + animation
    HapticFeedback.heavyImpact();
    await _scaleCtrl.forward();
    await _scaleCtrl.reverse();

    setState(() {
      _vetoState = VetoState.analyzing;
      _statusMsg = 'מנתח את המצב שלך...';
    });

    // Ensure location
    if (_lat == null) await _getLocation();

    // Connect socket and register listeners
    _socket = context.read<SocketService>();
    if (!_socket.isConnected) await _socket.connect();
    _registerSocketListeners();

    final lang = context.read<AppLanguageController>().locale.languageCode;

    // Emit start_veto
    _socket.emit('start_veto', {
      'location':          {'lat': _lat ?? 32.0853, 'lng': _lng ?? 34.7818},
      'preferredLanguage': lang,
    });

    setState(() => _vetoState = VetoState.searching);
  }

  void _navigateToCall() {
    if (_roomId == null || !mounted) return;
    Navigator.of(context).pushNamed('/call', arguments: {
      'roomId':    _roomId,
      'callType':  _selectedCallType,
      'peerName':  _lawyerName ?? 'עורך דין',
      'role':      'user',
    });
    _resetToIdle();
  }

  void _resetToIdle() {
    if (mounted) setState(() {
      _vetoState  = VetoState.idle;
      _statusMsg  = '';
      _eventId    = null;
      _roomId     = null;
      _lawyerName = null;
    });
  }

  Future<void> _cancelVeto() async {
    if (_eventId != null) {
      _socket.emit('cancel_veto', {'eventId': _eventId});
    }
    _resetToIdle();
  }

  // ── AI question ───────────────────────────────────────────
  Future<void> _askAI() async {
    final q = _aiCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _aiLoading = true; _aiAnswer = ''; _aiQuestion = q; });
    try {
      final ai   = AiService();
      final lang = context.read<AppLanguageController>().locale.languageCode;
      final res  = await ai.chat(message: q, history: const [], lang: lang);
      if (mounted) setState(() { _aiAnswer = res['reply'] ?? res['answer'] ?? ''; _aiLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _aiLoading = false; _aiAnswer = 'שגיאה. נסה שוב.'; });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _shakeCtrl.dispose();
    _scaleCtrl.dispose();
    _aiCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VetoColors.background,
      body: Container(
        decoration: VetoDecorations.gradientBg(),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _buildStatusSection(),
                      const SizedBox(height: 48),
                      _buildVetoButton(),
                      const SizedBox(height: 24),
                      _buildCallTypeSelector(),
                      const SizedBox(height: 48),
                      _buildSubscriptionBanner(),
                      const SizedBox(height: 32),
                      _buildAiSection(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
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
    final name = _userProfile?['full_name']?.toString().split(' ').first ?? 'שלום';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Logo
          RichText(
            text: const TextSpan(
              style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.w800),
              children: [
                TextSpan(text: 'VE', style: TextStyle(color: VetoColors.white)),
                TextSpan(text: 'TO', style: TextStyle(color: VetoColors.vetoRed)),
              ],
            ),
          ),
          const Spacer(),

          // Greeting
          Text(
            'שלום, $name',
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 14,
              color: VetoColors.silver,
            ),
          ),
          const SizedBox(width: 12),

          // Menu
          IconButton(
            icon: const Icon(Icons.more_vert, color: VetoColors.silver),
            onPressed: _showMenu,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Status section
  // ─────────────────────────────────────────────────────────
  Widget _buildStatusSection() {
    if (_vetoState == VetoState.idle) {
      return Column(
        children: [
          const Text(
            'מצב חירום משפטי?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: VetoColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'לחץ על VETO לקבלת עורך דין מיידית',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 15,
              color: VetoColors.silver,
            ),
          ),
        ],
      );
    }

    if (_vetoState == VetoState.lawyerFound) {
      return _buildLawyerFoundCard();
    }

    return Column(
      children: [
        Text(
          _getStateTitle(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Heebo',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: VetoColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _statusMsg,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Heebo',
            fontSize: 14,
            color: _vetoState == VetoState.error ? VetoColors.error : VetoColors.silver,
          ),
        ),
      ],
    );
  }

  String _getStateTitle() {
    switch (_vetoState) {
      case VetoState.analyzing:  return 'מנתח...';
      case VetoState.searching:  return 'מחפש עורך דין';
      case VetoState.lawyerFound: return 'עורך דין נמצא! ✓';
      case VetoState.calling:    return 'בשיחה';
      case VetoState.error:      return 'לא נמצאו עורכי דין';
      default: return '';
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Lawyer found card
  // ─────────────────────────────────────────────────────────
  Widget _buildLawyerFoundCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [VetoColors.success.withOpacity(0.15), VetoColors.accentGlow.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VetoColors.success.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [VetoColors.accent, VetoColors.accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: VetoDecorations.accentGlow(),
            ),
            child: Center(
              child: Text(
                (_lawyerName?.isNotEmpty == true) ? _lawyerName![0].toUpperCase() : 'ע',
                style: const TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: VetoColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _lawyerName ?? 'עורך דין',
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: VetoColors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'מתחבר לשיחה...',
            style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: VetoColors.success),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  VETO button
  // ─────────────────────────────────────────────────────────
  Widget _buildVetoButton() {
    final isIdle = _vetoState == VetoState.idle;
    final isActive = _vetoState == VetoState.searching || _vetoState == VetoState.analyzing;

    return Column(
      children: [
        // Outer glow ring
        AnimatedBuilder(
          animation: Listenable.merge([_glowAnim, _pulseAnim, _scaleAnim]),
          builder: (context, child) {
            return Transform.scale(
              scale: isIdle ? _pulseAnim.value * _scaleAnim.value : _scaleAnim.value,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: VetoColors.vetoRed.withOpacity(_glowAnim.value * 0.5),
                            blurRadius: 60 * _glowAnim.value,
                            spreadRadius: 10 * _glowAnim.value,
                          ),
                        ]
                      : isIdle
                          ? VetoDecorations.vetoGlow(intensity: _glowAnim.value)
                          : [],
                ),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: isIdle ? _onVetoPressed : null,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _vetoState == VetoState.error
                      ? [const Color(0xFF555555), const Color(0xFF333333)]
                      : isActive
                          ? [const Color(0xFFCC0000), const Color(0xFF880000)]
                          : [VetoColors.vetoRed, VetoColors.vetoRedDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: VetoColors.vetoRed.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isActive)
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: VetoColors.white,
                        strokeWidth: 3,
                      ),
                    )
                  else
                    const Text(
                      'VETO',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: VetoColors.white,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? _statusMsg : 'לחץ לעזרה מיידית',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Cancel button (when active)
        if (isActive) ...[
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _cancelVeto,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('ביטול'),
            style: TextButton.styleFrom(foregroundColor: VetoColors.silver),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Call type selector
  // ─────────────────────────────────────────────────────────
  Widget _buildCallTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: VetoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetoColors.border),
      ),
      child: Row(
        children: [
          _buildCallTypeBtn(
            type: 'video',
            icon: Icons.videocam_outlined,
            label: 'שיחת וידאו',
          ),
          _buildCallTypeBtn(
            type: 'audio',
            icon: Icons.mic_none,
            label: 'שיחת קול',
          ),
        ],
      ),
    );
  }

  Widget _buildCallTypeBtn({required String type, required IconData icon, required String label}) {
    final selected = _selectedCallType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCallType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? VetoColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? VetoColors.white : VetoColors.silver),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? VetoColors.white : VetoColors.silver,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Subscription banner
  // ─────────────────────────────────────────────────────────
  Widget _buildSubscriptionBanner() {
    if (_isSubscribed) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VetoColors.accent.withOpacity(0.15),
            VetoColors.accentDark.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetoColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: VetoColors.warning, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'שדרג לפרמיום',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w700, color: VetoColors.white),
                ),
                const Text(
                  'גישה בלתי מוגבלת לעורכי דין',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: VetoColors.silver),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            style: TextButton.styleFrom(
              backgroundColor: VetoColors.accent,
              foregroundColor: VetoColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('שדרג', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  AI section
  // ─────────────────────────────────────────────────────────
  Widget _buildAiSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: VetoDecorations.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_outlined, color: VetoColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'שאל את ה-AI המשפטי',
                style: TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w600, color: VetoColors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aiCtrl,
                  style: const TextStyle(fontFamily: 'Heebo', color: VetoColors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'מה הזכויות שלי ב...?',
                    hintStyle: const TextStyle(fontFamily: 'Heebo', color: VetoColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: VetoColors.surfaceHigh,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: VetoColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: VetoColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: VetoColors.accent),
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _askAI(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _askAI,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [VetoColors.accent, VetoColors.accentDark],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _aiLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          if (_aiAnswer.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VetoColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VetoColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: VetoColors.accent, size: 14),
                      SizedBox(width: 6),
                      Text('תשובה', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600, color: VetoColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _aiAnswer,
                    style: const TextStyle(fontFamily: 'Heebo', fontSize: 13, color: VetoColors.silverLight, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Quick actions
  // ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.folder_outlined,        'label': 'כספת מסמכים', 'route': '/files_vault'},
      {'icon': Icons.chat_bubble_outline,    'label': 'צ\'אט',        'route': '/chat'},
      {'icon': Icons.settings_outlined,      'label': 'הגדרות',       'route': '/settings'},
      {'icon': Icons.person_outline,         'label': 'פרופיל',       'route': '/profile'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'כלים נוספים',
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
          children: actions.map((a) => _buildActionTile(a)).toList(),
        ),
      ],
    );
  }

  Widget _buildActionTile(Map a) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, a['route'] as String),
      child: Container(
        decoration: VetoDecorations.surfaceCard(radius: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(a['icon'] as IconData, color: VetoColors.accent, size: 24),
            const SizedBox(height: 6),
            Text(
              a['label'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Heebo', fontSize: 11, color: VetoColors.silver),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Menu
  // ─────────────────────────────────────────────────────────
  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VetoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: VetoColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          _menuItem(Icons.person_outline,    'פרופיל',         '/profile'),
          _menuItem(Icons.settings_outlined, 'הגדרות',         '/settings'),
          _menuItem(Icons.folder_outlined,   'כספת מסמכים',    '/files_vault'),
          _menuItem(Icons.chat_outlined,     'צ\'אט',           '/chat'),
          const Divider(color: VetoColors.divider),
          ListTile(
            leading: const Icon(Icons.logout, color: VetoColors.error),
            title: const Text('התנתקות', style: TextStyle(fontFamily: 'Heebo', color: VetoColors.error)),
            onTap: () async {
              Navigator.pop(ctx);
              await AuthService().logout(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, String route) => ListTile(
    leading: Icon(icon, color: VetoColors.silver),
    title: Text(label, style: const TextStyle(fontFamily: 'Heebo', color: VetoColors.white)),
    onTap: () { Navigator.pop(context); Navigator.pushNamed(context, route); },
  );
}
