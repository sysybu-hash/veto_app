// ============================================================
//  v26_call_error_sheet.dart — Translates an Agora error into a
//  he/en/ru message and offers Retry / Exit actions.
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import '../../services/agora_service.dart';
import 'call_i18n.dart';

class V26CallErrorSheet extends StatelessWidget {
  const V26CallErrorSheet({
    super.key,
    required this.language,
    required this.error,
    required this.onRetry,
    required this.onExit,
  });

  final String language;
  final CallErrorEvent error;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  CallCopy _copyFor(CallErrorKind kind) {
    switch (kind) {
      case CallErrorKind.permissionDenied:
        return CallI18n.errorPermission;
      case CallErrorKind.tokenInvalid:
        return CallI18n.errorTokenInvalid;
      case CallErrorKind.tokenExpired:
        return CallI18n.errorTokenExpired;
      case CallErrorKind.networkLost:
      case CallErrorKind.connectionFailed:
        return CallI18n.errorNetwork;
      case CallErrorKind.mediaUnavailable:
        return CallI18n.errorMedia;
      case CallErrorKind.none:
      case CallErrorKind.unknown:
        return CallI18n.errorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(V26.rLg),
            border: Border.all(color: V26.emerg.withValues(alpha: 0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: V26.emerg.withValues(alpha: 0.2),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: V26.emerg.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFFB6BD),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                CallI18n.errorTitle.t(language),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: V26.serif,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _copyFor(error.kind).t(language),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFC7D3E5),
                  fontFamily: V26.sans,
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
              if (error.message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  error.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: V26.ink300,
                    fontFamily: V26.sans,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onExit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        CallI18n.errorExit.t(language),
                        style: const TextStyle(fontFamily: V26.sans),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: V26.emerg,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        CallI18n.errorRetry.t(language),
                        style: const TextStyle(fontFamily: V26.sans),
                      ),
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
