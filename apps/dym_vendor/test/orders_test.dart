import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/orders/orders_viewmodels.dart';
import 'package:dym_vendor/features/orders/orders_views.dart';
import 'package:dym_vendor/features/orders/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/store_fixtures.dart';

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
];

final _momo = PaymentMethod.fromJson(const {
  'id': 'sim',
  'country_code': 'TG',
  'provider_code': 'simulator',
  'label': {'fr': 'Mobile Money (simulé)', 'en': 'Mobile Money (simulated)'},
});
final _cash = PaymentMethod.fromJson(const {
  'id': 'cash',
  'country_code': 'TG',
  'provider_code': 'cash',
  'label': {'fr': 'Cash à la livraison', 'en': 'Cash on delivery'},
});

VendorOrder order(String id, {bool paid = true, String name = 'Awa'}) =>
    VendorOrder(
      id: id,
      createdAt: DateTime.utc(2026, 10, 5, 10, 42),
      status: OrderStatus.pending,
      fulfillment: paid ? Fulfillment.delivery : Fulfillment.pickup,
      currencyCode: 'XOF',
      subtotalMinor: 1300,
      deliveryFeeMinor: paid ? 500 : 0,
      totalMinor: paid ? 1800 : 1300,
      itemCount: 3,
      customerFirstName: name,
      zoneName: paid ? 'Bè' : null,
      paymentStatus: paid ? PaymentStatus.paid : PaymentStatus.cashOnDelivery,
      paymentMethod: paid ? _momo : _cash,
      items: const [
        OrderLine(
          productId: 'p1',
          variantId: 'v1',
          name: 'Tomates fraîches',
          unitLabel: LocalizedText({'fr': 'le tas', 'en': 'per heap'}),
          unitPriceMinor: 500,
          quantity: 2,
          amountMinor: 1000,
        ),
        OrderLine(
          productId: 'p2',
          variantId: 'v2',
          name: 'Gombo frais',
          unitPriceMinor: 300,
          quantity: 1,
          amountMinor: 300,
        ),
      ],
      delivery: paid
          ? const VendorOrderDelivery(
              zoneName: 'Bè',
              cityName: 'Lomé',
              landmark: 'Portail bleu après la pharmacie',
              phone: '+228 90 00 00 00',
            )
          : null,
      payment: paid
          ? VendorOrderPayment(
              status: PaymentAttemptStatus.succeeded,
              providerCode: 'simulator',
              amountMinor: 1800,
              reference: 'PA-7K2Q00',
              completedAt: DateTime.utc(2026, 10, 5, 10, 43),
            )
          : null,
    );

MemoryOrdersService _service([List<VendorOrder>? orders]) =>
    MemoryOrdersService(
      config: togoConfig(),
      orders: orders ?? [order('o1'), order('o2', paid: false, name: 'Kossi')],
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

void main() {
  test('liste : une commande payée apparaît à la relecture', () async {
    final service = _service([order('o2', paid: false)]);
    final vm = OrdersViewModel(
      service: service,
      refreshEvery: const Duration(milliseconds: 10),
    );
    await vm.load();
    expect(vm.orders.single.isPaid, isFalse);
    service.arrive(order('o3'));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(vm.orders.first.id, 'o3', reason: 'sans geste');
    expect(vm.orders.first.isPaid, isTrue);
    vm.dispose();
  });

  test('relecture hors ligne : liste gardée, signalée', () async {
    final service = _service();
    final vm = OrdersViewModel(service: service);
    await vm.load();
    service.failNext = const NetworkFailure('3G');
    await vm.refresh();
    expect(vm.offline, isTrue);
    expect(vm.orders, hasLength(2));
    vm.dispose();
  });

  test('détail : paiement et livraison', () async {
    final vm = OrderDetailViewModel(service: _service(), orderId: 'o1');
    await vm.load();
    expect(vm.order?.payment?.reference, 'PA-7K2Q00');
    expect(vm.order?.delivery?.landmark, 'Portail bleu après la pharmacie');
  });

  group('écrans 41 et 42 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        testWidgets('41 commandes · $name', (tester) async {
          await _pump(
            tester,
            OrdersView(service: _service(), onOpen: (_) {}),
            size: size,
            locale: locale,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
        for (final id in const ['o1', 'o2']) {
          testWidgets('42 détail $id · $name', (tester) async {
            await _pump(
              tester,
              OrderDetailView(service: _service(), orderId: id, onBack: () {}),
              size: size,
              locale: locale,
              textScale: 1.3,
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  testWidgets('41 : badges et ouverture du détail', (tester) async {
    final opened = <String>[];
    await _pump(tester, OrdersView(service: _service(), onOpen: opened.add));
    expect(find.text('Commande de Awa'), findsOneWidget);
    expect(find.text('Paiement confirmé'), findsOneWidget);
    expect(find.text('Cash à la livraison'), findsOneWidget);
    await tester.tap(find.text('Commande de Kossi'));
    expect(opened, ['o2']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('41 : aucune commande', (tester) async {
    await _pump(
      tester,
      OrdersView(service: _service(const []), onOpen: (_) {}),
    );
    expect(find.text("Aucune commande pour l'instant"), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('42 : bandeau, paiement, livraison', (tester) async {
    await _pump(
      tester,
      OrderDetailView(service: _service(), orderId: 'o1', onBack: () {}),
    );
    expect(find.text('Tu peux préparer la commande.'), findsOneWidget);
    expect(find.text('PA-7K2Q00'), findsOneWidget);
    expect(find.textContaining('Portail bleu'), findsOneWidget);
  });
}
