// ============================================================
//  NotebookLM Enterprise (prep) — list, open in browser, sync
// ============================================================

import 'package:flutter/material.dart';

import '../core/theme/veto_glass_system.dart';
import '../services/legal_notebook_api_service.dart';

class LegalNotebookScreen extends StatefulWidget {
  const LegalNotebookScreen({super.key});

  @override
  State<LegalNotebookScreen> createState() => _LegalNotebookScreenState();
}

class _LegalNotebookScreenState extends State<LegalNotebookScreen> {
  final _api = LegalNotebookApiService();
  bool _load = true;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _load = true);
    final n = await _api.list();
    if (!mounted) return;
    setState(() {
      _rows = n;
      _load = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VetoGlassTokens.bgBase,
      appBar: AppBar(
        backgroundColor: VetoGlassTokens.bgBase,
        foregroundColor: VetoGlassTokens.textPrimary,
        title: const Text('מחברת (Enterprise)'),
        actions: [
          IconButton(
            onPressed: _load ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _load
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _rows.length,
              itemBuilder: (ctx, i) {
                final r = _rows[i];
                final id = (r['_id'] ?? r['id']).toString();
                return Card(
                  color: VetoGlassTokens.glassFillStrong,
                  child: ListTile(
                    title: Text(
                      (r['name'] ?? 'Notebook') as String,
                      style: const TextStyle(
                        color: VetoGlassTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      (r['status'] ?? '—') as String,
                      style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 12),
                    ),
                    isThreeLine: r['lastError'] != null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sync, color: VetoGlassTokens.accentSoft, size: 20),
                          onPressed: () async {
                            final res = await _api.sync(id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res?['sync']?['ok'] == true
                                      ? 'הסנכרון הושלם (בבדיקת API)'
                                      : (res?['sync']?['message'] as String? ?? res?['sync']?['error'] as String? ?? 'סנכרון'),
                                ),
                              ),
                            );
                            await _reload();
                          },
                        ),
                        TextButton(
                          onPressed: () => _api.openInBrowser(id),
                          child: const Text('פתח', style: TextStyle(color: VetoGlassTokens.accentSoft)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _api.create();
          await _reload();
        },
        backgroundColor: VetoGlassTokens.accentSoft,
        icon: const Icon(Icons.add),
        label: const Text('מחברת'),
        heroTag: 'nb_ent_fab',
      ),
    );
  }
}
