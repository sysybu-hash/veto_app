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
import '../core/theme/veto_glass_system.dart';
import '../core/theme/veto_theme.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';

// ?? Google Sign-In singleton ??????????????????????????????????
// Replace 'YOUR_GOOGLE_CLIENT_ID' after creating credentials in
// Google Cloud Console ? APIs & Services ? Credentials (Web client).
// The same ID must also be set in GOOGLE_CLIENT_ID on the backend.
const _kGoogleClientId =
    '752712664923-7loca49f7fggd514q8reljn93meatmrf.apps.googleusercontent.com';

enum _Step { role, profile, otp }

// ?????????????????????????????????????????????????????????????
//  Translations
// ?????????????????????????????????????????????????????????????
const _copy = <String, Map<String, String>>{
  'he': {
    'eyebrow': 'כניסה / הרשמה',
    'tagline': 'שכבת גישה אחת לכל תפקיד',
    'stepRole': 'תפקיד',
    'stepProfile': 'פרטים',
    'stepOtp': 'אימות',
    'chooseRole': 'איך נכנסים ל-VETO?',
    'chooseRoleBody': 'הבחירה שלך קובעת את הלוח, הזרימה ושפת העבודה.',
    'citizenTitle': 'אזרח',
    'citizenBody': 'הנחיה משפטית מידית, AI, תרחישים, SOS ותיעוד ראיות.',
    'lawyerTitle': 'עורך דין',
    'lawyerBody': 'קבל התראות, שלוט בזמינות וטפל בתיקים בקונסולה.',
    'next': 'המשך',
    'login': 'כניסה',
    'register': 'הרשמה',
    'profileTitle': 'פרטי חשבון',
    'fullName': 'שם מלא',
    'phoneLabel': 'מספר טלפון',
    'phoneHint': 'לדוגמה: 0501234567 או 5XXXXXXXX',
    'back': 'חזרה',
    'sendOtp': 'שלח קוד',
    'orDivider': 'או',
    'googleBtn': 'המשך עם Google',
    'otpTitle': 'אימות טלפון',
    'otpSentTo': 'הקוד נשלח ל-',
    'copyCode': 'העתק קוד',
    'copied': 'הועתק!',
    'verify': 'אמת והמשך',
    'emailLabel': 'כתובת אימייל',
    'emailHint': 'name@example.com',
    'pasteOtp': 'הדבק קוד',
    'missingName': 'הכנס שם מלא כדי להשלים את ההרשמה.',
    'registerFailed': 'לא ניתן ליצור את החשבון שלך. נסה שוב.',
    'otpFailed': 'לא ניתן לשלוח את הקוד. ודא שהחשבון קיים או עבור להרשמה.',
    'otpNotFound': 'לא נמצא חשבון עם מספר זה. עבור להרשמה או בדוק את המספר.',
    'otpRateLimited': 'נשלחו יותר מדי בקשות לקוד בזמן קצר. המתן כ-10 דקות ונסה שוב.',
    'otpServer': 'השרת לא זמין כרגע. נסה שוב בעוד רגע.',
    'otpNetwork': 'לא ניתן להתחבר לשרת. ודא שה-API רץ (למשל פורט 5001) ושהכתובת נכונה.',
    'systemError': 'שגיאה זמנית. נסה שוב.',
    'otpInvalid': 'הקוד אינו תקין.',
    'otpIncomplete': 'הכנס את כל 6 הספרות.',
    'googleFailed': 'כניסה עם Google נכשלה. נסה שוב.',
    'googleNotConfigured': 'Google Sign-In עדיין לא מוגדר. השתמש בטלפון.',
    'otpDialogTitle': 'קוד האימות שלך',
    'otpDialogBody': 'SMS אינו זמין כרגע. השתמש בקוד הזמני הזה:',
    'understood': 'הבנתי',
    'pendingTitle': 'ממתין לאישור',
    'pendingBody': 'חשבון עורך הדין שלך נוצר ונשלח לאדמין לבדיקה. תקבל הודעה לאחר אישור.',
    'subscriptionTitle': 'הפעל גישה מלאה ל-VETO',
    'subscriptionBody': 'נדרש מנוי חודשי. שיגור עורך דין חירום מחויב בנפרד בלבד כשאתה מפעיל אירוע חי.',
    'subscriptionPlan': 'מנוי חודשי',
    'subscriptionPrice': '₪19.90 / חודש',
    'subscriptionLine1': 'AI משפטי ללא הגבלה',
    'subscriptionLine2': 'גישה לתרחישים, זכויות וכלי ראיות',
    'subscriptionLine3': 'שיגור עורך דין חירום מחויב בנפרד',
    'later': 'אולי מאוחר יותר',
    'paypal': 'פתח PayPal',
    'paymentOpened': 'סיימת ב-PayPal? חזור כאן ואשר.',
    'paymentConfirm': 'אשר תשלום',
    'paymentOpenFailed': 'לא ניתן לפתוח PayPal כרגע.',
    'paymentConfirmFailed': 'התשלום טרם אושר. בדוק את לשונית ה-PayPal ונסה שוב.',
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
    'otpNotFound': 'No account was found for this phone number. Switch to registration or check the number.',
    'otpRateLimited': 'Too many code requests in a short time. Please wait about 10 minutes and try again.',
    'otpServer': 'The server is temporarily unavailable. Please try again in a moment.',
    'otpNetwork': 'Could not reach the server. Make sure the API is running (port 5001 locally) and the address is correct.',
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
    'emailLabel': 'Email address',
    'emailHint': 'name@example.com',
    'pasteOtp': 'Paste code',
  },
  'ru': {
    'eyebrow': 'Вход / Регистрация',
    'tagline': 'Единый доступ для каждой роли',
    'stepRole': 'Роль',
    'stepProfile': 'Данные',
    'stepOtp': 'Подтверждение',
    'chooseRole': 'Как войти в VETO?',
    'chooseRoleBody': 'Ваш выбор задаёт интерфейс, сценарий и язык работы.',
    'citizenTitle': 'Гражданин',
    'citizenBody': 'Мгновенная юридическая помощь, AI, сценарии, SOS и запись доказательств.',
    'lawyerTitle': 'Адвокат',
    'lawyerBody': 'Получайте запросы, управляйте доступностью и работайте с делами в консоли.',
    'next': 'Продолжить',
    'login': 'Войти',
    'register': 'Регистрация',
    'profileTitle': 'Данные аккаунта',
    'fullName': 'Полное имя',
    'phoneLabel': 'Номер телефона',
    'phoneHint': 'пр. 0501234567 или 5XXXXXXXX',
    'back': 'Назад',
    'sendOtp': 'Отправить код',
    'orDivider': 'или',
    'googleBtn': 'Продолжить с Google',
    'otpTitle': 'Подтверждение телефона',
    'otpSentTo': 'Код отправлен на ',
    'copyCode': 'Скопировать код',
    'copied': 'Скопировано!',
    'verify': 'Подтвердить и продолжить',
    'invalidPhone': 'Введите корректный номер из 9–10 цифр.',
    'missingName': 'Введите полное имя для завершения регистрации.',
    'registerFailed': 'Не удалось создать аккаунт. Попробуйте снова.',
    'otpFailed': 'Не удалось отправить код. Убедитесь, что аккаунт существует.',
    'otpNotFound': 'Аккаунт с таким номером не найден. Перейдите к регистрации или проверьте номер.',
    'otpRateLimited': 'Слишком много запросов кода за короткое время. Подождите около 10 минут и попробуйте снова.',
    'otpServer': 'Сервер временно недоступен. Попробуйте снова чуть позже.',
    'otpNetwork': 'Не удалось подключиться к серверу. Убедитесь, что API запущен (локально порт 5001) и адрес верный.',
    'systemError': 'Временная ошибка. Попробуйте снова.',
    'otpInvalid': 'Код недействителен.',
    'otpIncomplete': 'Введите все 6 цифр.',
    'googleFailed': 'Вход через Google не удался. Попробуйте снова.',
    'googleNotConfigured': 'Google Sign-In ещё не настроен. Используйте телефон.',
    'otpDialogTitle': 'Ваш код подтверждения',
    'otpDialogBody': 'SMS сейчас недоступен. Используйте этот временный код:',
    'understood': 'Понятно',
    'pendingTitle': 'Ожидание подтверждения',
    'pendingBody': 'Ваш аккаунт адвоката создан и отправлен администратору на проверку.',
    'subscriptionTitle': 'Активировать полный доступ к VETO',
    'subscriptionBody': 'Требуется ежемесячная подписка. Вызов адвоката оплачивается отдельно.',
    'subscriptionPlan': 'Ежемесячная подписка',
    'subscriptionPrice': '₪19.90 / месяц',
    'subscriptionLine1': 'Безлимитный юридический AI',
    'subscriptionLine2': 'Доступ к сценариям, правам и доказательствам',
    'subscriptionLine3': 'Вызов адвоката оплачивается отдельно',
    'later': 'Позже',
    'paypal': 'Открыть PayPal',
    'paymentOpened': 'Завершили в PayPal? Вернитесь и подтвердите.',
    'paymentConfirm': 'Подтвердить оплату',
    'paymentOpenFailed': 'PayPal сейчас недоступен.',
    'paymentConfirmFailed': 'Оплата ещё не подтверждена. Проверьте PayPal и попробуйте снова.',
    'emailLabel': 'Адрес электронной почты',
    'emailHint': 'name@example.com',
    'pasteOtp': 'Вставить код',
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
          final msg = lang == 'he'
              ? (ok
                  ? 'Flows: הופעל (${stage ?? ''}${key != null ? ' · $key' : ''})'
                  : 'Flows: נכשל (${err ?? 'unknown'})')
              : lang == 'ru'
                  ? (ok
                      ? 'Flows: OK (${stage ?? ''}${key != null ? ' · $key' : ''})'
                      : 'Flows: ошибка (${err ?? 'unknown'})')
                  : (ok
                      ? 'Flows: OK (${stage ?? ''}${key != null ? ' · $key' : ''})'
                      : 'Flows: failed (${err ?? 'unknown'})');
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
      Navigator.of(context).pushReplacementNamed('/veto_screen');
    }
  }

  String _messageForOtpRequestFailure(String lang, String? result) {
    if (result == null || result == 'error') {
      return _t(lang, 'otpNetwork');
    }

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
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        );
        if (!ok) {
          setState(() { _loading = false; _error = _t(lang, 'registerFailed'); });
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
          _error = _messageForOtpRequestFailure(lang, otp);
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
        setState(() { _loading = false; _error = _t(lang, 'googleFailed'); });
        return;
      }

      await _navigateAfterAuth(data, lang);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (mounted) {
        setState(() { _loading = false; _error = _t(lang, 'googleFailed'); });
      }
    }
  }

  // ?? Build ????????????????????????????????????????????????????
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageController>().code;
    final dir  = AppLanguage.directionOf(lang);
    // wide layout removed – always centered card

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: VetoGlassTokens.bgBase,
        body: VetoGlassAuroraBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: Column(children: [
                  // Top row: back home (start) + language (end)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back to landing
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/landing'),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: VetoGlassTokens.neonCyan),
                        label: Text(
                          lang == 'he' ? 'דף הבית' : lang == 'ru' ? 'Главная' : 'Home',
                          style: const TextStyle(color: VetoGlassTokens.neonCyan, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                      ),
                      const AppLanguageMenu(compact: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Frosted card on dark aurora — inner forms keep VetoPalette (dark ink on light frost)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: VetoGlassBlur(
                      borderRadius: 24,
                      sigma: VetoGlassTokens.blurSigma,
                      fill: VetoGlassTokens.glassFillStrong,
                      borderColor: VetoGlassTokens.glassBorderBright,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        // Shield icon + title
                        Column(children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: VetoGlassTokens.neonBlue.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.35), width: 1.5),
                            ),
                            child: const Icon(Icons.shield_rounded, color: VetoGlassTokens.neonBlue, size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang == 'he' ? 'ברוך הבא ל-VETO' : lang == 'ru' ? 'Добро пожаловать в VETO' : 'Welcome to VETO',
                            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 22, fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lang == 'he' ? 'הגנה משפטית בהישג יד' : lang == 'ru' ? 'Юридическая защита рядом' : 'Legal protection within reach',
                            style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                        const SizedBox(height: 28),
                        _StepIndicator(
                          step: _step.index,
                          labels: [_t(lang,'stepRole'), _t(lang,'stepProfile'), _t(lang,'stepOtp')],
                        ),
                        const SizedBox(height: 24),
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
                      ]),
                    ),
                  ),
                ),
                  const SizedBox(height: 20),
                  Text(
                    lang == 'he' ? '🔒 מאובטח עם הצפנה מקצה לקצה' : lang == 'ru' ? '🔒 Защищено сквозным шифрованием' : '🔒 Secured with end-to-end encryption',
                    style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ),
          ),
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
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(_t(lang, 'chooseRoleBody'),
            style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 13, height: 1.6)),
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
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        if (_registerMode) ...[
          _VetoField(
            controller: _nameCtrl,
            label: _t(lang, 'fullName'),
            icon: Icons.badge_outlined,
            action: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          _VetoField(
            controller: _emailCtrl,
            label: _t(lang, 'emailLabel'),
            hint: _t(lang, 'emailHint'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 12),
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
      textStyle: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VetoGlassTokens.glassBorder),
      ),
    );

    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_t(lang, 'otpTitle'),
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(_t(lang, 'otpSentTo'),
              style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 14)),
          const SizedBox(width: 4),
          Text(_fullPhone, textDirection: TextDirection.ltr,
              style: const TextStyle(color: VetoGlassTokens.neonCyan, fontSize: 14, fontWeight: FontWeight.w600)),
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
                border: Border.all(color: VetoGlassTokens.neonCyan, width: 1.5),
              ),
            ),
            onChanged: (_) { if (_error.isNotEmpty) setState(() => _error = ''); },
            onCompleted: _verifyOtp,
          ),
        )),
        const SizedBox(height: 8),
        // Paste from clipboard button
        Center(child: TextButton.icon(
          icon: const Icon(Icons.content_paste_rounded, size: 16),
          label: Text(_t(lang, 'pasteOtp'),
              style: const TextStyle(fontSize: 13)),
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            final text = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
            if (text.length >= 6) {
              final code = text.substring(0, 6);
              _otpCtrl.text = code;
              await _verifyOtp(code);
            }
          },
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

// ── Reusable widgets ───────────────────────────────────────

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
                  color: active ? VetoGlassTokens.neonCyan : VetoGlassTokens.glassBorder,
                ),
              ),
              const SizedBox(height: 6),
              Text(labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? VetoGlassTokens.neonCyan : VetoGlassTokens.textSubtle,
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
        color: VetoGlassTokens.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoGlassTokens.glassBorder),
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
          color: selected ? VetoGlassTokens.neonCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFF041018) : VetoGlassTokens.textMuted,
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
          color: selected
              ? VetoGlassTokens.neonCyan.withValues(alpha: 0.10)
              : VetoGlassTokens.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border(
                  // Flutter requires uniform border colors when borderRadius is set.
                  left: BorderSide(
                    color: VetoGlassTokens.neonCyan.withValues(alpha: 0.35),
                    width: 3,
                  ),
                  top: BorderSide(
                    color: VetoGlassTokens.neonCyan.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  right: BorderSide(
                    color: VetoGlassTokens.neonCyan.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: VetoGlassTokens.neonCyan.withValues(alpha: 0.35),
                    width: 1,
                  ),
                )
              : Border.all(color: VetoGlassTokens.glassBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: selected ? VetoGlassTokens.neonCyan : VetoGlassTokens.textMuted, size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(
              color: selected ? VetoGlassTokens.neonCyan : VetoGlassTokens.textPrimary,
              fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(
              color: VetoGlassTokens.textMuted, fontSize: 13, height: 1.5)),
        ]),
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
      style: const TextStyle(color: VetoGlassTokens.textPrimary),
      cursorColor: VetoGlassTokens.neonCyan,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: VetoGlassTokens.textMuted),
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
          color: VetoGlassTokens.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VetoGlassTokens.glassBorder),
          ),
          child: Text(countryCode, textDirection: TextDirection.ltr,
              style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.go,
          textDirection: TextDirection.ltr,
          maxLength: 10,
          onSubmitted: onSubmitted,
          style: const TextStyle(color: VetoGlassTokens.textPrimary),
          cursorColor: VetoGlassTokens.neonCyan,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 18, color: VetoGlassTokens.textMuted),
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
      const Expanded(child: Divider(color: VetoGlassTokens.glassBorder)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(label, style: const TextStyle(
            color: VetoGlassTokens.textSubtle, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      const Expanded(child: Divider(color: VetoGlassTokens.glassBorder)),
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
          color: VetoGlassTokens.glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VetoGlassTokens.glassBorder),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 22, height: 22,
            child: CustomPaint(painter: _GoogleLogoPainter()),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(
              color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
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
        backgroundColor: const Color(0xE6121824),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VetoGlassTokens.glassBorder),
        ),
        title: Text(_t(widget.code, 'otpDialogTitle'),
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_t(widget.code, 'otpDialogBody'),
              style: const TextStyle(color: VetoGlassTokens.textMuted, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: VetoGlassTokens.glassFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(widget.otp, style: const TextStyle(
                  color: VetoGlassTokens.neonCyan, fontSize: 34,
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
                            color: VetoGlassTokens.neonCyan, size: 22),
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
        backgroundColor: const Color(0xE6121824),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VetoGlassTokens.glassBorder),
        ),
        title: Row(children: [
          const Icon(Icons.hourglass_empty_rounded, color: VetoPalette.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(_t(code, 'pendingTitle'),
              style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w800))),
        ]),
        content: Text(_t(code, 'pendingBody'),
            style: const TextStyle(color: VetoGlassTokens.textMuted, height: 1.6)),
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
