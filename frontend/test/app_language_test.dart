import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veto/core/i18n/app_language.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLanguageController', () {
    test('initializes with Hebrew by default', () {
      final controller = AppLanguageController();
      expect(controller.code, 'he');
      expect(controller.locale.languageCode, 'he');
    });

    test('can set language to English', () async {
      final controller = AppLanguageController();
      await controller.setLanguage('en');
      expect(controller.code, 'en');
      expect(controller.locale.languageCode, 'en');
    });

    test('can set language to Russian', () async {
      final controller = AppLanguageController();
      await controller.setLanguage('ru');
      expect(controller.code, 'ru');
      expect(controller.locale.languageCode, 'ru');
    });

    test('normalizes unsupported languages to English', () {
      expect(AppLanguage.normalize('fr'), 'en');
      expect(AppLanguage.normalize('es'), 'en');
      expect(AppLanguage.normalize('he'), 'he');
      expect(AppLanguage.normalize('ru'), 'ru');
    });

    test('returns correct text direction', () {
      expect(AppLanguage.directionOf('he'), equals(TextDirection.rtl));
      expect(AppLanguage.directionOf('en'), equals(TextDirection.ltr));
      expect(AppLanguage.directionOf('ru'), equals(TextDirection.ltr));
    });
  });
}
