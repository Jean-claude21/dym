import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_client/features/cart/payment/payment_view.dart';
import 'package:dym_client/features/cart/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cart_fixtures.dart';

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
];

/// Panier commandé en Mobile Money (simulé) : achat en attente de paiement.
Future<(MemoryCartService, Purchase)> _ordered() async {
  final service = memoryCart(online: true);
  await service.select(paymentMethodId: 'sim');
  final purchase = (await service.placeOrder()).valueOrNull!;
  return (service, purchase);
}

PaymentViewModel _vm(
  MemoryCartService service,
  Purchase purchase,
  List<Purchase> settled,
) => PaymentViewModel(
  service: service,
  purchase: purchase,
  onSettled: settled.add,
  pollEvery: const Duration(milliseconds: 10),
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
        child: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  test('commande en ligne : en attente, page ouverte, réussite', () async {
    final (service, purchase) = await _ordered();
    expect(purchase.awaitingPayment, isTrue);
    expect(purchase.payment?.checkoutUrl, isNotNull);
    final settled = <Purchase>[];
    final vm = _vm(service, purchase, settled);
    await vm.load();
    expect(service.openedPages, [purchase.payment!.checkoutUrl]);
    expect(vm.waiting, isTrue);

    service.simulatePayment(purchase.id, PaymentAttemptStatus.succeeded);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(settled.single.isPaid, isTrue, reason: 'relecture automatique');
    vm.dispose();
  });

  test('échec : écran 40, réessai puis paiement à la livraison', () async {
    final (service, purchase) = await _ordered();
    final settled = <Purchase>[];
    final vm = _vm(service, purchase, settled);
    await vm.load();
    service.simulatePayment(purchase.id, PaymentAttemptStatus.failed);
    await vm.check();
    expect(vm.failedPayment, isTrue);

    await vm.retry();
    expect(vm.waiting, isTrue);
    expect(service.openedPages, hasLength(2), reason: 'nouvelle page ouverte');

    await vm.payOnDelivery();
    expect(settled.single.paymentStatus, PaymentStatus.cashOnDelivery);
    vm.dispose();
  });

  test('relecture hors ligne : signalée, sans perdre l’attente', () async {
    final (service, purchase) = await _ordered();
    final vm = _vm(service, purchase, []);
    await vm.load();
    service.failNext = const NetworkFailure('3G');
    await vm.check();
    expect(vm.checkOffline, isTrue);
    expect(vm.waiting, isTrue);
    vm.dispose();
  });

  test('cash déjà décidé : confirmation directe', () async {
    final service = memoryCart();
    final purchase = (await service.placeOrder()).valueOrNull!;
    final settled = <Purchase>[];
    final vm = _vm(service, purchase, settled);
    await vm.load();
    expect(settled.single, purchase);
    vm.dispose();
  });

  group('écrans 39 et 40 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        for (final failed in [false, true]) {
          testWidgets('${failed ? '40' : '39'} · $name', (tester) async {
            final (service, purchase) = await _ordered();
            if (failed) {
              service.simulatePayment(purchase.id, PaymentAttemptStatus.failed);
            }
            await _pump(
              tester,
              PaymentView(
                service: service,
                purchase: (await service.purchase(purchase.id)).valueOrNull!,
                onSettled: (_) {},
                onBack: () {},
                openAtStart: false,
              ),
              size: size,
              locale: locale,
              textScale: 1.3,
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  });

  testWidgets('écran 39 puis 40 : textes et actions', (tester) async {
    final (service, purchase) = await _ordered();
    await _pump(
      tester,
      PaymentView(
        service: service,
        purchase: purchase,
        onSettled: (_) {},
        onBack: () {},
        openAtStart: false,
      ),
    );
    expect(find.text('En attente du paiement'), findsOneWidget);
    expect(find.text('Ouvrir la page de paiement'), findsOneWidget);
    service.simulatePayment(purchase.id, PaymentAttemptStatus.failed);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text("Le paiement n'a pas abouti"), findsOneWidget);
    expect(find.text('Réessayer le paiement'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
