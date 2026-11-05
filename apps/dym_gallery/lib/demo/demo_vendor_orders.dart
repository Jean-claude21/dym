import 'package:dym_core/dym_core.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/demo/demo_store.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/orders/testing.dart';

/// Commandes de démonstration de la vendeuse (écrans 41, 42 et 51).
abstract final class DemoVendorOrders {
  static PaymentMethod _method(DemoCountry c, {required bool cash}) =>
      PaymentMethod.fromJson({
        'id': cash ? 'cash' : 'sim',
        'country_code': c.code,
        'provider_code': cash ? 'cash' : 'simulator',
        'label': cash
            ? const {'fr': 'Cash à la livraison', 'en': 'Cash on delivery'}
            : const {'fr': 'Mobile Money', 'en': 'Mobile Money'},
      });

  static VendorOrder _order(
    DemoCountry c, {
    required String id,
    required String name,
    required int zone,
    required int minutesAgo,
    required List<(String, String, int, int)> lines,
    bool cash = false,
    bool pickup = false,
    OrderStatus status = OrderStatus.pending,
  }) {
    final zones = DemoStore.zoneNames(c);
    final subtotal = lines.fold(0, (sum, l) => sum + l.$3 * l.$4);
    final fee = pickup ? 0 : 500;
    final created = DateTime.utc(
      2026,
      10,
      5,
      10,
      47,
    ).subtract(Duration(minutes: minutesAgo));
    int minor(int xof) => c.price(xof).amountMinor;
    return VendorOrder(
      id: id,
      createdAt: created,
      status: status,
      fulfillment: pickup ? Fulfillment.pickup : Fulfillment.delivery,
      currencyCode: c.currency.code,
      subtotalMinor: minor(subtotal),
      deliveryFeeMinor: minor(fee),
      totalMinor: minor(subtotal + fee),
      itemCount: lines.fold(0, (sum, l) => sum + l.$4),
      customerFirstName: name,
      zoneName: pickup ? null : zones[zone],
      paymentStatus: cash ? PaymentStatus.cashOnDelivery : PaymentStatus.paid,
      paymentMethod: _method(c, cash: cash),
      items: [
        for (final (i, (n, unit, price, q)) in lines.indexed)
          OrderLine(
            productId: 'p$i',
            variantId: 'v$i',
            name: n,
            unitLabel: LocalizedText({'fr': unit, 'en': unit}),
            unitPriceMinor: minor(price),
            quantity: q,
            amountMinor: minor(price * q),
          ),
      ],
      delivery: pickup
          ? null
          : VendorOrderDelivery(
              zoneName: zones[zone],
              cityName: c.city.split(',').last.trim(),
              landmark: 'Portail bleu après la pharmacie',
              phone: c.code == 'GH' ? '+233 20 000 0000' : '+228 90 00 00 00',
            ),
      payment: cash
          ? null
          : VendorOrderPayment(
              status: PaymentAttemptStatus.succeeded,
              providerCode: 'simulator',
              amountMinor: minor(subtotal + fee),
              reference: 'PA-7K2Q0${id.length}',
              completedAt: created.add(const Duration(minutes: 1)),
            ),
    );
  }

  static MemoryOrdersService service(DemoCountry c) => MemoryOrdersService(
    config: DemoStore.config(c),
    orders: [
      _order(
        c,
        id: 'o1',
        name: 'Awa',
        zone: 1,
        minutesAgo: 5,
        lines: const [
          ('Tomates fraîches', 'le tas', 500, 2),
          ('Gombo frais', 'le tas', 300, 1),
        ],
      ),
      _order(
        c,
        id: 'o2',
        name: 'Kossi',
        zone: 0,
        minutesAgo: 12,
        cash: true,
        pickup: true,
        lines: const [('Bissap', '1 L', 700, 1)],
      ),
      _order(
        c,
        id: 'o3',
        name: 'Mawuli',
        status: OrderStatus.accepted,
        zone: 2,
        minutesAgo: 40,
        lines: const [
          ('Piment frais', 'le tas', 400, 2),
          ('Gingembre', '1 L', 700, 1),
        ],
      ),
    ],
  );

  /// Commande livrée hier avec un problème signalé (écran 51).
  static MemoryOrdersService disputed(DemoCountry c) =>
      MemoryOrdersService(
        config: DemoStore.config(c),
        orders: [
          _order(
            c,
            id: 'o5',
            name: 'Awa',
            status: OrderStatus.delivered,
            zone: 1,
            minutesAgo: 60 * 24,
            lines: const [
              ('Tomates fraîches', 'le tas', 500, 2),
              ('Gombo frais', 'le tas', 300, 1),
            ],
          ),
        ],
      )..seedDispute(
        Dispute(
          id: 'd1',
          orderId: 'o5',
          reason: DisputeReason.missingItem,
          description: 'Il manquait le gombo dans le sac.',
          status: 'open',
          createdAt: DateTime.utc(2026, 10, 5, 9),
          currencyCode: c.currency.code,
          customerFirstName: 'Awa',
          messages: [
            DisputeMessage(
              id: 'm0',
              authorRole: 'client',
              body: 'Il manquait le gombo dans le sac.',
              createdAt: DateTime.utc(2026, 10, 5, 9),
            ),
          ],
        ),
      );
}
