import 'package:dym_core/dym_core.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Cas limites de la spec (Edge Cases) et de l'analyse (E1).
void main() {
  const longName =
      'Tomates fraîches de la coopérative des maraîchères de Bè Kpota, '
      'récolte du matin';

  Widget card({required ImageProvider image, Money? price, int quantity = 0}) =>
      SizedBox(
        width: 160,
        height: 300,
        child: DymProductCard(
          image: image,
          name: longName,
          unit: 'le tas',
          price: price ?? Money(500, Currency.xof),
          quantity: quantity,
          store: const DymProductStore(
            name: "Étal d'Akossiwa, marché de Bè",
            origin: StoreOrigin.marche,
            originLabel: 'Au marché',
          ),
          onQuantityChanged: (_) {},
        ),
      );

  testWidgets('nom de 80 caractères : tronqué sur 2 lignes, sans débordement', (
    tester,
  ) async {
    await pumpDym(tester, card(image: testImage));
    expect(tester.takeException(), isNull);
    final name = tester.widget<Text>(find.text(longName));
    expect(name.maxLines, 2);
    expect(name.overflow, TextOverflow.ellipsis);
  });

  testWidgets('montant 1 250 000 F CFA : aucun débordement', (tester) async {
    await pumpDym(
      tester,
      card(image: testImage, price: Money(1250000, Currency.xof), quantity: 3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('image absente : repli affiché, aucune erreur', (tester) async {
    await pumpDym(tester, card(image: missingImage));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.shopping_basket_rounded), findsOneWidget);
  });

  testWidgets('texte système à 130 % : carte produit et carte boutique', (
    tester,
  ) async {
    await pumpDym(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          card(image: testImage, quantity: 2),
          const SizedBox(width: 8),
          SizedBox(
            height: 260,
            child: DymStoreCard(
              cover: testImage,
              avatar: testImage,
              name: "Les jus d'Esi",
              origin: StoreOrigin.maison,
              originLabel: 'Fait maison',
              meta: 'Tokoin · 1,1 km',
              width: 150,
            ),
          ),
        ],
      ),
      textScale: 1.3,
      size: const Size(360, 640),
    );
    expect(tester.takeException(), isNull);
  });
}
