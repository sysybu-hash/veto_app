// ============================================================
//  LoginScreen — VETO 2026
//  Pixel-aligned with design_mockups/2026/login.html.
//  3 steps: role → profile (phone or Google) → OTP.
//
//  Behaviour preserved from legacy LoginScreen v3:
//    - Phone OTP: AuthService.requestOTPDetailed → verifyOTP
//    - Google: GIS via browser_bridge → AuthService.googleAuth
//    - Pending lawyer approval dialog
//    - Role-aware post-auth navigation
//    - VETO Flows SDK identification (web)
// ============================================================
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_tokens_2026.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';

const _kGoogleClientId =
    '752712664923-7loca49f7fggd514q8reljn93meatmrf.apps.googleusercontent.com';

enum _Step { role, profile, otp }

// ──────────────────────────────────────────────────────────
//  i18n (preserved from legacy login_screen.dart)
// ──────────────────────────────────────────────────────────
const _copy = <String, Map<String, String>>{
  'he': {
    'eyebrow': 'כניסה / הרשמה',
    'tagline': 'שכבת גישה אחת לכל תפקיד',
    'stepRole': 'תפקיד', 'stepProfile': 'פרטים', 'stepOtp': 'אימות',
    'chooseRole': 'איך נכנסים ל-VETO?',
    'chooseRoleBody': 'הבחירה שלך קובעת את הלוח, הזרימה ושפת העבודה.',
    'citizenTitle': 'אזרח',
    'citizenBody': 'הנחיה משפטית מיידית, AI, תרחישים, SOS ותיעוד ראיות.',
    'lawyerTitle': 'עורך דין',
    'lawyerBody': 'קבל התראות, שלוט בזמינות וטפל בתיקים בקונסולה.',
    'next': 'המשך', 'login': 'כניסה', 'register': 'הרשמה',
    'profileTitle': 'בוא ניצור לך חשבון',
    'profileBody': 'אנחנו צריכים שם וטלפון בלבד. ניתן גם להירשם דרך Google.',
    'fullName': 'שם מלא',
    'phoneLabel': 'מספר טלפון',
    'phoneHint': 'לדוגמה: 0501234567 או 5XXXXXXXX',
    'phoneHelp': 'נשלח אליך SMS עם קוד אימות חד-פעמי.',
    'back': 'חזרה', 'sendOtp': 'שלח קוד אימות →',
    'orDivider': 'או', 'googleBtn': 'המשך עם Google',
    'otpTitle': 'הזן את קוד האימות',
    'otpSentTo': 'שלחנו קוד בן 6 ספרות אל מספר הטלפון שלך:',
    'otpChange': 'שינוי', 'verify': 'אמת והמשך →',
    'invalidPhone': 'הזן מספר תקין בן 9–10 ספרות.',
    'missingName': 'הכנס שם מלא כדי להשלים את ההרשמה.',
    'registerFailed': 'לא ניתן ליצור את החשבון שלך. נסה שוב.',
    'otpFailed': 'לא ניתן לשלוח את הקוד.',
    'otpNotFound': 'לא נמצא חשבון עם מספר זה. עבור להרשמה.',
    'otpRateLimited': 'יותר מדי בקשות. המתן 10 דקות ונסה שוב.',
    'otpServer': 'השרת לא זמין כרגע.',
    'otpNetwork': 'לא ניתן להתחבר לשרת.',
    'systemError': 'שגיאה זמנית.',
    'otpInvalid': 'הקוד אינו תקין.',
    'otpIncomplete': 'הכנס את כל 6 הספרות.',
    'googleFailed': 'כניסה עם Google נכשלה.',
    'googleNotConfigured': 'Google Sign-In לא מוגדר.',
    'otpDialogTitle': 'קוד האימות שלך',
    'otpDialogBody': 'SMS אינו זמין. השתמש בקוד הזמני:',
    'understood': 'הבנתי',
    'pendingTitle': 'בקשת אישור נשלחה',
    'pendingBody': 'חשבון העו"ד שלך נוצר ונשלח לאדמין לבדיקה. תיודע כשיאושר.',
    'emailLabel': 'אימייל', 'emailHint': 'name@example.com',
    'pasteOtp': 'הדבק קוד מהקליפבורד',
    'haveAccount': 'יש לך כבר חשבון?',
    'signInLink': 'כניסה מהירה',
    'home': 'דף הבית',
    'privacyShort': 'פרטיות',
    'termsShort': 'תנאי שימוש',
    'sideHero1': 'שכבת הגישה',
    'sideHero2': 'שלך — לכל תפקיד',
    'sideBody': 'בחר אם אתה אזרח שמחפש הגנה, או עו"ד שמצטרף למשרד הדיגיטלי. הזרימה והמסך יתאימו לתפקיד.',
    'sideF1': 'חשבון אחד · כל המכשירים',
    'sideF1Body': 'אפליקציה במובייל, דפדפן בדסקטופ — נתונים מסונכרנים.',
    'sideF2': 'אבטחה ברמת בנק',
    'sideF2Body': 'OTP חד-פעמי, JWT, אחסון מקומי מוצפן.',
    'sideF3': 'שלוש שפות',
    'sideF3Body': 'עברית, אנגלית, רוסית — ממשק מלא.',
    'badgeStep': 'שאלה',
    'badgeOf': 'מתוך',
  },
  'en': {
    'eyebrow': 'Sign in / Sign up',
    'tagline': 'One access layer for every role',
    'stepRole': 'Role', 'stepProfile': 'Details', 'stepOtp': 'Verify',
    'chooseRole': 'How do you sign in to VETO?',
    'chooseRoleBody': 'Your choice sets the dashboard, the flow, and the working language.',
    'citizenTitle': 'Citizen',
    'citizenBody': 'Instant legal guidance, AI, scenarios, SOS, evidence.',
    'lawyerTitle': 'Lawyer',
    'lawyerBody': 'Receive alerts, manage availability, handle cases.',
    'next': 'Continue', 'login': 'Sign in', 'register': 'Sign up',
    'profileTitle': "Let's create your account",
    'profileBody': 'We only need your name and phone. You can also sign up with Google.',
    'fullName': 'Full name',
    'phoneLabel': 'Phone number',
    'phoneHint': 'e.g. 0501234567 or 5XXXXXXXX',
    'phoneHelp': 'A one-time SMS code will be sent.',
    'back': 'Back', 'sendOtp': 'Send code →',
    'orDivider': 'or', 'googleBtn': 'Continue with Google',
    'otpTitle': 'Enter your verification code',
    'otpSentTo': 'We sent a 6-digit code to your phone:',
    'otpChange': 'Change', 'verify': 'Verify and continue →',
    'invalidPhone': 'Enter a valid 9–10 digit number.',
    'missingName': 'Enter your full name.',
    'registerFailed': 'Could not create your account.',
    'otpFailed': 'Could not send the code.',
    'otpNotFound': 'No account with that number.',
    'otpRateLimited': 'Too many requests. Wait ~10 minutes.',
    'otpServer': 'Server unavailable.',
    'otpNetwork': 'Could not reach the server.',
    'systemError': 'Temporary error.',
    'otpInvalid': 'Code is invalid.',
    'otpIncomplete': 'Enter all 6 digits.',
    'googleFailed': 'Google sign-in failed.',
    'googleNotConfigured': 'Google Sign-In not configured.',
    'otpDialogTitle': 'Your verification code',
    'otpDialogBody': 'SMS is unavailable. Use this temporary code:',
    'understood': 'Got it',
    'pendingTitle': 'Approval pending',
    'pendingBody': 'Your lawyer account was sent to admin for review. You will be notified once approved.',
    'emailLabel': 'Email', 'emailHint': 'name@example.com',
    'pasteOtp': 'Paste from clipboard',
    'haveAccount': 'Already have an account?',
    'signInLink': 'Quick sign in',
    'home': 'Home',
    'privacyShort': 'Privacy', 'termsShort': 'Terms',
    'sideHero1': 'Your access layer',
    'sideHero2': 'for every role',
    'sideBody': 'Pick whether you are a citizen seeking protection, or a lawyer joining our digital practice. The flow adapts.',
    'sideF1': 'One account · all devices',
    'sideF1Body': 'Mobile app, desktop browser — synced.',
    'sideF2': 'Bank-grade security',
    'sideF2Body': 'OTP, JWT, encrypted local storage.',
    'sideF3': 'Three languages',
    'sideF3Body': 'Hebrew, English, Russian — full UI.',
    'badgeStep': 'Step',
    'badgeOf': 'of',
  },
  'ru': {
    'eyebrow': 'Вход / Регистрация',
    'tagline': 'Единый доступ для каждой роли',
    'stepRole': 'Роль', 'stepProfile': 'Данные', 'stepOtp': 'Подтверждение',
    'chooseRole': 'Как войти в VETO?',
    'chooseRoleBody': 'Ваш выбор задаёт интерфейс, сценарий и язык работы.',
    'citizenTitle': 'Гражданин',
    'citizenBody': 'Мгновенная помощь, AI, сценарии, SOS, доказательства.',
    'lawyerTitle': 'Адвокат',
    'lawyerBody': 'Получайте запросы, управляйте делами в консоли.',
    'next': 'Продолжить', 'login': 'Войти', 'register': 'Регистрация',
    'profileTitle': 'Создадим ваш аккаунт',
    'profileBody': 'Нужны только имя и телефон. Можно через Google.',
    'fullName': 'Полное имя',
    'phoneLabel': 'Номер телефона',
    'phoneHint': 'пр. 0501234567 или 5XXXXXXXX',
    'phoneHelp': 'Будет отправлен одноразовый SMS-код.',
    'back': 'Назад', 'sendOtp': 'Отправить код →',
    'orDivider': 'или', 'googleBtn': 'Продолжить с Google',
    'otpTitle': 'Введите код подтверждения',
    'otpSentTo': 'Мы отправили 6-значный код на номер:',
    'otpChange': 'Изменить', 'verify': 'Подтвердить →',
    'invalidPhone': 'Введите корректный номер из 9–10 цифр.',
    'missingName': 'Введите полное имя.',
    'registerFailed': 'Не удалось создать аккаунт.',
    'otpFailed': 'Не удалось отправить код.',
    'otpNotFound': 'Аккаунт не найден.',
    'otpRateLimited': 'Слишком много запросов. Подождите ~10 минут.',
    'otpServer': 'Сервер недоступен.',
    'otpNetwork': 'Не удалось подключиться.',
    'systemError': 'Временная ошибка.',
    'otpInvalid': 'Код недействителен.',
    'otpIncomplete': 'Введите все 6 цифр.',
    'googleFailed': 'Вход через Google не удался.',
    'googleNotConfigured': 'Google Sign-In не настроен.',
    'otpDialogTitle': 'Ваш код подтверждения',
    'otpDialogBody': 'SMS недоступен. Используйте временный код:',
    'understood': 'Понятно',
    'pendingTitle': 'Ожидание подтверждения',
    'pendingBody': 'Ваш аккаунт адвоката отправлен на проверку.',
    'emailLabel': 'Email', 'emailHint': 'name@example.com',
    'pasteOtp': 'Вставить из буфера',
    'haveAccount': 'Уже есть аккаунт?',
    'signInLink': 'Быстрый вход',
    'home': 'Главная',
    'privacyShort': 'Конфиденциальность', 'termsShort': 'Условия',
    'sideHero1': 'Ваш слой доступа',
    'sideHero2': 'для каждой роли',
    'sideBody': 'Выберите, гражданин вы или адвокат — поток адаптируется.',
    'sideF1': 'Один аккаунт · все устройства',
    'sideF1Body': 'Приложение и браузер — синхронизация.',
    'sideF2': 'Защита банковского уровня',
    'sideF2Body': 'OTP, JWT, зашифрованное хранилище.',
    'sideF3': 'Три языка',
    'sideF3Body': 'Иврит, английский, русский.',
    'badgeStep': 'Шаг',
    'badgeOf': 'из',
  },
};

String _t(String code, String key) {
  final c = AppLanguage.normalize(code);
  return _copy[c]?[key] ?? _copy['he']?[key] ?? key;
}

// ══════════════════════════════════════════════════════════
//  LoginScreen
// ══════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _Step _step = _Step.role;
  String _role = 'user';
  bool _registerMode = true;
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

  // ── Navigation helpers ────────────────────────────────
  Future<void> _navigateAfterAuth(Map<String, dynamic> data, String lang) async {
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

    // Flows SDK (web only): identify after success — see legacy notes for timeout reason.
    if (userId != null && userId.isNotEmpty) {
      if (kIsWeb) {
        Map<String, dynamic>? status;
        try {
          status = await browser_bridge
              .flowsSetUser(userId: userId, role: role, lang: preferredLanguage)
              .timeout(const Duration(seconds: 8));
        } on TimeoutException {
          status = null;
        } catch (_) {
          status = null;
        }
        if (!mounted) return;
        if (mounted && status != null && status['ok'] != true) {
          messenger?.showSnackBar(SnackBar(
            content: Text('Flows: ${status['error'] ?? 'unknown error'}'),
            duration: const Duration(seconds: 3),
          ));
        }
      } else {
        browser_bridge.callBrowserMethod('vetoFlows', 'setUser', [userId, role, preferredLanguage]);
      }
    }

    if (!mounted) return;
    if (role == 'lawyer') {
      Navigator.of(context).pushReplacementNamed('/lawyer_dashboard');
    } else if (role == 'admin') {
      Navigator.of(context).pushReplacementNamed('/admin_settings');
    } else {
      Navigator.of(context).pushReplacementNamed('/veto_screen');
    }
  }

  String _messageForOtpRequestFailure(String lang, String? result) {
    if (result == null || result == 'error') return _t(lang, 'otpNetwork');
    if (result.startsWith('error|')) {
      final parts = result.split('|');
      if (parts.length >= 3) {
        final code = int.tryParse(parts[1]);
        final server = parts.sublist(2).join('|').trim();
        if (code == 404) return _t(lang, 'otpNotFound');
        if (code == 429) return _t(lang, 'otpRateLimited');
        if (code != null && code >= 500) return _t(lang, 'otpServer');
        if (server.isNotEmpty) return server;
      }
    }
    if (result.startsWith('error:')) {
      final code = int.tryParse(result.substring('error:'.length));
      if (code == 404) return _t(lang, 'otpNotFound');
      if (code == 429) return _t(lang, 'otpRateLimited');
      if (code != null && code >= 500) return _t(lang, 'otpServer');
    }
    return _t(lang, 'otpFailed');
  }

  // ── Phone flow ────────────────────────────────────────
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
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        );
        if (!ok) {
          setState(() { _loading = false; _error = _t(lang, 'registerFailed'); });
          return;
        }
      }

      final otp = await AuthService().requestOTPDetailed(_fullPhone, _role);
      if (!mounted) return;
      if (otp == 'error' || (otp != null && (otp.startsWith('error:') || otp.startsWith('error|')))) {
        setState(() { _loading = false; _error = _messageForOtpRequestFailure(lang, otp); });
        return;
      }
      setState(() { _loading = false; _step = _Step.otp; });
      if (otp != null && otp.isNotEmpty) {
        await showDialog<void>(context: context, builder: (_) => _OtpCodeDialog(code: lang, otp: otp));
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
        await showDialog<void>(context: context, builder: (_) => _PendingApprovalDialog(code: lang));
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

  Future<void> _signInWithGoogle() async {
    final lang = context.read<AppLanguageController>().code;
    setState(() { _loading = true; _error = ''; });
    try {
      final accessToken = await browser_bridge.googleSignInViaGIS(_kGoogleClientId);
      final data = await AuthService().googleAuth(accessToken: accessToken, language: lang);
      if (!mounted) return;
      if (data == null) {
        setState(() { _loading = false; _error = _t(lang, 'googleFailed'); });
        return;
      }
      await _navigateAfterAuth(data, lang);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = _t(lang, 'googleFailed'); });
    }
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageController>().code;
    final dir  = AppLanguage.directionOf(lang);
    final w    = MediaQuery.of(context).size.width;
    final compact = w < 900;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: VetoTokens.paper,
        body: SafeArea(
          child: compact
              ? _MobileLayout(
                  step: _step, role: _role, registerMode: _registerMode, loading: _loading,
                  error: _error,
                  fullPhone: _fullPhone,
                  ctrlName: _nameCtrl, ctrlPhone: _phoneCtrl, ctrlEmail: _emailCtrl, ctrlOtp: _otpCtrl,
                  onRoleChange: (r) => setState(() => _role = r),
                  onModeChange: (m) => setState(() { _registerMode = m; _error = ''; }),
                  onNext: () => setState(() => _step = _Step.profile),
                  onBack: () => setState(() {
                    _step = _step == _Step.otp ? _Step.profile : _Step.role;
                    _error = '';
                  }),
                  onContinue: _continueFromProfile,
                  onSubmitOtp: _submitOtp,
                  onGoogle: _signInWithGoogle,
                  onPasteOtp: _pasteOtp,
                  lang: lang,
                )
              : _DesktopLayout(
                  step: _step, role: _role, registerMode: _registerMode, loading: _loading,
                  error: _error,
                  fullPhone: _fullPhone,
                  ctrlName: _nameCtrl, ctrlPhone: _phoneCtrl, ctrlEmail: _emailCtrl, ctrlOtp: _otpCtrl,
                  onRoleChange: (r) => setState(() => _role = r),
                  onModeChange: (m) => setState(() { _registerMode = m; _error = ''; }),
                  onNext: () => setState(() => _step = _Step.profile),
                  onBack: () => setState(() {
                    _step = _step == _Step.otp ? _Step.profile : _Step.role;
                    _error = '';
                  }),
                  onContinue: _continueFromProfile,
                  onSubmitOtp: _submitOtp,
                  onGoogle: _signInWithGoogle,
                  onPasteOtp: _pasteOtp,
                  lang: lang,
                ),
        ),
      ),
    );
  }

  Future<void> _pasteOtp() async {
    final data = await Clipboard.getData('text/plain');
    final txt = data?.text?.trim() ?? '';
    final digits = txt.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      _otpCtrl.text = digits.substring(0, 6);
      await _verifyOtp(_otpCtrl.text);
    }
  }
}

// ──────────────────────────────────────────────────────────
//  Desktop layout — left dark panel + right form column
// ──────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.step, required this.role, required this.registerMode,
    required this.loading, required this.error, required this.fullPhone,
    required this.ctrlName, required this.ctrlPhone, required this.ctrlEmail, required this.ctrlOtp,
    required this.onRoleChange, required this.onModeChange,
    required this.onNext, required this.onBack, required this.onContinue,
    required this.onSubmitOtp, required this.onGoogle, required this.onPasteOtp,
    required this.lang,
  });
  final _Step step;
  final String role;
  final bool registerMode;
  final bool loading;
  final String error;
  final String fullPhone;
  final TextEditingController ctrlName, ctrlPhone, ctrlEmail, ctrlOtp;
  final ValueChanged<String> onRoleChange;
  final ValueChanged<bool> onModeChange;
  final VoidCallback onNext, onBack, onContinue, onSubmitOtp, onGoogle, onPasteOtp;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Dark side panel
        Expanded(flex: 21, child: _SidePanel(lang: lang)),
        // Form panel
        Expanded(flex: 19, child: _FormColumn(
          step: step, role: role, registerMode: registerMode,
          loading: loading, error: error, fullPhone: fullPhone,
          ctrlName: ctrlName, ctrlPhone: ctrlPhone, ctrlEmail: ctrlEmail, ctrlOtp: ctrlOtp,
          onRoleChange: onRoleChange, onModeChange: onModeChange,
          onNext: onNext, onBack: onBack, onContinue: onContinue,
          onSubmitOtp: onSubmitOtp, onGoogle: onGoogle, onPasteOtp: onPasteOtp,
          lang: lang, compact: false,
        )),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.step, required this.role, required this.registerMode,
    required this.loading, required this.error, required this.fullPhone,
    required this.ctrlName, required this.ctrlPhone, required this.ctrlEmail, required this.ctrlOtp,
    required this.onRoleChange, required this.onModeChange,
    required this.onNext, required this.onBack, required this.onContinue,
    required this.onSubmitOtp, required this.onGoogle, required this.onPasteOtp,
    required this.lang,
  });
  final _Step step;
  final String role;
  final bool registerMode;
  final bool loading;
  final String error;
  final String fullPhone;
  final TextEditingController ctrlName, ctrlPhone, ctrlEmail, ctrlOtp;
  final ValueChanged<String> onRoleChange;
  final ValueChanged<bool> onModeChange;
  final VoidCallback onNext, onBack, onContinue, onSubmitOtp, onGoogle, onPasteOtp;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return _FormColumn(
      step: step, role: role, registerMode: registerMode,
      loading: loading, error: error, fullPhone: fullPhone,
      ctrlName: ctrlName, ctrlPhone: ctrlPhone, ctrlEmail: ctrlEmail, ctrlOtp: ctrlOtp,
      onRoleChange: onRoleChange, onModeChange: onModeChange,
      onNext: onNext, onBack: onBack, onContinue: onContinue,
      onSubmitOtp: onSubmitOtp, onGoogle: onGoogle, onPasteOtp: onPasteOtp,
      lang: lang, compact: true,
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Side panel (desktop only) — navy gradient + value prop
// ──────────────────────────────────────────────────────────
class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(56, 48, 56, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.7, -1), end: Alignment(0.9, 1),
          colors: [VetoTokens.navy700, VetoTokens.navy600],
        ),
      ),
      child: Stack(
        children: [
          // Gold radial accent
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.9, -0.7),
                    radius: 0.85,
                    colors: [Color(0x33B8895C), Color(0x00B8895C)],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand
              Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0x2EFFFFFF), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text('V', style: VetoTokens.serif(15, FontWeight.w900, color: Colors.white, height: 1.0)),
                ),
                const SizedBox(width: 10),
                Text('VETO', style: VetoTokens.serif(18, FontWeight.w900, color: Colors.white, letterSpacing: 0.36)),
                const SizedBox(width: 6),
                Text(_t(lang, 'tagline'), style: VetoTokens.sans(11, FontWeight.w500, color: const Color(0xFFB6D2FB), letterSpacing: 1.76)),
              ]),
              const SizedBox(height: 48),
              RichText(
                text: TextSpan(
                  style: VetoTokens.serif(42, FontWeight.w800, color: Colors.white, height: 1.1),
                  children: [
                    TextSpan(text: '${_t(lang, 'sideHero1')}\n'),
                    TextSpan(text: _t(lang, 'sideHero2'), style: VetoTokens.serif(42, FontWeight.w800, color: VetoTokens.goldSoft, height: 1.1)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 460,
                child: Text(_t(lang, 'sideBody'), style: VetoTokens.sans(15, FontWeight.w500, color: const Color(0xFFC7D5EE), height: 1.7)),
              ),
              const SizedBox(height: 36),
              _SideFeature(icon: Icons.check_circle_outline_rounded, title: _t(lang, 'sideF1'), body: _t(lang, 'sideF1Body')),
              const SizedBox(height: 18),
              _SideFeature(icon: Icons.lock_outline_rounded, title: _t(lang, 'sideF2'), body: _t(lang, 'sideF2Body')),
              const SizedBox(height: 18),
              _SideFeature(icon: Icons.public_rounded, title: _t(lang, 'sideF3'), body: _t(lang, 'sideF3Body')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideFeature extends StatelessWidget {
  const _SideFeature({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            border: Border.all(color: const Color(0x24FFFFFF), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: const Color(0xFFB6D2FB)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: VetoTokens.sans(14, FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 2),
              Text(body, style: VetoTokens.sans(13, FontWeight.w500, color: const Color(0xFFC7D5EE), height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Form column (used on both layouts)
// ──────────────────────────────────────────────────────────
class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.step, required this.role, required this.registerMode,
    required this.loading, required this.error, required this.fullPhone,
    required this.ctrlName, required this.ctrlPhone, required this.ctrlEmail, required this.ctrlOtp,
    required this.onRoleChange, required this.onModeChange,
    required this.onNext, required this.onBack, required this.onContinue,
    required this.onSubmitOtp, required this.onGoogle, required this.onPasteOtp,
    required this.lang, required this.compact,
  });
  final _Step step;
  final String role;
  final bool registerMode;
  final bool loading;
  final String error;
  final String fullPhone;
  final TextEditingController ctrlName, ctrlPhone, ctrlEmail, ctrlOtp;
  final ValueChanged<String> onRoleChange;
  final ValueChanged<bool> onModeChange;
  final VoidCallback onNext, onBack, onContinue, onSubmitOtp, onGoogle, onPasteOtp;
  final String lang;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 56, vertical: compact ? 24 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Topbar — back link + lang menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (step == _Step.role)
                _BackChip(label: _t(lang, 'home'), onPressed: () => Navigator.of(context).pushReplacementNamed('/landing'))
              else
                _BackChip(label: _t(lang, 'back'), onPressed: onBack),
              const AppLanguageMenu(compact: true),
            ],
          ),
          const SizedBox(height: 28),
          _Stepper(step: step.index, lang: lang),
          const SizedBox(height: 24),

          Container(
            padding: EdgeInsets.all(compact ? 24 : 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(VetoTokens.r2Xl),
              border: Border.all(color: VetoTokens.hairline, width: 1),
              boxShadow: VetoTokens.shadow2,
            ),
            child: AnimatedSwitcher(
              duration: VetoTokens.durBase,
              switchInCurve: VetoTokens.ease,
              switchOutCurve: VetoTokens.ease,
              child: switch (step) {
                _Step.role => _RoleStep(
                  key: const ValueKey('role'),
                  role: role, lang: lang, onRoleChange: onRoleChange, onNext: onNext,
                ),
                _Step.profile => _ProfileStep(
                  key: const ValueKey('profile'),
                  role: role, registerMode: registerMode, loading: loading,
                  ctrlName: ctrlName, ctrlPhone: ctrlPhone, ctrlEmail: ctrlEmail,
                  onModeChange: onModeChange, onContinue: onContinue, onGoogle: onGoogle,
                  lang: lang,
                ),
                _Step.otp => _OtpStep(
                  key: const ValueKey('otp'),
                  fullPhone: fullPhone, ctrlOtp: ctrlOtp, loading: loading,
                  onChange: onBack, onSubmit: onSubmitOtp, onPaste: onPasteOtp,
                  lang: lang,
                ),
              },
            ),
          ),

          if (error.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: error),
          ],

          const SizedBox(height: 24),
          // Footer links
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/privacy'),
                child: Text(_t(lang, 'privacyShort'), style: VetoTokens.sans(12, FontWeight.w600, color: VetoTokens.ink500)),
              ),
              Text('·', style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink300)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/terms'),
                child: Text(_t(lang, 'termsShort'), style: VetoTokens.sans(12, FontWeight.w600, color: VetoTokens.ink500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackChip extends StatelessWidget {
  const _BackChip({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
      label: Text(label, style: VetoTokens.labelMd.copyWith(color: VetoTokens.ink700)),
      style: TextButton.styleFrom(
        foregroundColor: VetoTokens.ink700,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Stepper
// ──────────────────────────────────────────────────────────
class _Stepper extends StatelessWidget {
  const _Stepper({required this.step, required this.lang});
  final int step;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final labels = [_t(lang, 'stepRole'), _t(lang, 'stepProfile'), _t(lang, 'stepOtp')];
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          _StepDot(idx: i, current: step, label: labels[i]),
          if (i < 2)
            Expanded(child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: i < step ? VetoTokens.ok : VetoTokens.hairline,
            )),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.idx, required this.current, required this.label});
  final int idx, current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final done = idx < current;
    final active = idx == current;
    final (bg, fg, border) = done
        ? (VetoTokens.ok, Colors.white, VetoTokens.ok)
        : active
            ? (VetoTokens.navy600, Colors.white, VetoTokens.navy600)
            : (VetoTokens.paper2, VetoTokens.ink500, VetoTokens.hairline);
    return Row(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: border, width: 1)),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text('${idx + 1}', style: VetoTokens.sans(12, FontWeight.w800, color: fg)),
        ),
        const SizedBox(width: 8),
        Text(label, style: VetoTokens.sans(12, FontWeight.w700, color: active ? VetoTokens.ink900 : VetoTokens.ink500)),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Step 1 — role
// ──────────────────────────────────────────────────────────
class _RoleStep extends StatelessWidget {
  const _RoleStep({super.key, required this.role, required this.lang, required this.onRoleChange, required this.onNext});
  final String role, lang;
  final ValueChanged<String> onRoleChange;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_t(lang, 'eyebrow').toUpperCase(), style: VetoTokens.kicker),
        const SizedBox(height: 8),
        Text(_t(lang, 'chooseRole'), style: VetoTokens.headlineMd.copyWith(color: VetoTokens.ink900)),
        const SizedBox(height: 8),
        Text(_t(lang, 'chooseRoleBody'), style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink500)),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (ctx, c) {
            final twoCol = c.maxWidth > 380;
            final cards = [
              _RoleCard(
                selected: role == 'user',
                icon: Icons.person_outline_rounded,
                title: _t(lang, 'citizenTitle'),
                body: _t(lang, 'citizenBody'),
                onTap: () => onRoleChange('user'),
              ),
              _RoleCard(
                selected: role == 'lawyer',
                icon: Icons.gavel_rounded,
                title: _t(lang, 'lawyerTitle'),
                body: _t(lang, 'lawyerBody'),
                onTap: () => onRoleChange('lawyer'),
              ),
            ];
            return twoCol
                ? Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])])
                : Column(children: [cards[0], const SizedBox(height: 12), cards[1]]);
          },
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: VetoTokens.navy600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: VetoTokens.labelLg,
            ),
            child: Text('${_t(lang, 'next')} →'),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.selected, required this.icon, required this.title, required this.body, required this.onTap});
  final bool selected;
  final IconData icon;
  final String title, body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VetoTokens.rLg),
      child: AnimatedContainer(
        duration: VetoTokens.durBase,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF4F8FF)])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(VetoTokens.rLg),
          border: Border.all(color: selected ? VetoTokens.navy600 : VetoTokens.hairline, width: 2),
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x1F2E69E7), blurRadius: 0, spreadRadius: 4), ...VetoTokens.shadow1]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: selected ? VetoTokens.crestGradient : null,
                    color: selected ? null : VetoTokens.navy100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? VetoTokens.navy600 : VetoTokens.hairline, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: selected ? Colors.white : VetoTokens.navy700),
                ),
                const SizedBox(height: 14),
                Text(title, style: VetoTokens.serif(18, FontWeight.w700, color: VetoTokens.ink900)),
                const SizedBox(height: 4),
                Text(body, style: VetoTokens.sans(13, FontWeight.w500, color: VetoTokens.ink500, height: 1.5)),
              ],
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(color: VetoTokens.navy600, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Step 2 — profile (phone + name) or Google
// ──────────────────────────────────────────────────────────
class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    super.key, required this.role, required this.registerMode, required this.loading,
    required this.ctrlName, required this.ctrlPhone, required this.ctrlEmail,
    required this.onModeChange, required this.onContinue, required this.onGoogle,
    required this.lang,
  });
  final String role;
  final bool registerMode;
  final bool loading;
  final TextEditingController ctrlName, ctrlPhone, ctrlEmail;
  final ValueChanged<bool> onModeChange;
  final VoidCallback onContinue, onGoogle;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_t(lang, 'eyebrow').toUpperCase(), style: VetoTokens.kicker),
        const SizedBox(height: 8),
        Text(_t(lang, 'profileTitle'), style: VetoTokens.headlineMd.copyWith(color: VetoTokens.ink900)),
        const SizedBox(height: 8),
        Text(_t(lang, 'profileBody'), style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink500)),
        const SizedBox(height: 22),

        // Login/Register tabs (subtle pill)
        _ModePill(
          loginLabel: _t(lang, 'login'), registerLabel: _t(lang, 'register'),
          isRegister: registerMode, onChanged: onModeChange,
        ),
        const SizedBox(height: 18),

        if (registerMode) ...[
          _Field(label: _t(lang, 'fullName'), controller: ctrlName, icon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _Field(label: _t(lang, 'emailLabel'), hint: _t(lang, 'emailHint'), controller: ctrlEmail, icon: Icons.email_outlined),
          const SizedBox(height: 14),
        ],
        _Field(
          label: _t(lang, 'phoneLabel'), hint: _t(lang, 'phoneHint'),
          controller: ctrlPhone, icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          help: _t(lang, 'phoneHelp'),
          ltr: true,
        ),
        const SizedBox(height: 18),

        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: loading ? null : onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: VetoTokens.navy600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: VetoTokens.labelLg,
            ),
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_t(lang, 'sendOtp')),
          ),
        ),
        const SizedBox(height: 20),
        _OrDivider(label: _t(lang, 'orDivider')),
        const SizedBox(height: 14),
        _GoogleButton(label: _t(lang, 'googleBtn'), loading: loading, onTap: onGoogle),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.loginLabel, required this.registerLabel, required this.isRegister, required this.onChanged});
  final String loginLabel, registerLabel;
  final bool isRegister;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: VetoTokens.paper2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VetoTokens.hairline, width: 1),
      ),
      child: Row(
        children: [
          Expanded(child: _modeBtn(registerLabel, isRegister, () => onChanged(true))),
          Expanded(child: _modeBtn(loginLabel, !isRegister, () => onChanged(false))),
        ],
      ),
    );
  }

  Widget _modeBtn(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: VetoTokens.durBase,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected ? VetoTokens.shadow1 : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: VetoTokens.labelMd.copyWith(color: selected ? VetoTokens.navy700 : VetoTokens.ink500)),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label, required this.controller, this.hint, this.icon,
    this.keyboardType, this.help, this.ltr = false,
  });
  final String label;
  final String? hint;
  final IconData? icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? help;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VetoTokens.sans(12, FontWeight.w700, color: VetoTokens.ink700, letterSpacing: 0.4)),
        const SizedBox(height: 6),
        Directionality(
          textDirection: ltr ? TextDirection.ltr : Directionality.of(context),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: icon == null ? null : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(icon, size: 16, color: VetoTokens.ink300),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink900),
          ),
        ),
        if (help != null) ...[
          const SizedBox(height: 6),
          Text(help!, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
        ],
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: VetoTokens.hairline, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label.toUpperCase(), style: VetoTokens.kicker.copyWith(color: VetoTokens.ink300, letterSpacing: 1.98)),
        ),
        const Expanded(child: Divider(color: VetoTokens.hairline, thickness: 1)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.loading, required this.onTap});
  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onTap,
        icon: const _GoogleIcon(),
        label: Text(label, style: VetoTokens.labelLg.copyWith(color: VetoTokens.ink900)),
        style: OutlinedButton.styleFrom(
          foregroundColor: VetoTokens.ink900,
          backgroundColor: Colors.white,
          side: const BorderSide(color: VetoTokens.hairline, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // Quartered "G" using simple coloured circle. Real GIS button SVG isn't available without
    // an asset; this stays brand-neutral and accessible. Replace with proper SVG in a future pass.
    return Container(
      width: 18, height: 18,
      decoration: const BoxDecoration(
        gradient: SweepGradient(
          colors: [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4), Color(0xFFEA4335)],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Step 3 — OTP
// ──────────────────────────────────────────────────────────
class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key, required this.fullPhone, required this.ctrlOtp, required this.loading,
    required this.onChange, required this.onSubmit, required this.onPaste, required this.lang,
  });
  final String fullPhone;
  final TextEditingController ctrlOtp;
  final bool loading;
  final VoidCallback onChange, onSubmit, onPaste;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final pinTheme = PinTheme(
      width: 46, height: 54,
      textStyle: VetoTokens.serif(22, FontWeight.w800, color: VetoTokens.ink900),
      decoration: BoxDecoration(
        color: VetoTokens.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VetoTokens.navy300, width: 1),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_t(lang, 'eyebrow').toUpperCase(), style: VetoTokens.kicker),
        const SizedBox(height: 8),
        Text(_t(lang, 'otpTitle'), style: VetoTokens.headlineMd.copyWith(color: VetoTokens.ink900)),
        const SizedBox(height: 8),
        Text(_t(lang, 'otpSentTo'), style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink500)),
        const SizedBox(height: 14),

        // Phone target row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: VetoTokens.surface2,
            border: Border.all(color: VetoTokens.hairline, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: VetoTokens.navy100, borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: const Icon(Icons.phone_outlined, size: 16, color: VetoTokens.navy700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(fullPhone, style: VetoTokens.sans(14, FontWeight.w700, color: VetoTokens.ink900)),
                ),
              ),
              TextButton(onPressed: onChange, child: Text(_t(lang, 'otpChange'), style: VetoTokens.labelMd)),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Center(child: Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
            controller: ctrlOtp,
            length: 6,
            defaultPinTheme: pinTheme,
            focusedPinTheme: pinTheme.copyWith(
              decoration: pinTheme.decoration?.copyWith(
                border: Border.all(color: VetoTokens.navy500, width: 1.5),
                color: Colors.white,
              ),
            ),
            onChanged: (_) {},
            onCompleted: (_) => onSubmit(),
          ),
        )),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: loading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: VetoTokens.navy600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: VetoTokens.labelLg,
            ),
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_t(lang, 'verify')),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: OutlinedButton.icon(
            onPressed: onPaste,
            icon: const Icon(Icons.content_paste_rounded, size: 14),
            label: Text(_t(lang, 'pasteOtp')),
            style: OutlinedButton.styleFrom(
              foregroundColor: VetoTokens.ink700,
              side: const BorderSide(color: VetoTokens.hairline, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: VetoTokens.labelMd,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Misc
// ──────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: VetoTokens.emergBg,
        border: Border.all(color: VetoTokens.emergBorder, width: 1),
        borderRadius: BorderRadius.circular(VetoTokens.rMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: VetoTokens.emerg, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: VetoTokens.bodySm.copyWith(color: const Color(0xFF7A2A12), fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _OtpCodeDialog extends StatelessWidget {
  const _OtpCodeDialog({required this.code, required this.otp});
  final String code;
  final String otp;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_t(code, 'otpDialogTitle'), style: VetoTokens.titleLg),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t(code, 'otpDialogBody'), style: VetoTokens.bodyMd),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: VetoTokens.paper2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VetoTokens.hairline),
            ),
            child: Row(
              children: [
                Expanded(child: Text(otp, style: VetoTokens.serif(22, FontWeight.w800, color: VetoTokens.ink900, letterSpacing: 4))),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: otp));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(code, 'understood'))));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: VetoTokens.navy600),
          child: Text(_t(code, 'understood')),
        ),
      ],
    );
  }
}

class _PendingApprovalDialog extends StatelessWidget {
  const _PendingApprovalDialog({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: VetoTokens.warnSoft, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: const Icon(Icons.hourglass_empty_rounded, color: VetoTokens.warn, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(_t(code, 'pendingTitle'), style: VetoTokens.titleLg)),
      ]),
      content: Text(_t(code, 'pendingBody'), style: VetoTokens.bodyMd),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: VetoTokens.navy600),
          child: Text(_t(code, 'understood')),
        ),
      ],
    );
  }
}
