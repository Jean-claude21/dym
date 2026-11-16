@Tags(['golden'])
library;

import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Splash aux couleurs de chaque app (spec 093) : cliente, vendeuse, livreur.
void main() {
  for (final tone in DymSplashTone.values) {
    testWidgets('splash ${tone.name}', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844) * 2
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: DymTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: DymSplash(tagline: 'Le marché près de chez toi', tone: tone),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/splash_${tone.name}.png'),
      );
    });
  }
}
