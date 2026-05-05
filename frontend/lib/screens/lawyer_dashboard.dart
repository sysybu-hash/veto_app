import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../widgets/mockup_desktop_top_bar.dart';
import '../services/fcm_user_service.dart';
import '../services/push_service.dart';
import '../services/socket_service.dart';

import 'dash_profile_l10n_lookup.dart';

class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({super.key});

  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard> {
  final _lawyerTopSearch = TextEditingController();

  String _lawyerName = '';
  bool _isAvailable = true;
  bool _isBooting = true;
  final List<Map<String, dynamic>> _alerts = [];
  final List<Map<String, dynamic>> _activeCases = [];
  StreamSubscription<Map<String, dynamic>>? _alertSub;
  StreamSubscription<Map<String, dynamic>>? _caseAcceptedSub;
  StreamSubscription<Map<String, dynamic>>? _caseTakenSub;
  StreamSubscription<Map<String, dynamic>>? _sessionReadySub;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  String _t(BuildContext ctx, String key) {
    final l = AppLocalizations.of(ctx);
    if (l == null) return key;
    return lawyerDashT(l, key);
  }

  Future<void> _bootstrap() async {
    final auth = AuthService();
    final role = await auth.getStoredRole() ?? 'user';
    final name = await auth.getStoredName() ?? '';
    final preferredLanguage = AppLanguage.normalize(
      await auth.getStoredPreferredLanguage(),
    );

    if (!mounted) return;

    // Admins are allowed to be here
    if (role != 'lawyer' && role != 'admin') { Navigator.of(context).pushReplacementNamed('/veto_screen'); return; }

    final languageController = context.read<AppLanguageController>();
    if (languageController.code != preferredLanguage) {
      await languageController.setLanguage(preferredLanguage, persist: false);
    }

    setState(() {
      _lawyerName = name.isNotEmpty ? name : 'VETO';
      _isBooting = false;
    });

    final online = await SocketService().ensureConnected(role: role);
    if (!mounted) return;
    if (!online) {
      final lBoot = lookupAppLocalizations(Locale(preferredLanguage));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lBoot.lawyerDashServerUnreachable),
          backgroundColor: V26.emerg,
        ),
      );
    }
    SocketService().emit('lawyer_availability', {'available': _isAvailable});

    // Register browser push subscription (fire-and-forget — non-blocking)
    PushService().registerLawyerPush();
    if (!kIsWeb) {
      unawaited(registerFcmIfAvailable());
    }

    _alertSub = SocketService().onNewEmergencyAlert.listen((data) {
      if (!mounted) return;
      setState(() => _alerts.insert(0, data));
      _showAlertDialog(data);
    });

    _caseAcceptedSub = SocketService().onCaseAccepted.listen((data) {
      final awaiting = data['awaitingCitizenChoice'] == true;
      if (awaiting) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              preferredLanguage == 'he'
                  ? 'ממתין שהלקוח יבחר סוג שיחה…'
                  : preferredLanguage == 'ru'
                      ? 'Ожидаем выбор клиента…'
                      : 'Waiting for the client to choose session type…',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: V26.navy600,
          ),
        );
        return;
      }
      final roomId = data['roomId']?.toString();
      if (!mounted || roomId == null || roomId.isEmpty) return;
      Navigator.of(context).pushNamed(
        '/call',
        arguments: {
          'roomId': roomId,
          'callType': data['callType']?.toString() ?? 'video',
          'peerName': data['peerName']?.toString() ?? 'Client',
          'role': 'lawyer',
          'eventId': data['eventId']?.toString() ?? roomId,
          'language': data['language']?.toString() ?? preferredLanguage,
          'agoraToken': data['agoraToken']?.toString() ?? '',
          'agoraUid': data['agoraUid'],
        },
      );
    });

    _sessionReadySub = SocketService().onSessionReady.listen((data) {
      final roomId = data['roomId']?.toString();
      if (!mounted || roomId == null || roomId.isEmpty) return;
      Navigator.of(context).pushNamed(
        '/call',
        arguments: {
          'roomId': roomId,
          'callType': data['callType']?.toString() ?? 'video',
          'peerName': data['peerName']?.toString() ?? 'Client',
          'role': 'lawyer',
          'eventId': data['eventId']?.toString() ?? roomId,
          'language': data['language']?.toString() ?? preferredLanguage,
          'agoraToken': data['agoraToken']?.toString() ?? '',
          'agoraUid': data['agoraUid'],
        },
      );
    });

    _caseTakenSub = SocketService().onCaseTaken.listen((data) {
      final eventId = data['eventId']?.toString();
      if (!mounted || eventId == null) return;
      setState(() {
        _alerts.removeWhere((a) => a['eventId']?.toString() == eventId);
        _activeCases.removeWhere((c) => c['eventId']?.toString() == eventId);
      });
    });
  }

  @override
  void dispose() {
    _lawyerTopSearch.dispose();
    _alertSub?.cancel();
    _caseAcceptedSub?.cancel();
    _caseTakenSub?.cancel();
    _sessionReadySub?.cancel();
    super.dispose();
  }

  void _toggleAvailability(bool value) {
    setState(() => _isAvailable = value);
    SocketService().emit('lawyer_availability', {'available': value});
  }

  void _acceptCase(Map<String, dynamic> alert) {
    final eventId = alert['eventId'];
    SocketService().emit('accept_case', {'eventId': eventId});
    setState(() {
      _alerts.removeWhere((item) => item['eventId'] == eventId);
      _activeCases.insert(0, alert);
      _isAvailable = false;
    });
    SocketService().emit('lawyer_availability', {'available': false});
    _showSnack(_t(context, 'accepted'), background: V26.ok);
  }

  void _rejectCase(Map<String, dynamic> alert) {
    final eventId = alert['eventId'];
    SocketService().emit('reject_case', {'eventId': eventId});
    setState(() {
      _alerts.removeWhere((item) => item['eventId'] == eventId);
    });
    _showSnack(_t(context, 'rejected'));
  }

  void _showNotificationsPanel() {
    if (_alerts.isEmpty) {
      _showSnack(
        _t(context, 'noPendingAlerts'),
        background: V26.surface,
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: V26.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: V26.hairline),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: V26.hairline2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _t(ctx, 'queue'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: V26.ink900,
                ),
              ),
              const SizedBox(height: 12),
              for (final a in _alerts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.emergency_rounded, color: Color(0xFFFF3B3B)),
                  title: Text(
                    a['userName']?.toString() ?? _t(ctx, 'userFallback'),
                    style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    a['eventId']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: V26.ink500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSharedVaultFromCases() {
    final l = AppLocalizations.of(context);
    final userFb = l?.lawyerDashUserFallback ?? 'User';
    for (final c in _activeCases) {
      final uid = c['userId'];
      if (uid != null && uid.toString().isNotEmpty) {
        Navigator.pushNamed(context, '/shared_vault', arguments: {
          'userId': uid.toString(),
          'userName': c['userName'] ?? userFb,
        });
        return;
      }
    }
    for (final a in _alerts) {
      final uid = a['userId'];
      if (uid != null && uid.toString().isNotEmpty) {
        Navigator.pushNamed(context, '/shared_vault', arguments: {
          'userId': uid.toString(),
          'userName': a['userName'] ?? userFb,
        });
        return;
      }
    }
    _showSnack(
      _t(context, 'vaultRequiresCase'),
      background: V26.surface,
    );
  }

  void _showSnack(String message, {Color background = V26.surface}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: V26.ink900)),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: V26.hairline),
        ),
      ),
    );
  }

  void _showAlertDialog(Map<String, dynamic> alert) {
    final langCode = context.read<AppLanguageController>().code;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Directionality(
          textDirection: AppLanguage.directionOf(langCode),
          child: AlertDialog(
            backgroundColor: V26.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: V26.hairline),
            ),
            title: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: V26.emerg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t(dialogCtx, 'liveDialog'),
                    style: const TextStyle(
                      color: V26.ink900,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: _AlertSummary(
              title: _t(dialogCtx, 'requestDetails'),
              fromLabel: _t(dialogCtx, 'requestFrom'),
              fallbackText: _t(dialogCtx, 'requestUnknown'),
              data: alert,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  _rejectCase(alert);
                },
                child: Text(
                  _t(dialogCtx, 'reject'),
                  style: const TextStyle(color: V26.ink500),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  _acceptCase(alert);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: V26.ok,
                  foregroundColor: Colors.white,
                ),
                child: Text(_t(dialogCtx, 'accept')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguageController>();
    final code = language.code;
    final l = AppLocalizations.of(context)!;

    final isDesktop = context.isDesktop;
    final bodyContent = _isBooting
        ? const V26Backdrop(
            child: Center(child: CircularProgressIndicator(color: V26.navy600)),
          )
        : V26Backdrop(
            child: SafeArea(
              child: Column(children: [
                    if (isDesktop)
                      MockupDesktopTopBar(
                        searchController: _lawyerTopSearch,
                        trailing: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: VetoMockup.surfaceCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isAvailable
                                    ? VetoMockup.primaryCta.withValues(alpha: 0.45)
                                    : VetoMockup.hairline,
                              ),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isAvailable
                                      ? VetoMockup.primaryCta
                                      : const Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isAvailable
                                    ? l.lawyerDashBadgeOnline
                                    : l.lawyerDashBadgeOffline,
                                style: TextStyle(
                                  color: _isAvailable
                                      ? VetoMockup.primaryCtaDeep
                                      : VetoMockup.inkSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ]),
                          ),
                        ],
                        onProfile: () =>
                            Navigator.pushNamed(context, '/lawyer_settings'),
                        onNotifications: () {
                          HapticFeedback.lightImpact();
                          _showNotificationsPanel();
                        },
                      )
                    else
                      Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(children: [
                        // Bell
                        Stack(children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: V26.ink900),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showNotificationsPanel();
                            },
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                          if (_alerts.isNotEmpty)
                            Positioned(right: 8, top: 8, child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Color(0xFFFF3B3B), shape: BoxShape.circle),
                            )),
                        ]),
                        const Spacer(),
                        // Title
                        Text(
                          l.lawyerDashMobileHeader,
                          style: const TextStyle(
                            fontFamily: V26.serif,
                            color: V26.ink900,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Spacer(),
                        // Available badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: V26.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isAvailable
                                  ? V26.navy600.withValues(alpha: 0.35)
                                  : V26.hairline,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isAvailable ? V26.navy600 : const Color(0xFFF59E0B),
                                boxShadow: _isAvailable
                                    ? [
                                        BoxShadow(
                                          color: V26.navy600.withValues(alpha: 0.55),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isAvailable
                                  ? l.lawyerDashBadgeOnline
                                  : l.lawyerDashBadgeOffline,
                              style: TextStyle(
                                color: _isAvailable
                                    ? V26.navy600
                                    : V26.ink500,
                                fontSize: 12, fontWeight: FontWeight.w700,
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    ),

                    // ── Scrollable content ───────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(children: [
                          const V26CommandMapPanel(height: 176),
                          const SizedBox(height: 14),
                          // Greeting card
                          V26Card(
                            radius: 20,
                            padding: EdgeInsets.zero,
                            color: V26.surface,
                            borderColor: V26.hairline2,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.lawyerDashGreeting(_lawyerName),
                                        style: const TextStyle(
                                          fontFamily: V26.serif,
                                          color: V26.ink900,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l.lawyerDashActiveCaseCount(
                                          _activeCases.length,
                                        ),
                                        style: const TextStyle(
                                          color: V26.ink500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: V26.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: V26.navy600.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: V26.ink900,
                                    size: 28,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Stats row: 3 cards
                          Row(children: [
                            _LawyerStat(value: '${_activeCases.length}', label: l.lawyerDashStatActiveCases, color: const Color(0xFF5B8FFF)),
                            const SizedBox(width: 10),
                            _LawyerStat(value: '${_alerts.length}', label: l.lawyerDashStatTodayCalls, color: const Color(0xFF334155)),
                            const SizedBox(width: 10),
                            _LawyerStat(
                              value: '4.8',
                              label: l.lawyerDashStatRating,
                              color: const Color(0xFFF59E0B),
                              icon: Icons.star_rounded,
                            ),
                          ]),
                          const SizedBox(height: 14),

                          // Availability toggle
                          V26Card(
                            radius: 16,
                            padding: EdgeInsets.zero,
                            color: V26.surface,
                            borderColor: V26.hairline,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(children: [
                                const Icon(
                                  Icons.toggle_on_rounded,
                                  color: V26.navy600,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _isAvailable
                                        ? l.lawyerDashToggleAvailable
                                        : l.lawyerDashToggleUnavailable,
                                    style: TextStyle(
                                      color: _isAvailable
                                          ? V26.navy600
                                          : V26.ink500,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _isAvailable,
                                  onChanged: _toggleAvailability,
                                  activeThumbColor: V26.navy600,
                                  activeTrackColor: V26.navy600
                                      .withValues(alpha: 0.38),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Active cases section
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              l.lawyerDashSectionActiveCases,
                              style: const TextStyle(
                                color: V26.ink900,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (_alerts.isEmpty && _activeCases.isEmpty)
                            V26Card(
                              radius: 16,
                              padding: EdgeInsets.zero,
                              color: V26.surface,
                              borderColor: V26.hairline,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    _t(context, 'emptyTitle'),
                                    style: const TextStyle(
                                      color: V26.ink500,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),

                          // Alerts (incoming)
                          for (final alert in _alerts)
                            _LawyerCaseCard(
                              data: alert,
                              acceptLabel: _t(context, 'accept'),
                              rejectLabel: _t(context, 'reject'),
                              onAccept: () => _acceptCase(alert),
                              onReject: () => _rejectCase(alert),
                              urgency: 'urgent',
                            ),

                          // Active cases
                          for (int i = 0; i < _activeCases.length; i++)
                            _LawyerCaseCard(
                              data: _activeCases[i],
                              acceptLabel: l.lawyerDashViewCase,
                              rejectLabel: l.lawyerDashCloseCase,
                              onAccept: () {
                                final c = _activeCases[i];
                                final uid = c['userId'];
                                if (uid != null) {
                                  Navigator.pushNamed(context, '/shared_vault', arguments: {
                                    'userId': uid,
                                    'userName': c['userName'] ?? l.lawyerDashUserFallback,
                                  });
                                }
                              },
                              onReject: () => setState(() => _activeCases.removeAt(i)),
                              urgency: 'moderate',
                            ),

                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),

                    // ── Bottom nav bar (mobile only) ─────────────
                    if (!isDesktop)
                      Container(
                        decoration: const BoxDecoration(
                          color: V26.surface,
                          border: Border(
                            top: BorderSide(color: V26.hairline),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                            _BottomNavItem(
                              icon: Icons.home_rounded,
                              label: l.lawyerDashNavHome,
                              selected: true,
                              onTap: () => Navigator.pushReplacementNamed(context, '/lawyer_dashboard'),
                            ),
                            _BottomNavItem(
                              icon: Icons.folder_outlined,
                              label: l.lawyerDashNavCases,
                              selected: false,
                              onTap: _openSharedVaultFromCases,
                            ),
                            _BottomNavItem(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: l.lawyerDashNavChat,
                              selected: false,
                              onTap: () => Navigator.pushNamed(context, '/chat'),
                            ),
                            _BottomNavItem(
                              icon: Icons.person_outline_rounded,
                              label: l.lawyerDashNavProfile,
                              selected: false,
                              onTap: () => Navigator.pushNamed(context, '/lawyer_settings'),
                            ),
                          ]),
                        ),
                      ),
                  ]),
                ),
              );

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoMockup.pageBackground,
        body: isDesktop
            ? Row(
                children: [
                  _buildLawyerSidebar(context, l),
                  Expanded(child: bodyContent),
                ],
              )
            : bodyContent,
      ),
    );
  }

  /// Desktop-only sidebar mirroring 2026/lawyer.html layout.
  V26Sidebar _buildLawyerSidebar(BuildContext context, AppLocalizations l) {
    return V26Sidebar(
      width: 220,
      useMockupTokens: true,
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
                  l.lawyerDashRoleLawyer,
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
          title: l.lawyerDashSidebarNavigation,
          items: [
            V26SidebarItem(
              label: l.lawyerDashSidebarDashboard,
              icon: Icons.home_rounded,
              active: true,
              onTap: null,
            ),
            V26SidebarItem(
              label: l.lawyerDashSidebarCases,
              icon: Icons.folder_outlined,
              onTap: _openSharedVaultFromCases,
            ),
            V26SidebarItem(
              label: l.lawyerDashSidebarChat,
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => Navigator.pushNamed(context, '/chat'),
            ),
            V26SidebarItem(
              label: l.lawyerDashSidebarProfile,
              icon: Icons.person_outline_rounded,
              onTap: () => Navigator.pushNamed(context, '/lawyer_settings'),
            ),
            V26SidebarItem(
              label: l.lawyerDashSidebarSettings,
              icon: Icons.settings_rounded,
              onTap: () => Navigator.pushNamed(context, '/lawyer_settings'),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Lawyer stat tile ──────────────────────────────────────
class _LawyerStat extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData? icon;
  const _LawyerStat({required this.value, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: V26Card(
        radius: 14,
        padding: EdgeInsets.zero,
        color: V26.surface,
        borderColor: V26.hairline,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(children: [
            if (icon != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            else
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: V26.ink500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Case card ─────────────────────────────────────────────
class _LawyerCaseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String acceptLabel, rejectLabel, urgency;
  final VoidCallback onAccept, onReject;
  const _LawyerCaseCard({
    required this.data,
    required this.acceptLabel, required this.rejectLabel,
    required this.onAccept, required this.onReject, required this.urgency,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isUrgent = urgency == 'urgent';
    final chipColor = isUrgent ? const Color(0xFFFF3B3B) : const Color(0xFFF59E0B);
    final chipLabel = isUrgent ? l.lawyerDashChipUrgent : l.lawyerDashChipPending;
    final nameRaw = data['userName'] ?? data['name'] ?? l.lawyerDashUserFallback;
    final scenario = data['scenario'] ?? data['type'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: V26Card(
        radius: 16,
        padding: EdgeInsets.zero,
        color: V26.surface,
        borderColor: isUrgent
            ? const Color(0xFFFF3B3B).withValues(alpha: 0.4)
            : V26.hairline,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: chipColor.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    chipLabel,
                    style: TextStyle(
                      color: chipColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l.lawyerDashClientLine(nameRaw.toString()),
              style: const TextStyle(
                color: V26.ink900,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              scenario.isEmpty ? l.lawyerDashEmergencyFallback : scenario.toString(),
              style: const TextStyle(
                color: V26.ink500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: V26.navy500,
                      foregroundColor: V26.ink900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(acceptLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: V26.ink700,
                      side: const BorderSide(color: V26.hairline2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(rejectLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ── Bottom nav item ───────────────────────────────────────
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BottomNavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            icon,
            color: selected
                ? V26.navy600
                : V26.ink500,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? V26.navy600
                  : V26.ink500,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}

class _AlertSummary extends StatelessWidget {
  final String title;
  final String fromLabel;
  final String fallbackText;
  final Map<String, dynamic> data;

  const _AlertSummary({
    required this.title,
    required this.fromLabel,
    required this.fallbackText,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final details = data['details']?.toString().trim();
    final userId = data['userId']?.toString() ?? '—';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$fromLabel: $userId',
          style: const TextStyle(
            color: V26.ink900,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: V26.ink300,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (details == null || details.isEmpty) ? fallbackText : details,
          style: const TextStyle(
            color: V26.ink500,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

