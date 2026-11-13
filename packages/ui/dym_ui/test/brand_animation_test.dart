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
    testWidgets('splash : accroche et signature, sans débordement $size', (
      tester,
    ) async {
      await _pump(
        tester,
        const DymSplash(
          tagline: 'Le marché près de chez toi, livré chez toi',
          footer: DymMadeBy(prefix: 'Réalisé par', maker: 'Kete'),
        ),
        size: size,
      );
      expect(find.byType(LottieBuilder), findsOneWidget);
      expect(
        find.text('Le marché près de chez toi, livré chez toi'),
        findsOneWidget,
      );
      expect(find.textContaining('Kete', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('animations réduites : scène figée sur sa dernière image', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 360,
        height: 300,
        child: DymBrandSceneView(DymBrandScene.cart),
      ),
      reduce: true,
    );
    final lottie = tester.widget<Lottie>(find.byType(Lottie));
    expect(lottie.controller!.value, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  test('chaque scène a son fichier', () {
    expect(
      DymBrandScene.values.map((s) => s.file).toSet(),
      hasLength(DymBrandScene.values.length),
    );
  });
}
