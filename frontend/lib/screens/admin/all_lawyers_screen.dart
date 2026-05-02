// ============================================================
//  AllLawyersScreen — VETO 2026
//  Tokens-aligned. CRUD lawyers, specializations, availability.
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_tokens_2026.dart';
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
  void initState() {
    super.initState();
    _load();
  }

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
    bool available = lawyer?['is_available'] ?? true;
    final id = lawyer?['_id']?.toString();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          title: Text(id == null ? _t(code, 'addLawyer') : _t(code, 'editLawyer'), style: VetoTokens.titleLg),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _f(nameCtrl,  _t(code, 'fullName'),         Icons.badge_outlined),
                const SizedBox(height: 10),
                _f(phoneCtrl, _t(code, 'phone'),            Icons.phone_iphone_rounded, ltr: true),
                const SizedBox(height: 10),
                _f(emailCtrl, _t(code, 'email'),            Icons.email_outlined, ltr: true),
                const SizedBox(height: 10),
                _f(licCtrl,   _t(code, 'license'),          Icons.numbers),
                const SizedBox(height: 10),
                _f(expCtrl,   _t(code, 'experience'),       Icons.work_outline_rounded, type: TextInputType.number),
                const SizedBox(height: 10),
                _f(specsCtrl, _t(code, 'specializations'),  Icons.category_outlined),
                const SizedBox(height: 6),
                StatefulBuilder(builder: (_, ss) => SwitchListTile.adaptive(
                  value: available,
                  onChanged: (v) => ss(() => available = v),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: Colors.white,
                  activeTrackColor: VetoTokens.ok,
                  title: Text(_t(code, 'availableForCalls'), style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
                )),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t(code, 'cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: VetoTokens.navy600, foregroundColor: Colors.white),
              onPressed: () async {
                final specs = specsCtrl.text.trim().isEmpty
                    ? <String>[]
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
                final ok = id == null
                    ? (await _svc.createLawyer(body)) != null
                    : await _svc.updateLawyer(id, body);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (ok) {
                  _load();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_t(code, 'saveLawyerFailed')),
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
          title: Text(_t(code, 'deleteLawyer'), style: VetoTokens.titleLg),
          content: Text('${_t(code, 'deleteLawyerConfirm')}\n$name', style: VetoTokens.bodyMd),
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
    if (ok == true) { await _svc.deleteLawyer(id); _load(); }
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
            '${_t(code, 'lawyers')} (${_loading ? _t(code, 'loading') : _lawyers.length})',
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
          label: Text(_t(code, 'addLawyer'), style: VetoTokens.labelMd.copyWith(color: Colors.white)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
            : _lawyers.isEmpty
                ? Center(child: Text(_t(code, 'noLawyers'), style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink500)))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: _lawyers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final l = _lawyers[i];
                          final available = l['is_available'] == true;
                          final approved = l['is_approved'] == true;
                          final lid = l['_id']?.toString() ?? '';
                          final specs = (l['specializations'] as List?)?.join(', ') ?? '';
                          return _LawyerRow(
                            name: (l['full_name'] ?? _t(code, 'noName')).toString(),
                            phone: (l['phone'] ?? '').toString(),
                            specs: specs,
                            availableLabel: available ? _t(code, 'available') : _t(code, 'unavailable'),
                            available: available,
                            approved: approved,
                            pendingLabel: _t(code, 'pendingSingle'),
                            onEdit: () => _showForm(lawyer: Map<String, dynamic>.from(l as Map)),
                            onDelete: () => _confirmDelete(lid, l['full_name']?.toString() ?? ''),
                          );
                        },
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _f(TextEditingController c, String label, IconData icon, {bool ltr = false, TextInputType? type}) {
    return TextField(
      controller: c,
      textDirection: ltr ? TextDirection.ltr : null,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 16, color: VetoTokens.ink500),
        filled: true,
        fillColor: VetoTokens.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VetoTokens.hairline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VetoTokens.hairline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VetoTokens.navy500, width: 1.5)),
      ),
    );
  }
}

class _LawyerRow extends StatelessWidget {
  const _LawyerRow({
    required this.name, required this.phone, required this.specs,
    required this.availableLabel, required this.available,
    required this.approved, required this.pendingLabel,
    required this.onEdit, required this.onDelete,
  });
  final String name, phone, specs, availableLabel, pendingLabel;
  final bool available, approved;
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
          left: BorderSide(color: VetoTokens.navy500, width: 3),
          top: BorderSide(color: VetoTokens.hairline),
          right: BorderSide(color: VetoTokens.hairline),
          bottom: BorderSide(color: VetoTokens.hairline),
        ),
        boxShadow: VetoTokens.shadow1,
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(gradient: VetoTokens.crestGradient, borderRadius: BorderRadius.circular(VetoTokens.rSm)),
          alignment: Alignment.center,
          child: initial.isEmpty
              ? const Icon(Icons.gavel_rounded, size: 18, color: Colors.white)
              : Text(initial, style: VetoTokens.serif(15, FontWeight.w800, color: Colors.white)),
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
              if (specs.isNotEmpty)
                Text(specs, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink300), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: available ? VetoTokens.okSoft : VetoTokens.paper2,
            borderRadius: BorderRadius.circular(VetoTokens.rPill),
          ),
          child: Text(availableLabel,
              style: VetoTokens.sans(10, FontWeight.w700, color: available ? const Color(0xFF16664B) : VetoTokens.ink500)),
        ),
        if (!approved) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: VetoTokens.warnSoft, borderRadius: BorderRadius.circular(VetoTokens.rPill)),
            child: Text(pendingLabel, style: VetoTokens.sans(10, FontWeight.w700, color: const Color(0xFF7A5300))),
          ),
        ],
        IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: VetoTokens.navy600), onPressed: onEdit, tooltip: 'Edit'),
        IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: VetoTokens.emerg), onPressed: onDelete, tooltip: 'Delete'),
      ]),
    );
  }
}
