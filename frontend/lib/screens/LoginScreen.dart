// ============================================================
//  LoginScreen.dart — Entry Point
//  VETO Legal Emergency App
//  Flow: Language → Role → Phone → OTP → Route to dashboard
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../services/auth_service.dart';

// ── Brand palette ──────────────────────────────────────────
class _C {
  static const bgTop    = Color(0xFF000D1A); // darker navy
  static const bgBottom = Color(0xFF001F3F); // deep navy
  static const silver   = Color(0xFFC0C2C9);
  static const silverDim= Color(0xFF8A8C93);
  static const white    = Color(0xFFFFFFFF);
  static const accent   = Color(0xFF2ECC71); // success green
  static const error    = Color(0xFFE74C3C);
  static const cardBg   = Color(0xFF012A52);
  static const inputBg  = Color(0xFF01223F);
}

// ── Language model ─────────────────────────────────────────
enum VLang { en, he, ar }

class _LangMeta {
  final VLang       lang;
  final String      code;     // API value
  final String      label;    // display
  final String      flag;     // emoji
  final TextDirection dir;

  const _LangMeta({
    required this.lang,
    required this.code,
    required this.label,
    required this.flag,
    required this.dir,
  });
}

const _langs = [
  _LangMeta(lang: VLang.he, code: 'he', label: 'עברית',  flag: '🇮🇱', dir: TextDirection.rtl),
  _LangMeta(lang: VLang.en, code: 'en', label: 'English', flag: '🇺🇸', dir: TextDirection.ltr),
  _LangMeta(lang: VLang.ar, code: 'ar', label: 'العربية', flag: '🇸🇦', dir: TextDirection.rtl),
];

// ── i18n strings ───────────────────────────────────────────
const _strings = {
  VLang.en: {
    'tagline':        'Your Legal Emergency Shield',
    'chooseLang':     'Choose Language',
    'member':         'Member',
    'lawyer':         'Lawyer',
    'phone':          'Phone Number',
    'phonePlaceholder': '+972 05X XXX XXXX',
    'continue_':      'CONTINUE',
    'otpTitle':       'Enter Verification Code',
    'otpSub':         'A 6-digit code was sent to',
    'verify':         'VERIFY',
    'resend':         'Resend Code',
    'resendIn':       'Resend in',
    'back':           'Back',
    'sending':        'Sending...',
    'verifying':      'Verifying...',
    'timeoutHint':
        'Server took too long (Render free cold start can take 2–3 min). Open /health in a tab, wait, then try again.',
    'notFoundHint':
        'No account for this phone. Register first or check Render logs.',
  },
  VLang.he: {
    'tagline':        'מגן החירום המשפטי שלך',
    'chooseLang':     'בחר שפה',
    'member':         'משתמש',
    'lawyer':         'עורך דין',
    'phone':          'מספר טלפון',
    'phonePlaceholder': '+972 05X XXX XXXX',
    'continue_':      'המשך',
    'otpTitle':       'הזן קוד אימות',
    'otpSub':         'קוד בן 6 ספרות נשלח ל',
    'verify':         'אמת',
    'resend':         'שלח שוב',
    'resendIn':       'שלח שוב בעוד',
    'back':           'חזרה',
    'sending':        'שולח...',
    'verifying':      'מאמת...',
    'timeoutHint':
        'פג הזמן — ב-Render חינמי לפעמים 2–3 דקות עד שהשרת ער. פתח בטאב את …/health, המתן, ואז לחץ שוב המשך.',
    'notFoundHint':
        'אין חשבון למספר הזה, או שהשרת לא ענה. בדוק הרשמה / לוגים ב-Render.',
  },
  VLang.ar: {
    'tagline':        'درعك القانوني في الطوارئ',
    'chooseLang':     'اختر اللغة',
    'member':         'عضو',
    'lawyer':         'محامٍ',
    'phone':          'رقم الهاتف',
    'phonePlaceholder': '+972 05X XXX XXXX',
    'continue_':      'متابعة',
    'otpTitle':       'أدخل رمز التحقق',
    'otpSub':         'تم إرسال رمز مكون من 6 أرقام إلى',
    'verify':         'تحقق',
    'resend':         'إعادة الإرسال',
    'resendIn':       'إعادة الإرسال خلال',
    'back':           'رجوع',
    'sending':        'جارٍ الإرسال...',
    'verifying':      'جارٍ التحقق...',
    'timeoutHint':
        'انتهت المهلة — الخادوم المجاني قد يحتاج 2–3 دقائق. افتح …/health في تاب، انتظر، ثم أعد المحاولة.',
    'notFoundHint':
        'لا يوجد حساب لهذا الرقم أو لم يستجب الخادوم.',
  },
};

// ══════════════════════════════════════════════════════════════
//  LoginScreen
// ══════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ── Step state ─────────────────────────────────────────────
  // 0 = phone entry, 1 = OTP entry
  int _step = 0;

  // ── Selections ─────────────────────────────────────────────
  VLang  _lang = VLang.en;
  String _role = 'user'; // 'user' | 'lawyer'

  // ── Form state ─────────────────────────────────────────────
  final _phoneCtrl = TextEditingController(text: '+972');
  final _formKey   = GlobalKey<FormState>();
  String _otpValue = '';

  // ── Loading / error ────────────────────────────────────────
  bool   _loading   = false;
  String _errorMsg  = '';

  // ── OTP resend countdown ───────────────────────────────────
  int    _countdown  = 60;
  Timer? _countdownTimer;

  // ── Slide transition ───────────────────────────────────────
  late final AnimationController _slideCtrl;
  late Animation<Offset> _slideIn;

  // ── Services ───────────────────────────────────────────────
  final _auth = AuthService();

  // ── Helpers ────────────────────────────────────────────────
  _LangMeta get _langMeta => _langs.firstWhere((l) => l.lang == _lang);
  TextDirection get _dir  => _langMeta.dir;
  String _t(String key)   => _strings[_lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(1, 0),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _checkExistingSession();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _slideCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Session check on startup ───────────────────────────────
  Future<void> _checkExistingSession() async {
    final token = await _auth.getToken();
    final role = await _auth.getStoredRole();
    if (token != null && token.isNotEmpty && mounted) {
      _navigateToDashboard(role ?? 'user');
    }
  }

  void _navigateToDashboard(String role) {
    Navigator.of(context).pushReplacementNamed(
      role == 'lawyer' ? '/lawyer_dashboard' : '/veto_screen',
    );
  }

  // ════════════════════════════════════════════════════════════
  //  ACTIONS
  // ════════════════════════════════════════════════════════════

  void _selectLanguage(VLang lang) {
    HapticFeedback.selectionClick();
    setState(() { _lang = lang; _errorMsg = ''; });
  }

  void _selectRole(String role) {
    HapticFeedback.selectionClick();
    setState(() { _role = role; _errorMsg = ''; });
  }

  // ── Step 1: Request OTP ────────────────────────────────────
  Future<void> _requestOTP() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _phoneCtrl.text.trim();

    setState(() { _loading = true; _errorMsg = ''; });

    try {
      final outcome = await _auth.requestOTPDetailed(phone, _role);
      if (!mounted) return;

      if (outcome == OtpRequestOutcome.success) {
        setState(() {
          _loading = false;
          _step = 1;
          _countdown = 60;
        });
        _slideCtrl.forward(from: 0);
        _startCountdown();
      } else if (outcome == OtpRequestOutcome.timeout) {
        setState(() {
          _loading = false;
          _errorMsg = _t('timeoutHint');
        });
      } else {
        setState(() {
          _loading = false;
          _errorMsg = _t('notFoundHint');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = _t('notFoundHint');
        });
      }
    }
  }

  // ── Step 2: Verify OTP ─────────────────────────────────────
  Future<void> _verifyOTP() async {
    if (_otpValue.length < 6) return;

    setState(() { _loading = true; _errorMsg = ''; });

    try {
      final data = await _auth.verifyOTP(
        _phoneCtrl.text.trim(),
        _otpValue,
      );

      if (!mounted) return;

      if (data != null) {
        HapticFeedback.heavyImpact();
        final user = data['user'];
        final role = user is Map<String, dynamic>
            ? (user['role']?.toString() ?? _role)
            : _role;
        _navigateToDashboard(role);
      } else {
        setState(() {
          _loading = false;
          _errorMsg = 'Invalid OTP.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Invalid OTP.';
        });
      }
    }
  }

  void _goBackToPhone() {
    _slideCtrl.reverse();
    setState(() {
      _step = 0;
      _otpValue = '';
      _errorMsg = '';
    });
    _countdownTimer?.cancel();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) { t.cancel(); return; }
      if (mounted) setState(() => _countdown--);
    });
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _dir,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [_C.bgTop, _C.bgBottom],
              stops:  [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ── Language selector (always visible) ────
                  _buildLanguageSelector(),
                  const SizedBox(height: 48),

                  // ── Logo ──────────────────────────────────
                  _buildLogo(),
                  const SizedBox(height: 36),

                  // ── Role toggle ───────────────────────────
                  if (_step == 0) ...[
                    _buildRoleToggle(),
                    const SizedBox(height: 32),
                  ],

                  // ── Phone / OTP form ──────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end:   Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _step == 0
                        ? _buildPhoneStep()
                        : _buildOTPStep(),
                  ),

                  // ── Error message ─────────────────────────
                  if (_errorMsg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _ErrorBadge(message: _errorMsg),
                    ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  LANGUAGE SELECTOR
  // ══════════════════════════════════════════════════════════
  Widget _buildLanguageSelector() {
    return Column(
      children: [
        Text(
          _t('chooseLang'),
          style: TextStyle(
            color:       _C.silverDim.withOpacity(0.5),
            fontSize:    10,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _langs.map((l) {
            final selected = l.lang == _lang;
            return GestureDetector(
              onTap: () => _selectLanguage(l.lang),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: selected
                      ? _C.silver.withOpacity(0.12)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? _C.silver.withOpacity(0.6)
                        : _C.silver.withOpacity(0.15),
                    width: selected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      l.label,
                      style: TextStyle(
                        color: selected ? _C.white : _C.silverDim,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w500
                            : FontWeight.w300,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  LOGO
  // ══════════════════════════════════════════════════════════
  Widget _buildLogo() {
    return Column(
      children: [
        // Shield
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _C.silver.withOpacity(0.12),
                _C.silver.withOpacity(0.03),
              ],
            ),
            border: Border.all(
                color: _C.silver.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color:      _C.silver.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.shield_outlined,
                color: _C.silver, size: 44),
          ),
        ),
        const SizedBox(height: 16),
        // VETO wordmark
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: [_C.white, _C.silver],
          ).createShader(bounds),
          child: const Text(
            'VETO',
            style: TextStyle(
              color:       Colors.white,
              fontSize:    42,
              fontWeight:  FontWeight.w200,
              letterSpacing: 14,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t('tagline'),
          style: TextStyle(
            color:       _C.silver.withOpacity(0.4),
            fontSize:    11,
            letterSpacing: 1.8,
            fontStyle:   FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  ROLE TOGGLE
  // ══════════════════════════════════════════════════════════
  Widget _buildRoleToggle() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        color: _C.cardBg,
        border: Border.all(color: _C.silver.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          _RoleTab(
            label:    _t('member'),
            icon:     Icons.person_outline,
            selected: _role == 'user',
            onTap:    () => _selectRole('user'),
          ),
          _RoleTab(
            label:    _t('lawyer'),
            icon:     Icons.balance_outlined,
            selected: _role == 'lawyer',
            onTap:    () => _selectRole('lawyer'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 1 — PHONE
  // ══════════════════════════════════════════════════════════
  Widget _buildPhoneStep() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('phone'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('phone'),
            style: const TextStyle(
              color:       _C.silverDim,
              fontSize:    11,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),

          // Phone input
          TextFormField(
            controller:    _phoneCtrl,
            keyboardType:  TextInputType.phone,
            style: const TextStyle(
              color:       _C.white,
              fontSize:    18,
              letterSpacing: 1.2,
              fontWeight:  FontWeight.w300,
            ),
            textDirection: TextDirection.ltr, // phone always LTR
            decoration: InputDecoration(
              hintText:      _t('phonePlaceholder'),
              hintStyle: TextStyle(
                color:       _C.silverDim.withOpacity(0.35),
                fontSize:    15,
                letterSpacing: 0.8,
              ),
              filled:      true,
              fillColor:   _C.inputBg,
              prefixIcon:  const Icon(Icons.phone_outlined,
                  color: _C.silverDim, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:  BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:  const BorderSide(
                    color: _C.silver, width: 1.2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:  const BorderSide(
                    color: _C.error, width: 1.2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 18),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 8) {
                return 'Please enter a valid phone number.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Continue button
          _VetoButton(
            label:     _loading ? _t('sending') : _t('continue_'),
            loading:   _loading,
            onTap:     _loading ? null : _requestOTP,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 2 — OTP
  // ══════════════════════════════════════════════════════════
  Widget _buildOTPStep() {
    // Pinput theme
    final defaultPinTheme = PinTheme(
      width:  52,
      height: 58,
      textStyle: const TextStyle(
        fontSize:   22,
        color:      _C.white,
        fontWeight: FontWeight.w300,
        letterSpacing: 2,
      ),
      decoration: BoxDecoration(
        color:        _C.inputBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: _C.silver.withOpacity(0.2)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: _C.silver, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: _C.accent.withOpacity(0.6)),
      color:  _C.accent.withOpacity(0.07),
    );

    return Column(
      key: const ValueKey('otp'),
      children: [
        // Back
        Align(
          alignment: _dir == TextDirection.rtl
              ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onTap: _loading ? null : _goBackToPhone,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _dir == TextDirection.rtl
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  color: _C.silverDim, size: 14,
                ),
                const SizedBox(width: 4),
                Text(_t('back'),
                    style: const TextStyle(
                        color: _C.silverDim, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          _t('otpTitle'),
          style: const TextStyle(
            color:       _C.white,
            fontSize:    20,
            fontWeight:  FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_t('otpSub')} ${_phoneCtrl.text.trim()}',
          style: TextStyle(
            color:    _C.silverDim.withOpacity(0.6),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        // Pinput (OTP always LTR — wrap; pinput 5.x has no textDirection param)
        Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
          length:           6,
          defaultPinTheme:  defaultPinTheme,
          focusedPinTheme:  focusedPinTheme,
          submittedPinTheme:submittedPinTheme,
          autofocus:        true,
          hapticFeedbackType: HapticFeedbackType.lightImpact,
          onCompleted: (pin) {
            setState(() => _otpValue = pin);
            _verifyOTP();
          },
          onChanged: (pin) => setState(() => _otpValue = pin),
        ),
        ),
        const SizedBox(height: 32),

        // Verify button
        _VetoButton(
          label:   _loading ? _t('verifying') : _t('verify'),
          loading: _loading,
          onTap:   (_loading || _otpValue.length < 6) ? null : _verifyOTP,
        ),
        const SizedBox(height: 20),

        // Resend
        _countdown > 0
            ? Text(
                '${_t('resendIn')} $_countdown s',
                style: TextStyle(
                  color:    _C.silverDim.withOpacity(0.4),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              )
            : GestureDetector(
                onTap: () {
                  setState(() => _countdown = 60);
                  _startCountdown();
                  _auth.requestOTP(_phoneCtrl.text.trim(), _role);
                },
                child: Text(
                  _t('resend'),
                  style: const TextStyle(
                    color:          _C.silver,
                    fontSize:       13,
                    letterSpacing:  0.5,
                    decoration:     TextDecoration.underline,
                    decorationColor: _C.silver,
                  ),
                ),
              ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Reusable Sub-widgets
// ══════════════════════════════════════════════════════════════

// ── Role tab ───────────────────────────────────────────────
class _RoleTab extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final bool       selected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? _C.silver.withOpacity(0.13)
                : Colors.transparent,
            border: selected
                ? Border.all(color: _C.silver.withOpacity(0.35))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: selected ? _C.white : _C.silverDim,
                    size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color:      selected ? _C.white : _C.silverDim,
                    fontSize:   13,
                    fontWeight: selected
                        ? FontWeight.w500
                        : FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Primary action button ──────────────────────────────────
class _VetoButton extends StatelessWidget {
  final String       label;
  final bool         loading;
  final VoidCallback? onTap;

  const _VetoButton({
    required this.label,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = onTap == null || loading;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width:   double.infinity,
        height:  54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: locked
              ? _C.silver.withOpacity(0.06)
              : _C.silver.withOpacity(0.13),
          border: Border.all(
            color: locked
                ? _C.silverDim.withOpacity(0.2)
                : _C.silver.withOpacity(0.5),
            width: 1.2,
          ),
          boxShadow: locked
              ? []
              : [
                  BoxShadow(
                    color:      _C.silver.withOpacity(0.12),
                    blurRadius: 20,
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color:       _C.silver,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color:       locked ? _C.silverDim : _C.white,
                    fontSize:    13,
                    letterSpacing: 2.5,
                    fontWeight:  FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Error badge ────────────────────────────────────────────
class _ErrorBadge extends StatelessWidget {
  final String message;
  const _ErrorBadge({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        _C.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: _C.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: _C.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _C.error, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
