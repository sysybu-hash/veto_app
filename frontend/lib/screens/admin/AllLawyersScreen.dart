import 'package:flutter/material.dart';
import '../../core/theme/veto_theme.dart';
import '../../services/admin_service.dart';

class AllLawyersScreen extends StatefulWidget {
  const AllLawyersScreen({super.key});
  @override
  State<AllLawyersScreen> createState() => _AllLawyersScreenState();
}

class _AllLawyersScreenState extends State<AllLawyersScreen> {
  List<dynamic> _lawyers = [];
  bool _loading = true;
  final _svc = AdminService();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getAllLawyers();
    if (mounted) setState(() { _lawyers = data; _loading = false; });
  }

  Future<void> _showForm({Map<String, dynamic>? lawyer}) async {
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
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: Text(id == null ? 'הוסף עורך דין' : 'ערוך עורך דין',
              style: const TextStyle(color: VetoPalette.text)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(nameCtrl,  'שם מלא',          Icons.badge_outlined),
              const SizedBox(height: 10),
              _field(phoneCtrl, 'טלפון (+972...)',  Icons.phone_iphone_rounded, dir: TextDirection.ltr),
              const SizedBox(height: 10),
              _field(emailCtrl, 'אימייל',           Icons.email_outlined, dir: TextDirection.ltr),
              const SizedBox(height: 10),
              _field(licCtrl,   'מספר רישיון',      Icons.numbers),
              const SizedBox(height: 10),
              _field(expCtrl,   'שנות ניסיון',      Icons.work_outline,
                  type: TextInputType.number),
              const SizedBox(height: 10),
              _field(specsCtrl, 'התמחויות (פסיק)',  Icons.category_outlined),
              const SizedBox(height: 10),
              StatefulBuilder(builder: (_, ss) => SwitchListTile.adaptive(
                value: available,
                onChanged: (v) => ss(() => available = v),
                contentPadding: EdgeInsets.zero,
                title: const Text('זמין לקריאות', style: TextStyle(color: VetoPalette.text)),
              )),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
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
                if (id == null) await _svc.createLawyer(body);
                else await _svc.updateLawyer(id, body);
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
          title: const Text('מחיקת עורך דין', style: TextStyle(color: VetoPalette.text)),
          content: Text('מחק את "$name"?', style: const TextStyle(color: VetoPalette.textMuted)),
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
    if (ok == true) { await _svc.deleteLawyer(id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.surface,
          title: Text('עורכי דין (${_loading ? "..." : _lawyers.length})',
              style: const TextStyle(color: VetoPalette.text)),
          iconTheme: const IconThemeData(color: VetoPalette.text),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showForm(),
          backgroundColor: VetoPalette.primary,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('הוסף עורך דין'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _lawyers.isEmpty
                ? const Center(child: Text('אין עורכי דין', style: TextStyle(color: VetoPalette.textMuted)))
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
                            Text(l['full_name'] ?? 'ללא שם',
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
                            child: Text(available ? 'זמין' : 'לא זמין',
                                style: TextStyle(color: available ? VetoPalette.success : VetoPalette.textMuted, fontSize: 10)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: VetoPalette.primary),
                            onPressed: () => _showForm(lawyer: Map<String, dynamic>.from(l as Map)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: VetoPalette.emergency),
                            onPressed: () => _confirmDelete(lid, l['full_name']?.toString() ?? ''),
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
