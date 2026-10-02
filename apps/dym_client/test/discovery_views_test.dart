import 'package:dym_client/features/discovery/aisle/aisle_view.dart';
import 'package:dym_client/features/discovery/home/discovery_home_view.dart';
import 'package:dym_client/features/discovery/product/product_page_view.dart';
import 'package:dym_client/features/discovery/search/search_view.dart';
import 'package:dym_client/features/discovery/store/store_page_view.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _noop([Object? _]) {}

void main() {
  group('écrans 02, 03, 04, 28, 29 et 30 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        Future<void> show(WidgetTester tester, Widget view) =>
            _pump(tester, view, size: size, locale: locale, textScale: 1.3);

        testWidgets('02 accueil · $name', (tester) async {
          await show(
            tester,
            DiscoveryHomeView(
              service: memoryDiscovery(),
              onSearch: _noop,
              onOpenStore: _noop,
              onOpenAisle: _noop,
            ),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('03 rayon · $name', (tester) async {
          await show(
            tester,
            AisleView(
              service: memoryDiscovery(),
              categoryId: 'legumes',
              onBack: _noop,
              onSearch: _noop,
              onOpenProduct: _noop,
            ),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('04 boutique · $name', (tester) async {
          await show(
            tester,
            StorePageView(
              service: memoryDiscovery(),
              storeId: 'esi',
              onBack: _noop,
              onOpenProduct: _noop,
            ),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('28 fiche · $name', (tester) async {
          await show(
            tester,
            ProductPageView(
              service: memoryDiscovery(),
              productId: 'bissap',
              onBack: _noop,
              onOpenStore: _noop,
            ),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('29 et 30 recherche et filtres · $name', (tester) async {
          await show(
            tester,
            SearchView(
              service: memoryDiscovery(),
              onBack: _noop,
              onOpenProduct: _noop,
              onOpenStore: _noop,
              debounce: Duration.zero,
            ),
          );
          await tester.enterText(find.byType(TextField), 'bissap');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(ActionChip));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('accueil : quartier proposé par la position, confirmé', (
    tester,
  ) async {
    final service = memoryDiscovery(
      zoneMatch: const ZoneMatch(
        zoneId: 'tokoin',
        zoneName: 'Tokoin',
        cityId: 'lome',
        cityName: 'Lomé',
        countryCode: 'TG',
        distanceM: 180,
      ),
    );
    await _pump(
      tester,
      DiscoveryHomeView(
        service: service,
        onSearch: _noop,
        onOpenStore: _noop,
        onOpenAisle: _noop,
      ),
    );
    expect(find.text('Livré en 35 min'), findsOneWidget);
    await _tap(tester, find.text('Bè, Lomé'));
    await _tap(tester, find.text('Utiliser ma position'));
    expect(find.text('Tu es à Tokoin ?'), findsOneWidget);
    await _tap(tester, find.text("Oui, c'est ça"));
    expect(service.zone.value, 'tokoin');
  });

  testWidgets('parcours : recherche, fiche, variante', (tester) async {
    final service = memoryDiscovery();
    String? opened;
    await _pump(
      tester,
      SearchView(
        service: service,
        onBack: _noop,
        onOpenProduct: (id) => opened = id,
        onOpenStore: _noop,
        debounce: Duration.zero,
      ),
    );
    expect(find.text('Tape au moins 2 lettres.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'biss');
    await tester.pumpAndSettle();
    expect(find.text('2 résultats · Pertinence'), findsOneWidget);
    await _tap(tester, find.text('Jus de bissap'));
    expect(opened, 'bissap');

    await _pump(
      tester,
      ProductPageView(
        service: service,
        productId: 'bissap',
        onBack: _noop,
        onOpenStore: _noop,
      ),
    );
    expect(find.text('Livré en 50 min environ à Bè'), findsOneWidget);
    expect(find.text('En stock'), findsOneWidget);
    await _tap(tester, find.textContaining('1 L ·'));
    expect(find.text('Rupture'), findsOneWidget);
    expect(service.viewed, ['bissap']);
  });

  testWidgets('recherche hors ligne : reprise', (tester) async {
    final service = memoryDiscovery();
    await _pump(
      tester,
      SearchView(
        service: service,
        onBack: _noop,
        onOpenProduct: _noop,
        onOpenStore: _noop,
        debounce: Duration.zero,
      ),
    );
    service.failNext = const NetworkFailure('hors ligne');
    await tester.enterText(find.byType(TextField), 'bissap');
    await tester.pumpAndSettle();
    expect(find.text('Réessayer'), findsOneWidget);
    await _tap(tester, find.text('Réessayer'));
    expect(find.text('Jus de bissap'), findsOneWidget);
  });

  testWidgets('boutique fait maison : mention de retrait sans adresse', (
    tester,
  ) async {
    await _pump(
      tester,
      StorePageView(
        service: memoryDiscovery(),
        storeId: 'esi',
        onBack: _noop,
        onOpenProduct: _noop,
      ),
    );
    expect(
      find.textContaining('adresse partagée avec le livreur'),
      findsOneWidget,
    );
  });
}
