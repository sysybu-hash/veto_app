// ============================================================
//  accessibility_toolbar.dart — Global accessibility toolbar
//  FAB opens a bottom sheet with text size, contrast, motion, etc.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/accessibility/accessibility_settings.dart';
import '../core/i18n/app_language.dart';

const _copy = {
  'he': {
    'fab': 'נגישות',
    'title': 'סרגל נגישות',
    'hint': 'ההגדרות נשמרות במכשיר וחלות על כל המסכים.',
    'text': 'גודל טקסט',
    'smaller': 'קטן יותר',
    'larger': 'גדול יותר',
    'highContrast': 'ניגודיות גבוהה',
    'bold': 'טקסט מודגש',
    'reduceMotion': 'צמצום אנימציות',
    'underline': 'קו תחתון לקישורים',
    'focus': 'הדגשת מיקוד חזקה',
    'reset': 'איפוס הכל',
    'close': 'סגור',
  },
  'en': {
    'fab': 'Accessibility',
    'title': 'Accessibility toolbar',
    'hint': 'Preferences are saved on this device and apply to every screen.',
    'text': 'Text size',
    'smaller': 'Smaller',
    'larger': 'Larger',
    'highContrast': 'High contrast',
    'bold': 'Bold text',
    'reduceMotion': 'Reduce motion',
    'underline': 'Underline links',
    'focus': 'Stronger focus highlight',
    'reset': 'Reset all',
    'close': 'Close',
  },
  'ru': {
    'fab': 'Доступность',
    'title': 'Панель доступности',
    'hint': 'Настройки сохраняются на устройстве и действуют на всех экранах.',
    'text': 'Размер текста',
    'smaller': 'Меньше',
    'larger': 'Больше',
    'highContrast': 'Высокий контраст',
    'bold': 'Жирный текст',
    'reduceMotion': 'Меньше анимации',
    'underline': 'Подчёркивать ссылки',
    'focus': 'Яркое выделение фокуса',
    'reset': 'Сбросить всё',
    'close': 'Закрыть',
  },
};

String _tx(String code, String k) =>
    (_copy[AppLanguage.normalize(code)] ?? _copy['en']!)[k] ?? k;

/// Wraps the navigator subtree; shows a persistent accessibility FAB.
class AccessibilityToolbarHost extends StatelessWidget {
  final Widget child;

  const AccessibilityToolbarHost({super.key, required this.child});

  void _openSheet(BuildContext context) {
    final code = context.read<AppLanguageController>().code;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Consumer<AccessibilitySettings>(
              builder: (context, a11y, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _tx(code, 'title'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tx(code, 'hint'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _tx(code, 'text'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: a11y.textStep > 0
                                ? () => a11y.setTextStep(a11y.textStep - 1)
                                : null,
                            icon: const Icon(Icons.text_decrease_rounded),
                            label: Text(_tx(code, 'smaller')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: a11y.textStep < 4
                                ? () => a11y.setTextStep(a11y.textStep + 1)
                                : null,
                            icon: const Icon(Icons.text_increase_rounded),
                            label: Text(_tx(code, 'larger')),
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${(a11y.textScale * 100).round()}%',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      value: a11y.highContrast,
                      onChanged: (v) => a11y.setHighContrast(v),
                      title: Text(_tx(code, 'highContrast')),
                      secondary: const Icon(Icons.contrast),
                    ),
                    SwitchListTile.adaptive(
                      value: a11y.boldBody,
                      onChanged: (v) => a11y.setBoldBody(v),
                      title: Text(_tx(code, 'bold')),
                      secondary: const Icon(Icons.format_bold),
                    ),
                    SwitchListTile.adaptive(
                      value: a11y.reduceMotion,
                      onChanged: (v) => a11y.setReduceMotion(v),
                      title: Text(_tx(code, 'reduceMotion')),
                      secondary: const Icon(Icons.motion_photos_off_outlined),
                    ),
                    SwitchListTile.adaptive(
                      value: a11y.underlineLinks,
                      onChanged: (v) => a11y.setUnderlineLinks(v),
                      title: Text(_tx(code, 'underline')),
                      secondary: const Icon(Icons.link),
                    ),
                    SwitchListTile.adaptive(
                      value: a11y.strongerFocus,
                      onChanged: (v) => a11y.setStrongerFocus(v),
                      title: Text(_tx(code, 'focus')),
                      secondary: const Icon(Icons.center_focus_strong_outlined),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await a11y.resetAll();
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(_tx(code, 'reset')),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_tx(code, 'close')),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final pad = MediaQuery.paddingOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final endPad = isRtl ? pad.left : pad.right;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        PositionedDirectional(
          bottom: 20 + pad.bottom,
          end: 16 + endPad,
          child: Semantics(
            button: true,
            label: _tx(code, 'fab'),
            child: Material(
              elevation: 6,
              shadowColor: Colors.black45,
              shape: const CircleBorder(),
              color: Theme.of(context).colorScheme.primary,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _openSheet(context),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    Icons.accessibility_new_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
