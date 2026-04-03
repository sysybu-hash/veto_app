import os

content = '''import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import 'EvidenceScreen.dart';
import 'package:geolocator/geolocator.dart';

class VetoColors {
  static const Color background = Color(0xFF001F3F);
  static const Color silver     = Color(0xFFC0C2C9);
  static const Color silverDim  = Color(0xFF8A8C93);
  static const Color white      = Color(0xFFFFFFFF);
  static const Color safe       = Color(0xFF2ECC71);
  static const Color searchPulse= Color(0xFFC0C2C9);
  static const Color overlay    = Color(0x22C0C2C9);
}

enum VetoLanguage { en, he, ar }

class VetoL10n {
  static const Map<VetoLanguage, Map<String, String>> _data = {
    VetoLanguage.en: {
      'label':      'EN',
      'statusSafe': 'Status: Secure',
      'statusSearch':'Status: Searching for Lawyer...',
      'veto':       'VETO',
      'hint':       'Press & Hold to Activate',
      'camera':     'Evidence',
      'mic':        'Record',
      'tagline':    'Your Legal Emergency Shield',
    },
    VetoLanguage.he: {
      'label':      'עב',
      'statusSafe': 'סטטוס: מוגן',
      'statusSearch':'סטטוס: מחפש עורך דין זמין...',
      'veto':       'VETO',
      'hint':       'לחץ והחזק להפעלה',
      'camera':     'תיעוד אירוע',
      'mic':        'הקלטה',
      'tagline':    'המגן המשפטי שלך בשעת חירום',
    },
    VetoLanguage.ar: {
      'label':      '??',
      'statusSafe': '??????: ???',
      'statusSearch':'??????: ???? ????? ?? ????...',
      'veto':       'VETO',
      'hint':       '???? ?? ????????? ???????',
      'camera':     '????',
      'mic':        '?????',
      'tagline':    '???? ???????? ?? ????? ???????',
    },
  };

  static String get(VetoLanguage lang, String key) =>
      _data[lang]?[key] ?? '';

  static TextDirection directionOf(VetoLanguage lang) =>
      (lang == VetoLanguage.en) ? TextDirection.ltr : TextDirection.rtl;
}

class VetoScreen extends StatefulWidget {
  const VetoScreen({super.key});

  @override
  State<VetoScreen> createState() => _VetoScreenState();
}

class _VetoScreenState extends State<VetoScreen>
    with TickerProviderStateMixin {
  VetoLanguage _lang = VetoLanguage.he;
  String _role = '';
  bool _isSearching    = false;
  StreamSubscription? _emergencyCreatedSub;

  late final AnimationController _pulseCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _statusCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _idleCtrl;

  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;
  late Animation<double> _glowRadius;

  Timer? _searchTimer;

  Future<void> _fetchRole() async {
    final r = await AuthService().getStoredRole();
    if (mounted) {
      setState(() {
        _role = r ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRole();
    _buildAnimations();
    _idleCtrl.repeat(reverse: true);

    _emergencyCreatedSub = SocketService().onEmergencyCreated.listen((data) async {
      final eventId = data['eventId'];
      if (eventId != null) {
        debugPrint('VetoScreen: Emergency created successfully, eventId=\. Navigating to EvidenceScreen.');
        final token = await AuthService().getToken();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EvidenceScreen(
              eventId: eventId,
              token: token ?? '',
              language: _lang == VetoLanguage.he ? EvidenceLanguage.he : (_lang == VetoLanguage.ar ? EvidenceLanguage.ar : EvidenceLanguage.en),
            ),
          ),
        );
      }
    });

    SocketService().onEmergencyAlert.listen((data) {
      debugPrint('VetoScreen: Another user created an emergency? \');
    });

    try {
      SocketService().onCaseAccepted.listen((data) {
        debugPrint('VetoScreen: Lawyer accepted the case! \');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('עורך דין קיבל את הקריאה!'),
              backgroundColor: VetoColors.safe,
            ),
          );
          setState(() {
            _isSearching = false;
          });
        }
      });
    } catch(e) {}

  }

  void _buildAnimations() {
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOutQuad),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOutQuad),
    );

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _ringScale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutQuad),
    );
    _ringOpacity = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutQuad),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _glowRadius = Tween<double>(begin: 10.0, end: 24.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _statusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
  }

  @override
  void dispose() {
    _emergencyCreatedSub?.cancel();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _statusCtrl.dispose();
    _ringCtrl.dispose();
    _idleCtrl.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  TextDirection get _dir => VetoL10n.directionOf(_lang);
  String _t(String key) => VetoL10n.get(_lang, key);

  void _onPressStart() {
    if (_isSearching) return;
    HapticFeedback.heavyImpact();
    _glowCtrl.forward();
  }

  void _onPressEnd() {
    if (_isSearching) return;
    _glowCtrl.reverse();
  }

  void _triggerEmergency() async {
    if (_isSearching) return;

    HapticFeedback.vibrate();
    setState(() {
      _isSearching = true;
    });

    _idleCtrl.stop();
    _pulseCtrl.repeat();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _isSearching) _ringCtrl.repeat();
    });
    _statusCtrl.forward();

    Position? currentPos;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        currentPos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      }
    } catch (e) {
      debugPrint("Error getting location: \");
    }

    final Map<String, dynamic> locationData = currentPos != null
        ? {'lat': currentPos.latitude, 'lng': currentPos.longitude}
        : {'lat': 32.0853, 'lng': 34.7818}; // Default to Tel Aviv

    debugPrint('VetoScreen: Emitting start_veto with location: \');
    SocketService().emit('start_veto', {
      'location': locationData,
      'details': 'Emergency triggered via VETO button',
    });

    _searchTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isSearching) {
        setState(() {
          _isSearching = false;
        });
        _pulseCtrl.stop();
        _ringCtrl.stop();
        _statusCtrl.reverse();
        _idleCtrl.repeat(reverse: true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('לא נמצא עורך דין זמין כרגע. אנא נסה שוב או פנה למוקד.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _dir,
      child: Scaffold(
        backgroundColor: VetoColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildStatusBar(),
              const Spacer(flex: 2),
              _buildTagline(),
              const SizedBox(height: 28),
              _buildVetoButton(),
              const SizedBox(height: 16),
              _buildHintText(),
              const Spacer(flex: 3),
              _buildBottomActions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.person_outline, color: VetoColors.white, size: 24),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              const SizedBox(width: 8),
              if (_role == 'admin')
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: VetoColors.white, size: 24),
                  onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
                ),
              if (_role == 'admin') const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => AuthService().logout(context),
                icon: const Icon(Icons.logout_rounded, color: VetoColors.white, size: 20),
                label: const Text('LOGOUT', style: TextStyle(color: VetoColors.white, fontSize: 10, letterSpacing: 1.2)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: VetoColors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          _LanguageSwitcher(
            currentLang: _lang,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _lang = VetoLanguage.values[
                    (_lang.index + 1) % VetoLanguage.values.length];
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: _isSearching
          ? VetoColors.searchPulse.withOpacity(0.1)
          : VetoColors.safe.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.wifi_tethering : Icons.check_circle_outline,
            color: _isSearching ? VetoColors.searchPulse : VetoColors.safe,
            size: 16,
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isSearching ? _t('statusSearch') : _t('statusSafe'),
              key: ValueKey<bool>(_isSearching),
              style: TextStyle(
                color: _isSearching ? VetoColors.searchPulse : VetoColors.safe,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isSearching) ...[
            const SizedBox(width: 8),
            const _SearchingDots(),
          ]
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      _t('tagline'),
      style: TextStyle(
        color: VetoColors.silver.withOpacity(0.6),
        fontSize: 13,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget _buildVetoButton() {
    return GestureDetector(
      onTapDown: (_) => _onPressStart(),
      onTapUp: (_) => _onPressEnd(),
      onTapCancel: _onPressEnd,
      onLongPress: _triggerEmergency,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isSearching)
            AnimatedBuilder(
              animation: _ringCtrl,
              builder: (ctx, child) {
                return Transform.scale(
                  scale: _ringScale.value,
                  child: Opacity(
                    opacity: _ringOpacity.value,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: VetoColors.searchPulse, width: 1.5),
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_isSearching)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (ctx, child) {
                return Transform.scale(
                  scale: _pulseScale.value,
                  child: Opacity(
                    opacity: _pulseOpacity.value,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: VetoColors.overlay,
                      ),
                    ),
                  ),
                );
              },
            ),
          if (!_isSearching)
            AnimatedBuilder(
              animation: _idleCtrl,
              builder: (ctx, child) {
                final scale = 1.0 + (_idleCtrl.value * 0.04);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: VetoColors.silver.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (ctx, child) {
              return _VetoCoreButton(
                isActive: _isSearching,
                glowRadius: _glowRadius.value,
                label: _t('veto'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHintText() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _isSearching ? 0.0 : 0.4,
      child: Text(
        _t('hint'),
        style: const TextStyle(
          color: VetoColors.silver,
          fontSize: 11,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionIcon(
            icon: Icons.camera_alt_outlined,
            label: _t('camera'),
            onTap: () {
              debugPrint("Camera tapped");
            },
          ),
          _ActionIcon(
            icon: Icons.mic_none_rounded,
            label: _t('mic'),
            onTap: () {
              debugPrint("Mic tapped");
            },
          ),
        ],
      ),
    );
  }
}

class _VetoCoreButton extends StatelessWidget {
  final bool isActive;
  final double glowRadius;
  final String label;

  const _VetoCoreButton({
    required this.isActive,
    required this.glowRadius,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 200.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VetoColors.background,
        border: Border.all(
          color: isActive ? VetoColors.white : VetoColors.silver,
          width: isActive ? 2.5 : 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: VetoColors.silver.withOpacity(isActive ? 0.55 : 0.18),
            blurRadius: isActive ? glowRadius + 12 : 16,
            spreadRadius: isActive ? 4 : 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: VetoColors.silver.withOpacity(isActive ? 0.22 : 0.07),
            blurRadius: glowRadius,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? VetoColors.white : VetoColors.silver,
            fontSize: 42,
            letterSpacing: 8.0,
            fontWeight: FontWeight.w200,
            shadows: isActive
                ? [
                    const BoxShadow(
                        color: VetoColors.white, blurRadius: 12)
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _SearchingDots extends StatefulWidget {
  const _SearchingDots();

  @override
  State<_SearchingDots> createState() => _SearchingDotsState();
}

class _SearchingDotsState extends State<_SearchingDots> {
  int _dot = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (mounted) {
        setState(() {
          _dot = (_dot + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final bool lit = i <= _dot;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lit
                ? VetoColors.silver
                : VetoColors.silver.withOpacity(0.2),
          ),
        );
      }),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  final VetoLanguage currentLang;
  final VoidCallback onTap;

  const _LanguageSwitcher(
      {required this.currentLang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VetoColors.silver.withOpacity(0.35)),
          color: VetoColors.silver.withOpacity(0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              VetoL10n.get(currentLang, 'label'),
              style: const TextStyle(
                color: VetoColors.silver,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.language_rounded,
                color: VetoColors.silverDim, size: 14),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VetoColors.silver.withOpacity(0.07),
              border:
                  Border.all(color: VetoColors.silver.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: VetoColors.silver.withOpacity(0.08),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon,
                color: VetoColors.silver.withOpacity(0.75), size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: VetoColors.silver.withOpacity(0.5),
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
'''
with open(r'C:\Users\User\Desktop\VETO_App\frontend\lib\screens\VetoScreen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
