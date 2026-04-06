import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_theme.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_language_menu.dart';
import 'admin_i18n.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});
  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  final _svc = AdminService();

  String _t(String code, String key) => AdminStrings.t(code, key);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getAllUsers();
    if (mounted) setState(() { _users = data; _loading = false; });
  }

  Future<void> _showForm({Map<String, dynamic>? user}) async {
    final code = context.read<AppLanguageController>().code;
    final nameCtrl  = TextEditingController(text: user?['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    String role           = user?['role'] ?? 'user';
    String lang           = user?['preferred_language'] ?? 'he';
    bool   manuallyAdded  = user?['manually_added'] == true;
    final id              = user?['_id']?.toString();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: Text(id == null ? _t(code, 'addUser') : _t(code, 'editUser'),
              style: const TextStyle(color: VetoPalette.text)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(nameCtrl,  _t(code, 'fullName'),    Icons.badge_outlined),
              const SizedBox(height: 10),
              _field(phoneCtrl, _t(code, 'phone'), Icons.phone_iphone_rounded,
                  dir: TextDirection.ltr),
              const SizedBox(height: 10),
              StatefulBuilder(builder: (_, ss) => Column(children: [
                DropdownButtonFormField<String>(
                  initialValue: role,
                  dropdownColor: VetoPalette.bg,
                  style: const TextStyle(color: VetoPalette.text),
                  decoration: _dec(_t(code, 'role'), Icons.shield_outlined),
                  items: [
                    DropdownMenuItem(value: 'user',  child: Text(_t(code, 'citizen'))),
                    DropdownMenuItem(value: 'admin', child: Text(_t(code, 'admin'))),
                  ],
                  onChanged: (v) => ss(() => role = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: lang,
                  dropdownColor: VetoPalette.bg,
                  style: const TextStyle(color: VetoPalette.text),
                  decoration: _dec(_t(code, 'language'), Icons.language),
                  items: const [
                    DropdownMenuItem(value: 'he', child: Text('עברית')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ru', child: Text('Русский')),
                  ],
                  onChanged: (v) => ss(() => lang = v!),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  value: manuallyAdded,
                  onChanged: (v) => ss(() => manuallyAdded = v),
                  contentPadding: EdgeInsets.zero,
                  activeColor: VetoPalette.success,
                  title: Text(_t(code, 'manualExempt'),
                      style: const TextStyle(color: VetoPalette.text, fontSize: 14)),
                  subtitle: Text(_t(code, 'manualExemptHint'),
                      style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
                ),
              ])),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t(code, 'cancel'))),
            FilledButton(
              onPressed: () async {
                final body = {
                  'full_name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'role': role,
                  'preferred_language': lang,
                  'manually_added': manuallyAdded,
                };
                final bool ok = id == null
                    ? (await _svc.createUser(body)) != null
                    : await _svc.updateUser(id, body);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (ok) {
                  _load();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_t(code, 'saveUserFailed')),
                    backgroundColor: VetoPalette.emergency,
                  ));
                }
              },
              child: Text(id == null ? _t(code, 'add') : _t(code, 'save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    final code = context.read<AppLanguageController>().code;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: Text(_t(code, 'deleteUser'), style: const TextStyle(color: VetoPalette.text)),
          content: Text('${_t(code, 'deleteUserConfirm')}\n$name',
              style: const TextStyle(color: VetoPalette.textMuted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(code, 'cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t(code, 'delete')),
            ),
          ],
        ),
      ),
    );
    if (ok == true) { await _svc.deleteUser(id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.surface,
          title: Text('${_t(code, 'users')} (${_loading ? _t(code, 'loading') : _users.length})',
              style: const TextStyle(color: VetoPalette.text)),
          iconTheme: const IconThemeData(color: VetoPalette.text),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: AppLanguageMenu(compact: true)),
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: _t(code, 'refresh')),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showForm(),
          backgroundColor: VetoPalette.primary,
          icon: const Icon(Icons.person_add_rounded),
          label: Text(_t(code, 'addUser')),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
                ? Center(child: Text(_t(code, 'noUsers'), style: const TextStyle(color: VetoPalette.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final u = _users[i];
                      final verified = u['is_verified'] == true;
                      final uid = u['_id']?.toString() ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: VetoPalette.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: const BorderSide(color: VetoPalette.primary, width: 3),
                            top: BorderSide(color: VetoPalette.border),
                            right: BorderSide(color: VetoPalette.border),
                            bottom: BorderSide(color: VetoPalette.border),
                          ),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: VetoPalette.primary.withValues(alpha: 0.15),
                            child: Text(
                              ((u['full_name'] as String?) ?? '?').isNotEmpty
                                  ? (u['full_name'] as String).characters.first : '?',
                              style: const TextStyle(color: VetoPalette.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(u['full_name'] ?? _t(code, 'noName'),
                                style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w600)),
                            Text(u['phone'] ?? '', textDirection: TextDirection.ltr,
                                style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
                            Text(AdminStrings.roleLabel(code, u['role']?.toString()),
                                style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11)),
                            Text(AdminStrings.languageLabel(code, u['preferred_language']?.toString()),
                              style: const TextStyle(color: VetoPalette.info, fontSize: 11)),
                          ])),
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (verified ? VetoPalette.success : VetoPalette.warning).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(verified ? _t(code, 'verified') : _t(code, 'unverified'),
                                style: TextStyle(color: verified ? VetoPalette.success : VetoPalette.warning, fontSize: 10)),
                          ),
                          if (u['manually_added'] == true)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: VetoPalette.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_t(code, 'exempt'),
                                  style: const TextStyle(color: VetoPalette.success, fontSize: 10)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: VetoPalette.primary),
                            onPressed: () => _showForm(user: Map<String, dynamic>.from(u as Map)),
                            tooltip: _t(code, 'edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: VetoPalette.emergency),
                            onPressed: () => _confirmDelete(uid, u['full_name']?.toString() ?? ''),
                            tooltip: _t(code, 'delete'),
                          ),
                        ]),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextDirection dir = TextDirection.rtl}) =>
      TextField(
        controller: ctrl, textDirection: dir,
        style: const TextStyle(color: VetoPalette.text),
        decoration: _dec(label, icon),
      );

  InputDecoration _dec(String label, IconData ico) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: VetoPalette.textMuted),
    prefixIcon: Icon(ico, color: VetoPalette.textMuted, size: 18),
    filled: true, fillColor: VetoPalette.bg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VetoPalette.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VetoPalette.border)),
  );
}
