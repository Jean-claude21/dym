import 'package:dym_client/features/discovery/testing.dart';
import 'package:dym_client/features/orders/orders_viewmodels.dart';
import 'package:dym_client/features/orders/orders_views.dart';
import 'package:dym_client/features/orders/testing.dart';
import 'package:dym_client/features/reviews/review_views.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

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

CustomerOrder _order(String id, OrderStatus status) => copyOrder(
  CustomerOrder(
    id: id,
    purchaseId: 'pu-$id',
    status: OrderStatus.pending,
    fulfillment: Fulfillment.delivery,
    createdAt: DateTime.utc(2026, 10, 5, 10),
    currencyCode: 'XOF',
    totalMinor: 2300,
    subtotalMinor: 1800,
    deliveryFeeMinor: 500,
    itemCount: 2,
    store: const OrderStoreRef(id: 's1', name: "Étal d'Akossiwa"),
    paymentMethod: _cash,
  ),
  status: status,
);

MemoryOrdersService _orders() => MemoryOrdersService(
  config: togoConfig(),
  orders: [
    _order('o1', OrderStatus.delivered),
    _order('o2', OrderStatus.preparing),
  ],
);

final _reviews = StoreReviews(
  rating: 4.5,
  reviewCount: 2,
  distribution: const {'5': 1, '4': 1},
  reviews: [
    Review(
      id: 'r1',
      orderId: 'o1',
      storeId: 'kodjo',
      rating: 5,
      tags: const [ReviewTag.fresh],
      comment: 'Les tomates étaient très fraîches, merci !',
      reply: 'Merci Awa, à bientôt !',
      authorFirstName: 'Awa',
      createdAt: DateTime.utc(2026, 10, 3, 10),
    ),
    Review(
      id: 'r2',
      orderId: 'o9',
      storeId: 'kodjo',
      rating: 4,
      comment: 'Bon gombo, livraison un peu longue.',
      authorFirstName: 'Kossi',
      createdAt: DateTime.utc(2026, 9, 30, 10),
    ),
  ],
);

MemoryDiscoveryService _discovery() => MemoryDiscoveryService(
  config: togoConfig(),
  stores: [kodjo],
  reviews: {kodjo.id: _reviews},
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
  test('avis : note exigée, étiquettes, un seul avis', () async {
    final service = _orders();
    final sent = <Review>[];
    final vm = ReviewFormViewModel(
      service: service,
      orderId: 'o1',
      onSent: sent.add,
    );
    expect(vm.canSend, isFalse);
    vm
      ..setRating(4)
      ..toggle(ReviewTag.fresh)
      ..toggle(ReviewTag.fast)
      ..toggle(ReviewTag.fast)
      ..comment = ' Très frais ';
    await vm.send();
    expect(sent.single.rating, 4);
    expect(sent.single.tags, [ReviewTag.fresh]);
    expect(sent.single.comment, 'Très frais');
    final again = ReviewFormViewModel(
      service: service,
      orderId: 'o1',
      onSent: sent.add,
    )..setRating(5);
    await again.send();
    expect(again.failure, const ValidationFailure('review_exists'));
  });

  test('suivi : avis possible après livraison, puis réachat', () async {
    final service = _orders()..reorderSkipped = const ['Gombo'];
    final vm = TrackingViewModel(service: service, orderId: 'o1');
    await vm.load();
    expect(vm.canReview, isTrue);
    expect(vm.canReorder, isTrue);
    expect(await vm.reorder(), isTrue);
    expect(vm.reordered?.skipped, ['Gombo']);
    expect(service.reorders, ['o1']);
    vm.dispose();
    final active = TrackingViewModel(service: service, orderId: 'o2');
    await active.load();
    expect(active.canReview, isFalse);
    expect(active.canReorder, isFalse);
    active.dispose();
  });

  group('écrans 63 et 64 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        Future<void> show(WidgetTester tester, Widget view) async {
          await _pump(tester, view, size: size, locale: locale, textScale: 1.3);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }

        testWidgets('63 · $name', (tester) async {
          await show(
            tester,
            ReviewFormView(
              service: _orders(),
              orderId: 'o1',
              storeName: "Étal d'Akossiwa",
              onBack: () {},
              onSent: (_) {},
            ),
          );
        });
        testWidgets('64 · $name', (tester) async {
          await show(
            tester,
            StoreReviewsView(
              service: _discovery(),
              storeId: kodjo.id,
              storeName: kodjo.name,
              onBack: () {},
              onMessage: () {},
              clock: () => DateTime.utc(2026, 10, 5, 11),
            ),
          );
        });
        testWidgets('06 livrée · $name', (tester) async {
          await show(
            tester,
            TrackingView(
              service: _orders(),
              orderId: 'o1',
              onBack: () {},
              onReview: (_, _) async => true,
              onReordered: () {},
            ),
          );
        });
      }
    }
  });

  testWidgets('63 : étoiles, étiquette, publier', (tester) async {
    final sent = <Review>[];
    await _pump(
      tester,
      ReviewFormView(
        service: _orders(),
        orderId: 'o1',
        storeName: "Étal d'Akossiwa",
        onBack: () {},
        onSent: sent.add,
      ),
    );
    await tester.tap(find.byTooltip('4 étoiles'));
    await tester.pump();
    await tester.tap(find.text('Produits frais'));
    await tester.pump();
    await tester.tap(find.text('Publier mon avis'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(sent.single.rating, 4);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('06 : donner son avis et commander à nouveau', (tester) async {
    final reviewed = <String>[];
    var reordered = 0;
    await _pump(
      tester,
      TrackingView(
        service: _orders(),
        orderId: 'o1',
        onBack: () {},
        onReview: (id, _) async {
          reviewed.add(id);
          return false;
        },
        onReordered: () => reordered++,
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Donner mon avis'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Donner mon avis'));
    await tester.pump();
    expect(reviewed, ['o1']);
    await tester.scrollUntilVisible(
      find.text('Commander à nouveau'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Commander à nouveau'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(reordered, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('64 : note, réponse de la boutique', (tester) async {
    await _pump(
      tester,
      StoreReviewsView(
        service: _discovery(),
        storeId: kodjo.id,
        storeName: kodjo.name,
        onBack: () {},
        clock: () => DateTime.utc(2026, 10, 5, 11),
      ),
    );
    expect(find.text('4.5/5'), findsOneWidget);
    expect(find.textContaining('Merci Awa'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
