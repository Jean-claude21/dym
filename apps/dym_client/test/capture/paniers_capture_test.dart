// Fakes repris des tests d'écran : certaines aides n'y servent pas.
@Tags(['golden'])
library;

import 'package:dym_client/features/favorites/favorites_views.dart';
import 'package:dym_client/features/favorites/testing.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/discovery_fixtures.dart';
import 'capture.dart';

const _breakfast = SavedBasket(
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

void main() {
  testWidgets('paniers', (tester) async {
    await capture(
      tester,
      'paniers',
      BasketsView(
        service: MemoryFavoritesService(
          baskets: [_breakfast],
          skipped: ['Piment'],
        ),
        discovery: memoryDiscovery(photos: capturePhoto),
        onBack: () {},
        onAdded: () {},
      ),
    );
  });
}
