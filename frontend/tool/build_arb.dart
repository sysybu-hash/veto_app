// Run: dart run tool/build_arb.dart
import 'dart:io';

void main() {
  Directory('lib/l10n').createSync(recursive: true);
  throw UnimplementedError('Use manual ARB or install Python');
}
