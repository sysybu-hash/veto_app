// ============================================================
//  ProfileScreen — VETO 2026
//  Pixel-aligned with design_mockups/2026/settings.html (profile section).
//
//  Layout (centred, max 720):
//    profile-hero  → avatar xl + name + contact + badges + subscription/CTA
//    stats grid    → 4 cells (cases / files / AI / calls)
//    section       → "Personal info" + 3 row-items (name editable, phone, email)
//    save button   → CTA primary
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_tokens_2026.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _role;
  String? _phone;

  static const Map<String, Map<String, String>> _copy = {
    'he': {
      'eyebrow': 'הפרופיל שלי',
      'title': 'פרופיל',
      'editProfile': 'ערוך פרופיל',
      'subscription': 'סטטוס מנוי',
      'subActive': 'פעיל · מתחדש בקרוב',
      'renew': 'חידוש מנוי',
      'badgePrem': 'משתמש פרימיום',
      'badgeMember': 'חבר מאז 2025',
      'badgeVerified': 'חשבון מאומת',
      'statCases': 'תיקים פעילים',
      'statFiles': 'קבצים בכספת',
      'statAi': 'ייעוצי AI',
      'statCalls': 'שיחות עם עו"ד',
      'sectionTitle': 'פרטים אישיים',
      'sectionSub': 'נתונים אלה משמשים לאמת אותך בלבד. לא מועברים לעורכי דין ללא אישורך המפורש.',
      'name': 'שם מלא',
      'nameHint': 'הזן שם מלא',
      'nameDesc': 'מופיע במסמכים שאתה חותם',
      'phone': 'טלפון',
      'phoneDesc': 'לכניסה ול-OTP',
      'email': 'אימייל',
      'emailDesc': 'להתראות גיבוי וקבלות',
      'role': 'תפקיד',
      'save': 'שמור שינויים',
      'logout': 'התנתק',
      'nameEmpty': 'שם אינו יכול להיות ריק.',
      'saved': 'הפרופיל עודכן בהצלחה.',
      'saveError': 'לא הצלחנו לשמור את השינויים.',
    },
    'en': {
      'eyebrow': 'My profile',
      'title': 'Profile',
      'editProfile': 'Edit profile',
      'subscription': 'Subscription',
      'subActive': 'Active · auto-renew',
      'renew': 'Renew',
      'badgePrem': 'Premium',
      'badgeMember': 'Member since 2025',
      'badgeVerified': 'Verified',
      'statCases': 'Active cases',
      'statFiles': 'Vault files',
      'statAi': 'AI consultations',
      'statCalls': 'Lawyer calls',
      'sectionTitle': 'Personal info',
      'sectionSub': 'These details are used only to verify you. They are not shared with lawyers without your explicit consent.',
      'name': 'Full name',
      'nameHint': 'Enter your full name',
      'nameDesc': 'Appears on documents you sign',
      'phone': 'Phone',
      'phoneDesc': 'For sign-in and OTP',
      'email': 'Email',
      'emailDesc': 'For backups and receipts',
      'role': 'Role',
      'save': 'Save changes',
      'logout': 'Log out',
      'nameEmpty': 'Name cannot be empty.',
      'saved': 'Profile updated successfully.',
      'saveError': 'Failed to save changes.',
    },
    'ru': {
      'eyebrow': 'Мой профиль',
      'title': 'Профиль',
      'editProfile': 'Редактировать',
      'subscription': 'Подписка',
      'subActive': 'Активна · авто-продление',
      'renew': 'Продлить',
      'badgePrem': 'Premium',
      'badgeMember': 'Участник с 2025',
      'badgeVerified': 'Подтверждён',
      'statCases': 'Активных дел',
      'statFiles': 'Файлов',
      'statAi': 'AI-консультаций',
      'statCalls': 'Звонков',
      'sectionTitle': 'Личные данные',
      'sectionSub': 'Эти данные используются только для вашей идентификации.',
      'name': 'Полное имя',
      'nameHint': 'Введите полное имя',
      'nameDesc': 'Появляется в подписываемых документах',
      'phone': 'Телефон',
      'phoneDesc': 'Для входа и OTP',
      'email': 'Email',
      'emailDesc': 'Для резервных уведомлений и квитанций',
      'role': 'Роль',
      'save': 'Сохранить',
      'logout': 'Выйти',
      'nameEmpty': 'Имя не может быть пустым.',
      'saved': 'Профиль обновлён.',
      'saveError': 'Не удалось сохранить изменения.',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final name  = await AuthService().getStoredName();
    final role  = await AuthService().getStoredRole();
    final phone = await AuthService().getStoredPhone();
    if (mounted) {
      setState(() {
        _nameCtrl.text = name ?? '';
        _role = role;
        _phone = phone;
        _loading = false;
      });
    }
    final serverData = await AuthService().fetchProfile();
    if (serverData != null && mounted) {
      setState(() {
        _nameCtrl.text = (serverData['full_name'] as String?) ?? _nameCtrl.text;
        _phone = (serverData['phone'] as String?) ?? _phone;
      });
    }
  }

  Future<void> _saveProfile() async {
    final code = context.read<AppLanguageController>().code;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(code, 'nameEmpty'))));
      return;
    }
    setState(() => _saving = true);
    final ok = await AuthService().updateProfile(fullName: name, preferredLanguage: code);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? _t(code, 'saved') : _t(code, 'saveError')),
      backgroundColor: ok ? VetoTokens.ok : VetoTokens.emerg,
    ));
  }

  String _t(String code, String key) {
    return _copy[AppLanguage.normalize(code)]?[key] ?? _copy[AppLanguage.hebrew]![key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    String t(String k) => _t(code, k);
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text.trim().split(' ').take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase()
        : '?';

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
          actions: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Center(child: AppLanguageMenu(compact: true)))],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHero(
                          initial: initial,
                          name: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : '—',
                          phone: _phone ?? '—',
                          email: 'user@example.com', // not yet wired to backend
                          badges: [t('badgePrem'), t('badgeMember'), t('badgeVerified')],
                          subscriptionLabel: t('subscription'),
                          subscriptionValue: t('subActive'),
                          renewLabel: t('renew'),
                          onRenew: () {},
                        ),
                        const SizedBox(height: 18),
                        _StatsRow(
                          values: const ['3', '142', '8', '2'],
                          labels: [t('statCases'), t('statFiles'), t('statAi'), t('statCalls')],
                        ),
                        const SizedBox(height: 28),
                        _SectionHeader(title: t('sectionTitle'), sub: t('sectionSub')),
                        const SizedBox(height: 12),
                        _RowItemGroup(items: [
                          _EditableRowItem(
                            icon: Icons.person_outline,
                            title: t('name'),
                            desc: t('nameDesc'),
                            controller: _nameCtrl,
                          ),
                          _RowItem(
                            icon: Icons.phone_outlined,
                            title: t('phone'),
                            desc: t('phoneDesc'),
                            value: _phone ?? '—',
                            ltr: true,
                          ),
                          _RowItem(
                            icon: Icons.mail_outline_rounded,
                            title: t('email'),
                            desc: t('emailDesc'),
                            value: 'user@example.com',
                          ),
                          if (_role != null && _role!.isNotEmpty)
                            _RowItem(
                              icon: Icons.shield_outlined,
                              title: t('role'),
                              value: _role!.toUpperCase(),
                            ),
                        ]),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _saving ? null : _saveProfile,
                            style: FilledButton.styleFrom(
                              backgroundColor: VetoTokens.navy600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: VetoTokens.labelLg,
                            ),
                            child: _saving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(t('save')),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => AuthService().logout(context),
                          icon: const Icon(Icons.logout_rounded, size: 16, color: VetoTokens.emerg),
                          label: Text(t('logout'), style: VetoTokens.labelMd.copyWith(color: VetoTokens.emerg)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Sub-widgets
// ──────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.initial,
    required this.name,
    required this.phone,
    required this.email,
    required this.badges,
    required this.subscriptionLabel,
    required this.subscriptionValue,
    required this.renewLabel,
    required this.onRenew,
  });
  final String initial, name, phone, email;
  final List<String> badges;
  final String subscriptionLabel, subscriptionValue, renewLabel;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 600;
    final identity = Row(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: VetoTokens.crestGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: VetoTokens.shadow1,
            border: Border.all(color: const Color(0x1FFFFFFF), width: 1),
          ),
          alignment: Alignment.center,
          child: Text(initial, style: VetoTokens.serif(28, FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: VetoTokens.serif(24, FontWeight.w800, color: VetoTokens.ink900)),
              const SizedBox(height: 4),
              Text('$phone · $email', style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  _MiniBadge(badges[0], color: VetoTokens.infoSoft, fg: VetoTokens.navy700, border: const Color(0xFFC4D4F4)),
                  _MiniBadge(badges[1], color: VetoTokens.goldSoft, fg: VetoTokens.goldDeep, border: const Color(0xFFD4BB99)),
                  _MiniBadge(badges[2], color: VetoTokens.okSoft, fg: const Color(0xFF16664B), border: const Color(0xFFB7DFCB)),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final subscription = Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(subscriptionLabel.toUpperCase(), style: VetoTokens.kicker.copyWith(letterSpacing: 1.32)),
        const SizedBox(height: 6),
        Text(subscriptionValue, style: VetoTokens.titleMd.copyWith(color: VetoTokens.ink900)),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: onRenew,
          style: FilledButton.styleFrom(
            backgroundColor: VetoTokens.navy600,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: VetoTokens.labelMd,
          ),
          child: Text(renewLabel),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [VetoTokens.surface2, Colors.white]),
        borderRadius: BorderRadius.circular(VetoTokens.r2Xl),
        border: Border.all(color: VetoTokens.hairline, width: 1),
        boxShadow: VetoTokens.shadow1,
      ),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [identity, const SizedBox(height: 20), subscription])
          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: identity), const SizedBox(width: 24), subscription]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.values, required this.labels});
  final List<String> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < values.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
              child: Column(
                children: [
                  Text(values[i], style: VetoTokens.serif(22, FontWeight.w800, color: VetoTokens.ink900, height: 1.0)),
                  const SizedBox(height: 4),
                  Text(labels[i], textAlign: TextAlign.center, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500, letterSpacing: 0.4)),
                ],
              ),
            ),
          ),
          if (i < values.length - 1) const SizedBox(width: 10),
        ]
      ],
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

class _RowItemGroup extends StatelessWidget {
  const _RowItemGroup({required this.items});
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

class _RowItem extends StatelessWidget {
  const _RowItem({required this.icon, required this.title, this.desc, this.value, this.ltr = false});
  final IconData icon;
  final String title;
  final String? desc;
  final String? value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                  if (desc != null)
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(desc!, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500))),
                ],
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Directionality(
                  textDirection: ltr ? TextDirection.ltr : Directionality.of(context),
                  child: Text(value!, style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink700, fontWeight: FontWeight.w600)),
                ),
              ),
            const Icon(Icons.chevron_left_rounded, size: 18, color: VetoTokens.ink300),
          ],
        ),
      ),
    );
  }
}

class _EditableRowItem extends StatelessWidget {
  const _EditableRowItem({required this.icon, required this.title, required this.desc, required this.controller});
  final IconData icon;
  final String title;
  final String desc;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
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
                Text(desc, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
                const SizedBox(height: 8),
                TextField(controller: controller, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge(this.label, {required this.color, required this.fg, required this.border});
  final String label;
  final Color color, fg, border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(VetoTokens.rPill), border: Border.all(color: border, width: 1)),
      child: Text(label, style: VetoTokens.sans(11, FontWeight.w700, color: fg)),
    );
  }
}
