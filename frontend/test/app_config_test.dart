import 'package:flutter_test/flutter_test.dart';
import 'package:veto/config/app_config.dart';

void main() {
  test('baseUrl is a single /api suffix (no /api/api)', () {
    final u = AppConfig.baseUrl;
    expect(u.endsWith('/api'), isTrue);
    expect(u.contains('/api/api'), isFalse);
  });

  test('httpHeaders merges JSON Content-Type and preserves extra keys', () {
    final h = AppConfig.httpHeaders({'Authorization': 'Bearer x'});
    expect(h['Content-Type'], 'application/json');
    expect(h['Authorization'], 'Bearer x');
  });

  test('httpHeadersBinary does not force JSON Content-Type', () {
    final h = AppConfig.httpHeadersBinary({'Content-Type': 'multipart/form-data'});
    expect(h['Content-Type'], 'multipart/form-data');
  });
}
