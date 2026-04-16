import 'package:flutter_test/flutter_test.dart';
import 'package:veto/core/theme/veto_theme.dart';

void main() {
  test('luxuryLight: Hebrew on textTheme + global iconTheme (Material icons stay on default font)', () {
    final t = VetoTheme.luxuryLight();
    expect(t.textTheme.bodyLarge?.fontFamily, 'Heebo');
    expect(t.iconTheme.color, isNotNull);
    expect(t.iconTheme.size, 24);
  });
}
