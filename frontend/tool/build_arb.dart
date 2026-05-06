// Run: dart run tool/build_arb.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final out = Directory('lib/l10n');
  out.createSync(recursive: true);
  for (final loc in ['en', 'he', 'ru']) {
    final map = <String, String>{};
    // Minimal: invoke embedding via JSON asset - instead inline read from build_arb data
    // For maintainability, read merged JSON from repo if we add one file
    throw UnimplementedError('Use manual ARB or install Python');
  }
}
