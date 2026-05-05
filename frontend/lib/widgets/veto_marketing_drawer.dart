// ============================================================
//  Light marketing drawer (Pango-class) — RTL endDrawer
// ============================================================

import 'package:flutter/material.dart';

import '../core/theme/veto_mockup_tokens.dart';
import '../l10n/app_localizations.dart';

class VetoMarketingDrawer extends StatelessWidget {
  const VetoMarketingDrawer({super.key, required this.l10n, this.onItemTap});

  final AppLocalizations l10n;
  final VoidCallback? onItemTap;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final w = (mq.width * 0.36).clamp(300.0, 420.0);

    return Material(
      color: VetoMockup.drawerTint,
      child: SafeArea(
        child: SizedBox(
          width: w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: VetoMockup.ink),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: l10n.menuSearchPlaceholder,
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: VetoMockup.hairline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: VetoMockup.hairline),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _DrawerTile(title: l10n.menuSmartServices, onTap: onItemTap),
                    _DrawerTile(title: l10n.menuBenefits, onTap: onItemTap),
                    _DrawerTile(title: l10n.menuPlans, onTap: onItemTap),
                    _DrawerTile(title: l10n.menuCare, onTap: onItemTap),
                    _DrawerTile(title: l10n.menuContact, onTap: onItemTap),
                    _DrawerTile(title: l10n.menuBusiness, onTap: onItemTap),
                    _DrawerTile(title: l10n.menuTerms, onTap: onItemTap),
                    _DrawerTile(title: l10n.menuSafeUse, onTap: onItemTap),
                    _DrawerTile(title: l10n.menuAbout, onTap: onItemTap),
                    _DrawerTile(title: l10n.menuCareers, onTap: onItemTap),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({required this.title, this.onTap});
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.add_rounded, size: 18, color: VetoMockup.inkSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: VetoMockup.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
