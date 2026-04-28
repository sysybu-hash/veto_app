import 'dart:convert';

String? _json;

void callRouteArgsStorageWrite(Map<String, dynamic> args) {
  _json = jsonEncode({
    ...args,
    '_vetoSavedAt': DateTime.now().millisecondsSinceEpoch,
  });
}

Map<String, dynamic>? callRouteArgsStorageRead() {
  if (_json == null) return null;
  return _parseAndValidate(_json!);
}

void callRouteArgsStorageClear() {
  _json = null;
}

Map<String, dynamic>? _parseAndValidate(String raw) {
  try {
    final o = jsonDecode(raw);
    if (o is! Map) return null;
    final m = Map<String, dynamic>.from(
      o.map((k, v) => MapEntry(k.toString(), v)),
    );
    final t = m['_vetoSavedAt'];
    m.remove('_vetoSavedAt');
    if (t is num) {
      final age = DateTime.now().millisecondsSinceEpoch - t.toInt();
      if (age > const Duration(hours: 3).inMilliseconds) {
        return null;
      }
    }
    return m;
  } catch (_) {
    return null;
  }
}
