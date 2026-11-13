import 'package:dym_core/dym_core.dart';
import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_catalog.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/screens/common.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Panier de l'écran validé : 3 400 F + 700 F de livraison = 4 100 F.
abstract final class DemoCartScreenData {
  static const lines = <String, int>{
    'tomates': 2,
    'gombo': 1,
    'bissap': 2,
    'gingembre': 1,
  };
  static const deliveryXof = 700;
  static const freeDeliveryThresholdXof = 4000;

  static Money subtotal(DemoCountry c) => lines.entries.fold(
    Money.zero(c.currency),
    (sum, e) => sum + c.price(DemoCatalog.products[e.key]!.priceXof) * e.value,
  );

  static Money delivery(DemoCountry c) => c.price(deliveryXof);

  static Money total(DemoCountry c) => subtotal(c) + delivery(c);
}

/// Écran 05 — Panier multi-boutiques.
class CartScreen extends StatefulWidget {
  const new({required this.country, super.key});

  final DemoCountry country;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _quantities = Map<String, int>.of(DemoCartScreenData.lines);
  bool _replace = true;
  bool _cash = true;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final country = widget.country;
    final subtotal = _quantities.entries.fold(
      Money.zero(country.currency),
      (sum, e) =>
          sum + country.price(DemoCatalog.products[e.key]!.priceXof) * e.value,
    );
    final delivery = DemoCartScreenData.delivery(country);
    final threshold = country.price(
      DemoCartScreenData.freeDeliveryThresholdXof,
    );
    final remaining = threshold - subtotal;
    final total = subtotal + delivery;
    final count = _quantities.values.fold(0, (a, b) => a + b);

    final items = <Widget>[
      DymFreeDeliveryGauge(
        lead: 'Plus que',
        amount: remaining.format(),
        trail: 'pour la livraison offerte',
        progress: subtotal.amountMinor / threshold.amountMinor,
      ),
      const SizedBox(height: 12),
      _storeGroup('akossiwa', ['tomates', 'gombo']),
      const SizedBox(height: 12),
      _storeGroup('esi', ['bissap', 'gingembre']),
      const SizedBox(height: 12),
      WhiteCard(
        child: Row(
          children: [
            Icon(Icons.sync_rounded, color: c.brand, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Si un produit manque',
                    style: t.label.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'La boutique propose un équivalent '
                    'au même prix',
                    style: t.label.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: _replace,
              activeTrackColor: c.brand,
              onChanged: (v) => setState(() => _replace = v),
            ),
          ],
        ),
      ),
    ];
    final summary = <Widget>[
      WhiteCard(
        child: Row(
          children: [
            Image(image: DemoImages.rider, width: 44, height: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Livraison',
                    style: t.label.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '2 ramassages · 40-50 min',
                    style: t.label.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Changer ›',
                style: t.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.brandDeep,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paiement',
              style: t.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DymPaymentOption(
                    title: 'Cash à la livraison',
                    selected: _cash,
                    onTap: () => setState(() => _cash = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DymPaymentOption(
                    title: 'Mobile Money',
                    subtitle: 'T-Money, Flooz',
                    selected: !_cash,
                    onTap: () => setState(() => _cash = false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      WhiteCard(
        child: Column(
          children: [
            _sumRow('Sous-total', subtotal),
            _sumRow('Livraison', delivery),
            const Divider(height: 16),
            _sumRow('Total', total, strong: true),
          ],
        ),
      ),
    ];
    final order = DymButton(
      label: 'Commander · ${total.format()}',
      trailing: const Icon(Icons.chevron_right_rounded),
      onPressed: () {},
    );
    final header = DymContentWidth(
      child: ScreenHeader(
        title: 'Ton panier',
        subtitle: '2 boutiques · $count articles',
      ),
    );

    // Étendue et large : articles à gauche, récapitulatif à droite (FR-009).
    if (DymWindowClass.of(context) >= DymWindowClass.expanded) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final inset = DymLayout.sideInset(
                      box.maxWidth,
                      gutter: DymLayout.gutter(context),
                    );
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: inset),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 16,
                              ),
                              children: items,
                            ),
                          ),
                          const SizedBox(width: DymTokenSpace.s5),
                          SizedBox(
                            width: 400,
                            child: Column(
                              children: [
                                Flexible(
                                  child: ListView(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.only(top: 8),
                                    children: summary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                order,
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              // Téléphone et tablette portrait : une colonne, bornée à la
              // largeur d'un formulaire (identique sur téléphone).
              child: BoundedListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [...items, const SizedBox(height: 12), ...summary],
              ),
            ),
            DymContentWidth.form(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: order,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sumRow(String label, Money value, {bool strong = false}) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? t.title.copyWith(fontSize: 20)
                  : t.label.copyWith(fontSize: 15, color: c.textSecondary),
            ),
          ),
          MoneyText(
            value,
            size: strong ? 22 : 15,
            color: strong ? c.brandDeep : c.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _storeGroup(String storeId, List<String> productIds) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final store = DemoCatalog.stores[storeId]!;
    final country = widget.country;
    return WhiteCard(
      child: Column(
        children: [
          Row(
            children: [
              DymAvatar(image: store.avatar, size: 52, ring: false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name, style: t.title.copyWith(fontSize: 19)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        DymOriginBadge(
                          origin: store.origin,
                          label: originLabel(store.origin),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: c.textSecondary,
                        ),
                        Text(
                          store.area,
                          style: t.label.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final id in productIds) ...[
            const SizedBox(height: 10),
            _line(id, country),
          ],
        ],
      ),
    );
  }

  Widget _line(String id, DemoCountry country) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final p = DemoCatalog.products[id]!;
    final q = _quantities[id] ?? 0;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.tintPeche,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image(image: p.image, fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(p.unit, style: t.label.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
        DymQuantityStepper(
          quantity: q,
          min: 1,
          dense: true,
          onChanged: (v) => setState(() => _quantities[id] = v),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 88,
          child: Align(
            alignment: Alignment.centerRight,
            child: MoneyText(
              country.price(p.priceXof) * q,
              size: 15,
              color: c.brandDeep,
            ),
          ),
        ),
      ],
    );
  }
}
