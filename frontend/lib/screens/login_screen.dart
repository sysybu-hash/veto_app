// ============================================================
//  LoginScreen.dart — Full auth wizard (v3)
//  Steps: role ? profile (phone OR Google) ? otp
//  Improvements: Google Sign-In, OTP copy button, symmetric layout
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../core/theme/veto_2026_auth.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';
import '../l10n/app_localizations.dart';
import 'login_l10n_lookup.dart';

// ?? Google Sign-In singleton ??????????????????????????????????
// Replace 'YOUR_GOOGLE_CLIENT_ID' after creating credentials in
// Google Cloud Console ? APIs & Services ? Credentials (Web client).
// The same ID must also be set in GOOGLE_CLIENT_ID on the backend.
const _kGoogleClientId =
    '752712664923-7loca49f7fggd514q8reljn93meatmrf.apps.googleusercontent.com';

enum _Step { role, profile, otp }

String _t(BuildContext context, String key) =>
    loginT(AppLocalizations.of(context)!, key);

const TextStyle _kAuthMktBodyStyle = TextStyle(
  fontFamily: V26.sans,
  fontSize: 15,
  height: 1.7,
  color: Color(0xFFC7D5EE),
);

Widget _authMarketingHeadline(
    BuildContext context, String k1, String k2, String kem) {
  return Text.rich(
    TextSpan(
      style: const TextStyle(
        fontFamily: V26.serif,
        fontSize: 36,
        height: 1.12,
        color: Colors.white,
      ),
      children: [
        TextSpan(text: '${_t(context, k1)}\n'),
        TextSpan(text: _t(context, k2)),
        TextSpan(
          text: _t(context, kem),
          style: const TextStyle(color: V26.goldSoft),
        ),
      ],
    ),
  );
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
  final _emailCtrl = TextEditingController();
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
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ?? Navigation helpers ??????????????????????????????????????
  Future<void> _navigateAfterAuth(
    Map<String, dynamic> data,
    String lang,
  ) async {
    if (!mounted) return;
    final languageController = context.read<AppLanguageController>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    final userId = data['user']?['id']?.toString() ??
        data['user']?['_id']?.toString() ??
        await AuthService().getStoredUserId();
    final role = data['user']?['role']?.toString() ??
        await AuthService().getStoredRole() ??
        _role;
    final preferredLanguage = AppLanguage.normalize(
      data['user']?['preferred_language']?.toString() ?? lang,
    );
    if (!mounted) return;
    await languageController.setLanguage(preferredLanguage, persist: false);

    if (!mounted) return;

    // Flows SDK (web only): identify user after successful auth.
    // If the JS Promise never settles (network / Flows bug), awaiting here froze the tab ("Page unresponsive").
    if (userId != null && userId.isNotEmpty) {
      if (kIsWeb) {
        Map<String, dynamic>? status;
        try {
          status = await browser_bridge
              .flowsSetUser(
                userId: userId,
                role: role,
                lang: preferredLanguage,
              )
              .timeout(const Duration(seconds: 8));
        } on TimeoutException {
          debugPrint('[VETO Flows] flowsSetUser timed out after 8s; continuing login.');
          status = null;
        } catch (e, st) {
          debugPrint('[VETO Flows] flowsSetUser error: $e\n$st');
          status = null;
        }
        if (!mounted) return;
        if (mounted && status != null) {
          final ok = status['ok'] == true;
          final stage = status['stage']?.toString();
          final key = status['key']?.toString();
          final err = status['error']?.toString();
          final loc = AppLocalizations.of(context)!;
          final detail =
              '${stage ?? ''}${key != null ? ' · $key' : ''}'.trim();
          final msg = ok
              ? loc.loginFlowsSuccess(detail.isEmpty ? '—' : detail)
              : loc.loginFlowsFailed(err ?? 'unknown');
          messenger?.showSnackBar(
            SnackBar(
              content: Text(msg),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        browser_bridge.callBrowserMethod('vetoFlows', 'setUser', [
          userId,
          role,
          preferredLanguage,
        ]);
      }
    }

    if (!mounted) return;

    // Server role wins: lawyers and admins never land on the citizen VETO chat shell.
    if (role == 'lawyer') {
      Navigator.of(context).pushReplacementNamed('/lawyer_dashboard');
    } else if (role == 'admin') {
      Navigator.of(context).pushReplacementNamed('/admin_settings');
    } else {
      // Citizens: first-time visitors run through the 2026 onboarding quiz.
      final onboarded = await AuthService().getOnboarded();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        onboarded ? '/veto_screen' : '/wizard_home',
      );
    }
  }

  String _messageForOtpRequestFailure(BuildContext context, String? result) {
    if (result == null || result == 'error') {
      return _t(context, 'otpNetwork');
    }

    if (result.startsWith('error|')) {
      final parts = result.split('|');
      if (parts.length >= 3) {
        final code = int.tryParse(parts[1]);
        final server = parts.sublist(2).join('|').trim();
        if (code == 404) return _t(context, 'otpNotFound');
        if (code == 429) return _t(context, 'otpRateLimited');
        if (code != null && code >= 500) return _t(context, 'otpServer');
        if (server.isNotEmpty) return server;
      }
    }

    if (result.startsWith('error:')) {
      final code = int.tryParse(result.substring('error:'.length));
      if (code == 404) return _t(context, 'otpNotFound');
      if (code == 429) return _t(context, 'otpRateLimited');
      if (code != null && code >= 500) return _t(context, 'otpServer');
    }

    return _t(context, 'otpFailed');
  }

  // ?? Phone flow ??????????????????????????????????????????????
  Future<void> _continueFromProfile() async {
    final lang = context.read<AppLanguageController>().code;
    final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');

    if (digits.length < 9 || digits.length > 10) {
      setState(() => _error = _t(context, 'invalidPhone'));
      return;
    }
    if (_registerMode && _nameCtrl.text.trim().isEmpty) {
      setState(() => _error = _t(context, 'missingName'));
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
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        );
        if (!ok) {
          setState(() { _loading = false; _error = _t(context, 'registerFailed'); });
          return;
        }
      }

      final otp = await AuthService().requestOTPDetailed(_fullPhone, _role);
      if (!mounted) return;
      if (otp == 'error' ||
          (otp != null && otp.startsWith('error:')) ||
          (otp != null && otp.startsWith('error|'))) {
        setState(() {
          _loading = false;
          _error = _messageForOtpRequestFailure(context, otp);
        });
        return;
      }

      setState(() { _loading = false; _step = _Step.otp; });

      if (otp != null && otp.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (_) => _OtpCodeDialog(code: lang, otp: otp),
        );
      }
    } catch (_) {
      setState(() { _loading = false; _error = _t(context, 'systemError'); });
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

    setState(() { _loading = false; _error = _t(context, 'otpInvalid'); });
  }

  Future<void> _submitOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = _t(context, 'otpIncomplete'));
      return;
    }
    await _verifyOtp(code);
  }

  // ?? Google flow ?????????????????????????????????????????????
  Future<void> _signInWithGoogle() async {
    final lang = context.read<AppLanguageController>().code;
    setState(() { _loading = true; _error = ''; });

    try {
      // Use GIS token client via JavaScript bridge (reliable on Flutter Web)
      final accessToken = await browser_bridge.googleSignInViaGIS(_kGoogleClientId);

      final data = await AuthService().googleAuth(
        accessToken: accessToken,
        language: lang,
      );
      if (!mounted) return;

      if (data == null) {
        setState(() { _loading = false; _error = _t(context, 'googleFailed'); });
        return;
      }

      await _navigateAfterAuth(data, lang);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (mounted) {
        setState(() { _loading = false; _error = _t(context, 'googleFailed'); });
      }
    }
  }

  // ?? Build ????????????????????????????????????????????????????
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageController>().code;
    final dir = AppLanguage.directionOf(lang);
    final wide =
        MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;

    final form = _buildAuthFormColumn(context, lang, wide);

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: VetoMockup.pageBackground,
        body: V26Backdrop(
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 105,
                      child: _LoginMarketingSide(step: _step, lang: lang),
                    ),
                    Expanded(flex: 95, child: form),
                  ],
                )
              : form,
        ),
      ),
    );
  }

  Widget _buildAuthFormColumn(BuildContext context, String lang, bool wide) {
    final pad = wide
        ? const EdgeInsets.fromLTRB(56, 48, 56, 40)
        : const EdgeInsets.fromLTRB(20, 24, 20, 28);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: pad,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _loginTopBar(context, lang, wide),
                const SizedBox(height: 28),
                _LoginStepperDots(
                  stepIndex: _step.index,
                  labels: [
                    _t(context, 'stepRole'),
                    _t(context, 'stepProfile'),
                    _t(context, 'stepOtp'),
                  ],
                ),
                const SizedBox(height: 28),
                V26Card(
                  lift: true,
                  radius: wide ? V26.r2xl : V26.rXl,
                  padding: EdgeInsets.all(wide ? 36 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _buildStep(lang),
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ErrorBanner(message: _error),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _t(context, 'secureFootnote'),
                  style: const TextStyle(color: V26.ink300, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (ctx) {
                    final loc = AppLocalizations.of(ctx)!;
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 0,
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/privacy'),
                          child: Text(
                            loc.linkPrivacy,
                            style: const TextStyle(
                              color: VetoMockup.primaryCta,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Text(
                          '·',
                          style: TextStyle(color: V26.ink300, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/terms'),
                          child: Text(
                            loc.linkTerms,
                            style: const TextStyle(
                              color: VetoMockup.primaryCta,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginTopBar(BuildContext context, String lang, bool wide) {
    Widget backBtn(VoidCallback onTap) {
      return TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 14, color: VetoMockup.primaryCta),
        label: Text(
          _t(context, 'back'),
          style: const TextStyle(
            color: VetoMockup.primaryCta,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      );
    }

    final Widget left = switch (_step) {
      _Step.role when wide => V26Badge(
          _t(context, 'eyebrow'),
          tone: V26BadgeTone.brand,
        ),
      _Step.role => TextButton.icon(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/landing'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 14, color: VetoMockup.primaryCta),
          label: Text(
            AppLocalizations.of(context)!.vetoUiHamburgerHome,
            style: const TextStyle(
              color: VetoMockup.primaryCta,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
        ),
      _Step.profile =>
        backBtn(() => setState(() => _step = _Step.role)),
      _Step.otp =>
        backBtn(() => setState(() => _step = _Step.profile)),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        left,
        const AppLanguageMenu(compact: true),
      ],
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
    return LayoutBuilder(
      builder: (context, c) {
        final stack = c.maxWidth < 440;
        final citizen = _RoleCard(
          selected: _role == 'user',
          icon: Icons.person_outline_rounded,
          title: _t(context, 'citizenTitle'),
          body: _t(context, 'citizenBody'),
          onTap: () => setState(() => _role = 'user'),
        );
        final lawyer = _RoleCard(
          selected: _role == 'lawyer',
          icon: Icons.gavel_rounded,
          title: _t(context, 'lawyerTitle'),
          body: _t(context, 'lawyerBody'),
          onTap: () => setState(() => _role = 'lawyer'),
        );
        return Column(
          key: const ValueKey('role'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            V26Kicker(_t(context, 'roleStepKicker')),
            const SizedBox(height: 8),
            V26Headline(_t(context, 'chooseRole'), size: 28),
            const SizedBox(height: 8),
            Text(
              _t(context, 'chooseRoleBody'),
              style: const TextStyle(
                color: V26.ink500,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 22),
            if (stack)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  citizen,
                  const SizedBox(height: 12),
                  lawyer,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: citizen),
                  const SizedBox(width: 14),
                  Expanded(child: lawyer),
                ],
              ),
            const SizedBox(height: 22),
            V26CTA(
              _t(context, 'next'),
              variant: V26CtaVariant.primary,
              large: true,
              expanded: true,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => setState(() => _step = _Step.profile),
            ),
          ],
        );
      },
    );
  }

  // ?? Step 2: Profile ??????????????????????????????????????????
  Widget _profileStep(String lang) {
    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeTabs(
          loginLabel: _t(context, 'login'),
          registerLabel: _t(context, 'register'),
          isRegister: _registerMode,
          onChanged: (v) => setState(() {
            _registerMode = v;
            _error = '';
          }),
        ),
        const SizedBox(height: 20),
        V26Kicker(_t(context, 'profileStepKicker')),
        const SizedBox(height: 8),
        V26Headline(
          _registerMode
              ? _t(context, 'profileH2Register')
              : _t(context, 'profileH2Login'),
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          _registerMode
              ? _t(context, 'profileLedeRegister')
              : _t(context, 'profileLedeLogin'),
          style: const TextStyle(
            color: V26.ink500,
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
        if (_registerMode) ...[
          _VetoField(
            controller: _nameCtrl,
            label: _t(context, 'fullName'),
            icon: Icons.badge_outlined,
            action: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          _VetoField(
            controller: _emailCtrl,
            label: _t(context, 'emailLabel'),
            hint: _t(context, 'emailHint'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 12),
        ],
        _PhoneRow(
          controller: _phoneCtrl,
          label: _t(context, 'phoneLabel'),
          hint: _t(context, 'phoneHint'),
          countryCode: _countryCode,
          onSubmitted: _loading ? null : (_) => _continueFromProfile(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: V26CTA(
                _t(context, 'back'),
                variant: V26CtaVariant.ghost,
                large: true,
                expanded: true,
                onPressed: () => setState(() => _step = _Step.role),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: V26CTA(
                _t(context, 'sendOtp'),
                expanded: true,
                large: true,
                loading: _loading,
                onPressed: _continueFromProfile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _OrDivider(label: _t(context, 'orDivider')),
        const SizedBox(height: 16),
        _GoogleButton(
          label: _t(context, 'googleBtn'),
          loading: _loading,
          onTap: _signInWithGoogle,
        ),
      ],
    );
  }

  // ?? Step 3: OTP ??????????????????????????????????????????????
  Widget _otpStep(String lang) {
    final defaultTheme = PinTheme(
      width: 48,
      height: 58,
      textStyle: const TextStyle(
        fontFamily: V26.serif,
        color: V26.ink900,
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
      decoration: BoxDecoration(
        color: V26.surface,
        borderRadius: BorderRadius.circular(V26.rMd),
        border: Border.all(color: V26.hairline),
        boxShadow: V26.shadow1,
      ),
    );

    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        V26Kicker(_t(context, 'otpStepKicker')),
        const SizedBox(height: 8),
        V26Headline(_t(context, 'otpH2'), size: 28),
        const SizedBox(height: 8),
        Text(
          _t(context, 'otpLede'),
          style: const TextStyle(
            color: V26.ink500,
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: V26.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: V26.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: V26.navy100,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.phone_iphone_rounded,
                    size: 16, color: VetoMockup.primaryCtaDeep),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(context, 'otpSentLabel'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: V26.ink500,
                      ),
                    ),
                    Text(
                      _fullPhone,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontFamily: V26.sans,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: V26.ink900,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _step = _Step.profile),
                child: Text(
                  _t(context, 'changePhone'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: VetoMockup.primaryCta,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Pinput(
              controller: _otpCtrl,
              length: 6,
              defaultPinTheme: defaultTheme,
              focusedPinTheme: defaultTheme.copyWith(
                decoration: defaultTheme.decoration?.copyWith(
                  border: Border.all(color: VetoMockup.primaryCta, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: VetoMockup.primaryCta.withValues(alpha: 0.12),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              onChanged: (_) {
                if (_error.isNotEmpty) setState(() => _error = '');
              },
              onCompleted: _verifyOtp,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.content_paste_rounded,
                size: 16, color: VetoMockup.primaryCta),
            label: Text(
              _t(context, 'pasteOtp'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: VetoMockup.primaryCta,
              ),
            ),
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              final text = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
              if (text.length >= 6) {
                final code = text.substring(0, 6);
                _otpCtrl.text = code;
                await _verifyOtp(code);
              }
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: V26CTA(
                _t(context, 'back'),
                variant: V26CtaVariant.ghost,
                large: true,
                expanded: true,
                onPressed: () => setState(() => _step = _Step.profile),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: V26CTA(
                _t(context, 'verify'),
                expanded: true,
                large: true,
                loading: _loading,
                onPressed: _submitOtp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────

class _LoginMarketingSide extends StatelessWidget {
  final _Step step;
  final String lang;

  const _LoginMarketingSide({required this.step, required this.lang});

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case _Step.role:
        return V26AuthNavyPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      V26AuthBrandRow(tagline: _t(context, 'brandTagline')),
                      const SizedBox(height: 40),
                      _authMarketingHeadline(context, 'authSide_role_h1_l1',
                          'authSide_role_h1_l2', 'authSide_role_h1_em'),
                      const SizedBox(height: 16),
                      Text(_t(context, 'authSide_role_p'),
                          style: _kAuthMktBodyStyle),
                      const SizedBox(height: 36),
                      V26AuthFeatureLine(
                        icon: Icons.devices_rounded,
                        title: _t(context, 'authSide_role_f1t'),
                        body: _t(context, 'authSide_role_f1b'),
                      ),
                      const SizedBox(height: 18),
                      V26AuthFeatureLine(
                        icon: Icons.lock_outline_rounded,
                        title: _t(context, 'authSide_role_f2t'),
                        body: _t(context, 'authSide_role_f2b'),
                      ),
                      const SizedBox(height: 18),
                      V26AuthFeatureLine(
                        icon: Icons.language_rounded,
                        title: _t(context, 'authSide_role_f3t'),
                        body: _t(context, 'authSide_role_f3b'),
                      ),
                    ],
                  ),
                ),
              ),
              V26AuthQuote(
                quote: _t(context, 'authSide_role_q'),
                initials: _t(context, 'authSide_role_qi'),
                name: _t(context, 'authSide_role_qn'),
                role: _t(context, 'authSide_role_qr'),
              ),
            ],
          ),
        );
      case _Step.profile:
        return V26AuthNavyPanel(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                V26AuthBrandRow(tagline: _t(context, 'brandTagline')),
                const SizedBox(height: 40),
                _authMarketingHeadline(context, 'authSide_prof_h1_l1',
                    'authSide_prof_h1_l2', 'authSide_prof_h1_em'),
                const SizedBox(height: 16),
                Text(_t(context, 'authSide_prof_p'), style: _kAuthMktBodyStyle),
                const SizedBox(height: 36),
                V26AuthFeatureLine(
                  icon: Icons.phone_in_talk_outlined,
                  title: _t(context, 'authSide_prof_f1t'),
                  body: _t(context, 'authSide_prof_f1b'),
                ),
                const SizedBox(height: 18),
                V26AuthFeatureLine(
                  icon: Icons.login_rounded,
                  title: _t(context, 'authSide_prof_f2t'),
                  body: _t(context, 'authSide_prof_f2b'),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      case _Step.otp:
        return V26AuthNavyPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      V26AuthBrandRow(tagline: _t(context, 'brandTagline')),
                      const SizedBox(height: 40),
                      _authMarketingHeadline(context, 'authSide_otp_h1_l1',
                          'authSide_otp_h1_l2', 'authSide_otp_h1_em'),
                      const SizedBox(height: 16),
                      Text(_t(context, 'authSide_otp_p'),
                          style: _kAuthMktBodyStyle),
                    ],
                  ),
                ),
              ),
              V26AuthQuote(
                quote: _t(context, 'authSide_otp_q'),
                initials: _t(context, 'authSide_otp_qi'),
                name: _t(context, 'authSide_otp_qn'),
                role: _t(context, 'authSide_otp_qr'),
              ),
            ],
          ),
        );
    }
  }
}

class _LoginStepperDots extends StatelessWidget {
  final int stepIndex;
  final List<String> labels;

  const _LoginStepperDots({
    required this.stepIndex,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          _LoginStepDotCluster(
            index: i,
            stepIndex: stepIndex,
            label: labels[i],
          ),
          if (i < labels.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  height: 1,
                  color: stepIndex > i ? V26.ok : V26.hairline,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _LoginStepDotCluster extends StatelessWidget {
  final int index;
  final int stepIndex;
  final String label;

  const _LoginStepDotCluster({
    required this.index,
    required this.stepIndex,
    required this.label,
  });

  bool get done => stepIndex > index;
  bool get active => stepIndex == index;

  @override
  Widget build(BuildContext context) {
    final showCheck = done;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: showCheck ? V26.ok : (active ? VetoMockup.primaryCta : V26.paper2),
            border: Border.all(
              color: showCheck ? V26.ok : (active ? VetoMockup.primaryCta : V26.hairline),
              width: 1,
            ),
          ),
          child: Text(
            showCheck ? '✓' : '${index + 1}',
            style: TextStyle(
              fontFamily: V26.sans,
              fontSize: showCheck ? 11 : 12,
              fontWeight: FontWeight.w800,
              height: 1,
              color: showCheck || active ? Colors.white : V26.ink500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: V26.sans,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? V26.ink900 : (done ? V26.ink500 : V26.ink300),
          ),
        ),
      ],
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
        color: V26.paper2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: V26.hairline),
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(V26.rSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? V26.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(V26.rSm),
            boxShadow: selected ? V26.shadow1 : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: V26.sans,
              color: selected ? VetoMockup.primaryCtaDeep : V26.ink500,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(V26.rLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [V26.surface, Color(0xFFF4F8FF)],
                )
              : null,
          color: selected ? null : V26.surface,
          borderRadius: BorderRadius.circular(V26.rLg),
          border: Border.all(
            color: selected ? VetoMockup.primaryCta : V26.hairline,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: VetoMockup.primaryCta.withValues(alpha: 0.12),
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                  ...V26.shadow1,
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: selected
                          ? [VetoMockup.primaryCta, VetoMockup.primaryCta]
                          : [V26.navy100, V26.surface],
                    ),
                    border: Border.all(
                      color: selected ? VetoMockup.primaryCta : V26.hairline,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected ? Colors.white : VetoMockup.primaryCtaDeep,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: V26.serif,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: V26.ink900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    color: V26.ink500,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            if (selected)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: VetoMockup.primaryCta,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VetoField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputAction action;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  const _VetoField({
    required this.controller, required this.label,
    required this.icon, required this.action,
    this.hint, this.keyboardType, this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: action,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        fontFamily: V26.sans,
        color: V26.ink900,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: VetoMockup.primaryCta,
      decoration: InputDecoration(
        filled: true,
        fillColor: V26.surface2,
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: V26.ink300),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(V26.rMd),
          borderSide: const BorderSide(color: V26.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(V26.rMd),
          borderSide: const BorderSide(color: V26.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(V26.rMd),
          borderSide: const BorderSide(color: VetoMockup.primaryCta, width: 1.5),
        ),
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
      Text(label,
          style: const TextStyle(
              color: V26.ink500,
              fontSize: 12,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: V26.paper2,
            borderRadius: BorderRadius.circular(V26.rMd),
            border: Border.all(color: V26.hairline),
          ),
          child: Text(
            countryCode,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontFamily: V26.sans,
              color: V26.ink900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.go,
          textDirection: TextDirection.ltr,
          maxLength: 10,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontFamily: V26.sans,
            color: V26.ink900,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: VetoMockup.primaryCta,
          decoration: InputDecoration(
            filled: true,
            fillColor: V26.surface2,
            hintText: hint,
            counterText: '',
            prefixIcon:
                const Icon(Icons.phone_iphone_rounded, size: 18, color: V26.ink300),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(V26.rMd),
              borderSide: const BorderSide(color: V26.hairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(V26.rMd),
              borderSide: const BorderSide(color: V26.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(V26.rMd),
              borderSide: const BorderSide(color: VetoMockup.primaryCta, width: 1.5),
            ),
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
      const Expanded(child: Divider(color: V26.hairline)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(label,
            style: const TextStyle(
                color: V26.ink300,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8)),
      ),
      const Expanded(child: Divider(color: V26.hairline)),
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
          color: V26.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: V26.hairline),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CustomPaint(painter: _GoogleLogoPainter()),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontFamily: V26.sans,
                  color: V26.ink900,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
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
        color: V26.emerg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: V26.emerg.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: V26.emerg, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: const TextStyle(color: V26.emerg, fontSize: 13, height: 1.4))),
      ]),
    );
  }
}

// ── OTP Code Dialog (with copy button) ───────────────────────

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
        backgroundColor: V26.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: V26.hairline),
        ),
        title: Text(_t(context, 'otpDialogTitle'),
            style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_t(context, 'otpDialogBody'),
              style: const TextStyle(color: V26.ink500, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: V26.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VetoMockup.primaryCta.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(widget.otp, style: const TextStyle(
                  color: VetoMockup.primaryCta, fontSize: 34,
                  fontWeight: FontWeight.w900, letterSpacing: 8)),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _copied
                    ? const Icon(Icons.check_circle_rounded,
                        key: ValueKey('check'), color: V26.ok, size: 24)
                    : IconButton(
                        key: const ValueKey('copy'),
                        icon: const Icon(Icons.copy_rounded,
                            color: VetoMockup.primaryCta, size: 22),
                        tooltip: _t(context, 'copyCode'),
                        onPressed: _copy,
                      ),
              ),
            ]),
          ),
          if (_copied) ...[
            const SizedBox(height: 8),
            Text(_t(context, 'copied'),
                style: const TextStyle(color: V26.ok, fontSize: 13)),
          ],
        ]),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t(context, 'understood')),
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
        backgroundColor: V26.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: V26.hairline),
        ),
        title: Row(children: [
          const Icon(Icons.hourglass_empty_rounded, color: V26.warn, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(_t(context, 'pendingTitle'),
              style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w800))),
        ]),
        content: Text(_t(context, 'pendingBody'),
            style: const TextStyle(color: V26.ink500, height: 1.6)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t(context, 'understood')),
          ),
        ],
      ),
    );
  }
}
