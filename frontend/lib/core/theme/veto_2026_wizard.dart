// Wizard shell chrome — aligned with `2026/wizard.html` (`.wiz-progress-rail`, `.wiz-step`).
import 'package:flutter/material.dart';

import 'veto_2026.dart';

enum V26WizardRailStepState { pending, active, done }

/// Desktop left rail — ink→navy gradient, gold radial glow, numbered steps.
class V26WizardRail extends StatelessWidget {
  final String brandEm;
  final String headlineLine1;
  final String headlineBeforeEm;
  final String headlineEm;
  final String headlineLine3;
  final String description;
  final List<String> stepTitles;
  final List<String> stepSubtitles;
  final int currentStepIndex;
  final String saveStatusLine;
  final String saveExitLabel;
  final VoidCallback onSaveExit;

  const V26WizardRail({
    super.key,
    required this.brandEm,
    required this.headlineLine1,
    required this.headlineBeforeEm,
    required this.headlineEm,
    required this.headlineLine3,
    required this.description,
    required this.stepTitles,
    required this.stepSubtitles,
    required this.currentStepIndex,
    required this.saveStatusLine,
    required this.saveExitLabel,
    required this.onSaveExit,
  });

  @override
  Widget build(BuildContext context) {
    assert(stepTitles.length == stepSubtitles.length);
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [V26.ink900, V26.navy800],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      V26.gold.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _WizardRailBrand(brandEm: brandEm),
                          const SizedBox(height: 24),
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontFamily: V26.serif,
                                fontSize: 22,
                                height: 1.2,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(text: '$headlineLine1\n'),
                                TextSpan(text: headlineBeforeEm),
                                TextSpan(
                                  text: headlineEm,
                                  style:
                                      const TextStyle(color: V26.goldSoft),
                                ),
                                TextSpan(text: '\n$headlineLine3'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            description,
                            style: const TextStyle(
                              fontFamily: V26.sans,
                              fontSize: 13,
                              height: 1.6,
                              color: Color(0xFFB6C7E2),
                            ),
                          ),
                          const SizedBox(height: 32),
                          for (var i = 0; i < stepTitles.length; i++) ...[
                            _WizardRailStepTile(
                              stepNumber: i + 1,
                              title: stepTitles[i],
                              subtitle: stepSubtitles[i],
                              state: _stateFor(i),
                            ),
                            if (i < stepTitles.length - 1)
                              const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: V26.ok,
                                boxShadow: [
                                  BoxShadow(
                                    color: V26.ok.withValues(alpha: 0.35),
                                    blurRadius: 0,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                saveStatusLine,
                                style: const TextStyle(
                                  fontFamily: V26.sans,
                                  fontSize: 12,
                                  color: Color(0xFFB6C7E2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: onSaveExit,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            saveExitLabel,
                            style: const TextStyle(
                              fontFamily: V26.sans,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  V26WizardRailStepState _stateFor(int i) {
    if (i < currentStepIndex) return V26WizardRailStepState.done;
    if (i == currentStepIndex) return V26WizardRailStepState.active;
    return V26WizardRailStepState.pending;
  }
}

class _WizardRailBrand extends StatelessWidget {
  final String brandEm;
  const _WizardRailBrand({required this.brandEm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          alignment: Alignment.center,
          child: const Text(
            'V',
            style: TextStyle(
              fontFamily: V26.serif,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'VETO',
                style: TextStyle(
                  fontFamily: V26.serif,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Colors.white,
                ),
              ),
              Text(
                brandEm,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFFB6D2FB),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WizardRailStepTile extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String subtitle;
  final V26WizardRailStepState state;

  const _WizardRailStepTile({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final active = state == V26WizardRailStepState.active;
    final done = state == V26WizardRailStepState.done;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? V26.ok
                  : active
                      ? V26.gold
                      : Colors.white.withValues(alpha: 0.10),
              border: Border.all(
                color: done
                    ? V26.ok
                    : active
                        ? V26.gold
                        : Colors.white.withValues(alpha: 0.20),
              ),
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontFamily: V26.serif,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: active ? Colors.white : const Color(0xFFB6C7E2),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: V26.sans,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: done ? const Color(0xFFB6C7E2) : Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    fontSize: 11.5,
                    height: 1.4,
                    color: Color(0xFFB6C7E2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile-only progress bar (`phone-progress` in the mock).
class V26WizardPhoneProgress extends StatelessWidget {
  final int stepIndexZeroBased;
  final int stepCount;
  final String labelBold;
  final String labelDetail;

  const V26WizardPhoneProgress({
    super.key,
    required this.stepIndexZeroBased,
    required this.stepCount,
    required this.labelBold,
    required this.labelDetail,
  });

  @override
  Widget build(BuildContext context) {
    final frac =
        (stepIndexZeroBased + 1).clamp(1, stepCount) / stepCount.toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: V26.paper2),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: frac,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [V26.navy500, V26.navy600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: V26.ink500,
              ),
              children: [
                TextSpan(
                  text: labelBold,
                  style: const TextStyle(color: V26.ink900),
                ),
                TextSpan(text: ' · $labelDetail'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
