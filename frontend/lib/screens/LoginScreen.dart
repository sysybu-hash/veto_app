// ============================================================
//  LoginScreen.dart � Full auth wizard (v3)
//  Steps: role ? profile (phone OR Google) ? otp
//  Improvements: Google Sign-In, OTP copy button, symmetric layout
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/future_surface.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../widgets/app_language_menu.dart';

// ?? Google Sign-In singleton ??????????????????????????????????
// Replace 'YOUR_GOOGLE_CLIENT_ID' after creating credentials in
// Google Cloud Console ? APIs & Services ? Credentials (Web client).
// The same ID must also be set in GOOGLE_CLIENT_ID on the backend.
const _kGoogleClientId =
    '752712664923-7loca49f7fggd514q8reljn93meatmrf.apps.googleusercontent.com';

final _gSignIn = GoogleSignIn(
  clientId: _kGoogleClientId,
  scopes: ['email', 'profile'],
);

enum _Step { role, profile, otp }

// ?????????????????????????????????????????????????????????????
//  Translations
// ?????????????????????????????????????????????????????????????
const _copy = <String, Map<String, String>>{
  'he': {
    'eyebrow': '����� / �����',
    'tagline': '���� ���� ����� ��� ��������',
    'stepRole': '�����',
    'stepProfile': '�����',
    'stepOtp': '�����',
    'chooseRole': '��� ��� ���� �-VETO?',
    'chooseRoleBody': '������ ����� �� �������, ������ ���� ������ ������.',
    'citizenTitle': '����',
    'citizenBody': '���� ����� �����, AI, �������, SOS ������ �����.',
    'lawyerTitle': '���� ���',
    'lawyerBody': '���� ������, ����� ������� ������ ����� ����� �������.',
    'next': '����',
    'login': '�����',
    'register': '�����',
    'profileTitle': '���� ������',
    'fullName': '�� ���',
    'phoneLabel': '���� �����',
    'phoneHint': '�����: 0501234567 �� 5XXXXXXXX',
    'back': '����',
    'sendOtp': '��� ���',
    'orDivider': '��',
    'googleBtn': '����� �� Google',
    'otpTitle': '����� �����',
    'otpSentTo': '���� ���� �-',
    'copyCode': '���� ���',
    'copied': '�����!',
    'verify': '��� �����',
    'invalidPhone': '�� ����� ���� ����� ���� �� 9�10 �����.',
    'missingName': '�� ����� �� ��� ��� ������ �����.',
    'registerFailed': '�� ������ ����� ����� ���. ���� �� ������ ���� ���.',
    'otpFailed': '����� ��� ������ �����. ��� ������� ���� �� ���� ������.',
    'systemError': '����� ����� �����. ��� ��� ���� ��� �����.',
    'otpInvalid': '��� ������ ����� ���� ����.',
    'otpIncomplete': '�� ����� ��� ��� �� 6 �����.',
    'googleFailed': '����� �� Google �����. ��� ���.',
    'googleNotConfigured': '����� �� Google ���� ������ �����. �� ������ ������.',
    'otpDialogTitle': '��� ������ ���',
    'otpDialogBody': '����� SMS ���� ���� ����. ��� ���� �����:',
    'understood': '�����',
    'pendingTitle': '����� ������ ������',
    'pendingBody': '����� ���� ���� ���� ����� ������ ����. ���� ������ ���� ������.',
    'subscriptionTitle': '����� ���� ���� �-VETO',
    'subscriptionBody': '��� ������ ������ ����� �� ������ ���� �����. ����� ���� ��� ����� �� ��� ����� ��.',
    'subscriptionPlan': '���� �����',
    'subscriptionPrice': '�19.90 / ����',
    'subscriptionLine1': 'AI ����� ��� �����',
    'subscriptionLine2': '���� ��������, ������ ������',
    'subscriptionLine3': '����� ���� ��� ������ ���� ��� �����',
    'later': '�� �����',
    'paypal': '���� �-PayPal',
    'paymentOpened': '����� �-PayPal? ���� ���� ���� �����.',
    'paymentConfirm': '����� �����',
    'paymentOpenFailed': '�� ���� ����� PayPal ����. ��� ���.',
    'paymentConfirmFailed': '������ ����� �� ����. ���� �� ���� PayPal ���� ���.',
  },
  'en': {
    'eyebrow': 'Sign in / Register',
    'tagline': 'One access layer for every role',
    'stepRole': 'Role',
    'stepProfile': 'Details',
    'stepOtp': 'Verify',
    'chooseRole': 'How do you enter VETO?',
    'chooseRoleBody': 'Your choice sets the dashboard, flow and working language.',
    'citizenTitle': 'Citizen',
    'citizenBody': 'Immediate legal guidance, AI, scenarios, SOS and evidence capture.',
    'lawyerTitle': 'Lawyer',
    'lawyerBody': 'Receive alerts, control availability and handle cases in your console.',
    'next': 'Continue',
    'login': 'Sign in',
    'register': 'Register',
    'profileTitle': 'Account details',
    'fullName': 'Full name',
    'phoneLabel': 'Phone number',
    'phoneHint': 'e.g. 0501234567 or 5XXXXXXXX',
    'back': 'Back',
    'sendOtp': 'Send code',
    'orDivider': 'or',
    'googleBtn': 'Continue with Google',
    'otpTitle': 'Phone verification',
    'otpSentTo': 'Code sent to ',
    'copyCode': 'Copy code',
    'copied': 'Copied!',
    'verify': 'Verify and continue',
    'invalidPhone': 'Please enter a valid 9�10 digit phone number.',
    'missingName': 'Please enter your full name to complete registration.',
    'registerFailed': 'Could not create your account. Please try again.',
    'otpFailed': 'Could not send the code. Make sure the account exists or switch to registration.',
    'systemError': 'A temporary error occurred. Please try again.',
    'otpInvalid': 'The code is not valid.',
    'otpIncomplete': 'Please enter all 6 digits.',
    'googleFailed': 'Google sign-in failed. Please try again.',
    'googleNotConfigured': 'Google Sign-In is not configured yet. Please use phone.',
    'otpDialogTitle': 'Your verification code',
    'otpDialogBody': 'SMS is currently unavailable. Use this temporary code:',
    'understood': 'Got it',
    'pendingTitle': 'Approval pending',
    'pendingBody': 'Your lawyer account was created and sent to the admin for review. You will be notified once approved.',
    'subscriptionTitle': 'Activate full VETO access',
    'subscriptionBody': 'A monthly membership is required. Emergency lawyer dispatch is billed only when you trigger a live event.',
    'subscriptionPlan': 'Monthly membership',
    'subscriptionPrice': '�19.90 / month',
    'subscriptionLine1': 'Unlimited legal AI',
    'subscriptionLine2': 'Access to scenarios, rights and evidence tools',
    'subscriptionLine3': 'Emergency lawyer dispatch billed separately',
    'later': 'Maybe later',
    'paypal': 'Open PayPal',
    'paymentOpened': 'Done in PayPal? Return here and confirm.',
    'paymentConfirm': 'Confirm payment',
    'paymentOpenFailed': 'PayPal could not be opened right now.',
    'paymentConfirmFailed': 'Payment not confirmed yet. Check the PayPal tab and try again.',
  },
  'ru': {
    'eyebrow': '???? / ???????????',
    'tagline': '?????? ???? ??? ???? ?????',
    'stepRole': '????',
    'stepProfile': '??????',
    'stepOtp': '????????',
    'chooseRole': '??? ?? ??????? ? VETO?',
    'chooseRoleBody': '????? ?????????? ??????, ????? ? ??????? ????.',
    'citizenTitle': '?????????',
    'citizenBody': '??????????? ??????, AI, ????????, SOS ? ???????? ?????????????.',
    'lawyerTitle': '???????',
    'lawyerBody': '????????? ????????, ?????????? ???????????? ? ?????? ? ??????.',
    'next': '??????????',
    'login': '????',
    'register': '???????????',
    'profileTitle': '?????? ????????',
    'fullName': '?????? ???',
    'phoneLabel': '????? ????????',
    'phoneHint': '????. 0501234567 ??? 5XXXXXXXX',
    'back': '?????',
    'sendOtp': '????????? ???',
    'orDivider': '???',
    'googleBtn': '????? ????? Google',
    'otpTitle': '????????????? ????????',
    'otpSentTo': '??? ????????? ?? ',
    'copyCode': '??????????',
    'copied': '???????????!',
    'verify': '??????????? ? ??????????',
    'invalidPhone': '??????? ?????????? ????? ?? 9�10 ????.',
    'missingName': '??????? ?????? ??? ??? ?????????? ???????????.',
    'registerFailed': '?? ??????? ??????? ???????. ?????????? ??? ???.',
    'otpFailed': '?? ??????? ????????? ???. ?????????, ??? ??????? ??????????.',
    'systemError': '????????? ??????. ?????????? ??? ???.',
    'otpInvalid': '??? ????????????? ??????????????.',
    'otpIncomplete': '??????? ??? 6 ????.',
    'googleFailed': '???? ????? Google ?? ??????. ?????????? ??? ???.',
    'googleNotConfigured': '???? ????? Google ???? ?? ????????. ??????????? ???????.',
    'otpDialogTitle': '??? ??? ?????????????',
    'otpDialogBody': 'SMS ?????? ??????????. ??????????? ????????? ???:',
    'understood': '???????',
    'pendingTitle': '????????? ?????????',
    'pendingBody': '??????? ???????? ?????? ? ????????? ?????????????? ?? ????????.',
    'subscriptionTitle': '?????? ?????? ? VETO',
    'subscriptionBody': '??? ??????? ??????? ????????? ??????????? ????????.',
    'subscriptionPlan': '??????????? ????????',
    'subscriptionPrice': '�19.90 / ?????',
    'subscriptionLine1': '?????????????? ??????????? AI',
    'subscriptionLine2': '????????, ????? ? ??????????????',
    'subscriptionLine3': '????? ???????? ???????????? ????????',
    'later': '?????',
    'paypal': '??????? PayPal',
    'paymentOpened': '????????? ? PayPal? ????????? ? ???????????.',
    'paymentConfirm': '??????????? ??????',
    'paymentOpenFailed': 'PayPal ?????? ?? ???????????.',
    'paymentConfirmFailed': '?????? ??? ?? ????????????. ????????? ???????.',
  },
};

String _t(String code, String key) {
  return _copy[AppLanguage.normalize(code)]?[key] ??
      _copy[AppLanguage.hebrew]![key] ??
      key;
}

// ?????????????????????????????????????????????????????????????
//  LoginScreen
// ?????????????????????????????????????????????????????????????
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _Step _step = _Step.role;
  String _role = 'user';
  bool _registerMode = false;
  bool _loading = false;
  String _error = '';
  final String _countryCode = '+972';

  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();

  String get _fullPhone {
    final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    final normalized = digits.startsWith('0') ? digits.substring(1) : digits;
    return '$_countryCode$normalized';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ?? Navigation helpers ??????????????????????????????????????
  Future<void> _navigateAfterAuth(
    Map<String, dynamic> data,
    String lang,
  ) async {
    final role = data['user']?['role']?.toString() ??
        await AuthService().getStoredRole() ??
        _role;
    final preferredLanguage = AppLanguage.normalize(
      data['user']?['preferred_language']?.toString() ?? lang,
    );
    await context
        .read<AppLanguageController>()
        .setLanguage(preferredLanguage, persist: false);

    if (!mounted) return;
    if (role == 'lawyer') {
      Navigator.of(context).pushReplacementNamed('/lawyer_dashboard');
    } else if (role == 'admin') {
      Navigator.of(context).pushReplacementNamed('/admin_settings');
    } else {
      final isPaymentExempt = data['user']?['is_payment_exempt'] == true;
      final isSubscribed    = data['user']?['is_subscribed'] == true;
      if (isPaymentExempt || isSubscribed) {
        Navigator.of(context).pushReplacementNamed('/veto_screen');
      } else {
        final subscribed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SubscriptionGateDialog(code: preferredLanguage),
        );
        if (subscribed == true && mounted) {
          Navigator.of(context).pushReplacementNamed('/veto_screen');
        }
      }
    }
  }

  // ?? Phone flow ??????????????????????????????????????????????
  Future<void> _continueFromProfile() async {
    final lang = context.read<AppLanguageController>().code;
    final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');

    if (digits.length < 9 || digits.length > 10) {
      setState(() => _error = _t(lang, 'invalidPhone'));
      return;
    }
    if (_registerMode && _nameCtrl.text.trim().isEmpty) {
      setState(() => _error = _t(lang, 'missingName'));
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      if (_registerMode) {
        final ok = await AuthService().register(
          fullName: _nameCtrl.text.trim(),
          phoneNumber: _fullPhone,
          role: _role,
          language: lang,
        );
        if (!ok) {
          setState(() { _loading = false; _error = _t(lang, 'registerFailed'); });
          return;
        }
      }

      final otp = await AuthService().requestOTPDetailed(_fullPhone, _role);
      if (!mounted) return;
      if (otp == 'error') {
        setState(() { _loading = false; _error = _t(lang, 'otpFailed'); });
        return;
      }

      setState(() { _loading = false; _step = _Step.otp; });

      if (otp != null) {
        await showDialog<void>(
          context: context,
          builder: (_) => _OtpCodeDialog(code: lang, otp: otp),
        );
      }
    } catch (_) {
      setState(() { _loading = false; _error = _t(lang, 'systemError'); });
    }
  }

  Future<void> _verifyOtp(String otp) async {
    final lang = context.read<AppLanguageController>().code;
    setState(() { _loading = true; _error = ''; });

    final data = await AuthService().verifyOTP(_fullPhone, otp);
    if (!mounted) return;

    if (data != null) {
      if (data['pending_approval'] == true) {
        await showDialog<void>(
          context: context,
          builder: (_) => _PendingApprovalDialog(code: lang),
        );
        setState(() => _loading = false);
        return;
      }
      await _navigateAfterAuth(data, lang);
      return;
    }

    setState(() { _loading = false; _error = _t(lang, 'otpInvalid'); });
  }

  Future<void> _submitOtp() async {
    final lang = context.read<AppLanguageController>().code;
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = _t(lang, 'otpIncomplete'));
      return;
    }
    await _verifyOtp(code);
  }

  // ?? Google flow ?????????????????????????????????????????????
  Future<void> _signInWithGoogle() async {
    final lang = context.read<AppLanguageController>().code;

    if (_kGoogleClientId.startsWith('YOUR_')) {
      setState(() => _error = _t(lang, 'googleNotConfigured'));
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      final account = await _gSignIn.signIn();
      if (account == null) {
        setState(() => _loading = false);
        return;
      }
      final auth    = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        setState(() { _loading = false; _error = _t(lang, 'googleFailed'); });
        return;
      }

      final data = await AuthService().googleAuth(idToken: idToken, language: lang);
      if (!mounted) return;

      if (data == null) {
        setState(() { _loading = false; _error = _t(lang, 'googleFailed'); });
        return;
      }

      await _navigateAfterAuth(data, lang);
    } catch (_) {
      setState(() { _loading = false; _error = _t(lang, 'googleFailed'); });
    }
  }

  // ?? Build ????????????????????????????????????????????????????
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageController>().code;
    final dir  = AppLanguage.directionOf(lang);
    final wide = MediaQuery.of(context).size.width > 980;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        body: SafeArea(
          child: LayoutBuilder(builder: (_, constraints) {
            return Row(children: [
              if (wide)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _AuthHero(lang: lang),
                  ),
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: wide ? 32 : 24,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!wide) ...[
                            _AuthHero(lang: lang, compact: true),
                            const SizedBox(height: 20),
                          ],
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: const AppLanguageMenu(compact: true),
                          ),
                          const SizedBox(height: 14),
                          GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _BrandRow(tagline: _t(lang, 'tagline')),
                                const SizedBox(height: 20),
                                _StepIndicator(
                                  step: _step.index,
                                  labels: [
                                    _t(lang, 'stepRole'),
                                    _t(lang, 'stepProfile'),
                                    _t(lang, 'stepOtp'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: _buildStep(lang),
                                ),
                              ],
                            ),
                          ),
                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _ErrorBanner(message: _error),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildStep(String lang) {
    switch (_step) {
      case _Step.role:    return _roleStep(lang);
      case _Step.profile: return _profileStep(lang);
      case _Step.otp:     return _otpStep(lang);
    }
  }

  // ?? Step 1: Role ?????????????????????????????????????????????
  Widget _roleStep(String lang) {
    return Column(
      key: const ValueKey('role'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_t(lang, 'chooseRole'),
            style: const TextStyle(color: VetoPalette.text, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(_t(lang, 'chooseRoleBody'),
            style: const TextStyle(color: VetoPalette.textMuted, fontSize: 13, height: 1.6)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _RoleCard(
            selected: _role == 'user',
            icon: Icons.person_search_outlined,
            title: _t(lang, 'citizenTitle'),
            body: _t(lang, 'citizenBody'),
            onTap: () => setState(() => _role = 'user'),
          )),
          const SizedBox(width: 12),
          Expanded(child: _RoleCard(
            selected: _role == 'lawyer',
            icon: Icons.gavel_rounded,
            title: _t(lang, 'lawyerTitle'),
            body: _t(lang, 'lawyerBody'),
            onTap: () => setState(() => _role = 'lawyer'),
          )),
        ]),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => setState(() => _step = _Step.profile),
          child: Text(_t(lang, 'next')),
        ),
      ],
    );
  }

  // ?? Step 2: Profile ??????????????????????????????????????????
  Widget _profileStep(String lang) {
    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeTabs(
          loginLabel: _t(lang, 'login'),
          registerLabel: _t(lang, 'register'),
          isRegister: _registerMode,
          onChanged: (v) => setState(() { _registerMode = v; _error = ''; }),
        ),
        const SizedBox(height: 20),
        Text(_t(lang, 'profileTitle'),
            style: const TextStyle(color: VetoPalette.text, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        if (_registerMode) ...[
          _VetoField(
            controller: _nameCtrl,
            label: _t(lang, 'fullName'),
            icon: Icons.badge_outlined,
            action: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 12),
        ],
        _PhoneRow(
          controller: _phoneCtrl,
          label: _t(lang, 'phoneLabel'),
          hint: _t(lang, 'phoneHint'),
          countryCode: _countryCode,
          onSubmitted: _loading ? null : (_) => _continueFromProfile(),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() => _step = _Step.role),
            child: Text(_t(lang, 'back')),
          )),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(
            onPressed: _loading ? null : _continueFromProfile,
            child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_t(lang, 'sendOtp')),
          )),
        ]),
        const SizedBox(height: 20),
        _OrDivider(label: _t(lang, 'orDivider')),
        const SizedBox(height: 16),
        _GoogleButton(
          label: _t(lang, 'googleBtn'),
          loading: _loading,
          onTap: _signInWithGoogle,
        ),
      ],
    );
  }

  // ?? Step 3: OTP ??????????????????????????????????????????????
  Widget _otpStep(String lang) {
    final defaultTheme = PinTheme(
      width: 50,
      height: 58,
      textStyle: const TextStyle(color: VetoPalette.text, fontSize: 24, fontWeight: FontWeight.w700),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VetoPalette.border),
      ),
    );

    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_t(lang, 'otpTitle'),
            style: const TextStyle(color: VetoPalette.text, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(_t(lang, 'otpSentTo'),
              style: const TextStyle(color: VetoPalette.textMuted, fontSize: 14)),
          const SizedBox(width: 4),
          Text(_fullPhone, textDirection: TextDirection.ltr,
              style: const TextStyle(color: VetoPalette.info, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 22),
        Center(child: Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
            controller: _otpCtrl,
            length: 6,
            defaultPinTheme: defaultTheme,
            focusedPinTheme: defaultTheme.copyWith(
              decoration: defaultTheme.decoration?.copyWith(
                border: Border.all(color: VetoPalette.primary, width: 1.5),
              ),
            ),
            onChanged: (_) { if (_error.isNotEmpty) setState(() => _error = ''); },
            onCompleted: _verifyOtp,
          ),
        )),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: _loading ? null : () => setState(() => _step = _Step.profile),
            child: Text(_t(lang, 'back')),
          )),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(
            onPressed: _loading ? null : _submitOtp,
            child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_t(lang, 'verify')),
          )),
        ]),
      ],
    );
  }
}

// ?????????????????????????????????????????????????????????????
//  Reusable widgets
// ?????????????????????????????????????????????????????????????

class _BrandRow extends StatelessWidget {
  final String tagline;
  const _BrandRow({required this.tagline});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: VetoPalette.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.shield_rounded, color: VetoPalette.primary, size: 28),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VETO', style: TextStyle(
              color: VetoPalette.text, fontSize: 22,
              fontWeight: FontWeight.w900, letterSpacing: 4)),
          Text(tagline, style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
        ],
      )),
    ]);
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final List<String> labels;
  const _StepIndicator({required this.step, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i <= step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 6 : 0),
            child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: active ? VetoPalette.primary : VetoPalette.border,
                ),
              ),
              const SizedBox(height: 6),
              Text(labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? VetoPalette.primary : VetoPalette.textSubtle,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  )),
            ]),
          ),
        );
      }),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  final String loginLabel;
  final String registerLabel;
  final bool isRegister;
  final ValueChanged<bool> onChanged;

  const _ModeTabs({
    required this.loginLabel,
    required this.registerLabel,
    required this.isRegister,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VetoPalette.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _Tab(label: loginLabel,    selected: !isRegister, onTap: () => onChanged(false)),
        _Tab(label: registerLabel, selected: isRegister,  onTap: () => onChanged(true)),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? VetoPalette.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : VetoPalette.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            )),
      ),
    ));
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  const _RoleCard({
    required this.selected, required this.icon, required this.title,
    required this.body, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? VetoPalette.primary.withValues(alpha: 0.10) : VetoPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border(
                  left: const BorderSide(color: VetoPalette.primary, width: 3),
                  top: BorderSide(color: VetoPalette.primary.withValues(alpha: 0.3)),
                  right: BorderSide(color: VetoPalette.primary.withValues(alpha: 0.3)),
                  bottom: BorderSide(color: VetoPalette.primary.withValues(alpha: 0.3)),
                )
              : Border.all(color: VetoPalette.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: selected ? VetoPalette.primary : VetoPalette.textMuted, size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(
              color: selected ? VetoPalette.primary : VetoPalette.text,
              fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(
              color: VetoPalette.textMuted, fontSize: 12, height: 1.6)),
        ]),
      ),
    );
  }
}

class _VetoField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  const _VetoField({
    required this.controller, required this.label,
    required this.icon, required this.action, this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: action,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String countryCode;
  final ValueChanged<String>? onSubmitted;
  const _PhoneRow({
    required this.controller, required this.label,
    required this.hint, required this.countryCode, this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          color: VetoPalette.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: VetoPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VetoPalette.border),
          ),
          child: Text(countryCode, textDirection: TextDirection.ltr,
              style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.go,
          textDirection: TextDirection.ltr,
          maxLength: 10,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 18),
          ),
        )),
      ]),
    ]);
  }
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider(color: VetoPalette.border)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(label, style: const TextStyle(
            color: VetoPalette.textSubtle, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      const Expanded(child: Divider(color: VetoPalette.border)),
    ]);
  }
}

class _GoogleButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VetoPalette.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 22, height: 22,
            child: CustomPaint(painter: _GoogleLogoPainter()),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(
              color: VetoPalette.text, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const sweeps = [
      [0.0,    93.0,  0xFF4285F4],
      [93.0,   90.0,  0xFF34A853],
      [183.0,  90.0,  0xFFFBBC05],
      [273.0,  87.0,  0xFFEA4335],
    ];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.28;
    for (final s in sweeps) {
      paint.color = Color(s[2].toInt());
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - paint.strokeWidth / 2),
        _deg(s[0].toDouble()),
        _deg(s[1].toDouble()),
        false,
        paint,
      );
    }
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.28;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.94, size.height * 0.5),
      barPaint,
    );
  }

  double _deg(double deg) => deg * 3.14159265358979 / 180;

  @override
  bool shouldRepaint(_) => false;
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VetoPalette.emergency.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.emergency.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: VetoPalette.emergency, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: const TextStyle(color: VetoPalette.emergency, fontSize: 13, height: 1.4))),
      ]),
    );
  }
}

// ?????????????????????????????????????????????????????????????
//  Auth Hero
// ?????????????????????????????????????????????????????????????

class _AuthHero extends StatelessWidget {
  final String lang;
  final bool compact;
  const _AuthHero({required this.lang, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF060C17), Color(0xFF0E1E38), Color(0xFF091629)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: VetoPalette.border),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1D6FB8).withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_t(lang, 'eyebrow').toUpperCase(), style: const TextStyle(
            color: VetoPalette.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.5)),
        const SizedBox(height: 10),
        Text(
          lang == 'he'
              ? '����� �����.\n����� �����.\n��� ��� ������ ����.'
              : lang == 'ru'
                  ? '???????? ????.\n??????? ???????????.\n???? ????, ??????? ???????? ? ????.'
                  : 'Clear sign-in.\nFast onboarding.\nOne language that stays with you.',
          style: TextStyle(
              color: VetoPalette.text,
              fontSize: compact ? 26 : 42,
              fontWeight: FontWeight.w900,
              height: 1.08),
        ),
        const SizedBox(height: 14),
        _HeroLine(icon: Icons.account_tree_outlined,
            label: lang == 'he' ? '����, ���� ��� �� ����'
                : lang == 'ru' ? '?????????, ??????? ??? ?????????????'
                : 'Citizen, lawyer, or admin flow'),
        const SizedBox(height: 8),
        _HeroLine(icon: Icons.translate_rounded,
            label: lang == 'he' ? '�����, English, ???????'
                : lang == 'ru' ? '?????, ?????????? ? ???????'
                : 'Hebrew, English, and Russian'),
        const SizedBox(height: 8),
        _HeroLine(icon: Icons.auto_awesome_rounded,
            label: lang == 'he' ? 'OTP ������ ���� ����� ���'
                : lang == 'ru' ? 'OTP ? ???????? ? ????? ??????'
                : 'OTP and subscription in one wizard'),
      ]),
    );
  }
}

class _HeroLine extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: VetoPalette.primary, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(
          color: VetoPalette.textMuted, fontSize: 13, fontWeight: FontWeight.w500))),
    ]);
  }
}

// ?????????????????????????????????????????????????????????????
//  OTP Code Dialog � with copy button
// ?????????????????????????????????????????????????????????????

class _OtpCodeDialog extends StatefulWidget {
  final String code;
  final String otp;
  const _OtpCodeDialog({required this.code, required this.otp});

  @override
  State<_OtpCodeDialog> createState() => _OtpCodeDialogState();
}

class _OtpCodeDialogState extends State<_OtpCodeDialog> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.otp));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLanguage.directionOf(widget.code),
      child: AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_t(widget.code, 'otpDialogTitle'),
            style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_t(widget.code, 'otpDialogBody'),
              style: const TextStyle(color: VetoPalette.textMuted, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: VetoPalette.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(widget.otp, style: const TextStyle(
                  color: VetoPalette.primary, fontSize: 34,
                  fontWeight: FontWeight.w900, letterSpacing: 8)),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _copied
                    ? const Icon(Icons.check_circle_rounded,
                        key: ValueKey('check'), color: VetoPalette.success, size: 24)
                    : IconButton(
                        key: const ValueKey('copy'),
                        icon: const Icon(Icons.copy_rounded,
                            color: VetoPalette.primary, size: 22),
                        tooltip: _t(widget.code, 'copyCode'),
                        onPressed: _copy,
                      ),
              ),
            ]),
          ),
          if (_copied) ...[
            const SizedBox(height: 8),
            Text(_t(widget.code, 'copied'),
                style: const TextStyle(color: VetoPalette.success, fontSize: 13)),
          ],
        ]),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t(widget.code, 'understood')),
          ),
        ],
      ),
    );
  }
}

// ?????????????????????????????????????????????????????????????
//  Pending Approval Dialog
// ?????????????????????????????????????????????????????????????

class _PendingApprovalDialog extends StatelessWidget {
  final String code;
  const _PendingApprovalDialog({required this.code});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.hourglass_empty_rounded, color: VetoPalette.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(_t(code, 'pendingTitle'),
              style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w800))),
        ]),
        content: Text(_t(code, 'pendingBody'),
            style: const TextStyle(color: VetoPalette.textMuted, height: 1.6)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t(code, 'understood')),
          ),
        ],
      ),
    );
  }
}

// ?????????????????????????????????????????????????????????????
//  Subscription Gate Dialog
// ?????????????????????????????????????????????????????????????

class _SubscriptionGateDialog extends StatefulWidget {
  final String code;
  const _SubscriptionGateDialog({required this.code});

  @override
  State<_SubscriptionGateDialog> createState() => _SubscriptionGateDialogState();
}

class _SubscriptionGateDialogState extends State<_SubscriptionGateDialog> {
  bool _loading = false;
  String? _error;
  String? _orderId;

  Future<void> _openPayPal() async {
    setState(() { _loading = true; _error = null; });
    final orderId = await PaymentService.createAndOpenOrder(PaymentType.subscription);
    if (!mounted) return;
    if (orderId == null) {
      setState(() { _loading = false; _error = _t(widget.code, 'paymentOpenFailed'); });
      return;
    }
    setState(() { _loading = false; _orderId = orderId; });
  }

  Future<void> _confirmPayment() async {
    if (_orderId == null) return;
    setState(() { _loading = true; _error = null; });
    final phone  = await AuthService().getStoredPhone();
    final result = await PaymentService.captureOrder(
      orderId: _orderId!, type: PaymentType.subscription, userId: phone,
    );
    if (!mounted) return;
    if (result.success) {
      await AuthService().setSubscribed(true);
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _loading = false;
      _error = result.error ?? _t(widget.code, 'paymentConfirmFailed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.code;
    return Directionality(
      textDirection: AppLanguage.directionOf(c),
      child: AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(children: [
          const Icon(Icons.lock_open_rounded, color: VetoPalette.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(_t(c, 'subscriptionTitle'),
              style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w800))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t(c, 'subscriptionBody'),
                style: const TextStyle(color: VetoPalette.textMuted, fontSize: 14, height: 1.6)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VetoPalette.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.28)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_t(c, 'subscriptionPlan'),
                    style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(_t(c, 'subscriptionPrice'),
                    style: const TextStyle(color: VetoPalette.success, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                _PlanLine(text: _t(c, 'subscriptionLine1')),
                _PlanLine(text: _t(c, 'subscriptionLine2')),
                _PlanLine(text: _t(c, 'subscriptionLine3')),
              ]),
            ),
            if (_orderId != null) ...[
              const SizedBox(height: 12),
              Text(_t(c, 'paymentOpened'),
                  style: const TextStyle(color: VetoPalette.warning)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: VetoPalette.emergency)),
            ],
          ],
        ),
        actions: _orderId == null
            ? [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                  child: Text(_t(c, 'later'),
                      style: const TextStyle(color: VetoPalette.textMuted)),
                ),
                FilledButton(
                  onPressed: _loading ? null : _openPayPal,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF009CDE)),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_t(c, 'paypal')),
                ),
              ]
            : [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                  child: Text(_t(c, 'later'),
                      style: const TextStyle(color: VetoPalette.textMuted)),
                ),
                FilledButton(
                  onPressed: _loading ? null : _confirmPayment,
                  style: FilledButton.styleFrom(backgroundColor: VetoPalette.success),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_t(c, 'paymentConfirm')),
                ),
              ],
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  final String text;
  const _PlanLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: VetoPalette.success, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
            style: const TextStyle(color: VetoPalette.textMuted, fontSize: 13))),
      ]),
    );
  }
}
