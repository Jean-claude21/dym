import 'package:dym_client/features/orders/disputes_views.dart';
import 'package:dym_client/features/orders/orders_viewmodels.dart';
import 'package:dym_client/features/orders/orders_views.dart';
import 'package:dym_client/features/orders/testing.dart';
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

void main() {
  test('mes commandes : en cours puis terminées', () async {
    final vm = MyOrdersViewModel(service: _service(), refreshEvery: null);
    await vm.load();
    expect(vm.active.map((o) => o.id), ['o1', 'o2']);
    expect(vm.done.map((o) => o.id), ['o3', 'o4']);
  });

  test(
    'suivi : la vendeuse avance, la cliente le voit à la relecture',
    () async {
      final service = _service();
      final vm = TrackingViewModel(
        service: service,
        orderId: 'o1',
        refreshEvery: const Duration(milliseconds: 10),
      );
      await vm.load();
      expect(vm.order?.canCancel, isFalse, reason: 'en préparation');
      service.advance('o1', OrderStatus.outForDelivery);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(vm.order?.status, OrderStatus.outForDelivery);
      vm.dispose();
    },
  );

  test('annulation avant préparation ; conflit signalé', () async {
    final service = _service();
    final vm = TrackingViewModel(
      service: service,
      orderId: 'o2',
      refreshEvery: null,
    );
    await vm.load();
    expect(vm.order?.canCancel, isTrue);
    service.advance('o2', OrderStatus.preparing);
    await vm.cancel();
    expect(vm.statusChanged, isTrue);
    expect(vm.order?.status, OrderStatus.preparing, reason: 'état relu');

    final vm2 = TrackingViewModel(
      service: _service(),
      orderId: 'o2',
      refreshEvery: null,
    );
    await vm2.load();
    await vm2.cancel();
    expect(vm2.order?.status, OrderStatus.cancelled);
  });

  test('centre : non-lues, ouvrir, tout lire', () async {
    final service = _service();
    final vm = NotificationsViewModel(service: service);
    await vm.load();
    expect(service.unread.value, 2);
    await vm.open(vm.items.first);
    expect(service.unread.value, 1);
    await vm.readAll();
    expect(service.unread.value, 0);
    expect(vm.hasUnread, isFalse);
  });

  test('réglages : nuit calme activée', () async {
    final vm = NotificationSettingsViewModel(service: _service());
    await vm.load();
    await vm.toggle(NotificationCategory.quietNight, on: true);
    expect(
      vm.preferences
          .firstWhere((p) => p.category == NotificationCategory.quietNight)
          .pushEnabled,
      isTrue,
    );
  });

  test('réglages : couper une catégorie', () async {
    final vm = NotificationSettingsViewModel(service: _service());
    await vm.load();
    await vm.toggle(NotificationCategory.orders, on: false);
    expect(
      vm.preferences
          .firstWhere((p) => p.category == NotificationCategory.orders)
          .pushEnabled,
      isFalse,
    );
  });

  group('écrans 43, 06, 44 et 46 aux 7 tailles, texte 130 %', () {
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

        testWidgets('43 · $name', (tester) async {
          await show(
            tester,
            MyOrdersView(
              service: _service(),
              onOpen: (_) {},
              onNotifications: () {},
            ),
          );
        });
        for (final id in const ['o1', 'o2', 'o4']) {
          testWidgets('06 suivi $id · $name', (tester) async {
            await show(
              tester,
              TrackingView(service: _service(), orderId: id, onBack: () {}),
            );
          });
        }
        testWidgets('44 · $name', (tester) async {
          await show(
            tester,
            NotificationsView(
              service: _service(),
              onBack: () {},
              onOpenOrder: (_) {},
              clock: () => DateTime.utc(2026, 10, 5, 11),
            ),
          );
        });
        testWidgets('46 · $name', (tester) async {
          await show(
            tester,
            NotificationSettingsView(service: _service(), onBack: () {}),
          );
        });
      }
    }
  });

  testWidgets('43 : statuts et cloche avec le compteur', (tester) async {
    final opened = <String>[];
    await _pump(
      tester,
      MyOrdersView(
        service: _service(),
        onOpen: opened.add,
        onNotifications: () {},
      ),
    );
    expect(find.text('En préparation'), findsOneWidget);
    expect(find.text('Annulée'), findsOneWidget);
    expect(find.text('2'), findsOneWidget, reason: 'non-lues');
    await tester.tap(find.text('Chez Afi'));
    expect(opened, ['o4']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('06 : frise, heure estimée, cash à payer, annuler', (
    tester,
  ) async {
    final service = _service();
    await _pump(
      tester,
      TrackingView(service: service, orderId: 'o2', onBack: () {}),
    );
    expect(find.text('Confirmée'), findsOneWidget);
    expect(find.textContaining('Arrive vers'), findsOneWidget);
    expect(find.text('À payer à la livraison'), findsOneWidget);
    await tester.tap(find.text('Annuler la commande'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler la commande').last);
    await tester.pumpAndSettle();
    expect(find.text('Tu as annulé cette commande.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('06 : code de remise à donner au livreur (spec 042)', (
    tester,
  ) async {
    final service = _service()..handoverCodes['o2'] = '4821';
    await _pump(
      tester,
      TrackingView(service: service, orderId: 'o2', onBack: () {}),
    );
    expect(find.text('Code de remise'), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('44 : textes traduits, tout lire', (tester) async {
    final service = _service();
    await _pump(
      tester,
      NotificationsView(
        service: service,
        onBack: () {},
        onOpenOrder: (_) {},
        clock: () => DateTime.utc(2026, 10, 5, 11),
      ),
    );
    expect(find.text("Les jus d'Esi prépare ta commande."), findsOneWidget);
    expect(find.text('il y a 10 min'), findsNWidgets(3));
    await tester.tap(find.text('Tout lire'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(service.unread.value, 0);
    expect(find.text('Tout lire'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  group('litiges (spec 012)', () {
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

    test('signalement : récit exigé, envoi, puis déjà ouvert', () async {
      final service = _service();
      final sent = <Dispute>[];
      final vm = ReportProblemViewModel(
        service: service,
        orderId: 'o3',
        onSent: sent.add,
      );
      await vm.send();
      expect(vm.showErrors, isTrue);
      expect(sent, isEmpty);
      vm
        ..selectReason(DisputeReason.damaged)
        ..setDescription('  Tomates écrasées  ');
      await vm.send();
      expect(sent.single.reason, DisputeReason.damaged);
      expect(sent.single.description, 'Tomates écrasées');
      final again = ReportProblemViewModel(
        service: service,
        orderId: 'o3',
        onSent: sent.add,
      )..setDescription('Encore');
      await again.send();
      expect(again.failure, const ValidationFailure('dispute_already_open'));
    });

    test('suivi : signaler permis 7 jours après la livraison', () async {
      final service = _service();
      final vm = TrackingViewModel(service: service, orderId: 'o3')
        ..clock = () => DateTime.utc(2026, 10, 11);
      await vm.load();
      expect(vm.canReport, isTrue);
      vm.clock = () => DateTime.utc(2026, 10, 13);
      expect(vm.canReport, isFalse, reason: 'plus de 7 jours');
      vm.dispose();
      final open = TrackingViewModel(service: service, orderId: 'o2');
      await open.load();
      expect(open.canReport, isTrue, reason: 'acceptée');
      service.seedDispute(seeded('o2'));
      await open.refresh();
      expect(open.dispute, isNotNull);
      expect(open.canReport, isFalse, reason: 'déjà ouvert');
      open.dispose();
      final cancelled = TrackingViewModel(service: service, orderId: 'o4');
      await cancelled.load();
      expect(cancelled.canReport, isFalse);
      cancelled.dispose();
    });

    test('fil : aucun litige, puis réponse de la cliente', () async {
      final service = _service();
      final none = DisputeViewModel(
        service: service,
        orderId: 'o3',
        refreshEvery: null,
      );
      await none.load();
      expect(none.failure, isA<NotFoundFailure>());
      none.dispose();
      service.seedDispute(seeded('o3'));
      final vm = DisputeViewModel(
        service: service,
        orderId: 'o3',
        refreshEvery: null,
      );
      await vm.load();
      expect(await vm.send('   '), isFalse);
      expect(await vm.send('Merci'), isTrue);
      expect(vm.dispute!.messages.last.body, 'Merci');
      vm.dispose();
    });

    group('écrans 49 et 50 aux 7 tailles, texte 130 %', () {
      for (final size in _sizes) {
        for (final locale in const [Locale('fr'), Locale('en')]) {
          final name =
              '${size.width.toInt()}×${size.height.toInt()} · '
              '${locale.languageCode}';
          Future<void> show(WidgetTester tester, Widget view) async {
            await _pump(
              tester,
              view,
              size: size,
              locale: locale,
              textScale: 1.3,
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          }

          testWidgets('49 · $name', (tester) async {
            await show(
              tester,
              ReportProblemView(
                service: _service(),
                orderId: 'o3',
                storeName: "Étal d'Akossiwa",
                onBack: () {},
                onSent: (_) {},
              ),
            );
          });
          for (final status in const ['open', 'resolved']) {
            testWidgets('50 $status · $name', (tester) async {
              final service = _service()
                ..seedDispute(seeded('o3', status: status));
              await show(
                tester,
                DisputeView(
                  service: service,
                  orderId: 'o3',
                  onBack: () {},
                  clock: () => DateTime.utc(2026, 10, 5, 11),
                ),
              );
            });
          }
        }
      }
    });

    testWidgets('06 → 49 : signaler puis voir le signalement', (tester) async {
      final service = _service();
      final reported = <String>[];
      await _pump(
        tester,
        TrackingView(
          service: service,
          orderId: 'o3',
          onBack: () {},
          onReport: (id, store) async {
            reported.add('$id:$store');
            service.seedDispute(seeded(id));
            return true;
          },
          onDispute: (_) {},
          // Livrée le 5 : la fenêtre de 7 jours ne dépend pas du jour du test.
          clock: () => DateTime.utc(2026, 10, 6),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Signaler un problème'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Signaler un problème'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(reported, ["o3:Étal d'Akossiwa"]);
      expect(find.text('Voir le signalement'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('49 : raison, récit, envoi', (tester) async {
      final sent = <Dispute>[];
      await _pump(
        tester,
        ReportProblemView(
          service: _service(),
          orderId: 'o3',
          storeName: "Étal d'Akossiwa",
          onBack: () {},
          onSent: sent.add,
        ),
      );
      await tester.tap(find.text('Envoyer le signalement'));
      await tester.pump();
      expect(
        find.text('Décris le problème (3 à 500 caractères)'),
        findsOneWidget,
      );
      await tester.tap(find.text('Article abîmé'));
      await tester.enterText(find.byType(TextField), 'Sac déchiré');
      await tester.tap(find.text('Envoyer le signalement'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(sent.single.reason, DisputeReason.damaged);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('50 : décision et réponse', (tester) async {
      final service = _service()..seedDispute(seeded('o3'));
      await _pump(
        tester,
        DisputeView(
          service: service,
          orderId: 'o3',
          onBack: () {},
          clock: () => DateTime.utc(2026, 10, 5, 11),
        ),
      );
      expect(find.text('En cours de traitement'), findsOneWidget);
      expect(find.text('Pardon, je vous rembourse.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Merci');
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Merci'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final resolved = _service()
        ..seedDispute(seeded('o3', status: 'resolved'));
      await _pump(
        tester,
        DisputeView(
          service: resolved,
          orderId: 'o3',
          onBack: () {},
          clock: () => DateTime.utc(2026, 10, 5, 11),
        ),
      );
      expect(find.textContaining('Remboursement de'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
