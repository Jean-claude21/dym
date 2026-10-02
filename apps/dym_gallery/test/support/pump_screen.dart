import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/shell/reference_screens.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tailles de référence de la spec 002 (FR-013), en pixels logiques.
const referenceSizes = <String, Size>{
  'téléphone 360×640': Size(360, 640),
  'téléphone 412×915': Size(412, 915),
  'paysage 915×412': Size(915, 412),
  'paysage 640×360': Size(640, 360),
  'tablette 800×1280': Size(800, 1280),
  'tablette paysage 1280×800': Size(1280, 800),
  'bureau 1440×900': Size(1440, 900),
};

/// Monte un écran de la galerie à la taille logique [size], animations
/// désactivées (état final).
Future<void> pumpScreen(
  WidgetTester tester,
  ReferenceScreen screen, {
  required Size size,
  DemoCountry? country,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: screen.builder(country ?? DemoCountry.togo),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

/// Écran de référence par identifiant (« 05 »).
ReferenceScreen screenById(String id) =>
    referenceScreens.firstWhere((s) => s.id == id);
