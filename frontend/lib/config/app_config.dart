// —— Tunnel ————————————————————————————————————————————————
// אחרי `npm run tunnel`: קרא את הדף שמודפס בטרמינל — אם ה-host שונה מ-sweet-turkey-60.loca.lt,
// העתק את שורת flutter run --dart-define=VETO_HOST=... (localtunnel לא תמיד נותן את ה-subdomain המבוקש).
// `tunnel:any` → תמיד צריך --dart-define עם ה-host המודפס.
//
// localtunnel מציג דף אימות בדפדפן בלי כותרת; האפליקציה עוקפת ע"י kTunnelBypassHeaders בבקשות API.
// —————————————————————————————————————————————————————————————
//
// —— Production (Render) ——————————————————————————————————————
// ברירת מחדל ב-release: [kDefaultRenderOrigin] (אין צורך ב-define).
// לדריסה או ל-debug מול שרת אחר:
//   flutter run --dart-define=VETO_API_BASE=https://veto-app.onrender.com
// (ללא סיומת /api — רק origin). כשמוגדר, מתעלמים מ-VETO_HOST ל-REST/WebSocket.
// —————————————————————————————————————————————————————————————

import 'package:flutter/foundation.dart';

class AppConfig {
  /// Host קבוע ב-Render (לתיעוד / שימוש חיצוני; ה-origin המלא ב-[kDefaultRenderOrigin]).
  static const String kDefaultRenderHost = 'veto-app-new.onrender.com';

  /// Origin של ה-API בפרודקשן (Render). משמש כברירת מחדל ב-`kReleaseMode` כשאין `VETO_API_BASE`.
  static const String kDefaultRenderOrigin = 'https://veto-app-new.onrender.com';

  /// Host שמתאים ל-`npm run tunnel` (שורת ה-subdomain ב-backend/package.json)
  static const String kDefaultTunnelHost = 'sweet-turkey-60.loca.lt';
  static const int kLocalPort = 5001;

  /// כותרת חובה מול localtunnel לכל לקוח שאינו דפדפן עם הרחבה (ערך יכול להיות כל מחרוזת).
  static const String kTunnelBypassHeader = 'bypass-tunnel-reminder';
  static const String kTunnelBypassValue = 'true';

  /// מפה נפרדת ל-WebSocket / multipart (בלי Content-Type של JSON).
  static const Map<String, String> kTunnelBypassHeaders = {
    kTunnelBypassHeader: kTunnelBypassValue,
  };

  static String get _apiBaseFromEnv =>
      const String.fromEnvironment('VETO_API_BASE', defaultValue: '').trim();

  /// Set by CI: `--dart-define=VETO_BUILD_ID=<short-sha>` — shown in Settings to confirm a fresh deploy.
  static const String _buildIdRaw =
      String.fromEnvironment('VETO_BUILD_ID', defaultValue: '');

  /// Non-null after a CI/Vercel build that passed [VETO_BUILD_ID]; null in local `flutter run`.
  static String? get deployBuildLabel {
    final s = _buildIdRaw.trim();
    return s.isEmpty ? null : s;
  }

  static String get _host =>
      const String.fromEnvironment('VETO_HOST', defaultValue: kDefaultTunnelHost);

  static String _stripTrailingSlashes(String s) {
    var out = s.trim();
    while (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  /// מקור ל-HTTP (בלי `/api`). סדר עדיפות: `VETO_API_BASE` → ב-release Render → tunnel / LAN.
  static String get _socketOrigin {
    final fromEnv = _apiBaseFromEnv;
    if (fromEnv.isNotEmpty) return _stripTrailingSlashes(fromEnv);
    if (kReleaseMode) return _stripTrailingSlashes(kDefaultRenderOrigin);
    if (_host.contains('onrender.com')) return 'https://$_host';
    if (_host.contains('loca.lt')) return 'https://$_host';
    return 'http://$_host:$kLocalPort';
  }

  /// רק tunnel דורש את כותרת ה-bypass (לא Render / LAN).
  static bool get _needsTunnelBypass {
    if (_apiBaseFromEnv.isNotEmpty) return false;
    if (kReleaseMode) return false;
    return _host.contains('loca.lt');
  }

  /// בסיס לנתיבי REST תחת `/api/...` (השרת מגדיר ראוטים כמו `/api/auth/...`).
  static String get baseUrl => '$_socketOrigin/api';

  /// מקור ל-Socket.io (ללא `/api`).
  static String get socketOrigin => _socketOrigin;

  /// `GET /health` — לא תחת `/api`; משמש להשכמת אינסטנסים רדומים (למשל Render free).
  static String get healthCheckUrl => '$socketOrigin/health';

  /// כותרות ל-GET קל (בלי JSON).
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
