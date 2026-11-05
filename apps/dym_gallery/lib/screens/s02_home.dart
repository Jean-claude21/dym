import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_cart.dart';
import 'package:dym_gallery/demo/demo_catalog.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/screens/common.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Écran 02 — Accueil cliente.
class HomeScreen extends StatefulWidget {
  const new({required this.country, super.key});

  final DemoCountry country;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cart = DemoCart({'tomates': 1, 'bissap': 1, 'gari': 1});

  static const _rebuy = ['tomates', 'bissap', 'gari', 'huile'];
  static const _stores = ['akossiwa', 'esi', 'kodjo'];

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final country = widget.country;
    final aisles = <(String, String, Color, bool)>[
      ('legumes', 'Légumes', c.tintVertTendre, false),
      ('fruits', 'Fruits', c.tintPlantainClair, false),
      ('fait-maison', 'Fait maison', c.tintPeche, true),
      ('tubercules', 'Tubercules', c.tintPeche, false),
      ('poissons', 'Poissons fumés', c.tintIndigoClair, false),
      ('epices', 'Épices', c.tintPimentClair, false),
      ('boissons', 'Boissons', c.tintIndigoClair, false),
      ('hygiene', 'Hygiène', c.tintVertTendre, false),
    ];

    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: DymBottomNav(
        currentIndex: 0,
        onTap: (_) {},
        items: const [
          DymNavItem(icon: Icons.home_rounded, label: 'Accueil'),
          DymNavItem(icon: Icons.grid_view_rounded, label: 'Rayons'),
          DymNavItem(icon: Icons.receipt_long_rounded, label: 'Commandes'),
          DymNavItem(icon: Icons.person_outline_rounded, label: 'Moi'),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Row(
                  children: [
                    Flexible(flex: 2, child: LocationPill(label: country.city)),
                    const SizedBox(width: 6),
                    Flexible(
                      flex: 3,
                      child: DymDeliveryPill(
                        label: 'Livré en 35 min',
                        zem: DemoImages.zem,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const MeAvatar(),
                  ],
                ).enter(context),
                const SizedBox(height: 14),
                DymSearchBar(
                  hint: 'Cherche tomates, gari, jus maison…',
                  onTap: () {},
                  onMic: () {},
                  onCamera: () {},
                  micLabel: 'Chercher en parlant',
                  cameraLabel: 'Chercher avec une photo',
                ).enter(context, delay: const Duration(milliseconds: 60)),
                const SizedBox(height: 18),
                const DymSectionHeader(title: 'Racheter'),
                const SizedBox(height: 8),
                ListenableBuilder(
                  listenable: _cart,
                  builder: (context, _) => Row(
                    children: [
                      for (final id in _rebuy) ...[
                        Expanded(child: _compact(id, country)),
                        if (id != _rebuy.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ).enter(context, delay: const Duration(milliseconds: 120)),
                const SizedBox(height: 18),
                DymSectionHeader(
                  title: 'Boutiques ouvertes près de toi',
                  actionLabel: 'Tout voir',
                  onAction: () {},
                ),
                const SizedBox(height: 8),
                SizedBox(
                  // Hauteur adaptée à la taille de texte du téléphone.
                  height: 148 + MediaQuery.textScalerOf(context).scale(58),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: _stores.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final s = DemoCatalog.stores[_stores[i]]!;
                      return DymStoreCard(
                        cover: s.cover!,
                        avatar: s.avatar,
                        name: s.name,
                        origin: s.origin,
                        originLabel: originLabel(s.origin),
                        meta: '${s.area} · ${s.distance}',
                        width: 150,
                        onTap: () {},
                      );
                    },
                  ),
                ).enter(context, delay: const Duration(milliseconds: 180)),
                const SizedBox(height: 18),
                const DymSectionHeader(title: 'Rayons'),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.82,
                  children: [
                    for (final (img, label, tint, isNew) in aisles)
                      DymAisleTile(
                        image: DemoImages.aisle(img),
                        label: label,
                        tint: tint,
                        badge: isNew
                            ? const DymPromoBadge(
                                label: 'Nouveau',
                                tone: DymPromoTone.fresh,
                              )
                            : null,
                        onTap: () {},
                      ),
                  ],
                ).enter(context, delay: const Duration(milliseconds: 240)),
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
        ),
      ),
    );
  }

  Widget _compact(String id, DemoCountry country) {
    final p = DemoCatalog.products[id]!;
    final c = context.dym.colors;
    return DymProductCard(
      layout: DymProductCardLayout.compact,
      image: p.image,
      name: p.name == 'Tomates fraîches' ? 'Tomates' : p.name,
      unit: p.unit,
      price: country.price(p.priceXof),
      tint: id == 'bissap' ? c.tintPimentClair : c.tintPeche,
      onQuantityChanged: (q) => _cart.setQuantity(id, _cart.quantityOf(id) + q),
    );
  }
}
