import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/store/my_store/my_store_view.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_view.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_viewmodel.dart';
import 'package:dym_vendor/features/store/opened/store_opened_view.dart';
import 'package:dym_vendor/features/store/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/store_fixtures.dart';

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

void main() {
  group('onboarding : 7 étapes aux 7 tailles, texte 130 %', () {
    for (var step = 1; step <= 7; step++) {
      for (final size in _sizes) {
        for (final locale in const [Locale('fr'), Locale('en')]) {
          testWidgets(
            'étape $step · ${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}',
            (tester) async {
              await _pump(
                tester,
                StoreOnboardingView(
                  service: _atStep(step),
                  onOpened: (_, _) {},
                ),
                size: size,
                locale: locale,
                textScale: 1.3,
              );
              expect(tester.takeException(), isNull);
              expect(
                find.text(
                  locale.languageCode == 'fr'
                      ? 'Étape $step sur 7'
                      : 'Step $step of 7',
                ),
                findsOneWidget,
              );
            },
          );
        }
      }
    }
  });

  testWidgets('parcours nominal au toucher : 7 étapes puis ouverture', (
    tester,
  ) async {
    final stores = memoryStores();
    MyStore? opened;
    await _pump(
      tester,
      StoreOnboardingView(
        service: stores,
        onOpened: (store, _) => opened = store,
      ),
    );
    Future<void> next(String label) async {
      final button = find.text(label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await tester.enterText(find.byType(TextField).first, "Les jus d'Esi");
    await tester.pumpAndSettle();
    expect(find.text("Les jus d'Esi"), findsWidgets, reason: 'aperçu');
    await next('Continuer');

    expect(find.text('Étape 2 sur 7'), findsOneWidget);
    await tester.tap(find.text('Fait maison'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ton adresse reste privée'), findsOneWidget);
    await next('Continuer');

    expect(find.text('Étape 3 sur 7'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).first,
      'Rue des Hibiscus, maison bleue',
    );
    await tester.pumpAndSettle();
    await next('Continuer');

    expect(find.text('Étape 4 sur 7'), findsOneWidget);
    await tester.tap(find.text('Fait maison'));
    await tester.pumpAndSettle();
    await next('Continuer');

    expect(find.text('Étape 5 sur 7'), findsOneWidget);
    await tester.tap(find.text('Tout sélectionner'));
    await tester.pumpAndSettle();
    await next('Continuer');

    expect(find.text('Étape 6 sur 7'), findsOneWidget);
    expect(find.text('Bientôt'), findsNWidgets(2));
    await next('Continuer');

    expect(find.text('Étape 7 sur 7'), findsOneWidget);
    expect(find.text('Fermé'), findsOneWidget, reason: 'dimanche fermé');
    await next('Ouvrir ma boutique');

    expect(opened?.status, StoreStatus.active);
    expect(opened?.deliveryZoneIds, hasLength(7));
    expect(stores.calls.where((c) => c == 'publish'), hasLength(1));
  });

  testWidgets('étape vide : bouton inactif', (tester) async {
    final stores = memoryStores();
    await _pump(
      tester,
      StoreOnboardingView(service: stores, onOpened: (_, _) {}),
    );
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(stores.calls, isNot(contains('start')));
  });

  testWidgets('enregistrement hors ligne : message, étape conservée', (
    tester,
  ) async {
    final stores = _atStep(2);
    await _pump(
      tester,
      StoreOnboardingView(service: stores, onOpened: (_, _) {}),
    );
    stores.failNext = const NetworkFailure('hors ligne');
    await tester.tap(find.text('Au marché'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Étape 2 sur 7'), findsOneWidget);
    expect(find.textContaining('Pas de connexion'), findsOneWidget);
  });

  group('boutique ouverte et « Ma boutique »', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode} · texte 130 %';
        testWidgets('boutique ouverte · $name', (tester) async {
          await _pump(
            tester,
            StoreOpenedView(
              store: openStore(),
              config: togoConfig(),
              onSeeStore: () {},
              onAddProduct: () {},
            ),
            size: size,
            locale: locale,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
        });
        testWidgets('Ma boutique · $name', (tester) async {
          await _pump(
            tester,
            MyStoreView(
              service: memoryStores(initial: openStore()),
              onEdit: (_) async {},
            ),
            size: size,
            locale: locale,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('résumé : quartiers, paiement et horaires', (tester) async {
      await _pump(
        tester,
        StoreOpenedView(
          store: openStore(),
          config: togoConfig(),
          onSeeStore: () {},
          onAddProduct: () {},
        ),
      );
      expect(find.text('Ta boutique est ouverte !'), findsOneWidget);
      expect(find.text("Les jus d'Esi · Tokoin"), findsOneWidget);
      expect(find.text('Livraison dans 4 quartiers'), findsOneWidget);
      expect(find.text('Cash à la livraison'), findsOneWidget);
      expect(find.textContaining('Lundi au samedi'), findsOneWidget);
    });

    testWidgets('interrupteur : fermer en un geste', (tester) async {
      final stores = memoryStores(initial: openStore());
      await _pump(tester, MyStoreView(service: stores, onEdit: (_) async {}));
      expect(find.text('Ouverte'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Fermée'), findsOneWidget);
      expect(stores.current?.isOpen, isFalse);
    });

    testWidgets('réglage : la ligne ouvre l’étape correspondante', (
      tester,
    ) async {
      final edited = <StoreStep>[];
      await _pump(
        tester,
        MyStoreView(
          service: memoryStores(initial: openStore()),
          onEdit: (step) async => edited.add(step),
        ),
      );
      final row = find.textContaining('Horaires');
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(edited, [StoreStep.hours]);
    });

    testWidgets('suspendue : message et interrupteur inactif', (tester) async {
      final stores = memoryStores(
        initial: openStore(open: false, status: StoreStatus.suspended),
      );
      await _pump(tester, MyStoreView(service: stores, onEdit: (_) async {}));
      expect(find.textContaining('suspendue'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(stores.calls, isNot(contains('setOpen')));
    });
  });
}
