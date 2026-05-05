// Generates lib/l10n/app_*.arb from tool/arb_fragments/*.json
// Run from frontend/: dart run tool/write_arb.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current;
  final frag = Directory('${root.path}/tool/arb_fragments');
  for (final loc in ['en', 'he', 'ru']) {
    final merged = <String, String>{};
    for (final part in ['landing', 'pango', 'cset', 'lset']) {
      final f = File('${frag.path}/${loc}_$part.json');
      final map = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final e in map.entries) {
        merged[e.key] = e.value.toString();
      }
    }
    final out = <String, dynamic>{'@@locale': loc, ...merged};
    final sink = StringBuffer();
    const enc = JsonEncoder.withIndent('  ');
    sink.writeln(enc.convert(out));
    File('${root.path}/lib/l10n/app_$loc.arb').writeAsStringSync(sink.toString());
  }
  // ignore: avoid_print
  print('Wrote app_en.arb, app_he.arb, app_ru.arb');
}
