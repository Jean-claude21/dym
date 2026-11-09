import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cart_fixtures.dart';

void main() {
  group('finition (spec 026)', () {
    test(
      'panier : adresse de livraison affichée, absente sans adresse',
      () async {
        final vm = CartViewModel(service: memoryCart(), onOrdered: (_) {});
        await vm.load();
        expect(vm.deliveryAddress, isNotNull);
        expect(vm.deliveryAddress!.id, vm.cart.addressId);

        final none = CartViewModel(
          service: memoryCart(addresses: const []),
          onOrdered: (_) {},
        );
        await none.load();
        expect(none.deliveryAddress, isNull);
        expect(none.missingAddress, isTrue);
      },
    );

    test('commande réussie : retour sensible demandé une fois', () async {
      var feedback = 0;
      final vm = CartViewModel(
        service: memoryCart(),
        onOrdered: (_) {},
        onSuccess: () => feedback++,
      );
      await vm.load();
      await vm.order();
      expect(feedback, 1);
    });

    Widget app(Widget child, {bool reduceMotion = false}) => MaterialApp(
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    );

    testWidgets('squelette : statique si les animations sont coupées', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const DymSkeleton(label: 'Chargement'), reduceMotion: true),
      );
      // Aucune animation en cours : l'écran se stabilise immédiatement.
      await tester.pumpAndSettle();
      expect(find.byType(DymSkeleton), findsOneWidget);
    });

    testWidgets('bouton panier : nombre d\'articles et ouverture', (
      tester,
    ) async {
      final service = memoryCart();
      await service.refresh();
      var opened = 0;
      await tester.pumpWidget(
        app(
          CartScope(
            service: service,
            onOpenCart: () => opened++,
            child: const Center(child: CartButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('${service.cart.value.itemCount}'), findsOneWidget);
      await tester.tap(find.byType(CartButton));
      expect(opened, 1);
    });
  });
}
