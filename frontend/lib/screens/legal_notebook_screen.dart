// ============================================================
//  NotebookLM Enterprise (prep) — list, open in browser, sync
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/legal_notebook_api_service.dart';
import '../widgets/citizen_mockup_shell.dart';
import 'legal_notebook_editor_screen.dart';

class LegalNotebookScreen extends StatefulWidget {
  const LegalNotebookScreen({super.key});

  @override
  State<LegalNotebookScreen> createState() => _LegalNotebookScreenState();
}

class _LegalNotebookScreenState extends State<LegalNotebookScreen> {
  final _api = LegalNotebookApiService();
  final _auth = AuthService();
  late final Future<String?> _citizenChromeFuture = _auth.getStoredRole();

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  bool _load = true;
  bool _intentBannerHandled = false;
  String? _intent;
  String? _domain;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intentBannerHandled) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final intent = args['intent']?.toString();
      final domain = args['domain']?.toString();
      if (intent != null || domain != null) {
        _intent = intent;
        _domain = domain;
      }
    }
    _intentBannerHandled = true;
  }

  Widget _buildNotebookRow(Map<String, dynamic> r) {
    final id = (r['_id'] ?? r['id']).toString();
    return V26Card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            child: const Icon(Icons.book_outlined,
                color: V26.navy600, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (r['name'] ?? _l10n.nbScrDefaultNotebookName) as String,
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
            tooltip: _l10n.nbScrSyncTooltip,
            icon: const Icon(Icons.sync, color: V26.navy600, size: 20),
            onPressed: () async {
              final res = await _api.sync(id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    res?['sync']?['ok'] == true
                        ? _l10n.nbScrSyncOkTesting
                        : (res?['sync']?['message'] as String? ??
                            res?['sync']?['error'] as String? ??
                            _l10n.nbScrSyncFallback),
                  ),
                ),
              );
              await _reload();
            },
          ),
          IconButton(
            tooltip: _l10n.nbScrOpenBrowserTooltip,
            icon: const Icon(Icons.open_in_new,
                color: V26.ink500, size: 20),
            onPressed: () => _api.openInBrowser(id),
          ),
          IconButton(
            tooltip: _l10n.nbScrExportPdfTooltip,
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: VetoMockup.primaryCta, size: 20),
            onPressed: () => _exportNotebook(r, 'pdf'),
          ),
          IconButton(
            tooltip: _l10n.nbScrExportDocxTooltip,
            icon: const Icon(Icons.description_outlined,
                color: VetoMockup.primaryCta, size: 20),
            onPressed: () => _exportNotebook(r, 'docx'),
          ),
          V26CTA(
            _l10n.nbScrEdit,
            variant: V26CtaVariant.ghost,
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      LegalNotebookEditorScreen(notebookId: id),
                ),
              ).then((_) => _reload());
            },
          ),
        ],
      ),
    );
  }

  String _intentLabel(AppLocalizations loc) {
    switch (_intent) {
      case 'contract_review':
        return loc.nbScrIntentContractReview;
      case 'demand_letter':
        return loc.nbScrIntentDemandLetter;
      case 'civil_claim':
        return loc.nbScrIntentCivilClaim;
      case 'labor_doc':
        return loc.nbScrIntentLaborDoc;
      case 'family_doc':
        return loc.nbScrIntentFamilyDoc;
      default:
        return _intent ?? '';
    }
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

  Future<void> _exportNotebook(Map<String, dynamic> row, String format) async {
    final title = (row['name'] ?? _l10n.nbScrTitle) as String;
    final body =
        'Generated from notebook: $title\nStatus: ${(row['status'] ?? 'draft')}';
    final ok = await _api.exportLegalDocument(
      title: title,
      body: body,
      format: format,
      domain: 'notebook',
      intent: 'export',
      lang: codeForContext(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (format == 'pdf'
                ? _l10n.nbScrExportPdfOk
                : _l10n.nbScrExportDocxOk)
            : _l10n.nbScrExportFailed),
      ),
    );
  }

  String codeForContext() =>
      context.read<AppLanguageController>().code;

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isWide =
        MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;
    final statusText = _l10n.nbScrDesktopStatus;
    final intentBanner = (_intent != null)
        ? Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: VetoMockup.primaryCta.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(VetoMockup.radiusCard),
              border: Border.all(
                  color: VetoMockup.primaryCta.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded,
                    color: VetoMockup.primaryCta, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _l10n.nbScrIntentBanner(
                      _intentLabel(_l10n),
                      _domain ?? _l10n.nbScrIntentDomainFallback,
                    ),
                    style: const TextStyle(
                      color: VetoMockup.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await _api.create();
                    await _reload();
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(_l10n.nbScrNewNotebook),
                  style: FilledButton.styleFrom(
                    backgroundColor: VetoMockup.primaryCta,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
    final bodyChild = _load
            ? const Center(
                child: CircularProgressIndicator(color: V26.navy600))
            : Column(
                children: [
                  intentBanner,
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _buildNotebookRow(_rows[i]),
                    ),
                  ),
                ],
              );
    final fabNarrowCitizen = !isWide
        ? FloatingActionButton.extended(
            onPressed: () async {
              await _api.create();
              await _reload();
            },
            backgroundColor: VetoMockup.primaryCta,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(_l10n.nbScrNotebookShort,
                style: const TextStyle(
                    fontFamily: V26.sans, fontWeight: FontWeight.w700)),
            heroTag: 'nb_ent_fab',
          )
        : null;

    final fabNarrowLegacy = !isWide
        ? FloatingActionButton.extended(
            onPressed: () async {
              await _api.create();
              await _reload();
            },
            backgroundColor: V26.navy600,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(_l10n.nbScrNotebookShort,
                style: const TextStyle(
                    fontFamily: V26.sans, fontWeight: FontWeight.w700)),
            heroTag: 'nb_ent_fab',
          )
        : null;

    return FutureBuilder<String?>(
      future: _citizenChromeFuture,
      builder: (context, snap) {
        final citizen = snap.data == 'user';
        if (citizen) {
          return Directionality(
            textDirection: AppLanguage.directionOf(code),
            child: CitizenMockupShell(
              currentRoute: '/legal_notebook',
              mobileNavIndex:
                  citizenMobileNavIndexForRoute('/legal_notebook'),
              desktopTrailing: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: VetoMockup.ink),
                  tooltip: _l10n.nbScrRefreshTooltip,
                  onPressed: _load ? null : _reload,
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () async {
                    await _api.create();
                    await _reload();
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(_l10n.nbScrNewNotebook,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: VetoMockup.primaryCta,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
              floatingActionButton: fabNarrowCitizen,
              mobileAppBar: AppBar(
                backgroundColor: VetoMockup.surfaceCard,
                foregroundColor: VetoMockup.ink,
                elevation: 0,
                title: Text(
                  _l10n.nbScrTitle,
                  style: const TextStyle(
                    fontFamily: V26.serif,
                    color: VetoMockup.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1, color: VetoMockup.hairline),
                ),
                actions: [
                  IconButton(
                    onPressed: _load ? null : _reload,
                    tooltip: _l10n.nbScrRefreshTooltip,
                    icon: const Icon(Icons.refresh, color: VetoMockup.inkSecondary),
                  ),
                ],
              ),
              child: bodyChild,
            ),
          );
        }
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
                tooltip: _l10n.nbScrRefreshTooltip,
                onTap: _load ? null : _reload,
              ),
              const SizedBox(width: 8),
              V26PillCTA(
                label: _l10n.nbScrNewNotebook,
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
              title: Text(
                _l10n.nbScrTitle,
                style: const TextStyle(
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
                  tooltip: _l10n.nbScrRefreshTooltip,
                  icon: const Icon(Icons.refresh, color: V26.ink700),
                ),
              ],
            ),
            floatingAction: fabNarrowLegacy,
            child: bodyChild,
          ),
        );
      },
    );
  }
}
