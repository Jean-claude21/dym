@Tags(['golden'])
library;

import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/feed_view.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/discovery_fixtures.dart';
import 'capture.dart';

/// Captures du flux « Cuisine » (spec 057, planche 02).
CatalogItem _item(String id, String name, int price, String unit) =>
    CatalogItem(
      id: 'p-$id',
      name: name,
      currencyCode: 'XOF',
      minPriceMinor: price,
      defaultVariantId: id,
      unitLabel: LocalizedText({'fr': unit}),
      store: const CatalogItemStore(
        id: 's1',
        name: "Étal d'Akossiwa",
        zoneName: 'Bè',
      ),
    );

CopilotLine _line(String id, String name, int quantity, int unit) =>
    CopilotLine(
      variantId: id,
      productId: id,
      name: name,
      quantity: quantity,
      unitPriceMinor: unit,
      lineMinor: unit * quantity,
      unitLabel: const LocalizedText({'fr': 'le tas'}),
    );

MemoryContentService _service() => MemoryContentService(
  discovery: memoryDiscovery(),
  contents: [
    ContentItem(
      id: 'c1',
      kind: ContentKind.video,
      mediaKey: 'creators/u1/contents/c1.mp4',
      isVideo: true,
      caption: 'Sauce gombo comme à Bè, pour 4 personnes',
      createdAt: DateTime.utc(2026, 11, 10),
      author: const ContentAuthor(id: 'u1', displayName: 'Awa Cuisine'),
      likeCount: 12400,
      commentCount: 382,
      products: [
        _item('gombo', 'Gombo', 750, '500 g'),
        _item('poisson', 'Poisson fumé', 1800, '500 g'),
        _item('tomates', 'Tomates', 500, '500 g'),
        _item('oignons', 'Oignons', 300, '500 g'),
      ],
      ingredients: const [ShoppingItem(label: 'Huile rouge')],
    ),
  ],
  recipe: (servings) {
    final n = servings ?? 4;
    final lines = [
      _line('gombo', 'Gombo', (n / 4).ceil(), 750),
      _line('poisson', 'Poisson fumé', (n / 4).ceil(), 1800),
      _line('tomates', 'Tomates', (n / 4).ceil(), 500),
      _line('oignons', 'Oignons', 1, 300),
    ];
    return CopilotProposal(
      servings: n,
      baseServings: 4,
      currencyCode: 'XOF',
      totalMinor: lines.fold(0, (a, l) => a + l.lineMinor) + 1000,
      stores: [
        CopilotStoreLines(id: 's1', name: "Étal d'Akossiwa", lines: lines),
        CopilotStoreLines(
          id: 's2',
          name: 'Chez Ama',
          lines: [_line('huile', 'Huile rouge', 1, 1000)],
        ),
      ],
    );
  },
);

/// La vidéo est remplacée par la photo de cuisine des pages d'entrée.
Widget _video(BuildContext context, Uri url, {required bool active}) =>
    const Image(
      image: AssetImage('assets/onb_cook.webp', package: 'dym_auth'),
      fit: BoxFit.cover,
    );

Widget _shell(Widget feed) => Builder(
  builder: (context) {
    final l10n = DymLocalizations.of(context);
    return DymAdaptiveScaffold(
      darkBottomNav: true,
      currentIndex: 2,
      onDestinationSelected: (_) {},
      destinations: [
        DymNavItem(icon: Icons.home_outlined, label: l10n.navHome),
        DymNavItem(icon: Icons.storefront_outlined, label: l10n.navMarket),
        DymNavItem(icon: Icons.soup_kitchen_outlined, label: l10n.navCuisine),
        DymNavItem(icon: Icons.shopping_basket_outlined, label: l10n.navCart),
        DymNavItem(
          icon: Icons.person_outline_rounded,
          label: l10n.accountTitle,
        ),
      ],
      body: feed,
    );
  },
);

void main() {
  testWidgets('cuisine', (t) async {
    await capture(
      t,
      'cuisine',
      _shell(FeedView(service: _service(), videoBuilder: _video)),
    );
  });
  testWidgets('cuisine produits', (t) async {
    await capture(
      t,
      'cuisine_produits',
      _shell(FeedView(service: _service(), videoBuilder: _video)),
      before: (t) async {
        await t.tap(find.text('Gombo').first);
        await t.pump(const Duration(milliseconds: 600));
      },
    );
  });
  testWidgets('cuisine recette', (t) async {
    await capture(
      t,
      'cuisine_recette',
      _shell(FeedView(service: _service(), videoBuilder: _video)),
      before: (t) async {
        await t.tap(find.text('Gombo').first);
        await t.pump(const Duration(milliseconds: 600));
        await t.pump(const Duration(milliseconds: 600));
        await t.tap(find.textContaining('Tout pour la recette'));
        await t.pump(const Duration(milliseconds: 600));
        await t.pump(const Duration(milliseconds: 600));
      },
    );
  });
  testWidgets('cuisine ajouté', (t) async {
    await capture(
      t,
      'cuisine_ajoute',
      _shell(FeedView(service: _service(), videoBuilder: _video)),
      before: (t) async {
        await t.tap(find.text('Gombo').first);
        await t.pump(const Duration(milliseconds: 600));
        await t.pump(const Duration(milliseconds: 600));
        await t.tap(find.textContaining('Tout pour la recette'));
        await t.pump(const Duration(milliseconds: 600));
        await t.pump(const Duration(milliseconds: 600));
        await t.tap(find.textContaining('Ajouter 5 articles'));
        await t.pump(const Duration(milliseconds: 600));
        await t.pump(const Duration(milliseconds: 600));
      },
    );
  });
}
