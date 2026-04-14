// ============================================================
//  accessibility_toolbar.dart — (optional) FAB + bottom sheet
//  NOT mounted from main.dart — Web builds had full-screen barrier bugs when the FAB
//  lived in MaterialApp.builder beside the Navigator. Prefer a dedicated /accessibility
//  screen if you need this UI again. [AccessibilitySettings] still runs from main.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/accessibility/accessibility_settings.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';

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

// Explicit sheet colors — do not use VetoColors.white here (it is ink #1C1814).
const Color _sheetBg = Color(0xFFFFFFFF);
const Color _sheetInk = Color(0xFF1A1612);
const Color _sheetMuted = Color(0xFF5E5A52);

String _tx(String code, String k) =>
    (_copy[AppLanguage.normalize(code)] ?? _copy['en']!)[k] ?? k;

/// Optional host — currently unused (see file header).
class AccessibilityToolbarHost extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const AccessibilityToolbarHost({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  void _openSheet(BuildContext hostContext) {
    final navCtx = navigatorKey.currentContext;
    if (navCtx == null) return;

    final a11y = hostContext.read<AccessibilitySettings>();
    final code = hostContext.read<AppLanguageController>().code;

    showModalBottomSheet<void>(
      context: navCtx,
      isScrollControlled: true,
      useRootNavigator: false,
      isDismissible: true,
      enableDrag: true,
      barrierColor: const Color(0x66000000),
      showDragHandle: true,
      backgroundColor: _sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final viewInsets = MediaQuery.viewInsetsOf(sheetContext).bottom;
        final maxH = MediaQuery.sizeOf(sheetContext).height * 0.92;

        return SafeArea(
          minimum: const EdgeInsets.only(top: 8),
          child: Material(
            color: _sheetBg,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: ListenableBuilder(
                listenable: a11y,
                builder: (context, _) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + viewInsets),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _tx(code, 'title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _sheetInk,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tx(code, 'hint'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _sheetMuted,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _tx(code, 'text'),
                          style: const TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _sheetInk,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: a11y.textStep > 0
                                    ? () => a11y.setTextStep(a11y.textStep - 1)
                                    : null,
                                icon: Icon(Icons.text_decrease_rounded,
                                    color: VetoColors.accentDark),
                                label: Text(_tx(code, 'smaller'),
                                    style: const TextStyle(color: _sheetInk)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: a11y.textStep < 4
                                    ? () => a11y.setTextStep(a11y.textStep + 1)
                                    : null,
                                icon: Icon(Icons.text_increase_rounded,
                                    color: VetoColors.accentDark),
                                label: Text(_tx(code, 'larger'),
                                    style: const TextStyle(color: _sheetInk)),
                              ),
                            ),
                          ],
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${(a11y.textScale * 100).round()}%',
                              style: const TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: VetoColors.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: a11y.highContrast,
                          onChanged: (v) => a11y.setHighContrast(v),
                          title: Text(
                            _tx(code, 'highContrast'),
                            style: const TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _sheetInk,
                            ),
                          ),
                          secondary: const Icon(Icons.contrast,
                              color: VetoColors.accentDark),
                        ),
                        SwitchListTile(
                          value: a11y.boldBody,
                          onChanged: (v) => a11y.setBoldBody(v),
                          title: Text(
                            _tx(code, 'bold'),
                            style: const TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _sheetInk,
                            ),
                          ),
                          secondary: const Icon(Icons.format_bold,
                              color: VetoColors.accentDark),
                        ),
                        SwitchListTile(
                          value: a11y.reduceMotion,
                          onChanged: (v) => a11y.setReduceMotion(v),
                          title: Text(
                            _tx(code, 'reduceMotion'),
                            style: const TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _sheetInk,
                            ),
                          ),
                          secondary: const Icon(Icons.motion_photos_off_outlined,
                              color: VetoColors.accentDark),
                        ),
                        SwitchListTile(
                          value: a11y.underlineLinks,
                          onChanged: (v) => a11y.setUnderlineLinks(v),
                          title: Text(
                            _tx(code, 'underline'),
                            style: const TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _sheetInk,
                            ),
                          ),
                          secondary: const Icon(Icons.link,
                              color: VetoColors.accentDark),
                        ),
                        SwitchListTile(
                          value: a11y.strongerFocus,
                          onChanged: (v) => a11y.setStrongerFocus(v),
                          title: Text(
                            _tx(code, 'focus'),
                            style: const TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _sheetInk,
                            ),
                          ),
                          secondary: const Icon(
                              Icons.center_focus_strong_outlined,
                              color: VetoColors.accentDark),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await a11y.resetAll();
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          icon: Icon(Icons.restart_alt_rounded,
                              color: VetoColors.accentDark),
                          label: Text(_tx(code, 'reset'),
                              style: const TextStyle(color: _sheetInk)),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: VetoColors.accent,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_tx(code, 'close')),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        child,
        PositionedDirectional(
          bottom: 20 + pad.bottom,
          end: 16 + endPad,
          child: Tooltip(
            message: _tx(code, 'fab'),
            child: Semantics(
              button: true,
              label: _tx(code, 'fab'),
              child: Material(
                elevation: 16,
                shadowColor: Colors.black54,
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openSheet(context),
                  child: Ink(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1612),
                      border: Border.all(
                        color: const Color(0xFFC9A050),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: _AccessibilityFabGlyph(),
                    ),
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

/// Unicode ♿ — visible even when MaterialIcons web rendering fails.
class _AccessibilityFabGlyph extends StatelessWidget {
  const _AccessibilityFabGlyph();

  @override
  Widget build(BuildContext context) {
    return Text(
      String.fromCharCode(0x267F),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 28,
        height: 1.05,
        color: Colors.white,
        fontFamilyFallback: <String>[
          'Segoe UI Emoji',
          'Apple Color Emoji',
          'Noto Color Emoji',
        ],
      ),
    );
  }
}
