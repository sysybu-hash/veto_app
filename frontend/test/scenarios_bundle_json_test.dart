import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scenarios_bundle.json is well-formed and versioned', () {
    final path = '${Directory.current.path}${Platform.pathSeparator}'
        'assets${Platform.pathSeparator}l10n${Platform.pathSeparator}'
        'scenarios_bundle.json';
    final f = File(path);
    expect(f.existsSync(), isTrue, reason: 'Expected $path (run tests from frontend/)');
    final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    expect(m['version'], 1);
    expect(m['overrides'], isA<Map>());
  });
}
