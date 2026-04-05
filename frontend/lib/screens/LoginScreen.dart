import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../core/theme/future_surface.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';

enum AuthWizardStep { role, profile, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthWizardStep _step = AuthWizardStep.role;

  String _role = 'user';
  bool _registerMode = false;
  bool _loading = false;
  String _error = '';
  String _countryCode = '+972';

  final TextEditingController _nameController = TextEditingController();
  // Local part only — user types 05X or 5X, we normalize on submit
  final TextEditingController _phoneLocalController = TextEditingController();

  /// Normalized E.164 phone: +972XXXXXXXX (leading 0 stripped automatically)
  String get _fullPhone {
    final local = _phoneLocalController.text.trim();
    final stripped = local.startsWith('0') ? local.substring(1) : local;
    return '$_countryCode$stripped';
  }

  Future<void> _continueFromProfile() async {
    final local = _phoneLocalController.text.trim();
    final digitsOnly = local.replaceAll(RegExp(r'\D'), '');
    // Accept 9 digits (5XXXXXXXX) or 10 digits (05XXXXXXXX)
    if (digitsOnly.length < 9 || digitsOnly.length > 10) {
      setState(() => _error = 'נא להזין מספר טלפון תקין (9–10 ספרות)');
      return;
    }

    if (_registerMode && _nameController.text.trim().isEmpty) {
      setState(() => _error = 'נא להזין שם מלא');
      return;
    }

    final phone = _fullPhone;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      if (_registerMode) {
        final ok = await AuthService().register(
          fullName: _nameController.text.trim(),
          phoneNumber: phone,
          role: _role,
          language: 'he',
        );
        if (!ok) {
          setState(() {
            _loading = false;
            _error = 'הרשמה נכשלה. נסה שוב.';
          });
          return;
        }
      }

      final otp = await AuthService().requestOTPDetailed(phone, _role);
      if (otp == 'error') {
        setState(() {
          _loading = false;
          _error = 'שליחת קוד נכשלה. ודא שהחשבון קיים או בצע הרשמה.';
        });
        return;
      }
      setState(() {
        _loading = false;
        _step = AuthWizardStep.otp;
      });
      // If OTP returned in response (dev/testing mode) — show it to user
      if (otp != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('קוד האימות שלך'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('SMS לא זמין כרגע. הקוד שלך:'),
                  const SizedBox(height: 16),
                  Text(
                    otp,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('הבנתי'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'שגיאת מערכת. נסה שוב בעוד רגע.';
      });
    }
  }

  Future<void> _verifyOtp(String otp) async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final data = await AuthService().verifyOTP(_fullPhone, otp);
    if (!mounted) return;

    if (data != null) {
      Navigator.of(context).pushReplacementNamed('/wizard_home');
      return;
    }

    setState(() {
      _loading = false;
      _error = 'קוד אימות לא תקין';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 28),
                    _buildStepBar(),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _stepBody(),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              VetoPalette.emergency.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: VetoPalette.emergency
                                  .withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: VetoPalette.emergency, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error,
                                style: const TextStyle(
                                    color: VetoPalette.emergency,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: VetoPalette.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: VetoPalette.primary.withValues(alpha: 0.35)),
          ),
          child: const Icon(Icons.gavel_rounded,
              color: VetoPalette.primary, size: 30),
        ),
        const SizedBox(height: 14),
        Text(
          'VETO',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'הגנה משפטית מהירה בשעת חירום',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: VetoPalette.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepBar() {
    const labels = ['סוג חשבון', 'פרטים', 'אימות'];
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i <= _step.index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i < labels.length - 1 ? 6 : 0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: active ? VetoPalette.primary : VetoPalette.border,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: active
                        ? VetoPalette.primary
                        : VetoPalette.textSubtle,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case AuthWizardStep.role:
        return _roleStep();
      case AuthWizardStep.profile:
        return _profileStep();
      case AuthWizardStep.otp:
        return _otpStep();
    }
  }

  Widget _roleStep() {
    return GlassPanel(
      key: const ValueKey('roleStep'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('בחר סוג חשבון',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'אזרח הזקוק לסיוע משפטי, או עורך דין המציע שירות',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: VetoPalette.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child:
                      _roleCard('אזרח', 'user', Icons.person_outline_rounded)),
              const SizedBox(width: 12),
              Expanded(
                  child: _roleCard('עורך דין', 'lawyer', Icons.gavel_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => setState(() => _step = AuthWizardStep.profile),
            child: const Text('המשך'),
          ),
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool isRegister) {
    final selected = _registerMode == isRegister;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _registerMode = isRegister),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? VetoPalette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : VetoPalette.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String label, String value, IconData icon) {
    final selected = _role == value;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? VetoPalette.primary.withValues(alpha: 0.1)
              : VetoPalette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? VetoPalette.primary : VetoPalette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? VetoPalette.primary : VetoPalette.textMuted,
                size: 24),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? VetoPalette.primary
                        : VetoPalette.text)),
          ],
        ),
      ),
    );
  }

  Widget _profileStep() {
    return GlassPanel(
      key: const ValueKey('profileStep'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Login / Register toggle tabs ───────────────────────
          Container(
            decoration: BoxDecoration(
              color: VetoPalette.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _modeTab('כניסה', false),
                _modeTab('הרשמה', true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_registerMode) ...[
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'שם מלא',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 10),
          ],
          // ── Phone input: prefix chip + local number ────────────
          const Text(
            'מספר טלפון',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: VetoPalette.textMuted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Country code prefix (fixed)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: VetoPalette.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: VetoPalette.border),
                ),
                child: Text(
                  _countryCode,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: VetoPalette.text),
                ),
              ),
              const SizedBox(width: 8),
              // Local number — accepts 05XXXXXXXX or 5XXXXXXXX
              Expanded(
                child: TextField(
                  controller: _phoneLocalController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    hintText: '05X-XXXXXXX',
                    counterText: '',
                    prefixIcon: Icon(Icons.phone_iphone_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ניתן להזין עם 0 בהתחלה (0521234567) או בלי (521234567)',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: VetoPalette.textSubtle),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = AuthWizardStep.role),
                  child: const Text('חזור'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _continueFromProfile,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('שלח OTP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _otpStep() {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 58,
      textStyle: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(color: VetoPalette.text, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VetoPalette.border),
      ),
    );

    return GlassPanel(
      key: const ValueKey('otpStep'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('אימות טלפון',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'קוד נשלח ל-',
                  style: TextStyle(color: VetoPalette.textMuted, fontSize: 13),
                ),
                Text(
                  _fullPhone,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      color: VetoPalette.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Pinput(
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    border: Border.all(color: VetoPalette.primary, width: 1.5),
                  ),
                ),
                onCompleted: _verifyOtp,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _step = AuthWizardStep.profile),
                  child: const Text('חזור'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : () => setState(
                          () => _error = 'יש להזין קוד מלא בן 6 ספרות'),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('אמת והמשך'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
