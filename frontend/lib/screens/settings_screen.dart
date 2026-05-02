// ============================================================
//  SettingsScreen — VETO 2026
//  Pixel-aligned with design_mockups/2026/settings.html (settings section).
//
//  Layout: sidebar (desktop) / list (mobile) → row-item groups.
//  Sections: Account · Preferences · Notifications · Security · Danger zone.
//  Role-specific extras (lawyer, admin) are appended as additional groups.
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/accessibility/accessibility_settings.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_tokens_2026.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _notifyEmergency = true;
  bool _notifySms = true;
  bool _notifyDigest = false;
  bool _twoFactor = false;

  static const _i18n = <String, Map<String, String>>{
    'he': {
      'title': 'הגדרות',
      'eyebrow': 'ההעדפות שלי',
      'save': 'שמור',
      'logout': 'התנתק',

      'sectAccount': 'חשבון',
      'sectAccountSub': 'פרטי חשבון, פרופיל, ופרטיות.',
      'profile': 'פרופיל',
      'profileDesc': 'שם, טלפון, אימייל',
      'security': 'אבטחה',
      'securityDesc': 'PIN, ביומטריה, 2FA',
      'privacy': 'פרטיות',
      'privacyDesc': 'מי רואה את הנתונים שלך',

      'sectPrefs': 'העדפות',
      'sectPrefsSub': 'שפה, נגישות, ועיצוב.',
      'language': 'שפת ממשק',
      'languageDesc': 'עברית · אנגלית · רוסית',
      'a11y': 'נגישות',
      'a11yDesc': 'גודל טקסט, ניגודיות, האטת אנימציות',
      'textSize': 'גודל טקסט',
      'highContrast': 'ניגודיות גבוהה',
      'reduceMotion': 'האטת אנימציות',

      'sectNotif': 'התראות',
      'sectNotifSub': 'איך VETO ייצור איתך קשר במצב חירום ובאירועים יומיומיים.',
      'notifyEmerg': 'Push חירום',
      'notifyEmergDesc': 'בולט גם במצב מושתק',
      'notifySms': 'SMS גיבוי',
      'notifySmsDesc': 'אם Push לא הגיע תוך 5 שניות',
      'notifyDigest': 'סיכום שבועי באימייל',
      'notifyDigestDesc': 'פעילות החשבון, תיקים פעילים',

      'sectSecurity': 'אבטחה',
      'sectSecuritySub': 'הגנה על החשבון והנתונים שלך.',
      'devEnc': 'הצפנת מכשיר',
      'devEncDesc': 'PIN / Biometric',
      'twofa': '2FA · אימות דו-שלבי',
      'twofaDesc': 'הגנה נוספת לחשבון',
      'logoutAll': 'התנתקות מכל המכשירים',
      'logoutAllDesc': 'תידרש כניסה מחדש בכל המכשירים',

      'sectLegal': 'מסמכים משפטיים',
      'privacyDoc': 'מדיניות פרטיות',
      'termsDoc': 'תנאי שימוש',

      'danger': 'אזור מסוכן',
      'dangerSub': 'פעולות כאן אינן הפיכות. וודא לפני ביצוע.',
      'deleteAccount': 'מחק חשבון לצמיתות',
      'exportData': 'ייצא וצא',

      'badgeOn': 'פעיל',
    },
    'en': {
      'title': 'Settings',
      'eyebrow': 'My preferences',
      'save': 'Save',
      'logout': 'Log out',
      'sectAccount': 'Account',
      'sectAccountSub': 'Account details, profile, and privacy.',
      'profile': 'Profile',
      'profileDesc': 'Name, phone, email',
      'security': 'Security',
      'securityDesc': 'PIN, biometric, 2FA',
      'privacy': 'Privacy',
      'privacyDesc': 'Who sees your data',
      'sectPrefs': 'Preferences',
      'sectPrefsSub': 'Language, accessibility, and design.',
      'language': 'Interface language',
      'languageDesc': 'Hebrew · English · Russian',
      'a11y': 'Accessibility',
      'a11yDesc': 'Text size, contrast, motion',
      'textSize': 'Text size',
      'highContrast': 'High contrast',
      'reduceMotion': 'Reduce motion',
      'sectNotif': 'Notifications',
      'sectNotifSub': 'How VETO contacts you in emergencies and routine events.',
      'notifyEmerg': 'Emergency push',
      'notifyEmergDesc': 'Visible even when muted',
      'notifySms': 'SMS backup',
      'notifySmsDesc': 'If push doesn\'t arrive within 5 seconds',
      'notifyDigest': 'Weekly email digest',
      'notifyDigestDesc': 'Account activity, active cases',
      'sectSecurity': 'Security',
      'sectSecuritySub': 'Protect your account and data.',
      'devEnc': 'Device encryption',
      'devEncDesc': 'PIN / Biometric',
      'twofa': '2FA',
      'twofaDesc': 'Extra account protection',
      'logoutAll': 'Log out of all devices',
      'logoutAllDesc': 'Sign-in required on every device',
      'sectLegal': 'Legal',
      'privacyDoc': 'Privacy policy',
      'termsDoc': 'Terms of service',
      'danger': 'Danger zone',
      'dangerSub': 'These actions are irreversible.',
      'deleteAccount': 'Delete account permanently',
      'exportData': 'Export and leave',
      'badgeOn': 'On',
    },
    'ru': {
      'title': 'Настройки',
      'eyebrow': 'Мои настройки',
      'save': 'Сохранить',
      'logout': 'Выйти',
      'sectAccount': 'Аккаунт',
      'sectAccountSub': 'Данные аккаунта, профиль и конфиденциальность.',
      'profile': 'Профиль',
      'profileDesc': 'Имя, телефон, email',
      'security': 'Безопасность',
      'securityDesc': 'PIN, биометрия, 2FA',
      'privacy': 'Приватность',
      'privacyDesc': 'Кто видит ваши данные',
      'sectPrefs': 'Настройки',
      'sectPrefsSub': 'Язык, доступность и оформление.',
      'language': 'Язык интерфейса',
      'languageDesc': 'Иврит · Английский · Русский',
      'a11y': 'Доступность',
      'a11yDesc': 'Размер текста, контраст, анимации',
      'textSize': 'Размер текста',
      'highContrast': 'Высокий контраст',
      'reduceMotion': 'Замедлить анимации',
      'sectNotif': 'Уведомления',
      'sectNotifSub': 'Как VETO связывается с вами.',
      'notifyEmerg': 'Push для экстренных',
      'notifyEmergDesc': 'Видны даже в режиме без звука',
      'notifySms': 'Резервный SMS',
      'notifySmsDesc': 'Если push не пришёл за 5 секунд',
      'notifyDigest': 'Еженедельный email',
      'notifyDigestDesc': 'Активность, дела',
      'sectSecurity': 'Безопасность',
      'sectSecuritySub': 'Защита аккаунта и данных.',
      'devEnc': 'Шифрование устройства',
      'devEncDesc': 'PIN / Биометрия',
      'twofa': '2FA',
      'twofaDesc': 'Доп. защита аккаунта',
      'logoutAll': 'Выход со всех устройств',
      'logoutAllDesc': 'Потребуется повторный вход',
      'sectLegal': 'Юридическая информация',
      'privacyDoc': 'Конфиденциальность',
      'termsDoc': 'Условия',
      'danger': 'Опасная зона',
      'dangerSub': 'Эти действия необратимы.',
      'deleteAccount': 'Удалить аккаунт навсегда',
      'exportData': 'Экспорт и выход',
      'badgeOn': 'Вкл',
    },
  };

  String _t(String code, String key) =>
      _i18n[AppLanguage.normalize(code)]?[key] ?? _i18n['he']![key] ?? key;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Reserved: pre-fetch role-specific data when expanded sections are added.
    if (mounted) setState(() { _loading = false; });
  }

  void _confirmDelete(BuildContext context, String code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t(code, 'deleteAccount'), style: VetoTokens.titleLg),
        content: Text(_t(code, 'dangerSub'), style: VetoTokens.bodyMd),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: VetoTokens.emerg),
            child: Text(_t(code, 'deleteAccount')),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      // TODO: wire to backend delete endpoint
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final a11y = context.watch<AccessibilitySettings>();
    final w = MediaQuery.of(context).size.width;
    final compact = w < 900;

    String t(String k) => _t(code, k);

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoTokens.paper,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(t('title'), style: VetoTokens.titleLg),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: compact ? _buildMobile(t, a11y, code) : _buildDesktop(t, a11y, code),
                ),
              ),
      ),
    );
  }

  Widget _buildMobile(String Function(String) t, AccessibilitySettings a11y, String code) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _content(t, a11y, code),
    );
  }

  Widget _buildDesktop(String Function(String) t, AccessibilitySettings a11y, String code) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 240,
          child: _Sidebar(t: t),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
            child: _content(t, a11y, code),
          ),
        ),
      ],
    );
  }

  Widget _content(String Function(String) t, AccessibilitySettings a11y, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: t('sectAccount'), sub: t('sectAccountSub')),
        const SizedBox(height: 12),
        _Group(items: [
          _Row(icon: Icons.person_outline, title: t('profile'), desc: t('profileDesc'), onTap: () => Navigator.pushNamed(context, '/profile')),
          _Row(icon: Icons.lock_outline_rounded, title: t('security'), desc: t('securityDesc'), onTap: () {}),
          _Row(icon: Icons.shield_outlined, title: t('privacy'), desc: t('privacyDesc'), onTap: () => Navigator.pushNamed(context, '/privacy')),
        ]),
        const SizedBox(height: 28),

        _SectionHeader(title: t('sectPrefs'), sub: t('sectPrefsSub')),
        const SizedBox(height: 12),
        _Group(items: [
          _Row(icon: Icons.language_rounded, title: t('language'), desc: t('languageDesc'), value: _langName(code), onTap: () {}),
          _RowTextSize(
            label: t('textSize'),
            value: a11y.textScale,
            onChanged: (v) {
              // Map the three button values back to AccessibilitySettings step indices.
              // Steps in `accessibility_settings.dart`: [0.88, 0.94, 1.0, 1.12, 1.28]
              final step = v <= 1.0 ? 2 : (v <= 1.15 ? 3 : 4);
              a11y.setTextStep(step);
            },
          ),
          _RowToggle(
            icon: Icons.contrast_rounded,
            title: t('highContrast'),
            value: a11y.highContrast,
            onChanged: (v) => a11y.setHighContrast(v),
          ),
          _RowToggle(
            icon: Icons.motion_photos_off_rounded,
            title: t('reduceMotion'),
            value: a11y.reduceMotion,
            onChanged: (v) => a11y.setReduceMotion(v),
          ),
        ]),
        const SizedBox(height: 28),

        _SectionHeader(title: t('sectNotif'), sub: t('sectNotifSub')),
        const SizedBox(height: 12),
        _Group(items: [
          _RowToggle(
            icon: Icons.notifications_active_outlined,
            title: t('notifyEmerg'), desc: t('notifyEmergDesc'),
            value: _notifyEmergency,
            onChanged: (v) => setState(() => _notifyEmergency = v),
          ),
          _RowToggle(
            icon: Icons.sms_outlined,
            title: t('notifySms'), desc: t('notifySmsDesc'),
            value: _notifySms,
            onChanged: (v) => setState(() => _notifySms = v),
          ),
          _RowToggle(
            icon: Icons.mark_email_unread_outlined,
            title: t('notifyDigest'), desc: t('notifyDigestDesc'),
            value: _notifyDigest,
            onChanged: (v) => setState(() => _notifyDigest = v),
          ),
        ]),
        const SizedBox(height: 28),

        _SectionHeader(title: t('sectSecurity'), sub: t('sectSecuritySub')),
        const SizedBox(height: 12),
        _Group(items: [
          _Row(
            icon: Icons.lock_rounded,
            title: t('devEnc'), desc: t('devEncDesc'),
            valueWidget: const _Badge(label: 'פעיל', kind: _BadgeKind.ok),
          ),
          _RowToggle(
            icon: Icons.fingerprint_rounded,
            title: t('twofa'), desc: t('twofaDesc'),
            value: _twoFactor,
            onChanged: (v) => setState(() => _twoFactor = v),
          ),
          _Row(
            icon: Icons.logout_rounded,
            iconColor: VetoTokens.emerg,
            title: t('logoutAll'), desc: t('logoutAllDesc'),
            titleColor: VetoTokens.emerg,
            onTap: () => AuthService().logout(context),
          ),
        ]),
        const SizedBox(height: 28),

        _SectionHeader(title: t('sectLegal')),
        const SizedBox(height: 12),
        _Group(items: [
          _Row(icon: Icons.privacy_tip_outlined, title: t('privacyDoc'), onTap: () => Navigator.pushNamed(context, '/privacy')),
          _Row(icon: Icons.gavel_outlined, title: t('termsDoc'), onTap: () => Navigator.pushNamed(context, '/terms')),
        ]),
        const SizedBox(height: 28),

        // Danger zone
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: VetoTokens.emergBorder, width: 1),
            borderRadius: BorderRadius.circular(VetoTokens.rMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('danger'), style: VetoTokens.serif(16, FontWeight.w700, color: VetoTokens.emerg)),
              const SizedBox(height: 4),
              Text(t('dangerSub'), style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500)),
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, children: [
                OutlinedButton(
                  onPressed: () => _confirmDelete(context, code),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VetoTokens.emerg,
                    side: const BorderSide(color: Color(0xFFF4C7BD), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: Text(t('deleteAccount'), style: VetoTokens.labelMd.copyWith(color: VetoTokens.emerg)),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VetoTokens.emerg,
                    side: const BorderSide(color: Color(0xFFF4C7BD), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: Text(t('exportData'), style: VetoTokens.labelMd.copyWith(color: VetoTokens.emerg)),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  String _langName(String code) {
    switch (AppLanguage.normalize(code)) {
      case 'en': return 'English';
      case 'ru': return 'Русский';
      default: return 'עברית';
    }
  }
}

// ──────────────────────────────────────────────────────────
//  Sub-widgets
// ──────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sideGroup(t('sectAccount').toUpperCase(), [
            (Icons.person_outline, t('profile'), true),
            (Icons.lock_outline_rounded, t('security'), false),
            (Icons.shield_outlined, t('privacy'), false),
          ]),
          _sideGroup(t('sectPrefs').toUpperCase(), [
            (Icons.language_rounded, t('language'), false),
            (Icons.accessibility_new_rounded, t('a11y'), false),
            (Icons.notifications_active_outlined, t('sectNotif'), false),
          ]),
          _sideGroup(t('sectLegal').toUpperCase(), [
            (Icons.privacy_tip_outlined, t('privacyDoc'), false),
            (Icons.gavel_outlined, t('termsDoc'), false),
          ]),
        ],
      ),
    );
  }

  Widget _sideGroup(String title, List<(IconData, String, bool)> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
          child: Text(title, style: VetoTokens.kicker.copyWith(color: VetoTokens.ink300, letterSpacing: 1.8)),
        ),
        for (final it in items) _sideItem(it.$1, it.$2, it.$3),
      ],
    );
  }

  Widget _sideItem(IconData icon, String label, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: active ? VetoTokens.navy100 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 16, color: active ? VetoTokens.navy700 : VetoTokens.ink700),
        title: Text(label, style: VetoTokens.titleSm.copyWith(color: active ? VetoTokens.navy700 : VetoTokens.ink700)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
        onTap: () {},
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.sub});
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: VetoTokens.headlineSm.copyWith(color: VetoTokens.ink900)),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub!, style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500)),
        ],
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.items});
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VetoTokens.rMd),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              items[i],
              if (i < items.length - 1) const Divider(height: 1, thickness: 1, color: VetoTokens.hairline),
            ]
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon, required this.title,
    this.desc, this.value, this.valueWidget,
    this.onTap, this.iconColor, this.titleColor,
  });
  final IconData icon;
  final String title;
  final String? desc;
  final String? value;
  final Widget? valueWidget;
  final VoidCallback? onTap;
  final Color? iconColor, titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor == VetoTokens.emerg ? VetoTokens.emergBg : VetoTokens.paper2,
                border: Border.all(color: iconColor == VetoTokens.emerg ? VetoTokens.emergBorder : VetoTokens.hairline),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: iconColor ?? VetoTokens.navy600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: VetoTokens.titleSm.copyWith(color: titleColor ?? VetoTokens.ink900)),
                  if (desc != null)
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(desc!, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500))),
                ],
              ),
            ),
            if (valueWidget != null) valueWidget!,
            if (value != null && valueWidget == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(value!, style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink700, fontWeight: FontWeight.w600)),
              ),
            if (onTap != null) const Icon(Icons.chevron_left_rounded, size: 18, color: VetoTokens.ink300),
          ],
        ),
      ),
    );
  }
}

class _RowToggle extends StatelessWidget {
  const _RowToggle({required this.icon, required this.title, this.desc, required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final String? desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: VetoTokens.paper2, border: Border.all(color: VetoTokens.hairline), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: VetoTokens.navy600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
                  if (desc != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(desc!, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500))),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: Colors.white, activeTrackColor: VetoTokens.ok),
          ],
        ),
      ),
    );
  }
}

class _RowTextSize extends StatelessWidget {
  const _RowTextSize({required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: VetoTokens.paper2, border: Border.all(color: VetoTokens.hairline), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Icon(Icons.format_size_rounded, size: 16, color: VetoTokens.navy600),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900))),
          for (final v in const [1.0, 1.15, 1.3]) ...[
            _sizeBtn(v),
            if (v != 1.3) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _sizeBtn(double v) {
    final selected = (value - v).abs() < 0.001;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(v),
      child: Container(
        width: 36, height: 32,
        decoration: BoxDecoration(
          color: selected ? VetoTokens.navy600 : VetoTokens.paper2,
          border: Border.all(color: selected ? VetoTokens.navy600 : VetoTokens.hairline),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text('A${v == 1.0 ? '' : v == 1.15 ? '+' : '++'}', style: VetoTokens.labelMd.copyWith(color: selected ? Colors.white : VetoTokens.ink700)),
      ),
    );
  }
}

enum _BadgeKind { ok, warn, danger, brand }

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.kind = _BadgeKind.brand});
  final String label;
  final _BadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (kind) {
      _BadgeKind.ok     => (VetoTokens.okSoft, const Color(0xFF16664B), const Color(0xFFB7DFCB)),
      _BadgeKind.warn   => (VetoTokens.warnSoft, const Color(0xFF7A5300), const Color(0xFFF2D58E)),
      _BadgeKind.danger => (VetoTokens.emergBg, const Color(0xFF8E1626), VetoTokens.emergBorder),
      _BadgeKind.brand  => (VetoTokens.infoSoft, VetoTokens.navy700, const Color(0xFFC4D4F4)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(VetoTokens.rPill), border: Border.all(color: border)),
      child: Text(label, style: VetoTokens.sans(11, FontWeight.w700, color: fg)),
    );
  }
}
