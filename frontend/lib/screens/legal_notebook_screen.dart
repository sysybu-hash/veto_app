// ============================================================
//  LegalNotebookScreen — VETO 2026
//  Tokens-aligned. NotebookLM Enterprise list / open / sync.
// ============================================================
import 'package:flutter/material.dart';

import '../core/theme/veto_tokens_2026.dart';
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
      backgroundColor: VetoTokens.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('מחברת · Enterprise', style: VetoTokens.titleLg),
        actions: [
          IconButton(
            onPressed: _load ? null : _reload,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: 'רענן',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _api.create();
          await _reload();
        },
        backgroundColor: VetoTokens.navy600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('מחברת חדשה', style: VetoTokens.labelMd.copyWith(color: Colors.white)),
        heroTag: 'nb_ent_fab',
      ),
      body: _load
          ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
          : _rows.isEmpty
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(32),
                    decoration: VetoTokens.cardDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(color: VetoTokens.paper2, borderRadius: BorderRadius.circular(20)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.menu_book_rounded, size: 28, color: VetoTokens.ink300),
                        ),
                        const SizedBox(height: 12),
                        Text('אין מחברות עדיין', style: VetoTokens.serif(18, FontWeight.w700, color: VetoTokens.ink900)),
                        const SizedBox(height: 4),
                        Text('צור מחברת חדשה כדי להתחיל לתעד תיק.', style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final r = _rows[i];
                        final id = (r['_id'] ?? r['id']).toString();
                        final name = (r['name'] ?? 'Notebook').toString();
                        final status = (r['status'] ?? '—').toString();
                        return _NotebookCard(
                          name: name,
                          status: status,
                          onSync: () async {
                            final res = await _api.sync(id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                res?['sync']?['ok'] == true
                                    ? 'הסנכרון הושלם'
                                    : (res?['sync']?['message'] as String? ?? res?['sync']?['error'] as String? ?? 'סנכרון'),
                              ),
                              backgroundColor: res?['sync']?['ok'] == true ? VetoTokens.ok : VetoTokens.warn,
                            ));
                            await _reload();
                          },
                          onOpen: () => _api.openInBrowser(id),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({required this.name, required this.status, required this.onSync, required this.onOpen});
  final String name, status;
  final VoidCallback onSync, onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: VetoTokens.cardDecoration(radius: VetoTokens.rMd),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: VetoTokens.navy100, borderRadius: BorderRadius.circular(VetoTokens.rSm)),
          alignment: Alignment.center,
          child: const Icon(Icons.menu_book_rounded, size: 20, color: VetoTokens.navy700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900)),
              const SizedBox(height: 2),
              Text(status, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
            ],
          ),
        ),
        IconButton(
          onPressed: onSync,
          icon: const Icon(Icons.sync_rounded, size: 18, color: VetoTokens.navy600),
          tooltip: 'סנכרן',
        ),
        TextButton(
          onPressed: onOpen,
          style: TextButton.styleFrom(
            foregroundColor: VetoTokens.navy600,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle: VetoTokens.labelMd,
          ),
          child: const Text('פתח'),
        ),
      ]),
    );
  }
}
