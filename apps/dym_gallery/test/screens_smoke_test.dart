import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/shell/reference_screens.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Robustesse (spec, cas limites) : chaque écran s'affiche sans débordement
/// sur un petit téléphone 360 × 640, texte agrandi à 130 %, dans les deux pays.
void main() {
  for (final country in [DemoCountry.togo, DemoCountry.ghana]) {
    for (final screen in referenceScreens) {
      testWidgets(
        '${screen.id} · ${screen.title} · ${country.code} · 360×640',
        (tester) async {
          tester.view
            ..physicalSize = const Size(720, 1280)
            ..devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              theme: DymTheme.light(),
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(360, 640),
                  devicePixelRatio: 2,
                  disableAnimations: true,
                  textScaler: TextScaler.linear(1.3),
                ),
                child: screen.builder(country),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
