// Fakes repris des tests d'écran : certaines aides n'y servent pas.
// ignore_for_file: unused_element
@Tags(['golden'])
library;

import 'dart:typed_data';

import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/content/contents_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Octets vides pour un média de test.
final Uint8List _empty = Uint8List(0);

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
];

const _catalog = [
  Product(
    id: 'p1',
    name: 'Gombo frais',
    currencyCode: 'XOF',
    status: ProductStatus.published,
  ),
  Product(
    id: 'p2',
    name: 'Tomates fraîches',
    currencyCode: 'XOF',
    status: ProductStatus.published,
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(412, 915),
  Locale locale = const Locale('fr'),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: locale,
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name, Widget child) async {
  const size = Size(412, 915);
  tester.view
    ..physicalSize = size * 2
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: 2,
          disableAnimations: true,
          padding: EdgeInsets.only(top: 24, bottom: 16),
        ),
        child: child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 600));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  testWidgets('mine', (tester) async {
    final service = MemoryVendorContentService(catalog: _catalog);
    await service.publish(
      kind: ContentKind.video,
      media: (bytes: _empty, contentType: 'video/mp4', isVideo: true),
    );
    await _capture(
      tester,
      'v_mine',
      MyContentsView(service: service, onBack: () {}, onPublish: () async {}),
    );
  });
}
