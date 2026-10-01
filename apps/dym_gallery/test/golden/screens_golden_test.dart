@Tags(['golden'])
library;

import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/shell/reference_screens.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures 412 × 915 (×2) des 8 écrans reproduits, à comparer aux écrans
/// validés de docs/design/screens. Animations désactivées : état final.
void main() {
  for (final screen in referenceScreens) {
    testWidgets('écran ${screen.id} · ${screen.title}', (tester) async {
      tester.view
        ..physicalSize = const Size(824, 1830)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: DymTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              devicePixelRatio: 2,
              disableAnimations: true,
              padding: EdgeInsets.only(top: 24),
            ),
            child: screen.builder(DemoCountry.togo),
          ),
        ),
      );
      await _precacheImages(tester);
      await tester.pump(const Duration(milliseconds: 600));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${screen.id}.png'),
      );
    });
  }
}

/// Décode toutes les images de l'arbre avant la capture.
Future<void> _precacheImages(WidgetTester tester) async {
  final providers = <ImageProvider>{
    for (final e in find.byType(Image).evaluate()) (e.widget as Image).image,
    for (final e in find.byType(Container).evaluate())
      if ((e.widget as Container).decoration case BoxDecoration(
        image: DecorationImage(:final image),
      ))
        image,
  };
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    for (final p in providers) {
      await precacheImage(p, context);
    }
  });
  await tester.pump();
}
