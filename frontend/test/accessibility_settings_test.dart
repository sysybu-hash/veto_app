import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veto/core/accessibility/accessibility_settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AccessibilitySettings', () {
    test('initializes with default values', () {
      final a11y = AccessibilitySettings();
      expect(a11y.textStep, 0);
      expect(a11y.highContrast, false);
      expect(a11y.boldBody, false);
      expect(a11y.reduceMotion, false);
      expect(a11y.underlineLinks, false);
      expect(a11y.strongerFocus, false);
    });

    test('can toggle high contrast', () async {
      final a11y = AccessibilitySettings();
      await a11y.setHighContrast(true);
      expect(a11y.highContrast, true);
    });

    test('can increase text step', () async {
      final a11y = AccessibilitySettings();
      await a11y.setTextStep(2);
      expect(a11y.textStep, 2);
    });

    test('resetAll restores default values', () async {
      final a11y = AccessibilitySettings();
      await a11y.setHighContrast(true);
      await a11y.setTextStep(3);
      await a11y.setBoldBody(true);
      
      await a11y.resetAll();
      
      expect(a11y.textStep, 0);
      expect(a11y.highContrast, false);
      expect(a11y.boldBody, false);
    });
  });
}
