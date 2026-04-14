// ============================================================
//  webrtc_settings_store.dart — Persist WebRTC prefs locally
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

import 'webrtc_user_settings.dart';

class WebRtcSettingsStore {
  WebRtcSettingsStore._();
  static final WebRtcSettingsStore instance = WebRtcSettingsStore._();

  static const _key = 'veto_webrtc_user_settings_v1';

  Future<WebRtcUserSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return WebRtcUserSettings.decode(p.getString(_key));
  }

  Future<void> save(WebRtcUserSettings settings) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, WebRtcUserSettings.encode(settings));
  }
}
