import 'package:dym_client/features/cart/cart/cart_view.dart';
import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cart_fixtures.dart';

void main() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final day = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  DeliverySlots slots({bool required = false}) => DeliverySlots(
    required: required,
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

  group('créneaux (spec 033)', () {
    test('arrivage : créneau obligatoire, puis commande', () async {
      final service = memoryCart()..deliverySlots = slots(required: true);
      final ordered = <Purchase>[];
      final vm = CartViewModel(service: service, onOrdered: ordered.add);
      await vm.load();
      await vm.loadSlots();
      expect(vm.slots!.required, isTrue);
      await vm.order();
      expect(vm.orderError, OrderError.slotRequired);
      vm.selectSlot(SlotChoice(date: day, windowId: 'w2'));
      expect(vm.orderError, isNull);
      await vm.order();
      expect(ordered, hasLength(1));
    });

    test(
      'créneau disparu : la sélection revient à « dès que possible »',
      () async {
        final service = memoryCart()..deliverySlots = slots();
        final vm = CartViewModel(service: service, onOrdered: (_) {});
        await vm.load();
        vm.selectSlot(SlotChoice(date: day, windowId: 'ancien'));
        await vm.loadSlots();
        expect(vm.slot, isNull);
      },
    );

    test('requête : créneau au format de la base', () {
      final json = SlotChoice(
        date: DateTime(2026, 11, 12),
        windowId: 'w1',
      ).toJson();
      expect(json, {'date': '2026-11-12', 'window_id': 'w1'});
      expect(
        orderErrorOf(const ValidationFailure('slot_too_early')),
        OrderError.slotInvalid,
      );
    });

    testWidgets('panier : « Quand ? » et créneaux du jour', (tester) async {
      final service = memoryCart()..deliverySlots = slots();
      tester.view
        ..physicalSize = const Size(412, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: CartPageView(
            service: service,
            onBack: () {},
            onDelivery: () {},
            onOrdered: (_) {},
            onBrowse: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Quand ?'), findsOneWidget);
      expect(find.text('Dès que possible'), findsOneWidget);
      expect(find.text('Demain'), findsOneWidget);
      await tester.tap(find.text('14:00–16:00'));
      await tester.pump();
      expect(service.selection.slot?.windowId, 'w2');
    });
  });
}
