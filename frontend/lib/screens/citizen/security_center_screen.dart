import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../l10n/app_localizations.dart';
import '../legal_document_screen.dart';
import '../../widgets/citizen_mockup_shell.dart';

class SecurityCenterScreen extends StatelessWidget {
  const SecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<AppLanguageController>();
    final l10n = AppLocalizations.of(context)!;
    return CitizenMockupShell(
      currentRoute: '/security_center',
      mobileNavIndex: citizenMobileNavIndexForRoute('/security_center'),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.citizenSecurityTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.citizenSecurityPrivacy),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    const LegalDocumentScreen(kind: LegalDocKind.privacy),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: Text(l10n.citizenSecurityTerms),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const LegalDocumentScreen(kind: LegalDocKind.terms),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.citizenSecurityAccount),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }
}
