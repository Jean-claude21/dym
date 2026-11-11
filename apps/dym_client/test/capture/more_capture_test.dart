@Tags(['golden'])
library;

import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/discovery/copilot/copilot_view.dart';
import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_client/features/favorites/favorites_views.dart';
import 'package:dym_client/features/favorites/testing.dart';
import 'package:dym_client/features/shopping/shopping_views.dart';
import 'package:dym_client/features/shopping/testing.dart';
import 'package:dym_client/features/spaces/spaces_views.dart';
import 'package:dym_client/features/spaces/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/discovery_fixtures.dart';
import 'capture.dart';

/// Captures des pages de « Moi » et du copilote (spec 058).
Space _space() => const Space(
  id: 'sp1',
  name: 'Famille à Lomé',
  joinCode: 'ABCD2345',
  myRole: SpaceRole.payer,
  isOwner: true,
  currencyCode: 'XOF',
  monthlyBudgetMinor: 50000,
  spentMonthMinor: 4450,
  totalMinor: 2900,
  members: [
    SpaceMember(
      userId: 'u1',
      firstName: 'Awa',
      role: SpaceRole.payer,
      isOwner: true,
      isMe: true,
    ),
    SpaceMember(userId: 'u2', firstName: 'Mariam', role: SpaceRole.member),
    SpaceMember(userId: 'u3', firstName: 'Kofi', role: SpaceRole.member),
  ],
  items: [
    SpaceItem(
      variantId: 'v1',
      productId: 'p1',
      name: 'Gari',
      quantity: 2,
      unitPriceMinor: 700,
      available: true,
      addedBy: 'Mariam',
    ),
    SpaceItem(
      variantId: 'v2',
      productId: 'p2',
      name: 'Riz parfumé',
      quantity: 1,
      unitPriceMinor: 1500,
      available: true,
      addedBy: 'Kofi',
    ),
  ],
);

CopilotLine _line(String id, String name, int qty, int price, String need) =>
    CopilotLine(
      variantId: id,
      productId: 'p-$id',
      name: name,
      quantity: qty,
      unitLabel: const LocalizedText({'fr': 'tas'}),
      unitPriceMinor: price,
      lineMinor: qty * price,
      need: need,
    );

void main() {
  testWidgets('espace', (t) async {
    await capture(
      t,
      'espace',
      SpaceView(
        service: MemorySpacesService(
          discovery: memoryDiscovery(photos: capturePhoto),
          spaces: [_space()],
        ),
        spaceId: 'sp1',
        onBack: () {},
        onValidated: () {},
      ),
    );
  });
  testWidgets('espaces liste', (t) async {
    await capture(
      t,
      'espaces_liste',
      SpacesView(
        service: MemorySpacesService(
          discovery: memoryDiscovery(),
          spaces: [_space()],
        ),
        onBack: () {},
        onOpen: (_) async {},
      ),
    );
  });
  testWidgets('favoris remplis', (t) async {
    await capture(
      t,
      'favoris_remplis',
      FavoritesView(
        service: MemoryFavoritesService(favoriteStores: [esi, kodjo]),
        discovery: memoryDiscovery(photos: capturePhoto),
        onBack: () {},
        onOpenStore: (_) {},
        onOpenProduct: (_) {},
      ),
    );
  });
  testWidgets('listes', (t) async {
    final service = MemoryShoppingService(
      copilot: MemoryCopilotService(discovery: memoryDiscovery()),
    );
    await service.save(
      name: 'Courses du samedi',
      items: const [
        ShoppingItem(label: 'Tomates', quantity: 2),
        ShoppingItem(label: 'Gombo'),
        ShoppingItem(label: 'Poisson fumé'),
      ],
      period: ShoppingPeriod.weekly,
    );
    await capture(
      t,
      'listes',
      ShoppingListsView(
        service: service,
        onBack: () {},
        onEdit: (_) async => false,
        onOpen: (_) {},
      ),
    );
  });
  testWidgets('copilote', (t) async {
    await capture(
      t,
      'copilote',
      CopilotView(
        service: MemoryCopilotService(
          discovery: memoryDiscovery(photos: capturePhoto),
          proposal: CopilotProposal(
            currencyCode: 'XOF',
            totalMinor: 2 * 300 + 500 + 1200,
            stores: [
              CopilotStoreLines(
                id: 's1',
                name: "Étal d'Akossiwa",
                lines: [
                  _line('v1', 'Gombo frais', 2, 300, 'Gombo'),
                  _line('v2', 'Tomates fraîches', 1, 500, 'Tomates'),
                ],
              ),
              CopilotStoreLines(
                id: 's2',
                name: 'Chez Afi',
                lines: [_line('v3', 'Huile rouge', 1, 1200, 'Huile rouge')],
              ),
            ],
            missing: const ['Crevettes séchées'],
          ),
        ),
        ai: MemorySearchAiService(),
        initialText: 'Une sauce gombo pour 4 personnes ce soir',
        onBack: () {},
        onSearchMyself: (_) {},
        onAdded: () {},
      ),
    );
  });
}
