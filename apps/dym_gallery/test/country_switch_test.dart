import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/screens/s05_cart.dart';
import 'package:dym_gallery/screens/s06_tracking.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view
    ..physicalSize = const Size(824, 1830)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(412, 915),
          disableAnimations: true,
        ),
        child: screen,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

Iterable<String> _texts(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');

void main() {
  testWidgets('Togo : montants en F CFA, sans décimale (US3)', (tester) async {
    await _pump(tester, CartScreen(country: DemoCountry.togo));
    final texts = _texts(tester).map((s) => s.replaceAll(RegExp('[  ]'), ' '));
    expect(texts, contains('Commander · 4 100 F CFA'));
  });

  testWidgets('Ghana : aucun « F CFA », cedis à 2 décimales (US3, SC-004)', (
    tester,
  ) async {
    await _pump(tester, CartScreen(country: DemoCountry.ghana));
    final texts = _texts(tester).toList();
    expect(texts.where((t) => t.contains('F CFA')), isEmpty);
    expect(texts.where((t) => t.contains('GH₵')), isNotEmpty);
    final total = DemoCartScreenData.total(DemoCountry.ghana).format();
    expect(total, matches(RegExp(r'GH₵\s?\d+\.\d{2}')));
  });

  testWidgets('total du panier = montant à payer au suivi (FR-017)', (
    tester,
  ) async {
    for (final country in [DemoCountry.togo, DemoCountry.ghana]) {
      final total = DemoCartScreenData.total(country).format();
      await _pump(tester, TrackingScreen(country: country));
      expect(_texts(tester), contains('$total en cash'));
      await _pump(tester, CartScreen(country: country));
      expect(_texts(tester), contains('Commander · $total'));
    }
  });
}
