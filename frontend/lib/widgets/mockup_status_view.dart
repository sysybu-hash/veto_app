// ============================================================
//  mockup_status_view.dart — unified empty/loading/error states
//  Uses VetoMockup tokens to keep parity across all screens.
// ============================================================

import 'package:flutter/material.dart';

import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';

enum MockupStatusKind { loading, empty, error }

class MockupStatusView extends StatelessWidget {
  const MockupStatusView({
    super.key,
    required this.kind,
    this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final MockupStatusKind kind;
  final String? title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final defaultIcon = switch (kind) {
      MockupStatusKind.loading => Icons.hourglass_top_rounded,
      MockupStatusKind.empty => Icons.inbox_rounded,
      MockupStatusKind.error => Icons.error_outline_rounded,
    };
    final iconColor = switch (kind) {
      MockupStatusKind.loading => VetoMockup.primaryCta,
      MockupStatusKind.empty => VetoMockup.inkSecondary,
      MockupStatusKind.error => VetoMockup.emerg,
    };
    final defaultTitle = switch (kind) {
      MockupStatusKind.loading => 'טוען...',
      MockupStatusKind.empty => 'אין כאן עדיין שום דבר',
      MockupStatusKind.error => 'שגיאה',
    };
    final size = compact ? 56.0 : 84.0;
    final pad = compact
        ? const EdgeInsets.all(20)
        : const EdgeInsets.all(36);

    return Center(
      child: Padding(
        padding: pad,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kind == MockupStatusKind.loading)
              SizedBox(
                width: size * 0.75,
                height: size * 0.75,
                child: const CircularProgressIndicator(
                  color: VetoMockup.primaryCta,
                  strokeWidth: 3,
                ),
              )
            else
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.1),
                  border: Border.all(
                      color: iconColor.withValues(alpha: 0.25), width: 1),
                ),
                child: Icon(icon ?? defaultIcon,
                    size: size * 0.45, color: iconColor),
              ),
            const SizedBox(height: 14),
            Text(
              title ?? defaultTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: V26.serif,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: VetoMockup.ink,
              ),
            ),
            if ((message ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: VetoMockup.inkSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
            if (onAction != null && (actionLabel ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
