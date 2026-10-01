import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_cart.dart';
import 'package:dym_gallery/demo/demo_catalog.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/screens/common.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Écran 04 — Page boutique « Les jus d'Esi » (fait maison).
class StoreScreen extends StatefulWidget {
  const new({required this.country, super.key});

  final DemoCountry country;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _cart = DemoCart({'bissap': 1});
  static const _products = ['bissap', 'gingembre', 'baobab', 'pack-jus'];

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final store = DemoCatalog.stores['esi']!;
    final country = widget.country;
    final gutter = DymLayout.gutter(context);
    final tints = [
      c.tintPimentClair,
      c.tintVertTendre,
      c.tintPlantainClair,
      c.tintPimentClair,
    ];
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              SizedBox(
                height: 328,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 236,
                      child: Image(image: store.cover!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 216,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.background,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(DymTokenRadius.card),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: MediaQuery.paddingOf(context).top + 8,
                      child: Row(
                        children: [
                          RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Retour',
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          const Spacer(),
                          const RoundIconButton(
                            icon: Icons.share_outlined,
                            tooltip: 'Partager',
                          ),
                          const SizedBox(width: 8),
                          const RoundIconButton(
                            icon: Icons.favorite_border_rounded,
                            tooltip: 'Ajouter aux favoris',
                          ),
                        ],
                      ),
                    ),
                    // Avatar et nom alignés sur le contenu borné (spec 002).
                    Positioned.fill(
                      child: DymContentWidth(
                        child: Stack(
                          children: [
                            Positioned(
                              left: gutter,
                              top: 176,
                              child: DymAvatar(image: store.avatar, size: 124),
                            ),
                            Positioned(
                              left: gutter + 136,
                              right: gutter,
                              top: 228,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.display.copyWith(fontSize: 26),
                                  ),
                                  const SizedBox(height: 4),
                                  DymOriginBadge(
                                    origin: store.origin,
                                    label: originLabel(store.origin),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${store.area} · ${store.distance} · '
                                    "Ouvert jusqu'à 20 h",
                                    maxLines: 2,
                                    style: t.label.copyWith(
                                      fontSize: 14,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DymContentWidth(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      const WhiteCard(child: _Stats()),
                      const SizedBox(height: 14),
                      Text(
                        'Je prépare mes jus chaque matin avec les fleurs de '
                        "bissap du marché d'Adawlato.",
                        style: t.body.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      WhiteCard(
                        color: c.tintVertTendre,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: c.brandDeep,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Retrait chez Esi à ${store.area} · adresse '
                                'partagée avec le livreur uniquement',
                                style: t.label.copyWith(color: c.brandDeep),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const DymSectionHeader(title: 'Ses produits'),
                      const SizedBox(height: 8),
                      ListenableBuilder(
                        listenable: _cart,
                        builder: (context, _) => LayoutBuilder(
                          builder: (context, box) => GridView.count(
                            crossAxisCount: DymLayout.columns(
                              box.maxWidth,
                              minTileWidth: 168,
                              spacing: 12,
                              min: 2,
                              max: 6,
                            ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.66,
                            children: [
                              for (var i = 0; i < _products.length; i++)
                                _productCard(_products[i], tints[i], country),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12 + MediaQuery.paddingOf(context).bottom,
            child: ListenableBuilder(
              listenable: _cart,
              builder: (context, _) => DymMiniCartBar(
                itemCount: _cart.itemCount,
                total: _cart.total(country),
                summary:
                    '${_cart.itemCount} article'
                    '${_cart.itemCount > 1 ? 's' : ''} · '
                    '${_cart.total(country).format()}',
                actionLabel: 'Voir le panier',
                thumbnail: DemoImages.basket,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(String id, Color tint, DemoCountry country) {
    final p = DemoCatalog.products[id]!;
    return DymProductCard(
      image: p.image,
      name: p.name,
      unit: p.unit,
      price: country.price(p.priceXof),
      tint: tint,
      quantity: _cart.quantityOf(id),
      onQuantityChanged: (q) => _cart.setQuantity(id, q),
    );
  }
}

class _Stats extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    Widget stat(IconData icon, Color color, String value, String label) =>
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: context.dym.text.price.copyWith(fontSize: 20),
                  ),
                ],
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.dym.text.label.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        );
    final divider = Container(
      width: 1,
      height: 36,
      color: c.textSecondary.withValues(alpha: 0.2),
    );
    return Row(
      children: [
        stat(Icons.star_rounded, c.plantain, '4,9', 'note'),
        divider,
        stat(
          Icons.local_drink_outlined,
          c.textPrimary,
          '1 240',
          'bouteilles vendues',
        ),
        divider,
        stat(Icons.calendar_today_rounded, c.textPrimary, '2019', 'depuis'),
      ],
    );
  }
}
