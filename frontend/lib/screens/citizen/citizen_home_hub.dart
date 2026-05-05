// ============================================================
//  citizen_home_hub.dart — mockup hub (welcome, CTA, tools, KPIs)
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/veto_mockup_tokens.dart';
import '../../services/citizen_dashboard_api_service.dart';

class CitizenHomeHub extends StatefulWidget {
  const CitizenHomeHub({
    super.key,
    required this.userName,
    required this.onSendVeto,
    required this.onOpenLegalTool,
    this.inlineAiPanel,
  });

  final String userName;
  final VoidCallback onSendVeto;
  final void Function(String route, {Object? arguments}) onOpenLegalTool;
  final Widget? inlineAiPanel;

  @override
  State<CitizenHomeHub> createState() => _CitizenHomeHubState();
}

class _CitizenHomeHubState extends State<CitizenHomeHub> {
  Map<String, dynamic>? _summary;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await CitizenDashboardApiService.instance.fetchSummary();
      if (mounted) setState(() => _summary = m);
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w >= 1080;
    final isTablet = w >= 700 && !isDesktop;
    final pad = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
    final name = widget.userName.trim().isEmpty
        ? l10n.landingGuestName
        : widget.userName;

    final welcomeCard = _WelcomeCard(
      name: name,
      onSendVeto: widget.onSendVeto,
      aiPanel: widget.inlineAiPanel,
    );
    final shieldCard = _LegalShieldCard(
      onTapTool: widget.onOpenLegalTool,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: welcomeCard),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: shieldCard),
                ],
              )
            else ...[
              welcomeCard,
              const SizedBox(height: 16),
              shieldCard,
            ],
            const SizedBox(height: 24),
            Text(
              l10n.citizenHubYourTools,
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: VetoMockup.ink,
              ),
            ),
            const SizedBox(height: 12),
            _ToolsGrid(onRoute: widget.onOpenLegalTool),
            const SizedBox(height: 28),
            if (_err != null)
              Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12))
            else
              _MetricsRow(summary: _summary),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.name,
    required this.onSendVeto,
    this.aiPanel,
  });

  final String name;
  final VoidCallback onSendVeto;
  final Widget? aiPanel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: VetoMockup.surfaceCard,
        borderRadius: BorderRadius.circular(VetoMockup.radiusCard),
        border: Border.all(color: VetoMockup.hairline),
        boxShadow: VetoMockup.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.citizenHubWelcomeName(name),
            style: const TextStyle(
              fontFamily: V26.serif,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: VetoMockup.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.citizenHubWelcomeSubtitle,
            style: const TextStyle(
              fontFamily: V26.sans,
              color: VetoMockup.inkSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onSendVeto,
            icon: const Icon(Icons.send_rounded),
            label: Text(l10n.citizenHubSendVetoCta),
          ),
          if (aiPanel != null) ...[
            const SizedBox(height: 16),
            aiPanel!,
          ],
        ],
      ),
    );
  }
}

class _LegalShieldItem {
  const _LegalShieldItem({
    required this.route,
    required this.label,
    required this.icon,
    this.intent,
    this.domain,
  });

  final String route;
  final String Function(AppLocalizations l10n) label;
  final IconData icon;
  final String? intent;
  final String? domain;
}

class _LegalShieldCard extends StatelessWidget {
  const _LegalShieldCard({required this.onTapTool});

  final void Function(String route, {Object? arguments}) onTapTool;

  static final List<_LegalShieldItem> _items = [
    _LegalShieldItem(
      route: '/chat',
      label: (l) => l.citizenHubShieldRiskCheck,
      icon: Icons.security_rounded,
      intent: 'risk_check',
      domain: 'general',
    ),
    _LegalShieldItem(
      route: '/legal_notebook',
      label: (l) => l.nbScrIntentContractReview,
      icon: Icons.fact_check_rounded,
      intent: 'contract_review',
      domain: 'contracts',
    ),
    _LegalShieldItem(
      route: '/legal_notebook',
      label: (l) => l.nbScrIntentDemandLetter,
      icon: Icons.campaign_rounded,
      intent: 'demand_letter',
      domain: 'civil',
    ),
    _LegalShieldItem(
      route: '/legal_notebook',
      label: (l) => l.nbScrIntentCivilClaim,
      icon: Icons.balance_rounded,
      intent: 'civil_claim',
      domain: 'civil',
    ),
    _LegalShieldItem(
      route: '/legal_notebook',
      label: (l) => l.nbScrIntentLaborDoc,
      icon: Icons.work_outline_rounded,
      intent: 'labor_doc',
      domain: 'labor',
    ),
    _LegalShieldItem(
      route: '/legal_notebook',
      label: (l) => l.nbScrIntentFamilyDoc,
      icon: Icons.family_restroom_rounded,
      intent: 'family_doc',
      domain: 'family',
    ),
    _LegalShieldItem(
      route: '/legal_calendar',
      label: (l) => l.citizenHubShieldDeadlines,
      icon: Icons.calendar_today_rounded,
    ),
    _LegalShieldItem(
      route: '/maps',
      label: (l) => l.citizenHubShieldCourtMap,
      icon: Icons.map_rounded,
    ),
    _LegalShieldItem(
      route: '/citizen_contracts',
      label: (l) => l.citizenHubShieldManageContracts,
      icon: Icons.description_rounded,
    ),
    _LegalShieldItem(
      route: '/citizen_tasks',
      label: (l) => l.citizenHubShieldLegalTasks,
      icon: Icons.task_rounded,
    ),
    _LegalShieldItem(
      route: '/citizen_reports',
      label: (l) => l.citizenHubShieldCaseReport,
      icon: Icons.summarize_rounded,
    ),
    _LegalShieldItem(
      route: '/files_vault',
      label: (l) => l.citizenHubShieldVaultExport,
      icon: Icons.inventory_2_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VetoMockup.surfaceCard,
        borderRadius: BorderRadius.circular(VetoMockup.radiusCard),
        border: Border.all(color: VetoMockup.hairline),
        boxShadow: VetoMockup.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.citizenHubLegalShieldTitle,
            style: const TextStyle(
              fontFamily: V26.sans,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.45,
            ),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final it = _items[i];
              return OutlinedButton.icon(
                onPressed: () => onTapTool(
                  it.route,
                  arguments: (it.intent == null && it.domain == null)
                      ? null
                      : {
                          if (it.intent != null) 'intent': it.intent,
                          if (it.domain != null) 'domain': it.domain,
                        },
                ),
                icon: Icon(it.icon, size: 18, color: VetoMockup.primaryCta),
                label: Text(
                  it.label(l10n),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ToolsGrid extends StatelessWidget {
  const _ToolsGrid({required this.onRoute});

  final void Function(String route, {Object? arguments}) onRoute;

  static final List<({String r, IconData i, String Function(AppLocalizations l) title})> _tools = [
    (r: '/files_vault', i: Icons.folder_open_rounded, title: (l) => l.citizenHubToolCaseTracking),
    (r: '/citizen_contracts', i: Icons.handshake_outlined, title: (l) => l.citizenHubToolContracts),
    (r: '/citizen_tasks', i: Icons.checklist_rounded, title: (l) => l.citizenHubToolOpenTasks),
    (r: '/citizen_contacts', i: Icons.people_alt_outlined, title: (l) => l.citizenHubToolContacts),
    (r: '/citizen_reports', i: Icons.insights_outlined, title: (l) => l.citizenHubToolReports),
    (r: '/citizen_tools', i: Icons.apps_rounded, title: (l) => l.citizenHubToolAdvanced),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (_, c) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 132,
          ),
          itemCount: _tools.length,
          itemBuilder: (_, i) {
            final e = _tools[i];
            return Material(
              color: VetoMockup.surfaceCard,
              borderRadius: BorderRadius.circular(VetoMockup.radiusCard),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(VetoMockup.radiusCard),
                onTap: () => onRoute(e.r),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(VetoMockup.radiusCard),
                    border: Border.all(color: VetoMockup.hairline),
                    boxShadow: VetoMockup.cardShadow,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(e.i, color: VetoMockup.primaryCta, size: 28),
                      const Spacer(),
                      Text(
                        e.title(l10n),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.summary});

  final Map<String, dynamic>? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = summary;
    final tasks = s == null ? '—' : '${s['openTasks'] ?? 0}';
    final cases = s == null ? '—' : '${s['trackedCases'] ?? 0}';
    final contracts = s == null ? '—' : '${s['activeContracts'] ?? 0}';

    Widget card(String title, String value, Color accent, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: VetoMockup.surfaceCard,
          borderRadius: BorderRadius.circular(VetoMockup.radiusCard),
          border: Border.all(color: VetoMockup.hairline),
          boxShadow: VetoMockup.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: accent),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final entries = <Widget>[
      card(
        l10n.citizenHubMetricOpenTasks,
        tasks,
        VetoMockup.primaryCta,
        Icons.task_alt_rounded,
      ),
      card(
        l10n.citizenHubMetricTrackedCases,
        cases,
        VetoMockup.metricBlue,
        Icons.folder_rounded,
      ),
      card(
        l10n.citizenHubMetricActiveContracts,
        contracts,
        VetoMockup.metricPurple,
        Icons.description_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.citizenHubQuickSummary,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (_, c) {
            if (c.maxWidth < 700) {
              return Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    SizedBox(width: double.infinity, child: entries[i]),
                    if (i < entries.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  Expanded(child: entries[i]),
                  if (i < entries.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
