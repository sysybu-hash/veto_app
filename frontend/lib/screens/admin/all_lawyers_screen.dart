import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_2026.dart';
import '../../core/theme/veto_theme.dart';
import '../../services/admin_service.dart';
import '_shell.dart';
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
          backgroundColor: V26.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline),
          ),
          title: Text(id == null ? _t(code, 'addLawyer') : _t(code, 'editLawyer'),
              style: const TextStyle(color: V26.ink900)),
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
                title: Text(_t(code, 'availableForCalls'), style: const TextStyle(color: V26.ink900)),
              )),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t(code, 'cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: V26.navy600,
                foregroundColor: Colors.white,
              ),
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
          backgroundColor: V26.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline),
          ),
          title: Text(_t(code, 'deleteLawyer'), style: const TextStyle(color: V26.ink900)),
          content: Text('${_t(code, 'deleteLawyerConfirm')}\n$name', style: const TextStyle(color: V26.ink500)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(code, 'cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: VetoPalette.emergency, foregroundColor: Colors.white),
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
      child: AdminShell(
        active: AdminSection.lawyers,
        title: '${_t(code, 'lawyers')} (${_loading ? _t(code, 'loading') : _lawyers.length})',
        onRefresh: _load,
        floatingAction: FloatingActionButton.extended(
          onPressed: () => _showForm(),
          backgroundColor: V26.navy500,
          icon: const Icon(Icons.person_add_rounded),
          label: Text(_t(code, 'addLawyer')),
        ),
        body: V26Backdrop(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: V26.navy600))
            : _lawyers.isEmpty
                ? Center(child: Text(_t(code, 'noLawyers'), style: const TextStyle(color: V26.ink500)))
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
                          color: V26.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(color: V26.navy700, width: 3),
                            top: BorderSide(color: V26.hairline),
                            right: BorderSide(color: V26.hairline),
                            bottom: BorderSide(color: V26.hairline),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: V26.navy600.withValues(alpha: 0.12),
                            child: const Icon(Icons.gavel_rounded, color: V26.navy600, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l['full_name'] ?? _t(code, 'noName'),
                                style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w600)),
                            Text(l['phone'] ?? '', textDirection: TextDirection.ltr,
                                style: const TextStyle(color: V26.ink500, fontSize: 12)),
                            if (specs.isNotEmpty)
                              Text(specs, style: const TextStyle(color: V26.ink300, fontSize: 11)),
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
                            icon: const Icon(Icons.edit_outlined, size: 20, color: V26.navy600),
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
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextDirection dir = TextDirection.rtl, TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctrl, textDirection: dir, keyboardType: type,
        style: const TextStyle(color: V26.ink900),
        cursorColor: V26.navy600,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: V26.ink500),
          prefixIcon: Icon(icon, color: V26.ink500, size: 18),
          filled: true,
          fillColor: const Color(0xFF0F1A24),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: V26.hairline)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: V26.hairline)),
          focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: V26.navy600, width: 1.5)),
        ),
      );
}
