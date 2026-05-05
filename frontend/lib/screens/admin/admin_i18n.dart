import 'package:flutter/widgets.dart';

import '../../core/i18n/app_language.dart';
import '../../l10n/app_localizations.dart';
import 'admin_l10n_lookups.dart';

/// Admin-facing strings (merged into ARB under `adm*`).
class AdminStrings {
  static String t(BuildContext context, String key) {
    final l = AppLocalizations.of(context);
    if (l == null) return key;
    return admT(l, key);
  }

  static String roleLabel(BuildContext context, String? role) {
    return role == 'admin' ? t(context, 'admin') : t(context, 'citizen');
  }

  static String languageLabel(BuildContext context, String? language) {
    final l = AppLocalizations.of(context);
    if (l == null) return '';
    switch (AppLanguage.normalize(language)) {
      case AppLanguage.english:
        return l.csetEnglish;
      case AppLanguage.russian:
        return l.csetRussian;
      default:
        return l.csetHebrew;
    }
  }

  /// Values accepted by `PUT /admin/emergency-logs/:id` (EmergencyEvent.status).
  static const List<String> emergencyEventStatuses = [
    'dispatching',
    'accepted',
    'in_progress',
    'completed',
    'cancelled',
    'failed',
    'documentation',
  ];

  static String eventStatus(BuildContext context, String? status) {
    final l = AppLocalizations.of(context);
    if (l == null) {
      if (status != null && status.isNotEmpty) return status;
      return '';
    }
    switch (status) {
      case 'dispatching':
        return l.admStatusDispatching;
      case 'accepted':
        return l.admStatusAccepted;
      case 'in_progress':
        return l.admStatusInProgress;
      case 'completed':
        return l.admStatusCompleted;
      case 'cancelled':
        return l.admStatusCancelled;
      case 'failed':
        return l.admStatusFailed;
      case 'documentation':
        return l.admStatusDocumentation;
      case 'active':
        return l.admActive;
      case 'resolved':
        return l.admResolved;
      case 'pending':
        return l.admPendingStatus;
      default:
        if (status != null && status.isNotEmpty) return status;
        return l.admUnknown;
    }
  }
}
