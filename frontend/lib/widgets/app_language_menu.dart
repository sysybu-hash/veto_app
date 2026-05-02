import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_tokens_2026.dart';

class AppLanguageMenu extends StatelessWidget {
  final bool compact;

  /// Runs after [AppLanguageController.setLanguage] completes (e.g. reset chat on Veto).
  final ValueChanged<String>? onLanguageChanged;
  final String? tooltip;

  const AppLanguageMenu({
    super.key,
    this.compact = false,
    this.onLanguageChanged,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppLanguageController>();
    final code = controller.code;

    return PopupMenuButton<String>(
      tooltip: tooltip ?? 'Language',
      initialValue: code,
      color: VetoTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: VetoTokens.hairline),
      ),
      onSelected: (value) async {
        await context.read<AppLanguageController>().setLanguage(value);
        onLanguageChanged?.call(value);
      },
      itemBuilder: (context) {
        return AppLanguage.supportedCodes.map((languageCode) {
          final selected = languageCode == code;
          return PopupMenuItem<String>(
            value: languageCode,
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: selected ? VetoTokens.navy600 : VetoTokens.ink300,
                ),
                const SizedBox(width: 10),
                Text(
                  AppLanguage.labels[languageCode] ?? languageCode,
                  style: TextStyle(
                    color: selected ? VetoTokens.ink900 : VetoTokens.ink500,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: VetoTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VetoTokens.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded,
                size: 16, color: VetoTokens.navy600),
            const SizedBox(width: 8),
            Text(
              AppLanguage.labels[code] ?? code,
              style: TextStyle(
                color: compact ? VetoTokens.ink500 : VetoTokens.ink900,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
