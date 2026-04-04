import 'package:flutter/material.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שם אינו יכול להיות ריק')));
      return;
    }
    setState(() => _saving = true);
    final ok = await AuthService().updateProfile(fullName: name);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'הפרופיל עודכן בהצלחה' : 'שגיאה בשמירה, נסה שוב'),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          title: const Text('פרופיל'),
          backgroundColor: VetoPalette.surface,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: VetoPalette.border),
          ),
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
                            _sectionLabel('שם מלא'),
                            TextField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'הזן שם מלא',
                                prefixIcon:
                                    Icon(Icons.person_outline, size: 18),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _sectionLabel('טלפון'),
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
                            _sectionLabel('תפקיד'),
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
                                    _roleLabel(_role),
                                    style: const TextStyle(
                                        color: VetoPalette.textMuted),
                                  ),
                                ],
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
                              : const Text('שמור שינויים'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => AuthService().logout(context),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('התנתק'),
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

  String _roleLabel(String? role) {
    switch (role) {
      case 'lawyer':
        return 'עורך דין';
      case 'admin':
        return 'מנהל מערכת';
      default:
        return 'משתמש';
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
