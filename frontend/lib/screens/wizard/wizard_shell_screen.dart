import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_2026.dart';
import '../../core/theme/veto_mockup_tokens.dart';
import '../../core/theme/veto_2026_wizard.dart';
import '../../widgets/app_language_menu.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';

class _RailMarketing {
  final String brandEm;
  final String headlineLine1;
  final String headlineBeforeEm;
  final String headlineEm;
  final String headlineLine3;
  final String description;
  final String saveStatusLine;
  final String saveExitLabel;

  const _RailMarketing({
    required this.brandEm,
    required this.headlineLine1,
    required this.headlineBeforeEm,
    required this.headlineEm,
    required this.headlineLine3,
    required this.description,
    required this.saveStatusLine,
    required this.saveExitLabel,
  });
}

class WizardShellScreen extends StatefulWidget {
  const WizardShellScreen({super.key});

  @override
  State<WizardShellScreen> createState() => _WizardShellScreenState();
}

class _WizardShellScreenState extends State<WizardShellScreen> {
  final SocketService _socket = SocketService();

  String _role = 'user';
  String _langCode = 'he';
  bool _isBusy = false;
  bool _isAvailable = true;

  int _wizardIndex = 0;
  final List<Map<String, dynamic>> _alerts = [];

  StreamSubscription<Map<String, dynamic>>? _alertSub;
  StreamSubscription<Map<String, dynamic>>? _dispatchSub;
  StreamSubscription<Map<String, dynamic>>? _lawyerFoundSub;
  StreamSubscription<Map<String, dynamic>>? _noLawyersSub;
  StreamSubscription<Map<String, dynamic>>? _caseTakenSub;
  StreamSubscription<Map<String, dynamic>>? _sessionReadySub;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = AuthService();
    final role = await auth.getStoredRole() ?? 'user';
    final lang = AppLanguage.normalize(
      await auth.getStoredPreferredLanguage(),
    );

    if (!mounted) return;

    final controller = context.read<AppLanguageController>();
    if (controller.code != lang) {
      await controller.setLanguage(lang, persist: false);
    }

    setState(() {
      _role = role;
      _langCode = lang;
    });

    await _socket.connect(role: role);
    _socket.emit('lawyer_availability', {'available': _isAvailable});

    _alertSub = _socket.onNewEmergencyAlert.listen((data) {
      if (!mounted) return;
      setState(() => _alerts.add(data));
    });

    _dispatchSub = _socket.onVetoDispatched.listen((_) {
      if (!mounted) return;
      setState(() {
        _isBusy = true;
        _wizardIndex = 1;
      });
    });

    _lawyerFoundSub = _socket.onLawyerFound.listen((data) {
      if (!mounted) return;
      final awaiting = data['awaitingCitizenChoice'] == true;
      if (awaiting) {
        unawaited(_showWizardSessionPicker(data));
        return;
      }
      setState(() {
        _isBusy = false;
        _wizardIndex = 2;
      });
      final l10n = AppLocalizations.of(context)!;
      final foundName = data['lawyerName']?.toString() ?? l10n.wizDefaultLawyerName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.wizLawyerConnected(foundName)),
        ),
      );
    });

    _sessionReadySub = _socket.onSessionReady.listen((data) {
      final roomId = data['roomId']?.toString();
      if (!mounted || roomId == null || roomId.isEmpty) return;
      setState(() {
        _isBusy = false;
        _wizardIndex = 2;
      });
      Navigator.of(context).pushNamed(
        '/call',
        arguments: {
          'roomId': roomId,
          'callType': data['callType']?.toString() ?? 'video',
          'peerName': data['peerName']?.toString() ??
              AppLocalizations.of(context)!.wizDefaultLawyerName,
          'role': _role == 'admin' ? 'admin' : 'user',
          'eventId': data['eventId']?.toString() ?? roomId,
          'language': _langCode,
          'agoraToken': data['agoraToken']?.toString() ?? '',
          'agoraUid': data['agoraUid'],
        },
      );
    });

    _noLawyersSub = _socket.onNoLawyersAvailable.listen((_) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _wizardIndex = 0;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.wizNoLawyersAvailable),
        ),
      );
    });

    if (role == 'lawyer') {
      _caseTakenSub = _socket.onCaseTaken.listen((data) {
        final eventId = data['eventId']?.toString();
        if (!mounted || eventId == null) return;
        setState(() => _alerts.removeWhere((a) => a['eventId']?.toString() == eventId));
      });
    }
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _dispatchSub?.cancel();
    _lawyerFoundSub?.cancel();
    _noLawyersSub?.cancel();
    _caseTakenSub?.cancel();
    _sessionReadySub?.cancel();
    super.dispose();
  }

  Future<void> _showWizardSessionPicker(Map<String, dynamic> data) async {
    final eventId = data['eventId']?.toString();
    final l10n = AppLocalizations.of(context)!;
    final lawyerName =
        data['lawyerName']?.toString() ?? l10n.wizDefaultLawyerName;
    if (eventId == null || eventId.isEmpty) return;

    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: V26Card(
            lift: true,
            radius: V26.r2xl,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.wizSessionAccepted(lawyerName),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: V26.sans,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: V26.ink900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: V26.navy600,
                            side: const BorderSide(color: V26.hairline),
                          ),
                          onPressed: () => Navigator.pop(ctx, 'audio'),
                          child: Text(l10n.wizSessionAudio),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: V26.navy600,
                            side: const BorderSide(color: V26.hairline),
                          ),
                          onPressed: () => Navigator.pop(ctx, 'video'),
                          child: Text(l10n.wizSessionVideo),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: V26.navy600,
                            side: const BorderSide(color: V26.hairline),
                          ),
                          onPressed: () => Navigator.pop(ctx, 'chat'),
                          child: Text(l10n.wizSessionChat),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (chosen != null && mounted) {
      _socket.emitCitizenChoseSession(eventId: eventId, callType: chosen);
    }
  }

  Future<void> _triggerEmergency() async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
      _wizardIndex = 1;
    });

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {
      // Location failure keeps fallback coordinates for uninterrupted flow.
    }

    _socket.emitStartVeto(
      lat: pos?.latitude ?? 32.08088,
      lng: pos?.longitude ?? 34.78057,
      preferredLanguage: _langCode,
    );
  }

  void _acceptAlert(Map<String, dynamic> alert) {
    final eventId = alert['eventId']?.toString();
    if (eventId == null || eventId.isEmpty) return;

    _socket.emit('accept_case', {'eventId': eventId});
    setState(() {
      _alerts.removeWhere((a) => a['eventId'] == eventId);
      _isAvailable = false;
      _wizardIndex = 2;
    });
    _socket.emit('lawyer_availability', {'available': false});
  }

  void _rejectAlert(Map<String, dynamic> alert) {
    final eventId = alert['eventId']?.toString();
    if (eventId == null || eventId.isEmpty) return;

    _socket.emit('reject_case', {'eventId': eventId});
    setState(() => _alerts.removeWhere((a) => a['eventId'] == eventId));
  }

  void _exitWizard() {
    if (!mounted) return;
    if (_role == 'lawyer') {
      Navigator.of(context).pushReplacementNamed('/lawyer_dashboard');
    } else if (_role == 'admin') {
      Navigator.of(context).pushReplacementNamed('/admin_settings');
    } else {
      Navigator.of(context).pushReplacementNamed('/veto_screen');
    }
  }

  List<String> _wizardTitles(AppLocalizations l) {
    final lawyer = _role == 'lawyer';
    if (lawyer) {
      return [
        l.wizShellLawTitle1,
        l.wizShellLawTitle2,
        l.wizShellLawTitle3,
        l.wizShellLawTitle4,
      ];
    }
    return [
      l.wizShellUserTitle1,
      l.wizShellUserTitle2,
      l.wizShellUserTitle3,
      l.wizShellUserTitle4,
    ];
  }

  List<String> _wizardSubtitles(AppLocalizations l) {
    final lawyer = _role == 'lawyer';
    if (lawyer) {
      return [
        l.wizShellLawSub1,
        l.wizShellLawSub2,
        l.wizShellLawSub3,
        l.wizShellLawSub4,
      ];
    }
    return [
      l.wizShellUserSub1,
      l.wizShellUserSub2,
      l.wizShellUserSub3,
      l.wizShellUserSub4,
    ];
  }

  _RailMarketing _railMarketing(AppLocalizations l) {
    final lawyer = _role == 'lawyer';
    if (lawyer) {
      return _RailMarketing(
        brandEm: l.wizShellRailLawyerBrandEm,
        headlineLine1: l.wizShellRailLawyerHeadline1,
        headlineBeforeEm: l.wizShellRailLawyerBeforeEm,
        headlineEm: 'VETO',
        headlineLine3: l.wizShellRailLawyerLine3,
        description: l.wizShellRailLawyerDesc,
        saveStatusLine: l.wizShellRailLawyerSaveStatus,
        saveExitLabel: l.wizShellRailLawyerSaveExit,
      );
    }
    return _RailMarketing(
      brandEm: l.wizShellRailUserBrandEm,
      headlineLine1: l.wizShellRailUserHeadline1,
      headlineBeforeEm: l.wizShellRailUserBeforeEm,
      headlineEm: 'VETO',
      headlineLine3: l.wizShellRailUserLine3,
      description: l.wizShellRailUserDesc,
      saveStatusLine: l.wizShellRailUserSaveStatus,
      saveExitLabel: l.wizShellRailUserSaveExit,
    );
  }

  String _topKicker(AppLocalizations l) {
    final i = _wizardIndex + 1;
    return l.wizShellStepOfTotal(i);
  }

  String _phoneProgressBold(AppLocalizations l) {
    final i = _wizardIndex + 1;
    return l.wizShellStepOfTotal(i);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageController>().code;
    final l = AppLocalizations.of(context)!;
    final titles = _wizardTitles(l);
    final subtitles = _wizardSubtitles(l);
    final rail = _railMarketing(l);
    final wide =
        MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;

    return Directionality(
      textDirection: AppLanguage.directionOf(lang),
      child: Scaffold(
        backgroundColor: VetoMockup.pageBackground,
        body: V26Backdrop(
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  V26WizardRail(
                    brandEm: rail.brandEm,
                    headlineLine1: rail.headlineLine1,
                    headlineBeforeEm: rail.headlineBeforeEm,
                    headlineEm: rail.headlineEm,
                    headlineLine3: rail.headlineLine3,
                    description: rail.description,
                    stepTitles: titles,
                    stepSubtitles: subtitles,
                    currentStepIndex: _wizardIndex,
                    saveStatusLine: rail.saveStatusLine,
                    saveExitLabel: rail.saveExitLabel,
                    onSaveExit: _exitWizard,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _wizTopBar(context, l, titles, compact: !wide),
                      if (!wide)
                        V26WizardPhoneProgress(
                          stepIndexZeroBased: _wizardIndex,
                          stepCount: 4,
                          labelBold: _phoneProgressBold(l),
                          labelDetail: titles[_wizardIndex.clamp(0, 3)],
                        ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: _role == 'lawyer'
                              ? _lawyerWizard(!wide, l)
                              : _userWizard(!wide, l),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wizTopBar(
    BuildContext context,
    AppLocalizations l,
    List<String> titles, {
    required bool compact,
  }) {
    final idx = _wizardIndex.clamp(0, titles.length - 1);
    final sectionTitle = titles[idx];
    final roleBadge = switch (_role) {
      'lawyer' => l.wizShellBadgeLawyer,
      'admin' => l.wizShellBadgeAdmin,
      _ => l.wizShellBadgeUser,
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 32,
        compact ? 14 : 18,
        compact ? 14 : 32,
        compact ? 12 : 18,
      ),
      decoration: const BoxDecoration(
        color: V26.surface,
        border: Border(bottom: BorderSide(color: V26.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                V26Kicker(_topKicker(l)),
                const SizedBox(height: 4),
                Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontFamily: V26.serif,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: V26.ink900,
                  ),
                ),
              ],
            ),
          ),
          const AppLanguageMenu(compact: true),
          const SizedBox(width: 6),
          if (!compact) ...[
            V26Badge(roleBadge, tone: V26BadgeTone.brand),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: l.wizShellTooltipProfile,
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.account_circle_outlined, color: V26.ink700),
          ),
          if (_role == 'admin')
            IconButton(
              tooltip: l.wizShellTooltipAdmin,
              onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
              icon: const Icon(Icons.admin_panel_settings_outlined,
                  color: V26.ink700),
            ),
          IconButton(
            tooltip: l.wizShellTooltipLogout,
            onPressed: () => AuthService().logout(context),
            icon: const Icon(Icons.logout_rounded, color: V26.ink500),
          ),
        ],
      ),
    );
  }

  Widget _userWizard(bool compact, AppLocalizations l) {
    return ListView(
      key: const ValueKey('userWizard2050'),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 56,
        compact ? 18 : 32,
        compact ? 16 : 56,
        32,
      ),
      children: [
        _panel(
          compact: compact,
          title: l.wizShellUserPanel1Title,
          subtitle: l.wizShellUserPanel1Sub,
          child: Row(
            children: [
              V26Badge(
                _isBusy
                    ? l.wizShellUserBadgeDispatching
                    : l.wizShellUserBadgeProtected,
                tone: _isBusy ? V26BadgeTone.warn : V26BadgeTone.ok,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isBusy
                      ? l.wizShellUserPanel1BusyBody
                      : l.wizShellUserPanel1IdleBody,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    color: V26.ink700,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          compact: compact,
          title: l.wizShellUserPanel2Title,
          subtitle: l.wizShellUserPanel2Sub,
          child: V26CTA(
            _isBusy ? l.wizShellUserDispatchCtaBusy : l.wizShellUserDispatchCta,
            variant: V26CtaVariant.danger,
            large: true,
            expanded: true,
            loading: _isBusy,
            icon: Icons.shield_outlined,
            onPressed: _triggerEmergency,
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          compact: compact,
          title: l.wizShellUserPanel3Title,
          subtitle: l.wizShellUserPanel3Sub,
          child: V26CTA(
            l.wizShellUserOpenEmergency,
            variant: V26CtaVariant.ghost,
            large: true,
            expanded: true,
            icon: Icons.perm_camera_mic_outlined,
            onPressed: () => Navigator.pushNamed(context, '/veto_screen'),
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          compact: compact,
          title: l.wizShellUserPanel4Title,
          subtitle: l.wizShellUserPanel4Sub,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              V26CTA(
                l.wizShellUserCtaProfile,
                variant: V26CtaVariant.ghost,
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              if (_role == 'admin')
                V26CTA(
                  l.wizShellUserCtaAdmin,
                  variant: V26CtaVariant.ghost,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/admin_settings'),
                ),
              V26CTA(
                l.wizShellUserCtaLogout,
                variant: V26CtaVariant.subtle,
                onPressed: () => AuthService().logout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lawyerWizard(bool compact, AppLocalizations l) {
    return ListView(
      key: const ValueKey('lawyerWizard2050'),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 56,
        compact ? 18 : 32,
        compact ? 16 : 56,
        32,
      ),
      children: [
        _panel(
          compact: compact,
          title: l.wizShellLawPanel1Title,
          subtitle: l.wizShellLawPanel1Sub,
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: V26.navy600,
            activeTrackColor: V26.navy200,
            title: Text(
                _isAvailable ? l.wizShellLawAvailOn : l.wizShellLawAvailOff),
            subtitle: Text(_isAvailable
                ? l.wizShellLawAvailOnSub
                : l.wizShellLawAvailOffSub),
            value: _isAvailable,
            onChanged: (v) {
              setState(() {
                _isAvailable = v;
                _wizardIndex = 0;
              });
              _socket.emit('lawyer_availability', {'available': v});
            },
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          compact: compact,
          title: l.wizShellLawPanel2Title,
          subtitle: l.wizShellLawPanel2Sub,
          child: _alerts.isEmpty
              ? Text(l.wizShellLawNoAlerts)
              : Column(
                  children: _alerts
                      .map(
                        (alert) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(V26.rMd),
                            color: V26.surface2,
                            border: const Border(
                              top: BorderSide(color: V26.hairline),
                              right: BorderSide(color: V26.hairline),
                              bottom: BorderSide(color: V26.hairline),
                              left: BorderSide(color: V26.warn, width: 3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notification_important_outlined,
                                  color: V26.warn, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l.wizShellLawCallNumber(
                                      alert['eventId']?.toString() ?? 'N/A'),
                                  style: const TextStyle(
                                    fontFamily: V26.sans,
                                    color: V26.ink900,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: l.wizShellLawRejectTooltip,
                                onPressed: () => _rejectAlert(alert),
                                icon: const Icon(Icons.close_rounded,
                                    color: V26.emerg, size: 20),
                              ),
                              V26CTA(
                                l.wizShellLawAccept,
                                variant: V26CtaVariant.primary,
                                icon: Icons.check_rounded,
                                onPressed: () => _acceptAlert(alert),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 12),
        _panel(
          compact: compact,
          title: l.wizShellLawPanel3Title,
          subtitle: l.wizShellLawPanel3Sub,
          child: Text(
            _isAvailable ? l.wizShellLawNoCase : l.wizShellLawBusyCase,
            style: const TextStyle(
              fontFamily: V26.sans,
              color: V26.ink700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          compact: compact,
          title: l.wizShellLawPanel4Title,
          subtitle: l.wizShellLawPanel4Sub,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              V26CTA(
                l.wizShellUserCtaProfile,
                variant: V26CtaVariant.ghost,
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              if (_role == 'admin')
                V26CTA(
                  l.wizShellUserCtaAdmin,
                  variant: V26CtaVariant.ghost,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/admin_settings'),
                ),
              V26CTA(
                l.wizShellUserCtaLogout,
                variant: V26CtaVariant.subtle,
                onPressed: () => AuthService().logout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panel({
    required bool compact,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return V26Card(
      lift: true,
      radius: compact ? V26.rXl : V26.r2xl,
      padding: EdgeInsets.all(compact ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: V26.serif,
              color: V26.ink900,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: V26.sans,
              color: V26.ink500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
