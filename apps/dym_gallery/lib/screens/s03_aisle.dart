import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_cart.dart';
import 'package:dym_gallery/demo/demo_catalog.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/screens/common.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Écran 03 — Rayon Légumes. Interactif : « + » ajoute au panier de démo.
class AisleScreen extends StatefulWidget {
  const new({required this.country, super.key});

  final DemoCountry country;

  @override
  State<AisleScreen> createState() => _AisleScreenState();
}

class _AisleScreenState extends State<AisleScreen> {
  // Résumé de l'écran validé : « 4 articles · 2 boutiques · 1 500 F CFA ».
  final _cart = DemoCart({'tomates': 2, 'gombo': 1, 'piment': 1});
  int _chip = 0;

  static const _chips = [
    'Tous',
    'Au marché',
    'Fait maison',
    'Tomates',
    'Feuilles',
  ];
  static const _products = [
    'tomates',
    'gombo',
    'piment',
    'ademe',
    'oignons',
    'aubergines',
  ];

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final country = widget.country;
    final tints = [
      c.tintPeche,
      c.tintVertTendre,
      c.tintPimentClair,
      c.tintPlantainClair,
      c.tintIndigoClair,
      c.tintPeche,
    ];
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // Grille bornée et centrée ; 2 colonnes sur téléphone (spec 002).
            final inset = DymLayout.sideInset(
              box.maxWidth,
              gutter: DymLayout.gutter(context),
            );
            final columns = DymLayout.columns(
              box.maxWidth - 2 * inset,
              minTileWidth: 168,
              spacing: 12,
              min: 2,
              max: 6,
            );
            return Stack(
              children: [
                Column(
                  children: [
                    DymContentWidth(
                      child: ScreenHeader(
                        title: 'Légumes',
                        trailing: IconButton(
                          tooltip: 'Chercher',
                          onPressed: () {},
                          icon: Icon(Icons.search_rounded, color: c.brandDeep),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: inset),
                        scrollDirection: Axis.horizontal,
                        itemCount: _chips.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => DymFilterChip(
                          label: _chips[i],
                          selected: i == _chip,
                          onTap: () => setState(() => _chip = i),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: _cart,
                        builder: (context, _) => GridView.builder(
                          padding: EdgeInsets.fromLTRB(inset, 8, inset, 100),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 304,
                              ),
                          itemCount: _products.length,
                          itemBuilder: (context, i) {
                            final p = DemoCatalog.products[_products[i]]!;
                            final s = DemoCatalog.storeOf(p);
                            return DymProductCard(
                              image: p.image,
                              name: p.name,
                              unit: p.unit,
                              price: country.price(p.priceXof),
                              tint: tints[i],
                              store: DymProductStore(
                                name: s.name,
                                origin: s.origin,
                                originLabel: originLabel(s.origin),
                                avatar: s.avatar,
                              ),
                              badge: switch (p.badge) {
                                DemoBadge.promo20 => const DymPromoBadge(
                                  label: '−20 %',
                                ),
                                DemoBadge.arrivage => const DymPromoBadge(
                                  label: 'Arrivage du jour',
                                  tone: DymPromoTone.highlight,
                                ),
                                DemoBadge.none => null,
                              },
                              quantity: _cart.quantityOf(p.id),
                              onQuantityChanged: (q) =>
                                  _cart.setQuantity(p.id, q),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: ListenableBuilder(
                    listenable: _cart,
                    builder: (context, _) => DymMiniCartBar(
                      itemCount: _cart.itemCount,
                      total: _cart.total(country),
                      summary: _cart.summary(country),
                      actionLabel: 'Voir le panier',
                      thumbnail: DemoImages.basket,
                      onTap: () {},
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
