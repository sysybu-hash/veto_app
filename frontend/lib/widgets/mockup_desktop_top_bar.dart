// ============================================================
//  mockup_desktop_top_bar.dart — shared search + trailing + profile
//  (citizen shell, lawyer desktop, etc.)
// ============================================================

import 'package:flutter/material.dart';

import '../core/theme/veto_mockup_tokens.dart';
import '../services/auth_service.dart';

class MockupDesktopTopBar extends StatelessWidget {
  const MockupDesktopTopBar({
    super.key,
    required this.searchController,
    required this.langCode,
    this.trailing,
    required this.onProfile,
    required this.onNotifications,
  });

  final TextEditingController searchController;
  final String langCode;
  final List<Widget>? trailing;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final he = langCode == 'he';
    final ru = langCode == 'ru';
    final hint = he
        ? 'חיפוש תיקים, חוזים, אנשי קשר...'
        : (ru ? 'Поиск...' : 'Search cases, contracts...');
    return Material(
      color: VetoMockup.surfaceCard,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: VetoMockup.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: VetoMockup.inkSecondary),
                  filled: true,
                  fillColor: VetoMockup.pageBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          he ? 'חיפוש יתווסף בהמשך' : 'Search coming soon')),
                ),
              ),
            ),
            if (trailing != null && trailing!.isNotEmpty) ...[
              const SizedBox(width: 12),
              ...trailing!,
            ],
            const SizedBox(width: 16),
            IconButton(
              onPressed: onNotifications,
              icon: Badge(
                isLabelVisible: false,
                child: Icon(Icons.notifications_none_rounded,
                    color: VetoMockup.ink.withValues(alpha: 0.85)),
              ),
            ),
            FutureBuilder<String?>(
              future: AuthService().getStoredUserId(),
              builder: (_, __) {
                return IconButton(
                  onPressed: onProfile,
                  icon: CircleAvatar(
                    backgroundColor:
                        VetoMockup.primaryCta.withValues(alpha: 0.15),
                    child: const Icon(Icons.person_rounded,
                        color: VetoMockup.primaryCtaDeep),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
