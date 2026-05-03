// ============================================================
//  _shell.dart — shared admin console chrome (sidebar + top-bar)
//
//  Mirrors 2026/admin.html:
//    - Persistent left-edge sidebar on desktop (>=900px)
//    - Top-bar with global search, Production/Staging selector,
//      notifications bell, admin avatar
//    - Falls back to a plain AppBar on mobile
//
//  Usage:
//    return Directionality(
//      textDirection: AppLanguage.directionOf(code),
//      child: AdminShell(
//        active: AdminSection.users,
//        title: 'כל המשתמשים',
//        onRefresh: _load,
//        floatingAction: FloatingActionButton.extended(...),
//        body: V26Backdrop(child: ListView(...)),
//      ),
//    );
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_2026.dart';
import '../../widgets/app_language_menu.dart';

/// Admin section identity — one entry per navigable admin route.
enum AdminSection {
  dashboard,
  users,
  lawyers,
  pending,
  logs,
  subscriptions,
  settings,
}

/// Deploy-target selector surfaced in the top-bar.
enum AdminEnv { production, staging }

/// Global env selector — shared across every admin screen so the selector
/// state survives route transitions. Kept outside of any Provider to avoid
/// forcing admin screens to wire up an extra ChangeNotifier.
final ValueNotifier<AdminEnv> adminEnvNotifier =
    ValueNotifier<AdminEnv>(AdminEnv.production);

const _sidebarWidth = 220.0;

// ────────────────────────────────────────────────────────────
//  Route map — single source of truth for sidebar navigation.
// ────────────────────────────────────────────────────────────
const Map<AdminSection, String> _sectionRoutes = {
  AdminSection.dashboard: '/admin_dashboard',
  AdminSection.users: '/admin_users',
  AdminSection.lawyers: '/admin_lawyers',
  AdminSection.pending: '/admin_pending',
  AdminSection.logs: '/admin_logs',
  AdminSection.subscriptions: '/admin_subscriptions',
  AdminSection.settings: '/admin_settings',
};

// ────────────────────────────────────────────────────────────
//  i18n — only strings that live inside the shell itself.
// ────────────────────────────────────────────────────────────
String _shellStr(String code, String key) {
  const he = {
    'panel': 'פאנל ניהול',
    'admin_group': 'ניהול',
    'system_group': 'מערכת',
    'dashboard': 'לוח בקרה',
    'users': 'משתמשים',
    'lawyers': 'עורכי דין',
    'pending': 'ממתינים לאישור',
    'logs': 'יומני חירום',
    'subscriptions': 'מנויים',
    'settings': 'הגדרות',
    'search_hint': 'חיפוש גלובלי...',
    'refresh': 'רענן',
    'admin': 'מנהל',
    'env_production': 'Production',
    'env_staging': 'Staging',
    'notifications': 'התראות',
  };
  const en = {
    'panel': 'Admin Panel',
    'admin_group': 'ADMIN',
    'system_group': 'SYSTEM',
    'dashboard': 'Dashboard',
    'users': 'Users',
    'lawyers': 'Lawyers',
    'pending': 'Pending',
    'logs': 'Emergency Logs',
    'subscriptions': 'Subscriptions',
    'settings': 'Settings',
    'search_hint': 'Search everywhere...',
    'refresh': 'Refresh',
    'admin': 'Admin',
    'env_production': 'Production',
    'env_staging': 'Staging',
    'notifications': 'Notifications',
  };
  const ru = {
    'panel': 'Панель администратора',
    'admin_group': 'АДМИН',
    'system_group': 'СИСТЕМА',
    'dashboard': 'Панель',
    'users': 'Пользователи',
    'lawyers': 'Адвокаты',
    'pending': 'Ожидают',
    'logs': 'Журналы',
    'subscriptions': 'Подписки',
    'settings': 'Настройки',
    'search_hint': 'Поиск...',
    'refresh': 'Обновить',
    'admin': 'Администратор',
    'env_production': 'Production',
    'env_staging': 'Staging',
    'notifications': 'Уведомления',
  };
  final normalized = AppLanguage.normalize(code);
  final map = switch (normalized) {
    AppLanguage.english => en,
    AppLanguage.russian => ru,
    _ => he,
  };
  return map[key] ?? he[key] ?? key;
}

/// AdminShell — wraps an admin screen body in the unified VETO 2026 chrome.
///
/// On desktop (>=900px) renders: sidebar + top-bar + body. On mobile renders
/// a standard AppBar + body. Screens keep their own Directionality and state
/// handling; the shell only supplies chrome.
class AdminShell extends StatelessWidget {
  /// Which sidebar entry to highlight.
  final AdminSection active;

  /// Title used in the mobile AppBar and desktop top-bar.
  final String title;

  /// Main content. Pass an already-backdropped widget (e.g. V26Backdrop)
  /// if you want the backdrop — the shell itself does not apply one so it
  /// remains compatible with screens that paint their own background.
  final Widget body;

  /// Extra actions appended to both the mobile AppBar's `actions` list and
  /// the right side of the desktop top-bar.
  final List<Widget> actions;

  /// Optional FAB — surfaced identically in both layouts.
  final Widget? floatingAction;

  /// Optional refresh callback. When provided, adds a refresh icon button
  /// next to `actions` and rewires a pull-to-refresh-style affordance.
  final VoidCallback? onRefresh;

  /// Optional bar that sits immediately below the top-bar / AppBar.
  /// Useful for TabBar-style navigation that belongs to a specific screen.
  final PreferredSizeWidget? bottom;

  const AdminShell({
    super.key,
    required this.active,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingAction,
    this.onRefresh,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;
    final isDesktop = context.isDesktop;

    final combinedActions = <Widget>[
      if (onRefresh != null)
        IconButton(
          tooltip: _shellStr(code, 'refresh'),
          icon: const Icon(Icons.refresh_rounded, color: V26.ink700),
          onPressed: onRefresh,
        ),
      ...actions,
    ];

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: V26.paper,
        appBar: AppBar(
          backgroundColor: V26.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: V26.ink900),
          title: Text(
            title,
            style: const TextStyle(
              color: V26.ink900,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Center(child: AppLanguageMenu(compact: true)),
            ),
            ...combinedActions,
            const SizedBox(width: 4),
          ],
          bottom: bottom ??
              const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: V26.hairline),
              ),
        ),
        floatingActionButton: floatingAction,
        body: body,
      );
    }

    Widget desktopBody = body;
    if (bottom != null) {
      desktopBody = Column(
        children: [
          Container(
            color: V26.surface,
            child: bottom!,
          ),
          const Divider(height: 1, color: V26.hairline),
          Expanded(child: body),
        ],
      );
    }

    return VetoScaffold(
      backdrop: false,
      background: V26.paper,
      sidebar: _buildSidebar(context, code, isRtl),
      desktopTopBar: _AdminTopBar(
        title: title,
        code: code,
        actions: combinedActions,
      ),
      floatingAction: floatingAction,
      body: desktopBody,
    );
  }

  V26Sidebar _buildSidebar(BuildContext context, String code, bool isRtl) {
    final panelLabel = _shellStr(code, 'panel');
    return V26Sidebar(
      width: _sidebarWidth,
      header: Row(
        children: [
          const V26Crest(size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VETO',
                  style: TextStyle(
                    fontFamily: V26.serif,
                    color: V26.ink900,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  panelLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    color: V26.navy600,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      groups: [
        V26SidebarGroup(
          title: _shellStr(code, 'admin_group'),
          items: [
            _navItem(context, AdminSection.dashboard, Icons.home_rounded,
                _shellStr(code, 'dashboard')),
            _navItem(context, AdminSection.users, Icons.people_alt_rounded,
                _shellStr(code, 'users')),
            _navItem(context, AdminSection.lawyers, Icons.balance_rounded,
                _shellStr(code, 'lawyers')),
            _navItem(context, AdminSection.pending,
                Icons.pending_actions_rounded, _shellStr(code, 'pending')),
            _navItem(context, AdminSection.logs, Icons.warning_amber_rounded,
                _shellStr(code, 'logs')),
          ],
        ),
        V26SidebarGroup(
          title: _shellStr(code, 'system_group'),
          items: [
            _navItem(context, AdminSection.subscriptions,
                Icons.credit_card_rounded, _shellStr(code, 'subscriptions')),
            _navItem(context, AdminSection.settings, Icons.settings_rounded,
                _shellStr(code, 'settings')),
          ],
        ),
      ],
    );
  }

  V26SidebarItem _navItem(
    BuildContext context,
    AdminSection section,
    IconData icon,
    String label,
  ) {
    final isActive = section == active;
    return V26SidebarItem(
      label: label,
      icon: icon,
      active: isActive,
      onTap: isActive
          ? null
          : () => Navigator.of(context)
              .pushReplacementNamed(_sectionRoutes[section]!),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Desktop top-bar: search + env selector + avatar + actions.
// ────────────────────────────────────────────────────────────
class _AdminTopBar extends StatelessWidget {
  final String title;
  final String code;
  final List<Widget> actions;

  const _AdminTopBar({
    required this.title,
    required this.code,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: V26.surface,
        border: Border(bottom: BorderSide(color: V26.hairline)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: V26.sans,
              color: V26.ink900,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: TextField(
                style: const TextStyle(fontFamily: V26.sans, fontSize: 13),
                decoration: InputDecoration(
                  hintText: _shellStr(code, 'search_hint'),
                  hintStyle: const TextStyle(
                      color: V26.ink300, fontFamily: V26.sans, fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search, size: 18, color: V26.ink300),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: V26.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: V26.hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: V26.navy500, width: 1.5),
                  ),
                  filled: true,
                  fillColor: V26.paper2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const _EnvSelector(),
          const SizedBox(width: 12),
          IconButton(
            tooltip: _shellStr(code, 'notifications'),
            icon: const Icon(Icons.notifications_outlined, color: V26.ink500),
            onPressed: () {},
          ),
          const AppLanguageMenu(compact: true),
          ...actions,
          const SizedBox(width: 8),
          Tooltip(
            message: _shellStr(code, 'admin'),
            child: const V26Avatar('A', size: V26AvatarSize.sm),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Environment selector — Production / Staging dropdown.
// ────────────────────────────────────────────────────────────
class _EnvSelector extends StatelessWidget {
  const _EnvSelector();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminEnv>(
      valueListenable: adminEnvNotifier,
      builder: (context, env, _) {
        final code = context.watch<AppLanguageController>().code;
        final isProduction = env == AdminEnv.production;
        final dotColor =
            isProduction ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: V26.paper2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: V26.hairline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AdminEnv>(
              value: env,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: V26.ink500),
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: V26.ink900,
              ),
              dropdownColor: V26.surface,
              items: [
                DropdownMenuItem(
                  value: AdminEnv.production,
                  child: _envRow(
                      const Color(0xFF22C55E), _shellStr(code, 'env_production')),
                ),
                DropdownMenuItem(
                  value: AdminEnv.staging,
                  child: _envRow(
                      const Color(0xFFF59E0B), _shellStr(code, 'env_staging')),
                ),
              ],
              selectedItemBuilder: (_) => [
                _envRow(dotColor, _shellStr(code, 'env_production')),
                _envRow(dotColor, _shellStr(code, 'env_staging')),
              ],
              onChanged: (v) {
                if (v != null) adminEnvNotifier.value = v;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _envRow(Color dot, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dot,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dot.withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
