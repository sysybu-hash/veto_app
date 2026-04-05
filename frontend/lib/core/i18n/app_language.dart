import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../services/auth_service.dart';

class AppLanguage {
  static const String hebrew = 'he';
  static const String english = 'en';
  static const String russian = 'ru';

  static const List<String> supportedCodes = [hebrew, english, russian];

  static const Map<String, String> labels = {
    hebrew: 'עברית',
    english: 'English',
    russian: 'Русский',
  };

  static String normalize(String? code) {
    if (supportedCodes.contains(code)) {
      return code!;
    }
    return hebrew;
  }

  static Locale localeOf(String code) => Locale(normalize(code));

  static TextDirection directionOf(String code) {
    return normalize(code) == hebrew
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  static bool isRtl(String code) => normalize(code) == hebrew;
}

class AppLanguageController extends ChangeNotifier {
  String _code = AppLanguage.hebrew;

  String get code => _code;
  Locale get locale => AppLanguage.localeOf(_code);
  bool get isRtl => AppLanguage.isRtl(_code);

  Future<void> load() async {
    _code = AppLanguage.normalize(
      await AuthService().getStoredPreferredLanguage(),
    );
    notifyListeners();
  }

  Future<void> setLanguage(String code, {bool persist = true}) async {
    final normalized = AppLanguage.normalize(code);
    if (_code == normalized) {
      return;
    }
    _code = normalized;
    notifyListeners();
    if (persist) {
      await AuthService().setStoredPreferredLanguage(normalized);
    }
  }
}