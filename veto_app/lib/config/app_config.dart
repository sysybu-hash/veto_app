// Tunnel / Render — אותה לוגיקה כמו ב־`frontend/lib/config/app_config.dart`.
// אחרי `npm run tunnel`: `--dart-define=VETO_HOST=...` אם ה-subdomain השתנה.

import 'package:flutter/foundation.dart';

class AppConfig {
  static const String kDefaultRenderHost = 'veto-app.onrender.com';
  static const String kDefaultRenderOrigin = 'https://veto-app.onrender.com';

  static const String kDefaultTunnelHost = 'sweet-turkey-60.loca.lt';
  static const int kLocalPort = 5001;

  static const String kTunnelBypassHeader = 'bypass-tunnel-reminder';
  static const String kTunnelBypassValue = 'true';

  static const Map<String, String> kTunnelBypassHeaders = {
    kTunnelBypassHeader: kTunnelBypassValue,
  };

  /// גרסת API (לתצוגה / הרחבות עתידיות)
  static const String apiVersion = 'v1';

  static const int requestTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  static String get _apiBaseFromEnv =>
      const String.fromEnvironment('VETO_API_BASE', defaultValue: '').trim();

  static String get _host =>
      const String.fromEnvironment('VETO_HOST', defaultValue: kDefaultTunnelHost);

  static String _stripTrailingSlashes(String s) {
    var out = s.trim();
    while (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  static String get _socketOrigin {
    final fromEnv = _apiBaseFromEnv;
    if (fromEnv.isNotEmpty) return _stripTrailingSlashes(fromEnv);
    if (kReleaseMode) return _stripTrailingSlashes(kDefaultRenderOrigin);
    if (_host.contains('loca.lt')) return 'https://$_host';
    return 'http://$_host:$kLocalPort';
  }

  static bool get _needsTunnelBypass {
    if (_apiBaseFromEnv.isNotEmpty) return false;
    if (kReleaseMode) return false;
    return _host.contains('loca.lt');
  }

  static String get baseUrl => '$_socketOrigin/api';

  static String get socketOrigin => _socketOrigin;

  static String get healthCheckUrl => '$socketOrigin/health';

  static Map<String, String> get httpGetHeaders {
    if (_needsTunnelBypass) return Map<String, String>.from(kTunnelBypassHeaders);
    return <String, String>{};
  }

  static Map<String, String> httpHeaders(Map<String, String> additional) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      ...additional,
    };
    if (_needsTunnelBypass) return {...kTunnelBypassHeaders, ...h};
    return h;
  }

  static Map<String, String> httpHeadersBinary(Map<String, String> additional) {
    final h = <String, String>{...additional};
    if (_needsTunnelBypass) return {...kTunnelBypassHeaders, ...h};
    return h;
  }
}
