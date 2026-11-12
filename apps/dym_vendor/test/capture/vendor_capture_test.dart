@Tags(['golden'])
library;

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/catalog/products/products_view.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';
import 'package:dym_vendor/features/dashboard/dashboard_view.dart';
import 'package:dym_vendor/features/orders/orders_views.dart';
import 'package:dym_vendor/features/orders/testing.dart';
import 'package:dym_vendor/features/store/my_store/my_store_view.dart';
import 'package:dym_vendor/features/till/qr_charge_view.dart';
import 'package:dym_vendor/features/till/till_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/catalog_fixtures.dart';
import '../support/store_fixtures.dart';

/// Captures de contrôle de la vendeuse (design « Épuré », planche 04).
Future<void> _capture(WidgetTester tester, String name, Widget child) async {
  const size = Size(412, 915);
  tester.view
    ..physicalSize = size * 2
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: 2,
          disableAnimations: true,
          padding: EdgeInsets.only(top: 24, bottom: 16),
        ),
        child: Builder(
          builder: (context) {
            final l10n = DymLocalizations.of(context);
            return DymAdaptiveScaffold(
              currentIndex: 0,
              onDestinationSelected: (_) {},
              destinations: [
                DymNavItem(icon: Icons.today_outlined, label: l10n.navToday),
                DymNavItem(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.navOrders,
                ),
                DymNavItem(
                  icon: Icons.grid_view_outlined,
                  label: l10n.navCatalog,
                ),
                DymNavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: l10n.chatMessagesTitle,
                ),
                DymNavItem(
                  icon: Icons.storefront_outlined,
                  label: l10n.navStore,
                ),
              ],
              body: child,
            );
          },
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 600));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

class _Dashboard implements DashboardService {
  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(togoConfig());

  @override
  Future<Result<VendorDashboard>> summary(DashboardPeriod period) async => Ok(
    VendorDashboard(
      period: period,
      currencyCode: 'XOF',
      revenueMinor: 18450,
      orderCount: 9,
      pendingPayments: 2,
      pendingOrders: 3,
      activeOrders: 2,
      outOfStock: 2,
      criticalNotifications: 0,
    ),
  );

  @override
  Future<Result<int>> unreadMessages() async => const Ok(4);
}

class _Till implements TillService {
  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(togoConfig());

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

VendorOrder _order(String id, String name, int total) => VendorOrder(
  id: id,
  createdAt: DateTime.utc(2026, 11, 11, 12, 15),
  status: OrderStatus.pending,
  fulfillment: Fulfillment.delivery,
  currencyCode: 'XOF',
  subtotalMinor: total - 500,
  deliveryFeeMinor: 500,
  totalMinor: total,
  itemCount: 3,
  customerFirstName: name,
  zoneName: 'Bè',
  paymentStatus: PaymentStatus.cashOnDelivery,
  paymentMethod: PaymentMethod.fromJson(const {
    'id': 'cash',
    'country_code': 'TG',
    'provider_code': 'cash',
    'label': {'fr': 'Cash à la livraison'},
  }),
  items: const [
    OrderLine(
      productId: 'p1',
      variantId: 'v1',
      name: 'Tomates',
      unitLabel: LocalizedText({'fr': '2 kg'}),
      unitPriceMinor: 600,
      quantity: 2,
      amountMinor: 1200,
    ),
    OrderLine(
      productId: 'p2',
      variantId: 'v2',
      name: 'Oignons',
      unitLabel: LocalizedText({'fr': '1 kg'}),
      unitPriceMinor: 750,
      quantity: 1,
      amountMinor: 750,
    ),
  ],
  delivery: const VendorOrderDelivery(
    zoneName: 'Bè',
    cityName: 'Lomé',
    landmark: 'Portail bleu après la pharmacie',
    phone: '+228 90 00 00 00',
  ),
);

MemoryOrdersService _orders() => MemoryOrdersService(
  config: togoConfig(),
  orders: [_order('o1', 'Awa', 3450), _order('o2', 'Mariama', 2500)],
);

void main() {
  testWidgets('aujourdhui', (t) async {
    await _capture(
      t,
      'aujourdhui',
      DashboardView(
        service: _Dashboard(),
        greeting: 'Bonjour Fatou',
        onOrders: () {},
        onProducts: () {},
        onMessages: () {},
        onCharge: () {},
        onTill: () {},
      ),
    );
  });
  testWidgets('commandes', (t) async {
    await _capture(
      t,
      'commandes',
      OrdersView(service: _orders(), onOpen: (_) {}),
    );
  });
  testWidgets('commande', (t) async {
    await _capture(
      t,
      'commande',
      OrderDetailView(service: _orders(), orderId: 'o1', onBack: () {}),
    );
  });
  testWidgets('catalogue', (t) async {
    await _capture(
      t,
      'catalogue',
      ProductsView(
        service: memoryCatalog(),
        onEdit: (_) async {},
        onCategories: () async {},
      ),
    );
  });
  testWidgets('boutique', (t) async {
    await _capture(
      t,
      'boutique',
      MyStoreView(
        service: memoryStores(initial: openStore()),
        onEdit: (_) async {},
        onTill: () {},
        onCredit: () {},
        onCourierCash: () {},
        onHaggling: () {},
        onGroupOffers: () {},
        onReviews: () {},
        onAccount: () {},
      ),
    );
  });
  testWidgets('encaisser', (t) async {
    await _capture(
      t,
      'encaisser',
      QrChargeView(service: _Till(), onDone: () {}),
    );
  });
}
