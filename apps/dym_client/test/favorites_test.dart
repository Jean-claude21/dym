import 'package:dym_client/features/favorites/favorites_views.dart';
import 'package:dym_client/features/favorites/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

void main() {
  Widget app(Widget home) => MaterialApp(
    theme: DymTheme.light(),
    locale: const Locale('fr'),
    localizationsDelegates: DymLocalizations.localizationsDelegates,
    supportedLocales: DymLocalizations.supportedLocales,
    home: Scaffold(body: home),
  );

  const breakfast = SavedBasket(
    id: 'b1',
    name: 'Petit-déjeuner',
    currencyCode: 'XOF',
    totalMinor: 1000,
    availableCount: 1,
    items: [
      SavedBasketItem(
        variantId: 'v1',
        productId: 'p1',
        name: 'Tomates',
        quantity: 2,
        unitPriceMinor: 500,
        available: true,
      ),
      SavedBasketItem(
        variantId: 'v2',
        productId: 'p2',
        name: 'Piment',
        quantity: 1,
        unitPriceMinor: 200,
        available: false,
      ),
    ],
  );

  group('carnet (spec 030)', () {
    testWidgets('cœur : ajout puis retrait', (tester) async {
      final service = MemoryFavoritesService();
      await tester.pumpWidget(
        app(
          FavoriteButton(service: service, kind: FavoriteKind.store, id: 's1'),
        ),
      );
      expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
      expect(service.ids.value.contains(FavoriteKind.store, 's1'), isTrue);
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(service.ids.value.contains(FavoriteKind.store, 's1'), isFalse);
    });

    testWidgets('favoris : vide, puis une boutique', (tester) async {
      await tester.pumpWidget(
        app(
          FavoritesView(
            service: MemoryFavoritesService(),
            discovery: memoryDiscovery(),
            onBack: () {},
            onOpenStore: (_) {},
            onOpenProduct: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Touche le cœur'), findsOneWidget);

      String? opened;
      await tester.pumpWidget(
        app(
          FavoritesView(
            key: const ValueKey('avec'),
            service: MemoryFavoritesService(favoriteStores: [esi]),
            discovery: memoryDiscovery(),
            onBack: () {},
            onOpenStore: (id) => opened = id,
            onOpenProduct: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Boutiques'), findsOneWidget);
      await tester.tap(find.text(esi.name).first);
      expect(opened, esi.id);
    });

    testWidgets('paniers : disponibilité du jour et article non ajouté', (
      tester,
    ) async {
      final service = MemoryFavoritesService(
        baskets: [breakfast],
        skipped: ['Piment'],
      );
      var added = 0;
      await tester.pumpWidget(
        app(
          BasketsView(
            service: service,
            discovery: memoryDiscovery(),
            onBack: () {},
            onAdded: () => added++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Petit-déjeuner'), findsOneWidget);
      expect(find.text('1 article indisponible'), findsOneWidget);
      await tester.tap(find.text('Remettre au panier'));
      await tester.pumpAndSettle();
      expect(service.reordered, ['b1']);
      expect(find.textContaining('Pas ajouté'), findsOneWidget);
      expect(added, 0, reason: 'la cliente voit ce qui manque avant le panier');
    });

    testWidgets('paniers : tout ajouté, ouverture du panier', (tester) async {
      var added = 0;
      await tester.pumpWidget(
        app(
          BasketsView(
            service: MemoryFavoritesService(baskets: [breakfast]),
            discovery: memoryDiscovery(),
            onBack: () {},
            onAdded: () => added++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remettre au panier'));
      await tester.pumpAndSettle();
      expect(added, 1);
    });

    testWidgets('enregistrer le panier : nom, puis message', (tester) async {
      final service = MemoryFavoritesService();
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => saveCartAsBasket(context, service),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Déjeuner');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(service.stored.single.name, 'Déjeuner');
      expect(find.textContaining('Panier enregistré'), findsOneWidget);
    });

    test('refus du serveur traduits', () {
      expect(
        basketErrorOf(const ValidationFailure('cart_empty')),
        BasketError.empty,
      );
      expect(
        basketErrorOf(const ValidationFailure('too_many_baskets')),
        BasketError.tooMany,
      );
      expect(basketErrorOf(const NetworkFailure('x')), BasketError.offline);
    });
  });
}
