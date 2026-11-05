import 'package:dym_client/features/orders/testing.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/demo/demo_store.dart';
import 'package:dym_models/dym_models.dart';

/// Commandes et notifications de démonstration de la cliente (43, 44, 46, 47).
abstract final class DemoClientOrders {
  static final now = DateTime.utc(2026, 10, 5, 11);

  static CustomerOrder _order(
    DemoCountry c, {
    required String id,
    required String store,
    required String origin,
    required OrderStatus status,
    required int xof,
    required int items,
    Fulfillment mode = Fulfillment.delivery,
    int daysAgo = 0,
  }) {
    final created = now.subtract(Duration(days: daysAgo, minutes: 40));
    return copyOrder(
      CustomerOrder(
        id: id,
        purchaseId: 'pu-$id',
        status: OrderStatus.pending,
        fulfillment: mode,
        createdAt: created,
        currencyCode: c.currency.code,
        totalMinor: c.price(xof).amountMinor,
        subtotalMinor: c.price(xof - 500).amountMinor,
        deliveryFeeMinor: c.price(500).amountMinor,
        itemCount: items,
        etaAt: created.add(const Duration(minutes: 50)),
        store: OrderStoreRef(id: 's-$id', name: store, origin: origin),
        paymentMethod: PaymentMethod.fromJson({
          'id': 'cash',
          'country_code': c.code,
          'provider_code': 'cash',
          'label': const {
            'fr': 'Cash à la livraison',
            'en': 'Cash on delivery',
          },
        }),
        items: [
          OrderLine(
            productId: 'p-$id',
            variantId: 'v-$id',
            name: 'Bissap',
            variantLabel: '1 L',
            unitPriceMinor: c.price(700).amountMinor,
            quantity: 2,
            amountMinor: c.price(1400).amountMinor,
          ),
        ],
        history: [
          if (status != OrderStatus.pending)
            OrderStatusEvent(
              toStatus: OrderStatus.accepted,
              actorRole: 'vendor',
              occurredAt: created.add(const Duration(minutes: 3)),
            ),
        ],
      ),
      status: status,
    );
  }

  static List<CustomerOrder> orders(DemoCountry c) => [
    _order(
      c,
      id: 'o1',
      store: "Les jus d'Esi",
      origin: 'maison',
      status: OrderStatus.preparing,
      xof: 2300,
      items: 2,
    ),
    _order(
      c,
      id: 'o2',
      store: "Étal d'Akossiwa",
      origin: 'marche',
      status: OrderStatus.accepted,
      xof: 1800,
      items: 3,
    ),
    _order(
      c,
      id: 'o3',
      store: "Étal d'Akossiwa",
      origin: 'marche',
      status: OrderStatus.delivered,
      xof: 2600,
      items: 4,
      daysAgo: 4,
    ),
    _order(
      c,
      id: 'o4',
      store: 'Chez Afi',
      origin: 'magasin',
      status: OrderStatus.cancelled,
      xof: 700,
      items: 1,
      daysAgo: 7,
    ),
  ];

  static List<AppNotification> notifications() => [
    for (final (i, (kind, minutes, read)) in const [
      ('payment_succeeded', 2, false),
      ('order_preparing', 10, false),
      ('order_out_for_delivery', 60 * 22, false),
      ('order_delivered', 60 * 26, true),
    ].indexed)
      AppNotification(
        id: 'n$i',
        kind: kind,
        category: kind.startsWith('payment')
            ? NotificationCategory.payments
            : NotificationCategory.orders,
        orderId: 'o1',
        params: const {'store_name': "Les jus d'Esi"},
        readAt: read ? now : null,
        createdAt: now.subtract(Duration(minutes: minutes)),
      ),
  ];

  static MemoryOrdersService service(DemoCountry c) => MemoryOrdersService(
    config: DemoStore.config(c),
    orders: orders(c),
    notifications: notifications(),
  );
}
