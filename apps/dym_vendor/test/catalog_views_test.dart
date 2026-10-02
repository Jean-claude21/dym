import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/catalog/categories/store_categories_view.dart';
import 'package:dym_vendor/features/catalog/editor/product_editor_view.dart';
import 'package:dym_vendor/features/catalog/products/products_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/catalog_fixtures.dart';

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

void main() {
  group('écrans 24 à 27 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        Future<void> show(WidgetTester tester, Widget view) =>
            _pump(tester, view, size: size, locale: locale, textScale: 1.3);

        testWidgets('24 Mes produits · $name', (tester) async {
          await show(
            tester,
            ProductsView(
              service: memoryCatalog(),
              onEdit: (_) async {},
              onCategories: () async {},
            ),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('25 photo et fiche · $name', (tester) async {
          await show(
            tester,
            ProductEditorView(
              service: memoryCatalog(),
              product: esiProducts().first,
              onDone: (_) {},
              onCancel: () {},
            ),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('26 prix et stock · $name', (tester) async {
          await show(
            tester,
            ProductEditorView(
              service: memoryCatalog(),
              product: esiProducts().first,
              onDone: (_) {},
              onCancel: () {},
            ),
          );
          await tester.tap(find.byType(DymButton).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });

        testWidgets('27 Mes catégories · $name', (tester) async {
          await show(
            tester,
            StoreCategoriesView(service: memoryCatalog(), onBack: () {}),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('parcours nominal : photo, proposition, prix, publication', (
    tester,
  ) async {
    final catalog = memoryCatalog(products: const []);
    Product? done;
    await _pump(
      tester,
      ProductEditorView(
        service: catalog,
        onDone: (p) => done = p,
        onCancel: () {},
      ),
    );
    expect(find.text('Étape 1 sur 2'), findsOneWidget);
    await _tap(tester, find.text('Prendre une photo'));
    expect(find.text('Proposé par DYM'), findsOneWidget);
    expect(find.text('Jus de bissap 50 cl'), findsOneWidget);

    await _tap(tester, find.text('Continuer'));
    expect(find.text('Étape 2 sur 2'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('la pièce'));
    await _tap(tester, find.byTooltip('Un de plus'));
    await _tap(tester, find.text('Publier le produit'));

    expect(done?.status, ProductStatus.published);
    expect(done?.priceMinor, 500);
    expect(done?.unitId, 'unit-piece');
    expect(done?.variants.single.stockQuantity, 1);
    expect(catalog.suggestionsShown, 1);
  });

  testWidgets('fiche vide : Continuer inactif', (tester) async {
    final catalog = memoryCatalog(products: const []);
    await _pump(
      tester,
      ProductEditorView(service: catalog, onDone: (_) {}, onCancel: () {}),
    );
    await _tap(tester, find.text('Continuer'));
    expect(find.text('Étape 1 sur 2'), findsOneWidget);
    expect(catalog.calls, isNot(contains('saveProduct')));
  });

  testWidgets('Mes produits : rupture en un geste, puis filtre', (
    tester,
  ) async {
    final catalog = memoryCatalog();
    await _pump(
      tester,
      ProductsView(
        service: catalog,
        onEdit: (_) async {},
        onCategories: () async {},
      ),
    );
    expect(find.text('Rupture'), findsOneWidget);
    expect(find.text('Brouillon'), findsOneWidget);
    await _tap(tester, find.byType(Switch).first);
    expect(catalog.current.first.isAvailable, isFalse);
    expect(find.text('Rupture'), findsNWidgets(2));

    await _tap(tester, find.text('Sirops'));
    expect(find.text('Jus de bissap'), findsNothing);
    expect(find.text('Sirop de bissap'), findsOneWidget);
  });

  testWidgets('Mes produits : catalogue vide', (tester) async {
    await _pump(
      tester,
      ProductsView(
        service: memoryCatalog(products: const []),
        onEdit: (_) async {},
        onCategories: () async {},
      ),
    );
    expect(find.text('Aucun produit pour l’instant.'), findsNothing);
    expect(find.textContaining('Aucun produit'), findsOneWidget);
    expect(find.text('Ajouter un produit'), findsOneWidget);
  });

  testWidgets('Mes produits hors ligne : reprise proposée', (tester) async {
    final catalog = memoryCatalog()
      ..failNext = const NetworkFailure('hors ligne');
    await _pump(
      tester,
      ProductsView(
        service: catalog,
        onEdit: (_) async {},
        onCategories: () async {},
      ),
    );
    expect(find.text('Réessayer'), findsOneWidget);
    await _tap(tester, find.text('Réessayer'));
    expect(find.text('Jus de bissap'), findsOneWidget);
  });

  testWidgets('Mes catégories : ajout et doublon', (tester) async {
    await _pump(
      tester,
      StoreCategoriesView(service: memoryCatalog(), onBack: () {}),
    );
    final field = find.byType(TextField).last;
    await tester.enterText(field, 'Plats du jour');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Ajouter'));
    expect(find.text('Plats du jour'), findsOneWidget);
    await tester.enterText(field, 'jus');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Ajouter'));
    expect(find.text('Cette catégorie existe déjà.'), findsOneWidget);
  });
}
