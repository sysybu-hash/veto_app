import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_mockup_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/citizen_mockup_shell.dart';

class CitizenToolsScreen extends StatelessWidget {
  const CitizenToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<AppLanguageController>();
    final l10n = AppLocalizations.of(context)!;

    final tools = <(IconData, String route, String Function(AppLocalizations l))>[
      (Icons.chat_bubble_outline, '/chat', (l) => l.citizenShellMoreAiChat),
      (Icons.event_note, '/legal_calendar', (l) => l.citizenShellMoreCalendar),
      (Icons.edit_note, '/legal_notebook', (l) => l.citizenShellMoreNotebook),
      (Icons.map_outlined, '/maps', (l) => l.citizenShellMoreMap),
      (Icons.folder_open, '/files_vault', (l) => l.citizenToolVault),
      (Icons.security, '/security_center', (l) => l.citizenSecurityTitle),
    ];

    return CitizenMockupShell(
      currentRoute: '/citizen_tools',
      mobileNavIndex: citizenMobileNavIndexForRoute('/citizen_tools'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.1,
          ),
          itemCount: tools.length,
          itemBuilder: (_, i) {
            final e = tools[i];
            return Material(
              color: VetoMockup.surfaceCard,
              borderRadius: BorderRadius.circular(VetoMockup.radiusCard),
              child: InkWell(
                borderRadius: BorderRadius.circular(VetoMockup.radiusCard),
                onTap: () => Navigator.pushNamed(context, e.$2),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(VetoMockup.radiusCard),
                    border: Border.all(color: VetoMockup.hairline),
                    boxShadow: VetoMockup.cardShadow,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(e.$1, size: 36, color: VetoMockup.primaryCta),
                      const SizedBox(height: 10),
                      Text(
                        e.$3(l10n),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
