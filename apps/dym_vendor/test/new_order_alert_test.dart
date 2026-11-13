import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/orders/new_order_alert.dart';
import 'package:dym_vendor/features/orders/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'orders_test.dart' show order;
import 'support/store_fixtures.dart';

void main() {
  test('alerte : une commande jamais vue est annoncée une fois', () async {
    final service = MemoryOrdersService(
      config: togoConfig(),
      orders: [order('o1')],
    );
    final watcher = NewOrderWatcher(service: service);
    await watcher.check();
    expect(watcher.alert?.id, 'o1');
    watcher.acknowledge();
    await watcher.check();
    expect(watcher.alert, isNull, reason: 'déjà vue');
    service.arrive(order('o2', name: 'Mariama'));
    await watcher.check();
    expect(watcher.alert?.id, 'o2');
    expect(watcher.othersWaiting, 1);
    watcher.dispose();
  });

  test('alerte retirée quand la commande est traitée ailleurs', () async {
    final service = MemoryOrdersService(
      config: togoConfig(),
      orders: [order('o1')],
    );
    final watcher = NewOrderWatcher(service: service);
    await watcher.check();
    final o = (await service.order('o1')).valueOrNull!;
    await service.advance(o, OrderStatus.accepted);
    await watcher.check();
    expect(watcher.alert, isNull);
    watcher.dispose();
  });

  testWidgets('écran de l’alerte : délai et deux choix', (tester) async {
    final service = MemoryOrdersService(
      config: togoConfig(),
      orders: [order('o1')],
    );
    final o = (await service.order('o1')).valueOrNull!;
    await tester.pumpWidget(
      MaterialApp(
        theme: DymTheme.light(),
        locale: const Locale('fr'),
        localizationsDelegates: DymLocalizations.localizationsDelegates,
        supportedLocales: DymLocalizations.supportedLocales,
        home: NewOrderAlert(
          order: o,
          amount: '3 450 F CFA',
          othersWaiting: 0,
          clock: () => o.createdAt.add(const Duration(minutes: 17)),
          ring: false,
        ),
      ),
    );
    expect(find.text('Nouvelle commande !'), findsOneWidget);
    expect(find.text('3 min restantes'), findsOneWidget);
    expect(find.text('Voir la commande'), findsOneWidget);
    expect(find.text('Plus tard'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
