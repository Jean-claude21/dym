@Tags(['golden'])
library;

import 'package:dym_client/features/cart/cart/cart_view.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cart_fixtures.dart';
import 'capture.dart';

/// Retours des testeurs (spec 090) : menu « ⋯ » du panier, choix du jour.
void main() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final day = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  final slots = DeliverySlots(
    required: false,
    minDate: day,
    days: [
      DeliveryDay(
        date: day,
        windows: const [
          DeliveryWindow(id: 'w1', startsAt: '08:00', endsAt: '10:00'),
          DeliveryWindow(id: 'w2', startsAt: '14:00', endsAt: '16:00'),
        ],
      ),
    ],
  );
  CartPageView cart() => CartPageView(
    service: memoryCart()..deliverySlots = slots,
    onDelivery: () {},
    onOrdered: (_) {},
    onBrowse: () {},
    onSave: (_) async {},
    onSendToSpace: (_) async {},
  );

  testWidgets('panier menu', (t) async {
    await capture(
      t,
      'retours_panier_menu',
      cart(),
      before: (t) async {
        await t.tap(find.byTooltip('Plus d\'actions'));
        await t.pumpAndSettle();
      },
    );
  });
  testWidgets('panier jour', (t) async {
    await capture(
      t,
      'retours_panier_jour',
      cart(),
      before: (t) async {
        final list = find.byType(Scrollable).first;
        await t.scrollUntilVisible(find.text('Demain'), 200, scrollable: list);
        await t.drag(list, const Offset(0, -250));
        await t.pumpAndSettle();
        await t.tap(find.text('Demain'));
        await t.pumpAndSettle();
      },
    );
  });
}
