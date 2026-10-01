import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/shell/reference_screens.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_screen.dart';

/// Robustesse (spec 002, FR-011, SC-001) : 8 écrans × 7 tailles × 2 pays ×
/// 2 tailles de texte, sans débordement ni autre erreur de rendu.
void main() {
  for (final screen in referenceScreens) {
    group('${screen.id} · ${screen.title}', () {
      for (final MapEntry(key: name, value: size) in referenceSizes.entries) {
        for (final country in [DemoCountry.togo, DemoCountry.ghana]) {
          for (final textScale in [1.0, 1.3]) {
            testWidgets('$name · ${country.code} · texte ×$textScale', (
              tester,
            ) async {
              await pumpScreen(
                tester,
                screen,
                size: size,
                country: country,
                textScale: textScale,
              );
              expect(tester.takeException(), isNull);
            });
          }
        }
      }
    });
  }
}
