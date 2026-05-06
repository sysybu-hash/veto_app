// ============================================================
//  citizen_home_hub.dart — mockup hub (welcome, CTA, tools, KPIs)
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import '../../core/theme/veto_mockup_tokens.dart';
import '../../services/citizen_dashboard_api_service.dart';

class CitizenHomeHub extends StatefulWidget {
  const CitizenHomeHub({
    super.key,
    required this.langKey,
    required this.userName,
    required this.onSendVeto,
    required this.onOpenLegalTool,
    this.inlineAiPanel,
  });

  final String langKey;
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

  String _t(String he, String en, String ru) {
    if (widget.langKey == 'en') return en;
    if (widget.langKey == 'ru') return ru;
    return he;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w >= 1080;
    final isTablet = w >= 700 && !isDesktop;
    final pad = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
    final name = widget.userName.trim().isEmpty
        ? _t('משתמש', 'User', 'Пользователь')
        : widget.userName;

    final welcomeCard = _WelcomeCard(
      name: name,
      langKey: widget.langKey,
      onSendVeto: widget.onSendVeto,
      aiPanel: widget.inlineAiPanel,
    );
    final shieldCard = _LegalShieldCard(
      langKey: widget.langKey,
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
              _t('הכלים שלך', 'Your tools', 'Ваши инструменты'),
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: VetoMockup.ink,
              ),
            ),
            const SizedBox(height: 12),
            _ToolsGrid(langKey: widget.langKey, onRoute: widget.onOpenLegalTool),
            const SizedBox(height: 28),
            if (_err != null)
              Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12))
            else
              _MetricsRow(summary: _summary, langKey: widget.langKey),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.name,
    required this.langKey,
    required this.onSendVeto,
    this.aiPanel,
  });

  final String name;
  final String langKey;
  final VoidCallback onSendVeto;
  final Widget? aiPanel;

  @override
  Widget build(BuildContext context) {
    String t(String he, String en, String ru) {
      if (langKey == 'en') return en;
      if (langKey == 'ru') return ru;
      return he;
    }

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
            t('שלום, $name', 'Hello, $name', 'Здравствуйте, $name'),
            style: const TextStyle(
              fontFamily: V26.serif,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: VetoMockup.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'הגנה משפטית חכמה במקום אחד.',
              'Smart legal protection in one place.',
              'Умная юридическая защита в одном месте.',
            ),
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
            label: Text(t('שליחת VETO', 'Send VETO', 'Отправить VETO')),
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
  final String route;
  final String he;
  final String en;
  final String ru;
  final IconData icon;
  final String? intent;
  final String? domain;

  const _LegalShieldItem({
    required this.route,
    required this.he,
    required this.en,
    required this.ru,
    required this.icon,
    this.intent,
    this.domain,
  });
}

class _LegalShieldCard extends StatelessWidget {
  const _LegalShieldCard({required this.langKey, required this.onTapTool});

  final String langKey;
  final void Function(String route, {Object? arguments}) onTapTool;

  @override
  Widget build(BuildContext context) {
    String t(String he, String en, String ru) {
      if (langKey == 'en') return en;
      if (langKey == 'ru') return ru;
      return he;
    }

    const items = <_LegalShieldItem>[
      _LegalShieldItem(
        route: '/chat',
        he: 'בדיקת סיכון מיידית',
        en: 'Instant risk check',
        ru: 'Проверка рисков',
        icon: Icons.security_rounded,
        intent: 'risk_check',
        domain: 'general',
      ),
      _LegalShieldItem(
        route: '/legal_notebook',
        he: 'סקירת חוזה עם AI',
        en: 'AI contract review',
        ru: 'Проверка договора AI',
        icon: Icons.fact_check_rounded,
        intent: 'contract_review',
        domain: 'contracts',
      ),
      _LegalShieldItem(
        route: '/legal_notebook',
        he: 'יצירת מכתב התראה',
        en: 'Demand letter draft',
        ru: 'Письмо-претензия',
        icon: Icons.campaign_rounded,
        intent: 'demand_letter',
        domain: 'civil',
      ),
      _LegalShieldItem(
        route: '/legal_notebook',
        he: 'הכנת תביעה אזרחית',
        en: 'Civil claim draft',
        ru: 'Гражданский иск',
        icon: Icons.balance_rounded,
        intent: 'civil_claim',
        domain: 'civil',
      ),
      _LegalShieldItem(
        route: '/legal_notebook',
        he: 'מסמכי דיני עבודה',
        en: 'Labor law docs',
        ru: 'Документы по труду',
        icon: Icons.work_outline_rounded,
        intent: 'labor_doc',
        domain: 'labor',
      ),
      _LegalShieldItem(
        route: '/legal_notebook',
        he: 'מסמכי דיני משפחה',
        en: 'Family law docs',
        ru: 'Семейные документы',
        icon: Icons.family_restroom_rounded,
        intent: 'family_doc',
        domain: 'family',
      ),
      _LegalShieldItem(
        route: '/legal_calendar',
        he: 'תזכורות ודדליינים',
        en: 'Deadlines',
        ru: 'Сроки',
        icon: Icons.calendar_today_rounded,
      ),
      _LegalShieldItem(
        route: '/maps',
        he: 'איתור תחנה/בית משפט',
        en: 'Court & station map',
        ru: 'Карта судов',
        icon: Icons.map_rounded,
      ),
      _LegalShieldItem(
        route: '/citizen_contracts',
        he: 'ניהול חוזים פעילים',
        en: 'Manage contracts',
        ru: 'Управление договорами',
        icon: Icons.description_rounded,
      ),
      _LegalShieldItem(
        route: '/citizen_tasks',
        he: 'רשימת פעולות משפטיות',
        en: 'Legal task list',
        ru: 'Юридические задачи',
        icon: Icons.task_rounded,
      ),
      _LegalShieldItem(
        route: '/citizen_reports',
        he: 'דוח מצב תיק',
        en: 'Case status report',
        ru: 'Отчёт по делу',
        icon: Icons.summarize_rounded,
      ),
      _LegalShieldItem(
        route: '/files_vault',
        he: 'ייצוא מסמכים לכספת',
        en: 'Export to vault',
        ru: 'Экспорт в хранилище',
        icon: Icons.inventory_2_rounded,
      ),
    ];

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
            t('מגן משפטי', 'Legal shield', 'Юридический щит'),
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
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it = items[i];
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
                  t(it.he, it.en, it.ru),
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
  const _ToolsGrid({required this.langKey, required this.onRoute});

  final String langKey;
  final void Function(String route, {Object? arguments}) onRoute;

  @override
  Widget build(BuildContext context) {
    String t(String he, String en, String ru) {
      if (langKey == 'en') return en;
      if (langKey == 'ru') return ru;
      return he;
    }

    final tools = [
      (r: '/files_vault', he: 'מעקב תיקים', en: 'Case tracking', ru: 'Дела', i: Icons.folder_open_rounded),
      (r: '/citizen_contracts', he: 'ניהול חוזים', en: 'Contracts', ru: 'Договоры', i: Icons.handshake_outlined),
      (r: '/citizen_tasks', he: 'משימות פתוחות', en: 'Open tasks', ru: 'Задачи', i: Icons.checklist_rounded),
      (r: '/citizen_contacts', he: 'אנשי קשר', en: 'Contacts', ru: 'Контакты', i: Icons.people_alt_outlined),
      (r: '/citizen_reports', he: 'דוחות', en: 'Reports', ru: 'Отчёты', i: Icons.insights_outlined),
      (r: '/citizen_tools', he: 'כלים מתקדמים', en: 'Advanced', ru: 'Ещё', i: Icons.apps_rounded),
    ];

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
          itemCount: tools.length,
          itemBuilder: (_, i) {
            final e = tools[i];
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
                        t(e.he, e.en, e.ru),
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
  const _MetricsRow({required this.summary, required this.langKey});

  final Map<String, dynamic>? summary;
  final String langKey;

  @override
  Widget build(BuildContext context) {
    String t(String he, String en, String ru) {
      if (langKey == 'en') return en;
      if (langKey == 'ru') return ru;
      return he;
    }

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
        t('משימות פתוחות', 'Open tasks', 'Задачи'),
        tasks,
        VetoMockup.primaryCta,
        Icons.task_alt_rounded,
      ),
      card(
        t('תיקים במעקב', 'Tracked cases', 'Дела'),
        cases,
        VetoMockup.metricBlue,
        Icons.folder_rounded,
      ),
      card(
        t('חוזים פעילים', 'Active contracts', 'Договоры'),
        contracts,
        VetoMockup.metricPurple,
        Icons.description_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('סיכום מהיר', 'Quick summary', 'Сводка'),
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
