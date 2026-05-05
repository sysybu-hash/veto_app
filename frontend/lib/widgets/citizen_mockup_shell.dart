// ============================================================
//  citizen_mockup_shell.dart — RTL sidebar + top bar (desktop),
//  bottom nav + center VETO (mobile). Mockup-aligned.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import 'app_language_menu.dart';
import 'mockup_desktop_top_bar.dart';
import 'veto_dialogs.dart';

/// Desktop breakpoint aligned with [V26AppShell].
const double kCitizenMockupDesktopBreakpoint = 1080;

class _NavEntry {
  const _NavEntry({
    required this.route,
    required this.labelHe,
    required this.labelEn,
    required this.labelRu,
    required this.icon,
  });

  final String route;
  final String labelHe;
  final String labelEn;
  final String labelRu;
  final IconData icon;

  String label(String code) {
    if (code == 'en') return labelEn;
    if (code == 'ru') return labelRu;
    return labelHe;
  }
}

const List<_NavEntry> _kSidebarEntries = [
  _NavEntry(route: '/veto_screen', labelHe: 'בית', labelEn: 'Home', labelRu: 'Главная', icon: Icons.home_rounded),
  _NavEntry(route: '/files_vault', labelHe: 'תיקים', labelEn: 'Cases', labelRu: 'Дела', icon: Icons.folder_rounded),
  _NavEntry(
      route: '/citizen_contracts',
      labelHe: 'חוזים',
      labelEn: 'Contracts',
      labelRu: 'Договоры',
      icon: Icons.description_rounded),
  _NavEntry(
      route: '/citizen_notifications',
      labelHe: 'התראות',
      labelEn: 'Alerts',
      labelRu: 'Уведомления',
      icon: Icons.notifications_none_rounded),
  _NavEntry(route: '/citizen_tasks', labelHe: 'משימות', labelEn: 'Tasks', labelRu: 'Задачи', icon: Icons.task_alt_rounded),
  _NavEntry(
      route: '/citizen_contacts',
      labelHe: 'אנשי קשר',
      labelEn: 'Contacts',
      labelRu: 'Контакты',
      icon: Icons.people_outline_rounded),
  _NavEntry(route: '/citizen_tools', labelHe: 'כלים', labelEn: 'Tools', labelRu: 'Инструменты', icon: Icons.build_outlined),
  _NavEntry(route: '/citizen_reports', labelHe: 'דוחות', labelEn: 'Reports', labelRu: 'Отчёты', icon: Icons.bar_chart_rounded),
  _NavEntry(route: '/settings', labelHe: 'הגדרות', labelEn: 'Settings', labelRu: 'Настройки', icon: Icons.settings_outlined),
];

class CitizenMockupShell extends StatefulWidget {
  const CitizenMockupShell({
    super.key,
    required this.currentRoute,
    required this.child,
    this.mobileAppBar,
    this.mobileNavIndex = 0,
    this.showMobileBottomBar = true,
    /// Extra actions in the desktop top bar (e.g. vault upload) — appears after search.
    this.desktopTrailing,
    /// Shown on mobile layout only (above bottom nav).
    this.floatingActionButton,
  });

  final String currentRoute;
  final Widget child;
  final PreferredSizeWidget? mobileAppBar;
  /// 0 בית · 1 הגנות · 2 שלח VETO · 3 מסמכים · 4 עוד
  final int mobileNavIndex;
  final bool showMobileBottomBar;
  final List<Widget>? desktopTrailing;
  final Widget? floatingActionButton;

  @override
  State<CitizenMockupShell> createState() => _CitizenMockupShellState();
}

class _CitizenMockupShellState extends State<CitizenMockupShell> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _go(BuildContext context, String route) {
    if (widget.currentRoute == route) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _goVetoWizard(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/veto_screen', arguments: {'wizard': true});
  }

  void _goVetoHub(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/veto_screen');
  }

  Future<void> _moreSheet(BuildContext context, String code) async {
    final he = code == 'he';
    final ru = code == 'ru';
    await showVetoBottomSheet(
      context: context,
      title: he ? 'עוד' : (ru ? 'Ещё' : 'More'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(he ? 'צ\'אט AI' : (ru ? 'AI-чат' : 'AI Chat')),
            onTap: () {
              Navigator.pop(context);
              _go(context, '/chat');
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_note_rounded),
            title: Text(he ? 'יומן משפטי' : (ru ? 'Календарь' : 'Calendar')),
            onTap: () {
              Navigator.pop(context);
              _go(context, '/legal_calendar');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded),
            title: Text(he ? 'מחברת' : (ru ? 'Блокнот' : 'Notebook')),
            onTap: () {
              Navigator.pop(context);
              _go(context, '/legal_notebook');
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_rounded),
            title: Text(he ? 'מפה' : (ru ? 'Карта' : 'Map')),
            onTap: () {
              Navigator.pop(context);
              _go(context, '/maps');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: Text(he ? 'דוחות' : (ru ? 'Отчёты' : 'Reports')),
            onTap: () {
              Navigator.pop(context);
              _go(context, '/citizen_reports');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(he ? 'הגדרות' : (ru ? 'Настройки' : 'Settings')),
            onTap: () {
              Navigator.pop(context);
              _go(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: Text(he ? 'פרופיל' : (ru ? 'Профиль' : 'Profile')),
            onTap: () {
              Navigator.pop(context);
              _go(context, '/profile');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kCitizenMockupDesktopBreakpoint;

    if (isDesktop) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: VetoMockup.pageBackground,
          floatingActionButton: widget.floatingActionButton,
          body: Row(
            textDirection: TextDirection.rtl,
            children: [
              _DesktopSidebar(
                currentRoute: widget.currentRoute,
                langCode: code,
                onSelect: (r) => _go(context, r),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MockupDesktopTopBar(
                      searchController: _searchCtrl,
                      langCode: code,
                      trailing: widget.desktopTrailing,
                      onProfile: () => Navigator.pushNamed(context, '/profile'),
                      onNotifications: () => _go(context, '/citizen_notifications'),
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoMockup.pageBackground,
        appBar: widget.mobileAppBar,
        floatingActionButton: widget.floatingActionButton,
        body: widget.child,
        bottomNavigationBar: widget.showMobileBottomBar
            ? _CitizenMobileBottomNav(
                currentIndex: widget.mobileNavIndex,
                langCode: code,
                onHome: () => _goVetoHub(context),
                onProtections: () => _goVetoWizard(context),
                onSendVeto: () => _goVetoWizard(context),
                onDocuments: () => _go(context, '/files_vault'),
                onMore: () => _moreSheet(context, code),
              )
            : null,
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.currentRoute,
    required this.langCode,
    required this.onSelect,
  });

  final String currentRoute;
  final String langCode;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: VetoMockup.surfaceCard,
        border: Border(left: BorderSide(color: VetoMockup.hairline)),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'VETO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: V26.sans,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: VetoMockup.ink,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: _kSidebarEntries.length,
                itemBuilder: (_, i) {
                  final e = _kSidebarEntries[i];
                  final active = currentRoute == e.route;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: active ? VetoMockup.primaryCta.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSelect(e.route),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              right: BorderSide(
                                color: active ? VetoMockup.primaryCta : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                e.icon,
                                size: 22,
                                color: active ? VetoMockup.primaryCta : VetoMockup.inkSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.label(langCode),
                                  style: TextStyle(
                                    fontFamily: V26.sans,
                                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 14,
                                    color: active ? VetoMockup.primaryCtaDeep : VetoMockup.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: AppLanguageMenu(compact: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitizenMobileBottomNav extends StatelessWidget {
  const _CitizenMobileBottomNav({
    required this.currentIndex,
    required this.langCode,
    required this.onHome,
    required this.onProtections,
    required this.onSendVeto,
    required this.onDocuments,
    required this.onMore,
  });

  final int currentIndex;
  final String langCode;
  final VoidCallback onHome;
  final VoidCallback onProtections;
  final VoidCallback onSendVeto;
  final VoidCallback onDocuments;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final he = langCode == 'he';
    Widget item(int idx, IconData icon, String label, VoidCallback onTap) {
      final sel = currentIndex == idx;
      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: sel ? VetoMockup.primaryCta : VetoMockup.inkSecondary),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                  color: sel ? VetoMockup.primaryCta : VetoMockup.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 8, top: 8),
      decoration: BoxDecoration(
        color: VetoMockup.surfaceCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          item(0, Icons.home_rounded, he ? 'בית' : 'Home', onHome),
          item(1, Icons.shield_outlined, he ? 'הגנות' : 'Shield', onProtections),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: Center(
                child: Material(
                  color: VetoMockup.primaryCta,
                  elevation: 6,
                  shadowColor: VetoMockup.primaryCta.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onSendVeto,
                    child: const SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(Icons.shield_moon_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ),
          ),
          item(3, Icons.folder_rounded, he ? 'מסמכים' : 'Files', onDocuments),
          item(4, Icons.more_horiz_rounded, he ? 'עוד' : 'More', onMore),
        ],
      ),
    );
  }
}

/// Maps route to mobile bottom index (0–4).
int citizenMobileNavIndexForRoute(String route, {bool wizardMode = false}) {
  if (wizardMode) return 2;
  switch (route) {
    case '/veto_screen':
      return 0;
    case '/files_vault':
      return 3;
    case '/citizen_notifications':
    case '/citizen_contracts':
    case '/citizen_tasks':
    case '/citizen_contacts':
    case '/citizen_tools':
    case '/citizen_reports':
    case '/settings':
    case '/chat':
    case '/legal_calendar':
    case '/legal_notebook':
    case '/maps':
    case '/profile':
      return 4;
    default:
      return 0;
  }
}
