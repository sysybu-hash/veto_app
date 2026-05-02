// ============================================================
//  AllUsersScreen — VETO 2026
//  Tokens-aligned. CRUD users (citizen/admin), role + language + manual-exempt.
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_tokens_2026.dart';
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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getAllUsers();
    if (mounted) setState(() { _users = data; _loading = false; });
  }

  Future<void> _showForm({Map<String, dynamic>? user}) async {
    final code = context.read<AppLanguageController>().code;
    final nameCtrl  = TextEditingController(text: user?['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    String role          = user?['role'] ?? 'user';
    String lang          = user?['preferred_language'] ?? 'he';
    bool   manuallyAdded = user?['manually_added'] == true;
    final id             = user?['_id']?.toString();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          title: Text(id == null ? _t(code, 'addUser') : _t(code, 'editUser'), style: VetoTokens.titleLg),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LightField(controller: nameCtrl, label: _t(code, 'fullName'), icon: Icons.badge_outlined),
                  const SizedBox(height: 10),
                  _LightField(controller: phoneCtrl, label: _t(code, 'phone'), icon: Icons.phone_iphone_rounded, ltr: true),
                  const SizedBox(height: 10),
                  StatefulBuilder(builder: (_, ss) => Column(children: [
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: _LightField.dec(_t(code, 'role'), Icons.shield_outlined),
                      items: [
                        DropdownMenuItem(value: 'user', child: Text(_t(code, 'citizen'))),
                        DropdownMenuItem(value: 'admin', child: Text(_t(code, 'admin'))),
                      ],
                      onChanged: (v) => ss(() => role = v!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: lang,
                      decoration: _LightField.dec(_t(code, 'language'), Icons.language),
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
                      activeThumbColor: Colors.white,
                      activeTrackColor: VetoTokens.ok,
                      title: Text(_t(code, 'manualExempt'), style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
                      subtitle: Text(_t(code, 'manualExemptHint'), style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
                    ),
                  ])),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t(code, 'cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: VetoTokens.navy600, foregroundColor: Colors.white),
              onPressed: () async {
                final body = {
                  'full_name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'role': role,
                  'preferred_language': lang,
                  'manually_added': manuallyAdded,
                };
                final ok = id == null
                    ? (await _svc.createUser(body)) != null
                    : await _svc.updateUser(id, body);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (ok) {
                  _load();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_t(code, 'saveUserFailed')),
                    backgroundColor: VetoTokens.emerg,
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
          title: Text(_t(code, 'deleteUser'), style: VetoTokens.titleLg),
          content: Text('${_t(code, 'deleteUserConfirm')}\n$name', style: VetoTokens.bodyMd),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(code, 'cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: VetoTokens.emerg, foregroundColor: Colors.white),
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
        backgroundColor: VetoTokens.paper,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            '${_t(code, 'users')} (${_loading ? _t(code, 'loading') : _users.length})',
            style: VetoTokens.titleLg,
          ),
          actions: [
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Center(child: AppLanguageMenu(compact: true))),
            IconButton(icon: const Icon(Icons.refresh_rounded, size: 18), onPressed: _load, tooltip: _t(code, 'refresh')),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showForm(),
          backgroundColor: VetoTokens.navy600,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: Text(_t(code, 'addUser'), style: VetoTokens.labelMd.copyWith(color: Colors.white)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
            : _users.isEmpty
                ? Center(child: Text(_t(code, 'noUsers'), style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink500)))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final u = _users[i];
                          final verified = u['is_verified'] == true;
                          final manual = u['manually_added'] == true;
                          final uid = u['_id']?.toString() ?? '';
                          final name = (u['full_name'] ?? _t(code, 'noName')).toString();
                          return _UserRow(
                            name: name,
                            phone: (u['phone'] ?? '').toString(),
                            role: AdminStrings.roleLabel(code, u['role']?.toString()),
                            lang: AdminStrings.languageLabel(code, u['preferred_language']?.toString()),
                            verified: verified, manual: manual,
                            verifiedLabel: verified ? _t(code, 'verified') : _t(code, 'unverified'),
                            exemptLabel: _t(code, 'exempt'),
                            onEdit: () => _showForm(user: Map<String, dynamic>.from(u as Map)),
                            onDelete: () => _confirmDelete(uid, name),
                          );
                        },
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.name, required this.phone, required this.role, required this.lang,
    required this.verified, required this.manual,
    required this.verifiedLabel, required this.exemptLabel,
    required this.onEdit, required this.onDelete,
  });
  final String name, phone, role, lang, verifiedLabel, exemptLabel;
  final bool verified, manual;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().split(' ').take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(VetoTokens.rMd),
        border: const Border(
          left: BorderSide(color: VetoTokens.navy600, width: 3),
          top: BorderSide(color: VetoTokens.hairline),
          right: BorderSide(color: VetoTokens.hairline),
          bottom: BorderSide(color: VetoTokens.hairline),
        ),
        boxShadow: VetoTokens.shadow1,
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: VetoTokens.navy100,
            borderRadius: BorderRadius.circular(VetoTokens.rSm),
          ),
          alignment: Alignment.center,
          child: Text(initial.isEmpty ? '?' : initial,
              style: VetoTokens.serif(15, FontWeight.w800, color: VetoTokens.navy700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
              if (phone.isNotEmpty)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(phone, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
                ),
              Text('$role · $lang', style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink300)),
            ],
          ),
        ),
        _MicroBadge(verifiedLabel,
            color: verified ? VetoTokens.okSoft : VetoTokens.warnSoft,
            fg: verified ? const Color(0xFF16664B) : const Color(0xFF7A5300)),
        if (manual) ...[
          const SizedBox(width: 4),
          _MicroBadge(exemptLabel, color: VetoTokens.okSoft, fg: const Color(0xFF16664B)),
        ],
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18, color: VetoTokens.navy600),
          onPressed: onEdit,
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: VetoTokens.emerg),
          onPressed: onDelete,
          tooltip: 'Delete',
        ),
      ]),
    );
  }
}

class _MicroBadge extends StatelessWidget {
  const _MicroBadge(this.label, {required this.color, required this.fg});
  final String label;
  final Color color, fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(VetoTokens.rPill)),
      child: Text(label, style: VetoTokens.sans(10, FontWeight.w700, color: fg)),
    );
  }
}

class _LightField extends StatelessWidget {
  const _LightField({required this.controller, required this.label, required this.icon, this.ltr = false});
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool ltr;

  static InputDecoration dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 16, color: VetoTokens.ink500),
        filled: true,
        fillColor: VetoTokens.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VetoTokens.hairline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VetoTokens.hairline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VetoTokens.navy500, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textDirection: ltr ? TextDirection.ltr : Directionality.of(context),
      decoration: dec(label, icon),
    );
  }
}
