@Tags(['golden'])
library;

import 'package:dym_client/features/cart/addresses/addresses_view.dart';
import 'package:dym_client/features/cart/delivery/delivery_view.dart';
import 'package:dym_client/features/cart/sent/order_sent_view.dart';
import 'package:dym_client/features/discovery/aisle/aisle_view.dart';
import 'package:dym_client/features/discovery/product/product_page_view.dart';
import 'package:dym_client/features/discovery/search/search_view.dart';
import 'package:dym_client/features/discovery/store/store_page_view.dart';
import 'package:dym_client/features/favorites/favorites_views.dart';
import 'package:dym_client/features/favorites/testing.dart';
import 'package:dym_client/features/orders/orders_views.dart';
import 'package:dym_client/features/orders/testing.dart';
import 'package:dym_client/features/spaces/spaces_views.dart';
import 'package:dym_client/features/spaces/testing.dart';
import 'package:dym_client/features/wallet/testing.dart';
import 'package:dym_client/features/wallet/wallet_view.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cart_fixtures.dart';
import '../support/discovery_fixtures.dart';
import 'capture.dart';

final _cash = PaymentMethod.fromJson(const {
  'id': 'cash',
  'country_code': 'TG',
  'provider_code': 'cash',
  'label': {'fr': 'Cash à la livraison', 'en': 'Cash on delivery'},
});

CustomerOrder _order(String id, OrderStatus status, String store) => copyOrder(
  CustomerOrder(
    id: id,
    purchaseId: 'pu-$id',
    status: OrderStatus.pending,
    fulfillment: Fulfillment.delivery,
    createdAt: DateTime.utc(2026, 11, 10, 10),
    currencyCode: 'XOF',
    totalMinor: 2300,
    subtotalMinor: 1800,
    deliveryFeeMinor: 500,
    itemCount: 2,
    etaAt: DateTime.utc(2026, 11, 10, 11, 30),
    store: OrderStoreRef(id: 's-$id', name: store, origin: 'maison'),
    paymentMethod: _cash,
    items: const [
      OrderLine(
        productId: 'p1',
        variantId: 'v1',
        name: 'Bissap',
        unitPriceMinor: 900,
        quantity: 2,
        amountMinor: 1800,
      ),
    ],
    history: [
      if (status != OrderStatus.pending)
        OrderStatusEvent(
          toStatus: OrderStatus.accepted,
          actorRole: 'vendor',
          occurredAt: DateTime.utc(2026, 11, 10, 10, 5),
        ),
    ],
  ),
  status: status,
);

AppNotification _notif(String id, String kind, {bool read = false}) =>
    AppNotification(
      id: id,
      kind: kind,
      category: kind.startsWith('payment')
          ? NotificationCategory.payments
          : NotificationCategory.orders,
      orderId: 'o1',
      params: const {'store_name': "Les jus d'Esi"},
      readAt: read ? DateTime.utc(2026, 11, 10, 9) : null,
      createdAt: DateTime.utc(2026, 11, 10, 10, 50),
    );

MemoryOrdersService _orders() => MemoryOrdersService(
  config: togoConfig(),
  orders: [
    _order('o1', OrderStatus.preparing, "Les jus d'Esi"),
    _order('o2', OrderStatus.accepted, "Étal d'Akossiwa"),
    _order('o3', OrderStatus.delivered, "Étal d'Akossiwa"),
    _order('o4', OrderStatus.cancelled, 'Chez Afi'),
  ],
  notifications: [
    _notif('n1', 'payment_succeeded'),
    _notif('n2', 'order_preparing'),
    _notif('n3', 'order_delivered', read: true),
  ],
);

void _noop() {}

void main() {
  testWidgets('rayon', (t) async {
    await capture(
      t,
      'rayon',
      AisleView(
        service: memoryDiscovery(photos: capturePhoto),
        categoryId: 'legumes',
        onBack: _noop,
        onSearch: _noop,
        onOpenProduct: (_) {},
      ),
    );
  });
  testWidgets('boutique', (t) async {
    await capture(
      t,
      'boutique',
      StorePageView(
        service: memoryDiscovery(photos: capturePhoto),
        storeId: 'esi',
        onBack: _noop,
        onOpenProduct: (_) {},
      ),
    );
  });
  testWidgets('produit', (t) async {
    await capture(
      t,
      'produit',
      ProductPageView(
        service: memoryDiscovery(photos: capturePhoto),
        productId: 'bissap',
        onBack: _noop,
        onOpenStore: (_) {},
      ),
    );
  });
  testWidgets('recherche', (t) async {
    await capture(
      t,
      'recherche',
      SearchView(
        service: memoryDiscovery(photos: capturePhoto),
        onBack: _noop,
        onOpenProduct: (_) {},
        onOpenStore: (_) {},
        debounce: Duration.zero,
      ),
    );
  });
  testWidgets('livraison', (t) async {
    await capture(
      t,
      'livraison',
      DeliveryView(
        service: memoryCart(),
        onBack: _noop,
        onAddAddress: () async => false,
      ),
    );
  });
  testWidgets('adresses', (t) async {
    await capture(
      t,
      'adresses',
      AddressesView(
        service: memoryCart(),
        onBack: _noop,
        onEdit: (_) async => false,
      ),
    );
  });
  testWidgets('commande envoyée', (t) async {
    final purchase = (await memoryCart().placeOrder()).valueOrNull!;
    await capture(
      t,
      'commande_envoyee',
      OrderSentView(service: memoryCart(), purchase: purchase, onHome: _noop),
    );
  });
  testWidgets('mes commandes', (t) async {
    await capture(
      t,
      'mes_commandes',
      MyOrdersView(
        service: _orders(),
        onOpen: (_) {},
        onNotifications: _noop,
        onBack: _noop,
      ),
    );
  });
  testWidgets('suivi', (t) async {
    await capture(
      t,
      'suivi',
      TrackingView(service: _orders(), orderId: 'o1', onBack: _noop),
    );
  });
  testWidgets('notifications', (t) async {
    await capture(
      t,
      'notifications',
      NotificationsView(
        service: _orders(),
        onBack: _noop,
        onOpenOrder: (_) {},
        clock: () => DateTime.utc(2026, 11, 10, 11),
      ),
    );
  });
  testWidgets('wallet', (t) async {
    await capture(
      t,
      'wallet',
      WalletView(
        service: MemoryWalletService(config: togoConfig(), balanceMinor: 12500),
        onBack: _noop,
      ),
    );
  });
  testWidgets('favoris', (t) async {
    await capture(
      t,
      'favoris',
      FavoritesView(
        service: MemoryFavoritesService(),
        discovery: memoryDiscovery(photos: capturePhoto),
        onBack: _noop,
        onOpenStore: (_) {},
        onOpenProduct: (_) {},
      ),
    );
  });
  testWidgets('espaces', (t) async {
    await capture(
      t,
      'espaces',
      SpacesView(
        service: MemorySpacesService(
          discovery: memoryDiscovery(photos: capturePhoto),
        ),
        onBack: _noop,
        onOpen: (_) async {},
      ),
    );
  });
}
