import 'package:dym_client/features/cart/addresses/address_form_view.dart';
import 'package:dym_client/features/cart/addresses/addresses_view.dart';
import 'package:dym_client/features/cart/cart/cart_view.dart';
import 'package:dym_client/features/cart/delivery/delivery_view.dart';
import 'package:dym_client/features/cart/sent/order_sent_view.dart';
import 'package:dym_client/features/cart/testing.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
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

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(412, 915),
  Locale locale = const Locale('fr'),
  double textScale = 1,
  MemoryCartService? scope,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Widget home = MediaQuery(
    data: MediaQueryData(
      size: size,
      disableAnimations: true,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child,
  );
  if (scope != null) {
    home = CartScope(service: scope, onOpenCart: () {}, child: home);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: locale,
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _noop([Object? _]) {}

Future<Purchase> _purchase() async {
  final service = memoryCart();
  return (await service.placeOrder()).valueOrNull!;
}

void main() {
  group('écrans 05, 34, 35, 36 et 37 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        Future<void> show(WidgetTester tester, Widget view) =>
            _pump(tester, view, size: size, locale: locale, textScale: 1.3);

        testWidgets('05 panier · $name', (tester) async {
          await show(
            tester,
            CartPageView(
              service: memoryCart(),
              onBack: _noop,
              onDelivery: _noop,
              onOrdered: _noop,
              onBrowse: _noop,
            ),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('34 livraison · $name', (tester) async {
          await show(
            tester,
            DeliveryView(
              service: memoryCart(),
              onBack: _noop,
              onAddAddress: () async => false,
            ),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('35 mes adresses · $name', (tester) async {
          await show(
            tester,
            AddressesView(
              service: memoryCart(),
              onBack: _noop,
              onEdit: (_) async => false,
            ),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('36 nouvelle adresse · $name', (tester) async {
          await show(
            tester,
            AddressFormView(service: memoryCart(), onDone: _noop),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('37 commande envoyée · $name', (tester) async {
          final purchase = await _purchase();
          await show(
            tester,
            OrderSentView(
              service: memoryCart(),
              purchase: purchase,
              onHome: _noop,
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('panier : sous-paniers, total de la base, commande', (
    tester,
  ) async {
    final ordered = <Purchase>[];
    await _pump(
      tester,
      CartPageView(
        service: memoryCart(),
        onBack: _noop,
        onDelivery: _noop,
        onOrdered: ordered.add,
        onBrowse: _noop,
      ),
    );
    expect(find.text('Ton panier'), findsOneWidget);
    expect(find.text('2 boutiques · 6 articles'), findsOneWidget);
    expect(find.text("Étal d'Akossiwa"), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cash à la livraison'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Commander · ${xof(4100)}'), findsOneWidget);
    await _tap(tester, find.text('Commander · ${xof(4100)}'));
    expect(ordered.single.totalMinor, 4100);
  });

  testWidgets('panier vide : état vide et retour aux boutiques', (
    tester,
  ) async {
    var browsed = false;
    await _pump(
      tester,
      CartPageView(
        service: memoryCart(lines: const {}),
        onBack: _noop,
        onDelivery: _noop,
        onOrdered: _noop,
        onBrowse: () => browsed = true,
      ),
    );
    expect(find.text('Ton panier est vide'), findsOneWidget);
    await _tap(tester, find.text('Voir les boutiques'));
    expect(browsed, isTrue);
  });

  testWidgets('boutique fermée : signalée, bouton Commander désactivé', (
    tester,
  ) async {
    await _pump(
      tester,
      CartPageView(
        service: memoryCart(kodjoOpen: false),
        onBack: _noop,
        onDelivery: _noop,
        onOrdered: _noop,
        onBrowse: _noop,
      ),
    );
    expect(find.text('Fermée maintenant'), findsOneWidget);
    expect(
      find.text('Corrige les points signalés pour commander.'),
      findsOneWidget,
    );
    final button = tester.widget<DymButton>(
      find.widgetWithText(DymButton, 'Commander · ${xof(4100)}'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('livraison : retrait chez Esi, frais recalculés', (tester) async {
    final service = memoryCart();
    await _pump(
      tester,
      DeliveryView(
        service: service,
        onBack: _noop,
        onAddAddress: () async => false,
      ),
    );
    expect(find.text('Où te livrer ?'), findsOneWidget);
    expect(find.text('Je récupère'), findsOneWidget, reason: 'Esi seulement');
    await _tap(tester, find.text('Je récupère'));
    expect(service.cart.value.deliveryFeeMinor, 500);
    expect(service.events, contains('checkout_started'));
  });

  testWidgets('nouvelle adresse : recherche sans liste, enregistrement', (
    tester,
  ) async {
    final service = memoryCart(addresses: const []);
    final done = <bool>[];
    await _pump(tester, AddressFormView(service: service, onDone: done.add));
    expect(find.textContaining('Tokoin'), findsNothing, reason: 'aucune liste');
    await tester.enterText(find.byType(TextField).first, 'tok');
    await tester.pumpAndSettle();
    await _tap(tester, find.textContaining('Tokoin'));
    await tester.enterText(find.byType(TextField).at(1), 'Portail vert');
    await tester.enterText(find.byType(TextField).at(2), '+228 90 11 22 33');
    await tester.pumpAndSettle();
    await _tap(tester, find.text("Enregistrer l'adresse"));
    expect(done, [true]);
    expect((await service.addresses()).valueOrNull!.single.zoneName, 'Tokoin');
  });

  testWidgets('mini-panier : caché à 0 article, résumé sinon', (tester) async {
    final service = memoryCart(lines: const {});
    await _pump(
      tester,
      const Scaffold(body: WithMiniCart(child: SizedBox.expand())),
      scope: service,
    );
    expect(find.textContaining('articles'), findsNothing);
    await service.add('tomates', quantity: 2);
    await tester.pumpAndSettle();
    expect(find.text('Voir le panier'), findsOneWidget);
    expect(find.textContaining('2 articles · 1 boutique'), findsOneWidget);
  });
}
