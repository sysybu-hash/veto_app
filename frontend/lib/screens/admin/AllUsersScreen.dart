import 'package:flutter/material.dart';
import '../../core/theme/veto_theme.dart';
import '../../services/admin_service.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});
  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  final _svc = AdminService();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getAllUsers();
    if (mounted) setState(() { _users = data; _loading = false; });
  }

  Future<void> _showForm({Map<String, dynamic>? user}) async {
    final nameCtrl  = TextEditingController(text: user?['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    String role     = user?['role'] ?? 'user';
    String lang     = user?['preferred_language'] ?? 'he';
    final id        = user?['_id']?.toString();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: Text(id == null ? 'הוסף משתמש' : 'ערוך משתמש',
              style: const TextStyle(color: VetoPalette.text)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(nameCtrl,  'שם מלא',    Icons.badge_outlined),
              const SizedBox(height: 10),
              _field(phoneCtrl, 'טלפון (+972...)', Icons.phone_iphone_rounded,
                  dir: TextDirection.ltr),
              const SizedBox(height: 10),
              StatefulBuilder(builder: (_, ss) => Column(children: [
                DropdownButtonFormField<String>(
                  value: role,
                  dropdownColor: VetoPalette.bg,
                  style: const TextStyle(color: VetoPalette.text),
                  decoration: _dec('תפקיד', Icons.shield_outlined),
                  items: const [
                    DropdownMenuItem(value: 'user',  child: Text('אזרח')),
                    DropdownMenuItem(value: 'admin', child: Text('אדמין')),
                  ],
                  onChanged: (v) => ss(() => role = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: lang,
                  dropdownColor: VetoPalette.bg,
                  style: const TextStyle(color: VetoPalette.text),
                  decoration: _dec('שפה', Icons.language),
                  items: const [
                    DropdownMenuItem(value: 'he', child: Text('עברית')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  ],
                  onChanged: (v) => ss(() => lang = v!),
                ),
              ])),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final body = {
                  'full_name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'role': role,
                  'preferred_language': lang,
                };
                if (id == null) await _svc.createUser(body);
                else await _svc.updateUser(id, body);
                _load();
              },
              child: Text(id == null ? 'הוסף' : 'שמור'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: const Text('מחיקת משתמש', style: TextStyle(color: VetoPalette.text)),
          content: Text('מחק את "$name"? לא ניתן לבטל.',
              style: const TextStyle(color: VetoPalette.textMuted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ביטול')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('מחק'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) { await _svc.deleteUser(id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.surface,
          title: Text('משתמשים (${_loading ? "..." : _users.length})',
              style: const TextStyle(color: VetoPalette.text)),
          iconTheme: const IconThemeData(color: VetoPalette.text),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'רענן'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showForm(),
          backgroundColor: VetoPalette.primary,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('הוסף משתמש'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
                ? const Center(child: Text('אין משתמשים', style: TextStyle(color: VetoPalette.textMuted)))
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
                          border: Border.all(color: VetoPalette.border),
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
                            Text(u['full_name'] ?? 'ללא שם',
                                style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w600)),
                            Text(u['phone'] ?? '', textDirection: TextDirection.ltr,
                                style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
                            Text(u['role'] == 'admin' ? 'אדמין' : 'אזרח',
                                style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11)),
                          ])),
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (verified ? VetoPalette.success : VetoPalette.warning).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(verified ? 'מאומת' : 'לא מאומת',
                                style: TextStyle(color: verified ? VetoPalette.success : VetoPalette.warning, fontSize: 10)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: VetoPalette.primary),
                            onPressed: () => _showForm(user: Map<String, dynamic>.from(u as Map)),
                            tooltip: 'ערוך',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: VetoPalette.emergency),
                            onPressed: () => _confirmDelete(uid, u['full_name']?.toString() ?? ''),
                            tooltip: 'מחק',
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
