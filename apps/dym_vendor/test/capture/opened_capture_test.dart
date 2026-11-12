// Fakes repris des tests d'écran : certaines aides n'y servent pas.
// ignore_for_file: unused_element
@Tags(['golden'])
library;

import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/store/opened/store_opened_view.dart';
import 'package:dym_vendor/features/store/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/store_fixtures.dart';

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
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
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Brouillon arrêté à l'étape [step], étapes précédentes remplies.
MemoryStoreService _atStep(int step) {
  if (step == 1) return memoryStores();
  final full = openStore();
  return memoryStores(
    initial: MyStore(
      id: full.id,
      name: full.name,
      origin: step > 2 ? full.origin : null,
      zoneId: full.zoneId,
      mainCategoryId: step > 4 ? full.mainCategoryId : null,
      prepTimeMinutes: full.prepTimeMinutes,
      offersPickup: full.offersPickup,
      status: StoreStatus.draft,
      isOpen: false,
      onboardingStep: step,
      pickupAddress: step > 3 ? full.pickupAddress : null,
      deliveryZoneIds: step > 5 ? full.deliveryZoneIds : const [],
    ),
  );
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
  testWidgets('opened', (tester) async {
    await _capture(
      tester,
      'v_opened',
      StoreOpenedView(
        store: openStore(),
        config: togoConfig(),
        onSeeStore: () {},
        onAddProduct: () {},
      ),
    );
  });
}
