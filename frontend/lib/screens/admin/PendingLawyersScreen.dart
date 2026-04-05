import 'package:flutter/material.dart';
import '../../core/theme/veto_theme.dart';
import '../../services/admin_service.dart';

class PendingLawyersScreen extends StatefulWidget {
  const PendingLawyersScreen({super.key});

  @override
  State<PendingLawyersScreen> createState() => _PendingLawyersScreenState();
}

class _PendingLawyersScreenState extends State<PendingLawyersScreen> {
  List<dynamic> _lawyers = [];
  bool _loading = true;
  final _svc = AdminService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getPendingLawyers();
    if (mounted) setState(() { _lawyers = data; _loading = false; });
  }

  Future<void> _approve(String id, String name) async {
    final ok = await _svc.approveLawyer(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '׳׳•׳©׳¨: $name' : '׳©׳’׳™׳׳” ׳‘׳׳™׳©׳•׳¨'),
      backgroundColor: ok ? VetoPalette.success : VetoPalette.emergency,
    ));
    if (ok) _load();
  }

  Future<void> _reject(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: const Text('׳“׳—׳™׳™׳× ׳‘׳§׳©׳”', style: TextStyle(color: VetoPalette.text)),
          content: Text('׳”׳׳ ׳׳“׳—׳•׳× ׳׳× ׳‘׳§׳©׳× $name?',
              style: const TextStyle(color: VetoPalette.textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('׳‘׳™׳˜׳•׳', style: TextStyle(color: VetoPalette.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('׳“׳—׳”', style: TextStyle(color: VetoPalette.emergency)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _svc.rejectLawyer(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '׳ ׳“׳—׳”: $name' : '׳©׳’׳™׳׳” ׳‘׳“׳—׳™׳™׳”'),
      backgroundColor: ok ? VetoPalette.success : VetoPalette.emergency,
    ));
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.surface,
          title: const Text('׳¢׳•׳¨׳›׳™ ׳“׳™׳ ׳׳׳×׳™׳ ׳™׳ ׳׳׳™׳©׳•׳¨',
              style: TextStyle(color: VetoPalette.text, fontSize: 18)),
          iconTheme: const IconThemeData(color: VetoPalette.text),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: '׳¨׳¢׳ ׳',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoPalette.primary))
            : _lawyers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 64, color: VetoPalette.success),
                        SizedBox(height: 16),
                        Text('׳׳™׳ ׳‘׳§׳©׳•׳× ׳׳׳×׳™׳ ׳•׳×',
                            style: TextStyle(color: VetoPalette.textMuted, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _lawyers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final l = _lawyers[i];
                      final id = l['_id']?.toString() ?? '';
                      final name = l['full_name'] ?? 'ג€”';
                      final phone = l['phone'] ?? 'ג€”';
                      final email = l['email'] ?? '';
                      final license = l['license_number'] ?? 'ג€”';
                      final exp = l['years_of_experience']?.toString() ?? '0';
                      final specs = (l['specializations'] as List?)?.join(', ') ?? 'ג€”';

                      return Container(
                        decoration: BoxDecoration(
                          color: VetoPalette.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.gavel_rounded,
                                  color: VetoPalette.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        color: VetoPalette.text,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            _info(Icons.phone_iphone_rounded, phone),
                            if (email.isNotEmpty) _info(Icons.email_outlined, email),
                            _info(Icons.numbers_rounded, '׳¨׳™׳©׳™׳•׳: $license'),
                            _info(Icons.work_outline_rounded, '׳ ׳™׳¡׳™׳•׳: $exp ׳©׳ ׳™׳'),
                            _info(Icons.category_outlined, '׳”׳×׳׳—׳•׳™׳•׳×: $specs'),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _reject(id, name),
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  label: const Text('׳“׳—׳”'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: VetoPalette.emergency,
                                    side: const BorderSide(color: VetoPalette.emergency),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _approve(id, name),
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: const Text('׳׳©׳¨'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: VetoPalette.success,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(icon, size: 14, color: VetoPalette.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: VetoPalette.textMuted, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}
