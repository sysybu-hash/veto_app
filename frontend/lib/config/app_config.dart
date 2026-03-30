// —— Tunnel ————————————————————————————————————————————————
// אחרי `npm run tunnel`: קרא את הדף שמודפס בטרמינל — אם ה-host שונה מ-sweet-turkey-60.loca.lt,
// העתק את שורת flutter run --dart-define=VETO_HOST=... (localtunnel לא תמיד נותן את ה-subdomain המבוקש).
// `tunnel:any` → תמיד צריך --dart-define עם ה-host המודפס.
//
// localtunnel מציג דף אימות בדפדפן בלי כותרת; האפליקציה עוקפת ע"י kTunnelBypassHeaders בבקשות API.
// —————————————————————————————————————————————————————————————
//
// —— Production (לינק קבוע, למשל Render) ——————————————————————
//   flutter run --dart-define=VETO_API_BASE=https://veto-api.onrender.com
// (ללא סיומת /api — רק origin). כשמוגדר, מתעלמים מ-VETO_HOST ל-REST/WebSocket.
// —————————————————————————————————————————————————————————————

class AppConfig {
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

  static String get _host =>
      const String.fromEnvironment('VETO_HOST', defaultValue: kDefaultTunnelHost);

  static String _stripTrailingSlashes(String s) {
    var out = s.trim();
    while (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  /// רק tunnel דורש את כותרת ה-bypass (לא Render / LAN).
  static bool get _needsTunnelBypass {
    if (_apiBaseFromEnv.isNotEmpty) return false;
    return _host.contains('loca.lt');
  }

  static String get baseUrl {
    final base = _apiBaseFromEnv;
    if (base.isNotEmpty) return '${_stripTrailingSlashes(base)}/api';
    if (_host.contains('loca.lt')) return 'https://$_host/api';
    return 'http://$_host:$kLocalPort/api';
  }

  static String get socketOrigin {
    final base = _apiBaseFromEnv;
    if (base.isNotEmpty) return _stripTrailingSlashes(base);
    if (_host.contains('loca.lt')) return 'https://$_host';
    return 'http://$_host:$kLocalPort';
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
