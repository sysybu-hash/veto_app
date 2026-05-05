// ============================================================
//  NotebookLM Enterprise (prep) — list, open in browser, sync
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../services/legal_notebook_api_service.dart';
import 'legal_notebook_editor_screen.dart';

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
    final code = context.watch<AppLanguageController>().code;
    final isWide =
        MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;
    final statusText = code == 'he'
        ? 'מחברת משפטית · VETO'
        : (code == 'ru'
            ? 'Юр. блокнот · VETO'
            : 'Legal notebook · VETO');
    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: V26AppShell(
        destinations: isWide
            ? V26CitizenNav.destinations(code)
            : V26CitizenNav.bottomDestinations(code),
        currentIndex: isWide ? 4 /* מחברת */ : -1,
        onDestinationSelected: (i) {
          final routes =
              isWide ? V26CitizenNav.routes : V26CitizenNav.bottomRoutes;
          V26CitizenNav.go(context, routes[i], current: '/legal_notebook');
        },
        desktopStatusText: statusText,
        desktopTrailing: [
          V26IconBtn(
            icon: Icons.refresh,
            tooltip: 'רענון',
            onTap: _load ? null : _reload,
          ),
          const SizedBox(width: 8),
          V26PillCTA(
            label: 'מחברת חדשה',
            icon: Icons.add,
            onTap: () async {
              await _api.create();
              await _reload();
            },
          ),
        ],
        mobileAppBar: AppBar(
          backgroundColor: V26.surface,
          foregroundColor: V26.ink900,
          elevation: 0,
          title: const Text(
            'מחברת משפטית',
            style: TextStyle(
              fontFamily: V26.serif,
              color: V26.ink900,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: V26.hairline),
          ),
          actions: [
            IconButton(
              onPressed: _load ? null : _reload,
              icon: const Icon(Icons.refresh, color: V26.ink700),
            ),
          ],
        ),
        floatingAction: isWide
            ? null
            : FloatingActionButton.extended(
                onPressed: () async {
                  await _api.create();
                  await _reload();
                },
                backgroundColor: V26.navy600,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('מחברת',
                    style: TextStyle(
                        fontFamily: V26.sans, fontWeight: FontWeight.w700)),
                heroTag: 'nb_ent_fab',
              ),
        child: _load
            ? const Center(
                child: CircularProgressIndicator(color: V26.navy600))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final r = _rows[i];
                  final id = (r['_id'] ?? r['id']).toString();
                  return V26Card(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: V26.paper2,
                            border: Border.all(color: V26.hairline),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              const Icon(Icons.book_outlined, color: V26.navy600, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (r['name'] ?? 'Notebook') as String,
                                style: const TextStyle(
                                  fontFamily: V26.sans,
                                  color: V26.ink900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (r['status'] ?? '—') as String,
                                style: const TextStyle(
                                  fontFamily: V26.sans,
                                  color: V26.ink500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'סנכרון',
                          icon: const Icon(Icons.sync,
                              color: V26.navy600, size: 20),
                          onPressed: () async {
                            final res = await _api.sync(id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res?['sync']?['ok'] == true
                                      ? 'הסנכרון הושלם (בבדיקת API)'
                                      : (res?['sync']?['message'] as String? ??
                                          res?['sync']?['error'] as String? ??
                                          'סנכרון'),
                                ),
                              ),
                            );
                            await _reload();
                          },
                        ),
                        IconButton(
                          tooltip: 'NotebookLM בדפדפן',
                          icon: const Icon(Icons.open_in_new, color: V26.ink500, size: 20),
                          onPressed: () => _api.openInBrowser(id),
                        ),
                        V26CTA(
                          'עריכה',
                          variant: V26CtaVariant.ghost,
                          onPressed: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => LegalNotebookEditorScreen(notebookId: id),
                              ),
                            ).then((_) => _reload());
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
