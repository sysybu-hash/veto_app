import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_mockup_tokens.dart';
import '../../widgets/citizen_mockup_shell.dart';

class CitizenToolsScreen extends StatelessWidget {
  const CitizenToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final he = code == 'he';
    final ru = code == 'ru';
    String t(String a, String b, String c) => he ? a : (ru ? c : b);

    final tools = <({IconData i, String route, String la, String lb, String lc})>[
      (i: Icons.chat_bubble_outline, route: '/chat', la: 'צ\'אט AI', lb: 'AI Chat', lc: 'AI-чат'),
      (i: Icons.event_note, route: '/legal_calendar', la: 'יומן', lb: 'Calendar', lc: 'Календарь'),
      (i: Icons.edit_note, route: '/legal_notebook', la: 'מחברת', lb: 'Notebook', lc: 'Блокнот'),
      (i: Icons.map_outlined, route: '/maps', la: 'מפה', lb: 'Map', lc: 'Карта'),
      (i: Icons.folder_open, route: '/files_vault', la: 'כספת', lb: 'Vault', lc: 'Хранилище'),
      (i: Icons.security, route: '/security_center', la: 'מרכז ביטחון', lb: 'Security', lc: 'Безопасность'),
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
                onTap: () => Navigator.pushNamed(context, e.route),
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
                      Icon(e.i, size: 36, color: VetoMockup.primaryCta),
                      const SizedBox(height: 10),
                      Text(
                        t(e.la, e.lb, e.lc),
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
