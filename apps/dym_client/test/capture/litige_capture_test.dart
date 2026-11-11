// Fakes repris des tests d'écran : certaines aides n'y servent pas.
// ignore_for_file: unused_element
@Tags(['golden'])
library;

import 'package:dym_client/features/orders/disputes_views.dart';
import 'package:dym_client/features/orders/testing.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/discovery_fixtures.dart';
import 'capture.dart';

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
];

final _cash = PaymentMethod.fromJson(const {
  'id': 'cash',
  'country_code': 'TG',
  'provider_code': 'cash',
  'label': {'fr': 'Cash à la livraison', 'en': 'Cash on delivery'},
});

CustomerOrder _order(
  String id,
  OrderStatus status, {
  Fulfillment mode = Fulfillment.delivery,
  String store = "Les jus d'Esi",
}) => copyOrder(
  CustomerOrder(
    id: id,
    purchaseId: 'pu-$id',
    status: OrderStatus.pending,
    fulfillment: mode,
    createdAt: DateTime.utc(2026, 10, 5, 10),
    currencyCode: 'XOF',
    totalMinor: 2300,
    subtotalMinor: 1800,
    deliveryFeeMinor: 500,
    itemCount: 2,
    etaAt: DateTime.utc(2026, 10, 5, 11, 30),
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
          occurredAt: DateTime.utc(2026, 10, 5, 10, 5),
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
      readAt: read ? DateTime.utc(2026, 10, 5, 9) : null,
      createdAt: DateTime.utc(2026, 10, 5, 10, 50),
    );

MemoryOrdersService _service() => MemoryOrdersService(
  config: togoConfig(),
  orders: [
    _order('o1', OrderStatus.preparing),
    _order('o2', OrderStatus.accepted, store: "Étal d'Akossiwa"),
    _order('o3', OrderStatus.delivered, store: "Étal d'Akossiwa"),
    _order('o4', OrderStatus.cancelled, store: 'Chez Afi'),
  ],
  notifications: [
    _notif('n1', 'payment_succeeded'),
    _notif('n2', 'order_preparing'),
    _notif('n3', 'order_delivered', read: true),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(412, 915),
  Locale locale = const Locale('fr'),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: locale,
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Dispute seeded(String orderId, {String status = 'open'}) => Dispute(
  id: 'd-$orderId',
  orderId: orderId,
  reason: DisputeReason.missingItem,
  description: 'Il manquait le gombo.',
  status: status,
  createdAt: DateTime.utc(2026, 10, 5, 10, 40),
  currencyCode: 'XOF',
  storeName: "Étal d'Akossiwa",
  resolution: status == 'open' ? null : DisputeResolution.partialRefund,
  refundMinor: status == 'open' ? null : 300,
  messages: [
    DisputeMessage(
      id: 'm0',
      authorRole: 'client',
      body: 'Il manquait le gombo.',
      createdAt: DateTime.utc(2026, 10, 5, 10, 40),
    ),
    DisputeMessage(
      id: 'm1',
      authorRole: 'vendor',
      body: 'Pardon, je vous rembourse.',
      createdAt: DateTime.utc(2026, 10, 5, 10, 50),
    ),
    if (status != 'open')
      DisputeMessage(
        id: 'm2',
        authorRole: 'admin',
        body: 'Remboursement décidé.',
        createdAt: DateTime.utc(2026, 10, 5, 10, 55),
      ),
  ],
);

void main() {
  testWidgets('litige', (tester) async {
    final service = _service()..seedDispute(seeded('o3'));
    await capture(
      tester,
      'litige',
      DisputeView(
        service: service,
        orderId: 'o3',
        onBack: () {},
        clock: () => DateTime.utc(2026, 10, 5, 11),
      ),
    );
  });
}
