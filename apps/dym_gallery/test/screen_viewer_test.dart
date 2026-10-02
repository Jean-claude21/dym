import 'package:dym_gallery/shell/device_frame.dart';
import 'package:dym_gallery/shell/screen_viewer.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_screen.dart';

Future<void> _pumpViewer(WidgetTester tester, String id) async {
  tester.view
    ..physicalSize = const Size(1280, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(1280, 900),
          disableAnimations: true,
        ),
        child: ScreenViewer(screen: screenById(id)),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

FilterChip _compareChip(WidgetTester tester) =>
    tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Comparer'));

void main() {
  testWidgets('téléphone par défaut : « Comparer » disponible', (tester) async {
    await _pumpViewer(tester, '02');
    expect(_compareChip(tester).onSelected, isNotNull);
    expect(find.byType(DymBottomNav), findsOneWidget);
  });

  testWidgets('format Bureau : rendu 1 440 de large, « Comparer » indisponible '
      '(US4)', (tester) async {
    await _pumpViewer(tester, '02');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Bureau'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(DeviceFrame), findsOneWidget);
    expect(_compareChip(tester).onSelected, isNull);
    // L'écran voit une fenêtre de bureau : rail étendu.
    expect(tester.widget<DymNavRail>(find.byType(DymNavRail)).extended, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('format Tablette : rail compact', (tester) async {
    await _pumpViewer(tester, '02');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tablette'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      tester.widget<DymNavRail>(find.byType(DymNavRail)).extended,
      isFalse,
    );
  });
}
