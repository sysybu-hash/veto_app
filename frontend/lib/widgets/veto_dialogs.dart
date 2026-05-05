// ============================================================
//  veto_dialogs.dart — unified dialogs / sheets (mockup style)
// ============================================================

import 'package:flutter/material.dart';

import '../core/theme/veto_mockup_tokens.dart';
import '../l10n/app_localizations.dart';

Future<T?> showVetoConfirmDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool danger = false,
}) {
  final loc = AppLocalizations.of(context)!;
  final confirm = confirmLabel ?? loc.commonOk;
  final cancel = cancelLabel ?? loc.vetoUiCancel;
  return showDialog<T>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoMockup.radiusCard)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancel)),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: VetoMockup.primaryCta)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
}

Future<void> showVetoBottomSheet({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.paddingOf(ctx).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}
