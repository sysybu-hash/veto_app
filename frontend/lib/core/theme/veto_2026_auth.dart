// Auth wizard chrome — aligned with `2026/login.html` (`.auth-side`, `.feature-line`, `.quote`).
import 'package:flutter/material.dart';

import 'veto_2026.dart';

/// Navy gradient column with gold radial glow (desktop marketing panel).
class V26AuthNavyPanel extends StatelessWidget {
  final Widget child;
  const V26AuthNavyPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: V26.navy800,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [V26.navy700, V26.navy600],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 420,
                height: 520,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      V26.gold.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 48, 48, 40),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Crest + wordmark; optional [tagline] sits beside **VETO** like `<em>` in the HTML mock.
class V26AuthBrandRow extends StatelessWidget {
  final String tagline;
  const V26AuthBrandRow({super.key, required this.tagline});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'V',
            style: TextStyle(
              fontFamily: V26.serif,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'VETO',
                style: TextStyle(
                  fontFamily: V26.serif,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                tagline,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFFB6D2FB),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class V26AuthFeatureLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const V26AuthFeatureLine({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: const Color(0xFFB6D2FB)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  fontFamily: V26.sans,
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class V26AuthQuote extends StatelessWidget {
  final String quote;
  final String initials;
  final String name;
  final String role;
  const V26AuthQuote({
    super.key,
    required this.quote,
    required this.initials,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(top: 32),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quote,
                style: const TextStyle(
                  fontFamily: V26.serif,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFC7D5EE)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontFamily: V26.serif,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: V26.navy700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: V26.sans,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          role,
                          style: const TextStyle(
                            fontFamily: V26.sans,
                            fontSize: 11,
                            color: Color(0xFFB6D2FB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
