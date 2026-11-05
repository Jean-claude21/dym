import 'package:dym_core/dym_core.dart';
import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Composants dym_ui dans leurs états, côte à côte.
class ComponentsPage extends StatefulWidget {
  const new({super.key});

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> {
  int _quantity = 0;
  int _items = 2;
  bool _selected = true;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final price = Money(500, Currency.xof);
    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DymSectionHeader(title: title),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        section('DymButton', [
          SizedBox(
            width: 260,
            child: DymButton(label: 'Commander', onPressed: () {}),
          ),
          SizedBox(
            width: 260,
            child: DymButton(
              label: 'Refuser',
              variant: DymButtonVariant.secondary,
              onPressed: () {},
            ),
          ),
          SizedBox(
            width: 260,
            child: DymButton(
              label: 'Accepter',
              variant: DymButtonVariant.plantain,
              onPressed: () {},
            ),
          ),
          const SizedBox(
            width: 260,
            child: DymButton(label: 'Désactivé', onPressed: null),
          ),
          SizedBox(
            width: 260,
            child: DymButton(label: 'Envoi', loading: true, onPressed: () {}),
          ),
        ]),
        section('DymFilterChip', [
          DymFilterChip(label: 'Tous', selected: true, onTap: () {}),
          DymFilterChip(label: 'Au marché', selected: false, onTap: () {}),
        ]),
        section('DymOriginBadge · DymPromoBadge', [
          for (final o in StoreOrigin.values)
            DymOriginBadge(
              origin: o,
              label: switch (o) {
                StoreOrigin.marche => 'Au marché',
                StoreOrigin.maison => 'Fait maison',
                StoreOrigin.magasin => 'Boutique',
              },
            ),
          const DymPromoBadge(label: '−20 %'),
          const DymPromoBadge(
            label: 'Arrivage du jour',
            tone: DymPromoTone.highlight,
          ),
          const DymPromoBadge(label: 'Nouveau', tone: DymPromoTone.fresh),
        ]),
        section('DymDeliveryPill · DymAvatar', [
          DymDeliveryPill(label: 'Livré en 35 min', zem: DemoImages.zem),
          DymAvatar(image: DemoImages.person('esi'), presenceDot: true),
        ]),
        section('DymSearchBar', [
          SizedBox(
            width: 360,
            child: DymSearchBar(
              hint: 'Cherche tomates, gari…',
              onTap: () {},
              onMic: () {},
              onCamera: () {},
            ),
          ),
        ]),
        section('DymProductCard · « + » ↔ compteur', [
          SizedBox(
            width: 180,
            height: 250,
            child: DymProductCard(
              image: DemoImages.product('tomates'),
              name: 'Tomates fraîches',
              unit: 'le tas',
              price: price,
              quantity: _quantity,
              onQuantityChanged: (q) => setState(() => _quantity = q),
            ),
          ),
          SizedBox(
            width: 92,
            child: DymProductCard(
              layout: DymProductCardLayout.compact,
              image: DemoImages.product('gari'),
              name: 'Gari',
              unit: 'la boîte',
              price: Money(600, Currency.xof),
              onQuantityChanged: (_) {},
            ),
          ),
        ]),
        section('DymMiniCartBar (touche + / −)', [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () =>
                    setState(() => _items = (_items - 1).clamp(0, 99)),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                onPressed: () => setState(() => _items++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          SizedBox(
            width: 380,
            height: 72,
            child: DymMiniCartBar(
              itemCount: _items,
              total: price * _items,
              summary: '$_items articles · ${(price * _items).format()}',
              actionLabel: 'Voir le panier',
              thumbnail: DemoImages.basket,
              onTap: () {},
            ),
          ),
        ]),
        section('DymStoreCard · DymAisleTile', [
          SizedBox(
            height: 236,
            child: DymStoreCard(
              cover: DemoImages.store('cour-esi'),
              avatar: DemoImages.person('esi'),
              name: "Les jus d'Esi",
              origin: StoreOrigin.maison,
              originLabel: 'Fait maison',
              meta: 'Tokoin · 1,1 km',
            ),
          ),
          SizedBox(
            width: 96,
            height: 118,
            child: DymAisleTile(
              image: DemoImages.aisle('legumes'),
              label: 'Légumes',
              tint: c.tintVertTendre,
            ),
          ),
        ]),
        section('DymFreeDeliveryGauge · DymPaymentOption', [
          const SizedBox(
            width: 360,
            child: DymFreeDeliveryGauge(
              lead: 'Plus que',
              amount: '600 F CFA',
              trail: 'pour la livraison offerte',
              progress: 0.85,
            ),
          ),
          SizedBox(
            width: 200,
            child: DymPaymentOption(
              icon: Icons.payments_outlined,
              title: 'Cash à la livraison',
              selected: _selected,
              onTap: () => setState(() => _selected = true),
            ),
          ),
          SizedBox(
            width: 200,
            child: DymPaymentOption(
              icon: Icons.phone_android_rounded,
              title: 'Mobile Money',
              subtitle: 'T-Money, Flooz',
              selected: !_selected,
              onTap: () => setState(() => _selected = false),
            ),
          ),
        ]),
        section('DymTimeline', [
          const SizedBox(
            width: 360,
            child: DymTimeline(
              steps: [
                DymStep('Confirmée', DymStepState.done),
                DymStep('Préparée', DymStepState.done),
                DymStep('En route', DymStepState.current),
                DymStep('Livrée', DymStepState.todo),
              ],
            ),
          ),
        ]),
        section('DymSelectableCard', [
          SizedBox(
            width: 360,
            child: DymSelectableCard(
              image: DemoImages.store('cour-esi'),
              title: 'Depuis chez moi',
              description: 'Tu prépares ou vends depuis ta maison.',
              selected: true,
              onTap: () {},
            ),
          ),
        ]),
        section('DymStateView', [
          for (final (kind, title, message, action) in const [
            (
              DymStateKind.empty,
              'Ton panier est vide',
              'Ajoute des produits '
                  'depuis les rayons.',
              'Voir les rayons',
            ),
            (
              DymStateKind.error,
              'Impossible de charger',
              'Vérifie ta '
                  'connexion puis réessaie.',
              'Réessayer',
            ),
            (
              DymStateKind.offline,
              'Tu es hors ligne',
              'Tes paniers sont '
                  'gardés ; on reprend dès le retour du réseau.',
              null,
            ),
          ])
            SizedBox(
              width: 300,
              child: DymStateView(
                kind: kind,
                title: title,
                message: message,
                actionLabel: action,
                onAction: action == null ? null : () {},
              ),
            ),
        ]),
        section('DymBottomNav', [
          SizedBox(
            width: 380,
            child: DymBottomNav(
              currentIndex: 0,
              onTap: (_) {},
              items: const [
                DymNavItem(icon: Icons.home_rounded, label: 'Accueil'),
                DymNavItem(icon: Icons.grid_view_rounded, label: 'Rayons'),
                DymNavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Commandes',
                ),
                DymNavItem(icon: Icons.person_outline_rounded, label: 'Moi'),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}
