import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../legal_document_screen.dart';
import '../../widgets/citizen_mockup_shell.dart';

class SecurityCenterScreen extends StatelessWidget {
  const SecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final he = code == 'he';
    return CitizenMockupShell(
      currentRoute: '/security_center',
      mobileNavIndex: citizenMobileNavIndexForRoute('/security_center'),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            he ? 'מרכז ביטחון' : 'Security center',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(he ? 'מדיניות פרטיות' : 'Privacy'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const LegalDocumentScreen(kind: LegalDocKind.privacy),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: Text(he ? 'תנאי שימוש' : 'Terms'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const LegalDocumentScreen(kind: LegalDocKind.terms),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(he ? 'הגדרות חשבון' : 'Account settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }
}
