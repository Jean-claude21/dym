import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/orders/orders_viewmodels.dart';
import 'package:dym_vendor/features/orders/orders_views.dart';
import 'package:dym_vendor/features/orders/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'orders_test.dart' show order;
import 'support/store_fixtures.dart';

MemoryOrdersService _service() => MemoryOrdersService(
  config: togoConfig(),
  orders: [
    order('o1'),
    order('o2', paid: false, name: 'Kossi'),
  ],
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view
    ..physicalSize = const Size(412, 915)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  test('livraison : accepter → préparer → prête → en route → livrée', () async {
    final service = _service();
    final vm = OrderDetailViewModel(service: service, orderId: 'o1');
    await vm.load();
    expect(vm.canRefuse, isTrue);
    for (final step in [
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ]) {
      await vm.advance(step);
      expect(vm.order?.status, step);
    }
    expect(vm.nextStep, isNull);
    expect(service.gestures, hasLength(5));
  });

  test('retrait cash : prête → récupérée → encaissement une fois', () async {
    final service = _service();
    final vm = OrderDetailViewModel(service: service, orderId: 'o2');
    await vm.load();
    await vm.advance(OrderStatus.accepted);
    await vm.advance(OrderStatus.ready);
    expect(vm.nextStep, OrderStatus.delivered, reason: 'pas d’« en route »');
    await vm.advance(OrderStatus.delivered);
    expect(vm.order?.awaitsCash, isTrue);
    await vm.confirmCash();
    expect(vm.order?.cashCollectedAt, isNotNull);
    expect(vm.order?.awaitsCash, isFalse);
  });

  test('refus avec raison ; état changé entre-temps : relu', () async {
    final service = _service();
    final vm = OrderDetailViewModel(service: service, orderId: 'o1');
    await vm.load();
    await vm.refuse(RefusalReason.outOfStock, 'Plus de tomates');
    expect(vm.order?.status, OrderStatus.refused);
    expect(vm.order?.statusReason, RefusalReason.outOfStock);

    final other = OrderDetailViewModel(service: service, orderId: 'o2');
    await other.load();
    await service.advance(other.order!, OrderStatus.accepted);
    await other.advance(OrderStatus.accepted);
    expect(other.statusChanged, isTrue);
    expect(other.order?.status, OrderStatus.accepted, reason: 'état relu');
  });

  test('liste : une nouvelle commande déclenche l’alerte', () async {
    final service = _service();
    final vm = OrdersViewModel(
      service: service,
      refreshEvery: const Duration(milliseconds: 10),
    );
    var alerts = 0;
    vm.onArrival = () => alerts++;
    await vm.load();
    expect(alerts, 0, reason: 'commandes déjà là au chargement');
    service.arrive(order('o3', name: 'Mawuli'));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(alerts, 1);
    expect(vm.newCount, 3);
    vm.dispose();
  });

  testWidgets('08 : nouvelle commande, accepter ; 45 : refuser', (
    tester,
  ) async {
    final service = _service();
    await _pump(
      tester,
      OrderDetailView(service: service, orderId: 'o1', onBack: () {}),
    );
    expect(find.text('Nouvelle commande !'), findsOneWidget);
    await tester.tap(find.text('Accepter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Commencer la préparation'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _pump(
      tester,
      OrderDetailView(service: service, orderId: 'o2', onBack: () {}),
    );
    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();
    expect(find.text('Refuser la commande ?'), findsOneWidget);
    await tester.tap(find.text('Boutique trop chargée'));
    await tester.pump();
    await tester.tap(find.text('Refuser la commande').last);
    await tester.pumpAndSettle();
    expect(service.gestures, contains('o2:refused'));
    expect(find.textContaining('Boutique trop chargée'), findsOneWidget);
  });

  testWidgets('41 : onglets nouvelles, en cours, terminées', (tester) async {
    final service = _service();
    await service.advance(order('o2', paid: false), OrderStatus.accepted);
    await _pump(tester, OrdersView(service: service, onOpen: (_) {}));
    expect(find.text('Nouvelles (1)'), findsOneWidget);
    expect(find.text('Commande de Awa'), findsOneWidget);
    expect(find.text('Commande de Kossi'), findsNothing);
    await tester.tap(find.text('En cours'));
    await tester.pump();
    expect(find.text('Commande de Kossi'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
