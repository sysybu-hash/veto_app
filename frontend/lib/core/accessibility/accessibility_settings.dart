// ============================================================
//  accessibility_settings.dart — Global a11y prefs + theme merge
//  Persisted with shared_preferences (key: veto_accessibility_v1).
// ============================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilitySettings extends ChangeNotifier {
  AccessibilitySettings();

  static const _prefsKey = 'veto_accessibility_v1';

  /// Discrete step 0–4 → effective text scale ~0.9–1.35
  int _textStep = 2;
  bool _highContrast = false;
  bool _boldBody = false;
  bool _reduceMotion = false;
  bool _underlineLinks = false;
  bool _strongerFocus = false;

  int get textStep => _textStep;
  bool get highContrast => _highContrast;
  bool get boldBody => _boldBody;
  bool get reduceMotion => _reduceMotion;
  bool get underlineLinks => _underlineLinks;
  bool get strongerFocus => _strongerFocus;

  double get textScale {
    const steps = <double>[0.88, 0.94, 1.0, 1.12, 1.28];
    return steps[_textStep.clamp(0, steps.length - 1)];
  }

  Future<void> hydrate() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      _textStep = (m['textStep'] as num?)?.toInt() ?? 2;
      _highContrast = m['highContrast'] as bool? ?? false;
      _boldBody = m['boldBody'] as bool? ?? false;
      _reduceMotion = m['reduceMotion'] as bool? ?? false;
      _underlineLinks = m['underlineLinks'] as bool? ?? false;
      _strongerFocus = m['strongerFocus'] as bool? ?? false;
      _textStep = _textStep.clamp(0, 4);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _prefsKey,
        jsonEncode({
          'textStep': _textStep,
          'highContrast': _highContrast,
          'boldBody': _boldBody,
          'reduceMotion': _reduceMotion,
          'underlineLinks': _underlineLinks,
          'strongerFocus': _strongerFocus,
        }),
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setTextStep(int step) async {
    _textStep = step.clamp(0, 4);
    await _persist();
  }

  Future<void> setHighContrast(bool v) async {
    _highContrast = v;
    await _persist();
  }

  Future<void> setBoldBody(bool v) async {
    _boldBody = v;
    await _persist();
  }

  Future<void> setReduceMotion(bool v) async {
    _reduceMotion = v;
    await _persist();
  }

  Future<void> setUnderlineLinks(bool v) async {
    _underlineLinks = v;
    await _persist();
  }

  Future<void> setStrongerFocus(bool v) async {
    _strongerFocus = v;
    await _persist();
  }

  Future<void> resetAll() async {
    _textStep = 2;
    _highContrast = false;
    _boldBody = false;
    _reduceMotion = false;
    _underlineLinks = false;
    _strongerFocus = false;
    await _persist();
  }

  /// Merge accessibility choices into the app theme.
  ThemeData mergeTheme(ThemeData base) {
    var t = base;

    if (_highContrast) {
      t = t.copyWith(
        colorScheme: const ColorScheme.highContrastLight(),
        scaffoldBackgroundColor: Colors.white,
      );
    }

    if (_strongerFocus) {
      t = t.copyWith(
        focusColor: _highContrast ? Colors.black : const Color(0xFFB8941E),
        highlightColor: Colors.black12,
      );
    }

    if (_underlineLinks) {
      final linkStyle = TextButton.styleFrom(
        foregroundColor: _highContrast ? Colors.blue.shade900 : const Color(0xFF0D47A1),
        textStyle: const TextStyle(
          decoration: TextDecoration.underline,
          decorationThickness: 2,
          fontWeight: FontWeight.w600,
        ),
      );
      t = t.copyWith(
        textButtonTheme: TextButtonThemeData(style: linkStyle),
      );
    }

    return t;
  }
}
