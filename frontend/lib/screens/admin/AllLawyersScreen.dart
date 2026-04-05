import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_theme.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_language_menu.dart';
import 'admin_i18n.dart';

class AllLawyersScreen extends StatefulWidget {
  const AllLawyersScreen({super.key});
  @override
  State<AllLawyersScreen> createState() => _AllLawyersScreenState();
}

class _AllLawyersScreenState extends State<AllLawyersScreen> {
  List<dynamic> _lawyers = [];
  bool _loading = true;
  final _svc = AdminService();

  String _t(String code, String key) => AdminStrings.t(code, key);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getAllLawyers();
    if (mounted) setState(() { _lawyers = data; _loading = false; });
  }

  Future<void> _showForm({Map<String, dynamic>? lawyer}) async {
    final code = context.read<AppLanguageController>().code;
    final nameCtrl    = TextEditingController(text: lawyer?['full_name'] ?? '');
    final phoneCtrl   = TextEditingController(text: lawyer?['phone'] ?? '');
    final emailCtrl   = TextEditingController(text: lawyer?['email'] ?? '');
    final licCtrl     = TextEditingController(text: lawyer?['license_number'] ?? '');
    final expCtrl     = TextEditingController(text: (lawyer?['years_of_experience'] ?? 0).toString());
    final specsCtrl   = TextEditingController(
        text: ((lawyer?['specializations'] as List?)?.join(', ')) ?? '');
    bool available    = lawyer?['is_available'] ?? true;
    final id          = lawyer?['_id']?.toString();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: Text(id == null ? _t(code, 'addLawyer') : _t(code, 'editLawyer'),
              style: const TextStyle(color: VetoPalette.text)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(nameCtrl,  _t(code, 'fullName'),          Icons.badge_outlined),
              const SizedBox(height: 10),
              _field(phoneCtrl, _t(code, 'phone'),  Icons.phone_iphone_rounded, dir: TextDirection.ltr),
              const SizedBox(height: 10),
              _field(emailCtrl, _t(code, 'email'),           Icons.email_outlined, dir: TextDirection.ltr),
              const SizedBox(height: 10),
              _field(licCtrl,   _t(code, 'license'),      Icons.numbers),
              const SizedBox(height: 10),
              _field(expCtrl,   _t(code, 'experience'),      Icons.work_outline,
                  type: TextInputType.number),
              const SizedBox(height: 10),
              _field(specsCtrl, _t(code, 'specializations'),  Icons.category_outlined),
              const SizedBox(height: 10),
              StatefulBuilder(builder: (_, ss) => SwitchListTile.adaptive(
                value: available,
                onChanged: (v) => ss(() => available = v),
                contentPadding: EdgeInsets.zero,
                title: Text(_t(code, 'availableForCalls'), style: const TextStyle(color: VetoPalette.text)),
              )),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t(code, 'cancel'))),
            FilledButton(
              onPressed: () async {
                final specs = specsCtrl.text.trim().isEmpty ? <String>[]
                    : specsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                final body = {
                  'full_name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'license_number': licCtrl.text.trim(),
                  'years_of_experience': int.tryParse(expCtrl.text.trim()) ?? 0,
                  'specializations': specs,
                  'is_available': available,
                };
                final bool ok = id == null
                    ? (await _svc.createLawyer(body)) != null
                    : await _svc.updateLawyer(id, body);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (ok) {
                  _load();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_t(code, 'saveLawyerFailed')),
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
          title: Text(_t(code, 'deleteLawyer'), style: const TextStyle(color: VetoPalette.text)),
          content: Text('${_t(code, 'deleteLawyerConfirm')}\n$name', style: const TextStyle(color: VetoPalette.textMuted)),
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
    if (ok == true) { await _svc.deleteLawyer(id); _load(); }
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
          title: Text('${_t(code, 'lawyers')} (${_loading ? _t(code, 'loading') : _lawyers.length})',
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
          label: Text(_t(code, 'addLawyer')),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _lawyers.isEmpty
                ? Center(child: Text(_t(code, 'noLawyers'), style: const TextStyle(color: VetoPalette.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _lawyers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final l = _lawyers[i];
                      final available = l['is_available'] == true;
                      final lid = l['_id']?.toString() ?? '';
                      final specs = (l['specializations'] as List?)?.join(', ') ?? '';
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
                            child: const Icon(Icons.gavel_rounded, color: VetoPalette.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l['full_name'] ?? _t(code, 'noName'),
                                style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w600)),
                            Text(l['phone'] ?? '', textDirection: TextDirection.ltr,
                                style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
                            if (specs.isNotEmpty)
                              Text(specs, style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11)),
                          ])),
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (available ? VetoPalette.success : VetoPalette.textMuted).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(available ? _t(code, 'available') : _t(code, 'unavailable'),
                                style: TextStyle(color: available ? VetoPalette.success : VetoPalette.textMuted, fontSize: 10)),
                          ),
                          if (l['is_approved'] != true)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: VetoPalette.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_t(code, 'pendingSingle'),
                                  style: const TextStyle(color: VetoPalette.warning, fontSize: 10)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: VetoPalette.primary),
                            onPressed: () => _showForm(lawyer: Map<String, dynamic>.from(l as Map)),
                            tooltip: _t(code, 'edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: VetoPalette.emergency),
                            onPressed: () => _confirmDelete(lid, l['full_name']?.toString() ?? ''),
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
      {TextDirection dir = TextDirection.rtl, TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctrl, textDirection: dir, keyboardType: type,
        style: const TextStyle(color: VetoPalette.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: VetoPalette.textMuted),
          prefixIcon: Icon(icon, color: VetoPalette.textMuted, size: 18),
          filled: true, fillColor: VetoPalette.bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VetoPalette.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VetoPalette.border)),
        ),
      );
}
