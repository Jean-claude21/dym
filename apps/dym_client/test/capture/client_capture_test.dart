@Tags(['golden'])
library;

import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/features/cart/cart/cart_view.dart';
import 'package:dym_client/features/orders/testing.dart';
import 'package:dym_client/ui/navigation.dart';
import 'package:dym_client/ui/views/home/home_view.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cart_fixtures.dart';
import '../support/discovery_fixtures.dart';
import 'capture.dart';

/// Captures de contrôle de la cliente (design « Épuré ») : 412 × 915, ×2.
class _Auth implements AuthService {
  @override
  AccountApp get app => AccountApp.client;

  @override
  String? get email => 'awa.mensah@gmail.com';

  @override
  Me? me = const Me(
    userId: 'u1',
    roles: {UserRole.client},
    profile: Profile(
      userId: 'u1',
      firstName: 'Awa',
      countryCode: 'TG',
      locale: 'fr',
      zoneId: 'z',
    ),
  );

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Nav implements AppNavigator {
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

MemoryOrdersService _orders() => MemoryOrdersService(
  config: togoConfig(),
  orders: [
    copyOrder(
      CustomerOrder(
        id: 'o1',
        purchaseId: 'pu-o1',
        status: OrderStatus.pending,
        fulfillment: Fulfillment.delivery,
        createdAt: DateTime.utc(2026, 11, 11, 10),
        currencyCode: 'XOF',
        totalMinor: 3450,
        subtotalMinor: 2950,
        deliveryFeeMinor: 500,
        itemCount: 1,
        etaAt: DateTime.utc(2026, 11, 11, 12, 40),
        store: const OrderStoreRef(
          id: 's1',
          name: 'Chez Fatou',
          origin: 'magasin',
        ),
      ),
      status: OrderStatus.preparing,
    ),
  ],
);

void main() {
  HomeView home(ClientTab tab) => HomeView(
    service: _Auth(),
    discovery: memoryDiscovery(photos: capturePhoto),
    navigator: _Nav(),
    orders: _orders(),
    initialTab: tab,
  );

  testWidgets('accueil', (t) => capture(t, 'accueil', home(ClientTab.home)));
  testWidgets('marché', (t) => capture(t, 'marche', home(ClientTab.market)));
  testWidgets('moi', (t) => capture(t, 'moi', home(ClientTab.me)));
  testWidgets('panier bas', (t) async {
    await capture(
      t,
      'panier_bas',
      CartPageView(
        service: memoryCart(),
        onDelivery: () {},
        onOrdered: (_) {},
        onBrowse: () {},
      ),
      scroll: 900,
    );
  });
  testWidgets('panier', (t) async {
    await capture(
      t,
      'panier',
      CartPageView(
        service: memoryCart(),
        onDelivery: () {},
        onOrdered: (_) {},
        onBrowse: () {},
      ),
    );
  });
}
