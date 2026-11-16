import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(412, 915),
  bool reduce = false,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: reduce),
        child: Scaffold(body: child),
      ),
    ),
  );
  // Laisse Lottie lire et décoder le JSON (entrées-sorties réelles).
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  for (final size in const [Size(360, 640), Size(412, 915), Size(915, 412)]) {
    testWidgets('splash : accroche, sans débordement $size', (tester) async {
      await _pump(
        tester,
        const DymSplash(tagline: 'Le marché près de chez toi, livré chez toi'),
        size: size,
      );
      expect(find.byType(Lottie), findsOneWidget);
      expect(
        find.text('Le marché près de chez toi, livré chez toi'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final tone in DymSplashTone.values) {
    testWidgets('splash aux couleurs de l’app : ${tone.name}', (tester) async {
      await _pump(tester, DymSplash(tagline: 'DYM', tone: tone));
      expect(find.byType(Lottie), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('animations réduites : entrée du splash signalée aussitôt', (
    tester,
  ) async {
    var done = false;
    await _pump(
      tester,
      DymSplash(tagline: 'DYM', onIntroComplete: () => done = true),
      reduce: true,
    );
    expect(done, isTrue);
  });
}
