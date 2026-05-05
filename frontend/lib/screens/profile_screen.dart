import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../widgets/citizen_mockup_shell.dart';
import '../widgets/app_language_menu.dart';

import 'dash_profile_l10n_lookup.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _role;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final code = context.read<AppLanguageController>().code;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t(context, 'nameEmpty'))));
      return;
    }
    setState(() => _saving = true);
    final ok = await AuthService().updateProfile(
      fullName: name,
      preferredLanguage: code,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? _t(context, 'saved') : _t(context, 'saveError')),
      backgroundColor: ok ? V26.ok : V26.emerg,
    ));
  }

  Future<void> _loadUserData() async {
    // First show local cache immediately, then refresh from server
    final name  = await AuthService().getStoredName();
    final role  = await AuthService().getStoredRole();
    final phone = await AuthService().getStoredPhone();
    if (mounted) {
      setState(() {
        _nameCtrl.text = name ?? '';
        _role  = role;
        _phone = phone;
        _loading = false;
      });
    }
    // Refresh from server in background
    final serverData = await AuthService().fetchProfile();
    if (serverData != null && mounted) {
      setState(() {
        _nameCtrl.text = (serverData['full_name'] as String?) ?? _nameCtrl.text;
        _phone = (serverData['phone'] as String?) ?? _phone;
      });
    }
  }

  String _t(BuildContext ctx, String key) {
    final l = AppLocalizations.of(ctx);
    if (l == null) return key;
    return profScreenT(l, key);
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isWide =
        MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;

    final body = _loading
        ? const Center(
            child: CircularProgressIndicator(color: V26.navy600))
        : _profileScrollBody();

    if (_role == 'user' && !_loading) {
      return Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: CitizenMockupShell(
          currentRoute: '/profile',
          mobileNavIndex: citizenMobileNavIndexForRoute('/profile'),
          desktopTrailing: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: AppLanguageMenu(compact: true)),
            ),
          ],
          mobileAppBar: AppBar(
            backgroundColor: VetoMockup.surfaceCard,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: VetoMockup.ink, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              _t(context, 'title'),
              style: const TextStyle(
                  color: VetoMockup.ink,
                  fontFamily: V26.serif,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
            centerTitle: true,
            actions: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: AppLanguageMenu(compact: true)),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: VetoMockup.hairline),
            ),
          ),
          child: body,
        ),
      );
    }

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: V26AppShell(
        destinations: isWide
            ? V26CitizenNav.destinations(code)
            : V26CitizenNav.bottomDestinations(code),
        currentIndex: isWide ? -1 : 4 /* פרופיל */,
        onDestinationSelected: (i) {
          final routes = isWide
              ? V26CitizenNav.routes
              : V26CitizenNav.bottomRoutes;
          V26CitizenNav.go(context, routes[i], current: '/profile');
        },
        desktopStatusText: _t(context, 'title'),
        desktopTrailing: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: AppLanguageMenu(compact: true)),
          ),
        ],
        mobileAppBar: AppBar(
          backgroundColor: V26.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: V26.ink900, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            _t(context, 'title'),
            style: const TextStyle(
                color: V26.ink900,
                fontFamily: V26.serif,
                fontWeight: FontWeight.w800,
                fontSize: 18),
          ),
          centerTitle: true,
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: AppLanguageMenu(compact: true)),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: V26.hairline),
          ),
        ),
        child: body,
      ),
    );
  }

  Widget _profileScrollBody() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _buildHero(),
                        const SizedBox(height: 20),
                        _buildStatsStrip(),
                        const SizedBox(height: 20),
                        _buildSubscriptionBlock(),
                        const SizedBox(height: 20),
                        _buildCard(
                          children: [
                            _sectionLabel(_t(context, 'name')),
                            TextField(
                              controller: _nameCtrl,
                              decoration: InputDecoration(
                                hintText: _t(context, 'nameHint'),
                                prefixIcon:
                                    const Icon(Icons.person_outline, size: 18),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel(_t(context, 'phone')),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: V26.paper2,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: V26.hairline),
                              ),
                              child: Text(
                                _phone ?? '—',
                                style: const TextStyle(
                                    color: V26.ink500),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel(_t(context, 'role')),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: V26.paper2,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: V26.hairline),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _role == 'lawyer'
                                        ? Icons.gavel_rounded
                                        : _role == 'admin'
                                            ? Icons.admin_panel_settings_outlined
                                            : Icons.person_outline,
                                    size: 16,
                                    color: V26.navy600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _roleLabel(context, _role),
                                    style: const TextStyle(
                                        color: V26.ink500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel(_t(context, 'language')),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: V26.paper2,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: V26.hairline),
                              ),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: AppLanguageMenu(compact: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // ── Quick links ────────────────────
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/files_vault'),
                            icon: const Icon(Icons.folder_special_outlined, size: 16),
                            label: Text(
                              l10n.citizenToolVault,
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: V26.navy600,
                              side: BorderSide(color: V26.navy600.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/settings'),
                            icon: const Icon(Icons.settings_outlined, size: 16),
                            label: Text(
                              l10n.citizenShellNavSettings,
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: V26.navy600,
                              side: BorderSide(color: V26.navy600.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )),
                        ]),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _saving ? null : _saveProfile,
                          icon: _saving
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Color(0xFF041018)))
                              : const Icon(Icons.check_rounded, size: 18, color: Color(0xFF041018)),
                          label: Text(_t(context, 'save'),
                            style: const TextStyle(color: Color(0xFF041018)),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: V26.navy600,
                            foregroundColor: const Color(0xFF041018),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => AuthService().logout(context),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: Text(_t(context, 'logout')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: V26.emerg,
                            side: BorderSide(
                                color: V26.emerg.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _roleLabel(BuildContext context, String? role) {
    final l = AppLocalizations.of(context)!;
    switch (role) {
      case 'lawyer':
        return l.landingRoleLawyer;
      case 'admin':
        return l.landingRoleAdmin;
      default:
        return l.landingRoleUser;
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: V26Kicker(text),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return V26Card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // ── Hero: avatar + name + 3 V26Badge chips (Premium · Since 2025 · Verified)
  Widget _buildHero() {
    final name = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text
        : (_phone ?? _roleLabel(context, _role));
    final avatarInitial =
        _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?';
    return V26Card(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(
        children: [
          V26Avatar(avatarInitial, size: V26AvatarSize.xl),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontFamily: V26.serif,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: V26.ink900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _roleLabel(context, _role),
            style: const TextStyle(
              fontFamily: V26.sans,
              fontSize: 13,
              color: V26.ink500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              V26Badge(_t(context, 'badgePremium'), tone: V26BadgeTone.gold),
              V26Badge(_t(context, 'badgeSince'), tone: V26BadgeTone.neutral),
              V26Badge(_t(context, 'badgeVerified'), tone: V26BadgeTone.ok),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats strip: 3 numbers (cases · files · days) ──
  Widget _buildStatsStrip() {
    Widget cell(String num, String label) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                num,
                style: const TextStyle(
                  fontFamily: V26.serif,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: V26.navy600,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  fontSize: 11,
                  color: V26.ink500,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    return V26Card(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Row(
        children: [
          cell('0', _t(context, 'statCases')),
          Container(width: 1, height: 32, color: V26.hairline),
          cell('0', _t(context, 'statFiles')),
          Container(width: 1, height: 32, color: V26.hairline),
          cell('—', _t(context, 'statDays')),
        ],
      ),
    );
  }

  // ── Subscription block: admins → console; everyone else → app settings ──
  Widget _buildSubscriptionBlock() {
    return V26Card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: V26.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                _t(context, 'subscriptionTitle'),
                style: const TextStyle(
                  fontFamily: V26.serif,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: V26.ink900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t(context, 'subscriptionBody'),
            style: const TextStyle(
              fontFamily: V26.sans,
              fontSize: 13,
              height: 1.5,
              color: V26.ink500,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: V26CTA(
              _t(context, 'subscriptionCta'),
              onPressed: () {
                if (_role == 'admin') {
                  Navigator.pushNamed(context, '/admin_subscriptions');
                } else {
                  Navigator.pushNamed(context, '/settings');
                }
              },
              variant: V26CtaVariant.ghost,
            ),
          ),
        ],
      ),
    );
  }
}
