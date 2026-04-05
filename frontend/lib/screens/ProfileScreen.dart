import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
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
      'title': 'פרופיל',
      'nameEmpty': 'שם אינו יכול להיות ריק.',
      'saved': 'הפרופיל עודכן בהצלחה.',
      'saveError': 'לא הצלחנו לשמור את השינויים.',
      'name': 'שם מלא',
      'nameHint': 'הזן שם מלא',
      'phone': 'טלפון',
      'role': 'תפקיד',
      'save': 'שמור שינויים',
      'logout': 'התנתק',
      'language': 'שפת ממשק',
    },
    'en': {
      'title': 'Profile',
      'nameEmpty': 'Name cannot be empty.',
      'saved': 'Your profile was updated successfully.',
      'saveError': 'We could not save your changes.',
      'name': 'Full name',
      'nameHint': 'Enter your full name',
      'phone': 'Phone',
      'role': 'Role',
      'save': 'Save changes',
      'logout': 'Log out',
      'language': 'Interface language',
    },
    'ru': {
      'title': 'Профиль',
      'nameEmpty': 'Имя не может быть пустым.',
      'saved': 'Профиль успешно обновлен.',
      'saveError': 'Не удалось сохранить изменения.',
      'name': 'Полное имя',
      'nameHint': 'Введите полное имя',
      'phone': 'Телефон',
      'role': 'Роль',
      'save': 'Сохранить изменения',
      'logout': 'Выйти',
      'language': 'Язык интерфейса',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _saveProfile() async {
    final code = context.read<AppLanguageController>().code;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t(code, 'nameEmpty'))));
      return;
    }
    setState(() => _saving = true);
    final ok = await AuthService().updateProfile(
      fullName: name,
      preferredLanguage: code,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? _t(code, 'saved') : _t(code, 'saveError')),
      backgroundColor: ok ? VetoPalette.success : VetoPalette.emergency,
    ));
  }

  Future<void> _loadUserData() async {
    final name = await AuthService().getStoredName();
    final role = await AuthService().getStoredRole();
    final phone = await AuthService().getStoredPhone();
    setState(() {
      _nameCtrl.text = name ?? '';
      _role = role;
      _phone = phone;
      _loading = false;
    });
  }

  String _t(String code, String key) {
    return _copy[AppLanguage.normalize(code)]?[key] ??
        _copy[AppLanguage.hebrew]![key] ??
        key;
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          title: Text(_t(code, 'title')),
          backgroundColor: VetoPalette.surface,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: VetoPalette.border),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: AppLanguageMenu(compact: true)),
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: VetoPalette.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: VetoPalette.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      VetoPalette.primary.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: VetoPalette.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildCard(
                          children: [
                            _sectionLabel(_t(code, 'name')),
                            TextField(
                              controller: _nameCtrl,
                              decoration: InputDecoration(
                                hintText: _t(code, 'nameHint'),
                                prefixIcon:
                                    const Icon(Icons.person_outline, size: 18),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _sectionLabel(_t(code, 'phone')),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: VetoPalette.surface,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: VetoPalette.border),
                              ),
                              child: Text(
                                _phone ?? '—',
                                style: const TextStyle(
                                    color: VetoPalette.textMuted),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _sectionLabel(_t(code, 'role')),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: VetoPalette.surface,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: VetoPalette.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _role == 'lawyer'
                                        ? Icons.gavel_rounded
                                        : _role == 'admin'
                                            ? Icons.admin_panel_settings_outlined
                                            : Icons.person_outline,
                                    size: 16,
                                    color: VetoPalette.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _roleLabel(code, _role),
                                    style: const TextStyle(
                                        color: VetoPalette.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _sectionLabel(_t(code, 'language')),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: VetoPalette.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: VetoPalette.border),
                              ),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: AppLanguageMenu(compact: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _saving ? null : _saveProfile,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text(_t(code, 'save')),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => AuthService().logout(context),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: Text(_t(code, 'logout')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VetoPalette.emergency,
                            side: BorderSide(
                                color: VetoPalette.emergency
                                    .withValues(alpha: 0.4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  String _roleLabel(String code, String? role) {
    switch (role) {
      case 'lawyer':
        return switch (AppLanguage.normalize(code)) {
          'en' => 'Lawyer',
          'ru' => 'Адвокат',
          _ => 'עורך דין',
        };
      case 'admin':
        return switch (AppLanguage.normalize(code)) {
          'en' => 'Admin',
          'ru' => 'Администратор',
          _ => 'מנהל מערכת',
        };
      default:
        return switch (AppLanguage.normalize(code)) {
          'en' => 'User',
          'ru' => 'Пользователь',
          _ => 'משתמש',
        };
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: VetoPalette.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
