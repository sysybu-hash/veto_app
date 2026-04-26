// ============================================================
//  SharedPrefs + secure storage + WebView platform fake for E2E-style tests
//  under flutter_tester (VM), where real plugins may hang.
// ============================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'support/fake_webview_platform.dart';

void initE2ePluginMocks() {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  WebViewPlatform.instance = E2eFakeWebViewPlatform();
}
