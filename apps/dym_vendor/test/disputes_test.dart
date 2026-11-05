import 'package:dym_core/dym_core.dart';
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

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
];

Dispute _dispute({String status = 'open'}) => Dispute(
  id: 'd1',
  orderId: 'o2',
  reason: DisputeReason.missingItem,
  description: 'Il manquait le gombo dans le sac.',
  status: status,
  createdAt: DateTime.utc(2026, 10, 5, 10, 40),
  currencyCode: 'XOF',
  customerFirstName: 'Awa',
  messages: [
    DisputeMessage(
      id: 'm0',
      authorRole: 'client',
      body: 'Il manquait le gombo dans le sac.',
      createdAt: DateTime.utc(2026, 10, 5, 10, 40),
    ),
  ],
);

MemoryOrdersService _service({String? dispute}) {
  final service = MemoryOrdersService(
    config: togoConfig(),
    orders: [order('o1'), order('o2', paid: false)],
  );
  if (dispute != null) service.seedDispute(_dispute(status: dispute));
  return service;
}

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
        child: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  test('détail : litige chargé, réponse ajoutée au fil', () async {
    final service = _service(dispute: 'open');
    final vm = OrderDetailViewModel(service: service, orderId: 'o2');
    await vm.load();
    expect(vm.dispute?.reason, DisputeReason.missingItem);
    expect(await vm.replyDispute('  '), isFalse);
    expect(await vm.replyDispute('Pardon, je te rembourse.'), isTrue);
    expect(vm.dispute!.messages.last.authorRole, 'vendor');
    expect(service.gestures, ['o2:reply']);
  });

  test('détail : litige clos, réponse refusée', () async {
    final vm = OrderDetailViewModel(
      service: _service(dispute: 'resolved'),
      orderId: 'o2',
    );
    await vm.load();
    expect(await vm.replyDispute('Encore'), isFalse);
    expect(vm.actionFailure, const ValidationFailure('dispute_closed'));
  });

  test('détail : sans litige, rien', () async {
    final vm = OrderDetailViewModel(service: _service(), orderId: 'o2');
    await vm.load();
    expect(vm.dispute, isNull);
  });

  group('écran 51 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        for (final status in const ['open', 'resolved']) {
          testWidgets(
            '51 $status · ${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}',
            (tester) async {
              await _pump(
                tester,
                OrderDetailView(
                  service: _service(dispute: status),
                  orderId: 'o2',
                  onBack: () {},
                ),
                size: size,
                locale: locale,
                textScale: 1.3,
              );
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox());
            },
          );
        }
      }
    }
    testWidgets('feuille de réponse · 360×640 · 130 %', (tester) async {
      await _pump(
        tester,
        const Scaffold(body: DisputeReplySheet()),
        size: const Size(360, 640),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('51 : bandeau, répondre, le fil s’allonge', (tester) async {
    final service = _service(dispute: 'open');
    await _pump(
      tester,
      OrderDetailView(service: service, orderId: 'o2', onBack: () {}),
    );
    expect(
      find.text('Problème signalé : Il manque un article'),
      findsOneWidget,
    );
    expect(
      find.text('Awa : Il manquait le gombo dans le sac.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Répondre'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Je te rembourse le gombo.');
    await tester.pump();
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(find.text('Toi : Je te rembourse le gombo.'), findsOneWidget);
    expect(service.gestures, ['o2:reply']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('51 : litige traité, plus de bouton', (tester) async {
    await _pump(
      tester,
      OrderDetailView(
        service: _service(dispute: 'resolved'),
        orderId: 'o2',
        onBack: () {},
      ),
    );
    expect(find.text('Traité'), findsOneWidget);
    expect(find.text('Répondre'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
