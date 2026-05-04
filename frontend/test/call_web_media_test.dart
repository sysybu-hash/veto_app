import 'package:flutter_test/flutter_test.dart';

import 'package:veto/features/call/call_web_media.dart';

void main() {
  test('isCallMediaSecureContext is true off-web (VM tests)', () {
    expect(isCallMediaSecureContext(), isTrue);
  });
}
