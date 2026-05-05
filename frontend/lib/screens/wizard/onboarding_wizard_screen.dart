// ============================================================
//  OnboardingWizardScreen — 1:1 port of 2026/wizard.html
//  4-step onboarding quiz: role → scenario → alerts → privacy.
//  Runs at `/wizard_home` for first-time citizens after verify-OTP.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_2026.dart';
import '../../core/theme/veto_2026_wizard.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_language_menu.dart';
import '../../l10n/app_localizations.dart';

/// Single option definition (role / scenario / alerts / privacy).
class _Opt {
  final String id;
  final IconData icon;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) desc;
  const _Opt(this.id, this.icon, this.title, this.desc);
  String t(AppLocalizations l) => title(l);
  String d(AppLocalizations l) => desc(l);
}

List<_Opt> _roleOpts() => [
      _Opt(
        'citizen',
        Icons.shield_rounded,
        (l) => l.wizOnbRoleCitizenTitle,
        (l) => l.wizOnbRoleCitizenDesc,
      ),
      _Opt(
        'lawyer',
        Icons.gavel_rounded,
        (l) => l.wizOnbRoleLawyerTitle,
        (l) => l.wizOnbRoleLawyerDesc,
      ),
    ];

List<_Opt> _scenarioOpts() => [
      _Opt(
        'police',
        Icons.shield_rounded,
        (l) => l.wizOnbScnPoliceTitle,
        (l) => l.wizOnbScnPoliceDesc,
      ),
      _Opt(
        'traffic',
        Icons.traffic_rounded,
        (l) => l.wizOnbScnTrafficTitle,
        (l) => l.wizOnbScnTrafficDesc,
      ),
      _Opt(
        'civil',
        Icons.description_rounded,
        (l) => l.wizOnbScnCivilTitle,
        (l) => l.wizOnbScnCivilDesc,
      ),
      _Opt(
        'labor',
        Icons.work_rounded,
        (l) => l.wizOnbScnLaborTitle,
        (l) => l.wizOnbScnLaborDesc,
      ),
      _Opt(
        'family',
        Icons.family_restroom_rounded,
        (l) => l.wizOnbScnFamilyTitle,
        (l) => l.wizOnbScnFamilyDesc,
      ),
      _Opt(
        'consumer',
        Icons.shopping_bag_rounded,
        (l) => l.wizOnbScnConsumerTitle,
        (l) => l.wizOnbScnConsumerDesc,
      ),
    ];

List<_Opt> _alertsOpts() => [
      _Opt(
        'push_sms',
        Icons.notifications_active_rounded,
        (l) => l.wizOnbAlertPushSmsTitle,
        (l) => l.wizOnbAlertPushSmsDesc,
      ),
      _Opt(
        'push',
        Icons.phone_android_rounded,
        (l) => l.wizOnbAlertPushTitle,
        (l) => l.wizOnbAlertPushDesc,
      ),
      _Opt(
        'sms',
        Icons.sms_rounded,
        (l) => l.wizOnbAlertSmsTitle,
        (l) => l.wizOnbAlertSmsDesc,
      ),
      _Opt(
        'call',
        Icons.call_rounded,
        (l) => l.wizOnbAlertCallTitle,
        (l) => l.wizOnbAlertCallDesc,
      ),
    ];

List<_Opt> _privacyOpts() => [
      _Opt(
        'anonymous',
        Icons.visibility_off_rounded,
        (l) => l.wizOnbPrivAnonTitle,
        (l) => l.wizOnbPrivAnonDesc,
      ),
      _Opt(
        'verified',
        Icons.verified_user_rounded,
        (l) => l.wizOnbPrivVerifiedTitle,
        (l) => l.wizOnbPrivVerifiedDesc,
      ),
    ];

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  int _step = 1; // 1..4 (matches mockup wording "שאלה N מתוך 4")
  String _role = 'citizen';
  String _scenario = 'police';
  String _alerts = 'push_sms';
  String _privacy = 'anonymous';

  DateTime _lastSaved = DateTime.now();
  Timer? _saveTicker;
  bool _submitting = false;

  static const int _stepCount = 4;

  @override
  void initState() {
    super.initState();
    _saveTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {}); // refresh "נשמר אוטומטית · לפני N שניות"
    });
  }

  @override
  void dispose() {
    _saveTicker?.cancel();
    super.dispose();
  }

  void _touchSaved() => _lastSaved = DateTime.now();

  String _saveStatusText(AppLocalizations l) {
    final secs = DateTime.now().difference(_lastSaved).inSeconds;
    final n = secs.clamp(0, 999);
    if (n == 0) return l.wizOnbSaveJustNow;
    return l.wizOnbSaveSecondsAgo(n);
  }

  String _stepTitle(int idx, AppLocalizations l) {
    switch (idx) {
      case 1:
        return l.wizOnbStepTitle1;
      case 2:
        return l.wizOnbStepTitle2;
      case 3:
        return l.wizOnbStepTitle3;
      case 4:
        return l.wizOnbStepTitle4;
    }
    return '';
  }

  String _stepSubtitle(int idx, AppLocalizations l) {
    switch (idx) {
      case 1:
        return l.wizOnbStepSubtitle1;
      case 2:
        return l.wizOnbStepSubtitle2;
      case 3:
        return l.wizOnbStepSubtitle3;
      case 4:
        return l.wizOnbStepSubtitle4;
    }
    return '';
  }

  List<_Opt> _optsFor(int step) {
    switch (step) {
      case 1:
        return _roleOpts();
      case 2:
        return _scenarioOpts();
      case 3:
        return _alertsOpts();
      case 4:
        return _privacyOpts();
    }
    return <_Opt>[];
  }

  String _currentSelection() {
    switch (_step) {
      case 1:
        return _role;
      case 2:
        return _scenario;
      case 3:
        return _alerts;
      case 4:
        return _privacy;
    }
    return '';
  }

  void _select(String id) {
    setState(() {
      switch (_step) {
        case 1:
          _role = id;
          break;
        case 2:
          _scenario = id;
          break;
        case 3:
          _alerts = id;
          break;
        case 4:
          _privacy = id;
          break;
      }
      _touchSaved();
    });
  }

  Future<void> _next() async {
    if (_step < _stepCount) {
      setState(() {
        _step += 1;
        _touchSaved();
      });
      return;
    }
    await _finish();
  }

  void _back() {
    if (_step <= 1) return;
    setState(() {
      _step -= 1;
      _touchSaved();
    });
  }

  Future<void> _saveExit() async {
    final auth = AuthService();
    await auth.saveOnboarding(
      scenario: _scenario,
      alerts: _alerts,
      privacy: _privacy,
    );
    if (!mounted) return;
    _routeForRole();
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final auth = AuthService();
    await auth.saveOnboarding(
      scenario: _scenario,
      alerts: _alerts,
      privacy: _privacy,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    _routeForRole();
  }

  void _routeForRole() {
    final target = _role == 'lawyer' ? '/lawyer_dashboard' : '/veto_screen';
    Navigator.of(context).pushReplacementNamed(target);
  }

  // ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final l = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= V26AppShell.desktopBreakpoint;

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: V26.paper,
        body: SafeArea(
          child: isWide ? _buildDesktop(l) : _buildMobile(l),
        ),
      ),
    );
  }

  Widget _buildDesktop(AppLocalizations l) {
    return Row(
      children: [
        V26WizardRail(
          brandEm: l.wizOnbRailBrandEm,
          headlineLine1: l.wizOnbRailHeadline1,
          headlineBeforeEm: l.wizOnbRailHeadlineBeforeEm,
          headlineEm: 'VETO',
          headlineLine3: l.wizOnbRailHeadline3,
          description: l.wizOnbRailDescription,
          stepTitles: [
            _stepTitle(1, l),
            _stepTitle(2, l),
            _stepTitle(3, l),
            _stepTitle(4, l),
          ],
          stepSubtitles: [
            _stepSubtitleShort(1, l, _role),
            _stepSubtitleShort(2, l, _scenario),
            _stepSubtitleShort(3, l, _alerts),
            _stepSubtitleShort(4, l, _privacy),
          ],
          currentStepIndex: _step - 1,
          saveStatusLine: _saveStatusText(l),
          saveExitLabel: l.wizOnbSaveExit,
          onSaveExit: _saveExit,
        ),
        Expanded(
          child: Column(
            children: [
              _wizTopbar(l, compact: false),
              Expanded(child: _wizBody(l, compact: false)),
              V26WizFoot(
                backLabel: _step > 1 ? l.wizOnbBack : null,
                onBack: _back,
                nextLabel: _step < _stepCount ? l.wizOnbContinue : l.wizOnbFinish,
                onNext: _submitting ? null : _next,
                hint: _step < _stepCount ? _nextHint(l) : null,
                compact: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _stepSubtitleShort(int idx, AppLocalizations l, String selectedId) {
    if (idx > _step) return _stepSubtitle(idx, l);
    final selected = _optsFor(idx).firstWhere(
      (o) => o.id == selectedId,
      orElse: () => _optsFor(idx).first,
    );
    if (idx < _step) {
      return '${selected.t(l)} · ${l.wizOnbSelectedLabel}';
    }
    return _stepSubtitle(idx, l);
  }

  Widget _buildMobile(AppLocalizations l) {
    return Column(
      children: [
        _wizTopbar(l, compact: true),
        V26WizardPhoneProgress(
          stepIndexZeroBased: _step - 1,
          stepCount: _stepCount,
          labelBold: l.wizOnbQuestionProgress(_step, _stepCount),
          labelDetail: _stepTitle(_step, l),
        ),
        Expanded(child: _wizBody(l, compact: true)),
        V26WizFoot(
          backLabel: _step > 1 ? '←' : null,
          onBack: _back,
          nextLabel: _step < _stepCount
              ? l.wizOnbContinue.replaceAll(' →', '')
              : l.wizOnbFinish,
          onNext: _submitting ? null : _next,
          compact: true,
        ),
      ],
    );
  }

  String _nextHint(AppLocalizations l) {
    final nextIdx = _step + 1;
    if (nextIdx > _stepCount) return '';
    return '${l.wizOnbNextHintPrefix}${_stepTitle(nextIdx, l)}';
  }

  Widget _wizTopbar(AppLocalizations l, {required bool compact}) {
    final stepLabel = l.wizOnbQuestionProgress(_step, _stepCount);
    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(14, 14, 14, 12)
          : const EdgeInsets.fromLTRB(32, 18, 32, 18),
      decoration: const BoxDecoration(
        color: V26.surface,
        border: Border(bottom: BorderSide(color: V26.hairline)),
      ),
      child: Row(
        children: [
          if (compact)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_right,
                  color: V26.ink700, size: 22),
              onPressed: _step > 1 ? _back : null,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stepLabel,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: V26.ink500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stepTitle(_step, l),
                  style: TextStyle(
                    fontFamily: V26.serif,
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: V26.ink900,
                  ),
                ),
              ],
            ),
          ),
          const AppLanguageMenu(compact: true),
          if (compact) ...[
            const SizedBox(width: 6),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded,
                  color: V26.ink700, size: 22),
              onPressed: _saveExit,
            ),
          ],
        ],
      ),
    );
  }

  Widget _wizBody(AppLocalizations l, {required bool compact}) {
    if (_step == _stepCount) {
      return _summaryBody(l, compact: compact);
    }
    final opts = _optsFor(_step);
    final selected = _currentSelection();
    return SingleChildScrollView(
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 18, 16, 18)
          : const EdgeInsets.fromLTRB(56, 32, 56, 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const maxCard = 920.0;
          final cardWidth = constraints.maxWidth > maxCard
              ? maxCard
              : constraints.maxWidth;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: cardWidth,
              child: V26QuizCard(
                title: _buildQuestionHeadline(l),
                lede: _buildQuestionLede(l),
                compact: compact,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    V26OptGrid(
                      compact: compact,
                      options: [
                        for (final o in opts)
                          V26OptTile(
                            icon: o.icon,
                            title: o.t(l),
                            description: o.d(l),
                            selected: selected == o.id,
                            onTap: () => _select(o.id),
                          ),
                      ],
                    ),
                    if (_step == 2) ...[
                      const SizedBox(height: 24),
                      _calloutInfo(l),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _buildQuestionHeadline(AppLocalizations l) {
    switch (_step) {
      case 1:
        return l.wizOnbQ1Head;
      case 2:
        return l.wizOnbQ2Head;
      case 3:
        return l.wizOnbQ3Head;
      case 4:
        return l.wizOnbQ4Head;
    }
    return '';
  }

  String _buildQuestionLede(AppLocalizations l) {
    switch (_step) {
      case 1:
        return l.wizOnbQ1Lede;
      case 2:
        return l.wizOnbQ2Lede;
      case 3:
        return l.wizOnbQ3Lede;
      case 4:
        return l.wizOnbQ4Lede;
    }
    return '';
  }

  Widget _calloutInfo(AppLocalizations l) {
    final body = l.wizOnbCalloutScenario;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: V26.paper2,
        border: Border.all(color: V26.navy100),
        borderRadius: BorderRadius.circular(V26.rMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: V26.navy600,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.info_outline,
                size: 13, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              body,
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 13,
                height: 1.5,
                color: V26.ink700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBody(AppLocalizations l, {required bool compact}) {
    final items = <_SummaryRow>[
      _SummaryRow(
        title: '${l.wizOnbSumRolePrefix} ${_optLabel(_roleOpts(), _role, l)}',
        subtitle: l.wizOnbSumRoleSub,
      ),
      _SummaryRow(
        title:
            '${l.wizOnbSumScenarioPrefix} ${_optLabel(_scenarioOpts(), _scenario, l)}',
        subtitle: l.wizOnbSumScenarioSub,
      ),
      _SummaryRow(
        title: '${l.wizOnbSumAlertsPrefix} ${_optLabel(_alertsOpts(), _alerts, l)}',
        subtitle: l.wizOnbSumAlertsSub,
      ),
      _SummaryRow(
        title:
            '${l.wizOnbSumPrivacyPrefix} ${_optLabel(_privacyOpts(), _privacy, l)}',
        subtitle: l.wizOnbSumPrivacySub,
      ),
    ];

    return SingleChildScrollView(
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 18, 16, 18)
          : const EdgeInsets.fromLTRB(56, 32, 56, 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const maxCard = 920.0;
          final cardWidth = constraints.maxWidth > maxCard
              ? maxCard
              : constraints.maxWidth;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: cardWidth,
              child: V26QuizCard(
                title: l.wizOnbSumAllSet,
                lede: l.wizOnbSumSummaryLede,
                compact: compact,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _summaryTile(items[i]),
                    ],
                    const SizedBox(height: 18),
                    _calloutSuccess(l),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _optLabel(List<_Opt> opts, String id, AppLocalizations l) {
    return opts
        .firstWhere((o) => o.id == id, orElse: () => opts.first)
        .t(l);
  }

  Widget _summaryTile(_SummaryRow row) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: V26.surface,
        border: Border.all(color: V26.hairline),
        borderRadius: BorderRadius.circular(V26.rMd),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: V26.ok,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_rounded,
                size: 13, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.title,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: V26.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.subtitle,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    fontSize: 12,
                    color: V26.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calloutSuccess(AppLocalizations l) {
    final head = l.wizOnbSuccessHead;
    final body = l.wizOnbSuccessBody;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFCF6),
        border: Border.all(color: V26.ok.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(V26.rMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: V26.ok,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_rounded,
                size: 13, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: V26.sans,
                  fontSize: 13,
                  height: 1.5,
                  color: V26.ink900,
                ),
                children: [
                  TextSpan(
                    text: '$head ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String title;
  final String subtitle;
  const _SummaryRow({required this.title, required this.subtitle});
}
