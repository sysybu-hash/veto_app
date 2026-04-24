import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_glass_system.dart';
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
    // First show local cache immediately, then refresh from server
    final name  = await AuthService().getStoredName();
    final role  = await AuthService().getStoredRole();
    final phone = await AuthService().getStoredPhone();
    if (mounted) {
      setState(() {
        _nameCtrl.text = name ?? '';
        _role  = role;
        _phone = phone;
        _loading = false;
      });
    }
    // Refresh from server in background
    final serverData = await AuthService().fetchProfile();
    if (serverData != null && mounted) {
      setState(() {
        _nameCtrl.text = (serverData['full_name'] as String?) ?? _nameCtrl.text;
        _phone = (serverData['phone'] as String?) ?? _phone;
      });
    }
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
        backgroundColor: VetoGlassTokens.bgBase,
        appBar: AppBar(
          backgroundColor: const Color(0x18FFFFFF),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: VetoGlassTokens.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            _t(code, 'title'),
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          centerTitle: true,
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: AppLanguageMenu(compact: true)),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: VetoGlassTokens.glassBorder),
          ),
        ),
        body: VetoGlassAuroraBackground(
          child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: VetoGlassTokens.neonCyan))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // Avatar
                        Center(
                          child: Container(
                            width: 80, height: 80,
                            decoration: const BoxDecoration(
                              gradient: VetoGlassTokens.neonButton,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x4000E5FF),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.w900,
                                  color: Color(0xFF041018),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
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
                            const SizedBox(height: 20),
                            _sectionLabel(_t(code, 'phone')),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1A24),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: VetoGlassTokens.glassBorder),
                              ),
                              child: Text(
                                _phone ?? '—',
                                style: const TextStyle(
                                    color: VetoGlassTokens.textMuted),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel(_t(code, 'role')),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1A24),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: VetoGlassTokens.glassBorder),
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
                                    color: VetoGlassTokens.neonCyan,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _roleLabel(code, _role),
                                    style: const TextStyle(
                                        color: VetoGlassTokens.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel(_t(code, 'language')),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1A24),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: VetoGlassTokens.glassBorder),
                              ),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: AppLanguageMenu(compact: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // ── Quick links ────────────────────
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/files_vault'),
                            icon: const Icon(Icons.folder_special_outlined, size: 16),
                            label: Text(
                              code == 'he' ? 'כספת קבצים' : code == 'ru' ? 'Хранилище' : 'File Vault',
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: VetoGlassTokens.neonCyan,
                              side: BorderSide(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/settings'),
                            icon: const Icon(Icons.settings_outlined, size: 16),
                            label: Text(
                              code == 'he' ? 'הגדרות' : code == 'ru' ? 'Настройки' : 'Settings',
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: VetoGlassTokens.neonCyan,
                              side: BorderSide(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )),
                        ]),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _saving ? null : _saveProfile,
                          icon: _saving
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Color(0xFF041018)))
                              : const Icon(Icons.check_rounded, size: 18, color: Color(0xFF041018)),
                          label: Text(_t(code, 'save'),
                            style: const TextStyle(color: Color(0xFF041018)),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: VetoGlassTokens.neonCyan,
                            foregroundColor: const Color(0xFF041018),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => AuthService().logout(context),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: Text(_t(code, 'logout')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VetoPalette.emergency,
                            side: BorderSide(
                                color: VetoPalette.emergency
                                    .withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: VetoGlassTokens.neonCyan,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return VetoGlassBlur(
      borderRadius: 16,
      sigma: 14,
      fill: VetoGlassTokens.glassFillStrong,
      borderColor: VetoGlassTokens.glassBorder,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
