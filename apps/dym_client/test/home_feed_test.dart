import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/home/discovery_home_view.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

void main() {
  group('nouvel accueil (spec 027)', () {
    HomeFeed fullFeed() => HomeFeed(
      lastOrder: const LastOrder(
        orderId: 'order-1',
        storeName: 'Étal de Kodjo',
        itemCount: 3,
      ),
      popular: [for (final p in products().take(2)) p.item],
      fresh: [products().last.item],
    );

    test('le fil est chargé avec les boutiques', () async {
      final service = memoryDiscovery()..feed = fullFeed();
      final vm = DiscoveryHomeViewModel(service: service);
      await vm.load();
      expect(vm.ready, isTrue);
      expect(vm.feed.lastOrder?.orderId, 'order-1');
      expect(vm.feed.popular, hasLength(2));
    });

    test("un échec du fil n'empêche pas l'accueil", () async {
      final service = memoryDiscovery()
        ..feed = fullFeed()
        ..feedFailure = const NetworkFailure('coupé');
      final vm = DiscoveryHomeViewModel(service: service);
      await vm.load();
      expect(vm.ready, isTrue, reason: "l'accueil reste affiché");
      expect(vm.result.stores, isNotEmpty);
      expect(vm.feed.isEmpty, isTrue);
    });

    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view
        ..physicalSize = const Size(412, 1800)
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
      await tester.pumpAndSettle();
    }

    testWidgets('question, réachat et sections produits', (tester) async {
      final reordered = <String>[];
      await pump(
        tester,
        DiscoveryHomeView(
          service: memoryDiscovery()..feed = fullFeed(),
          onSearch: () {},
          onOpenStore: (_) {},
          onOpenAisle: (_) {},
          onOpenProduct: (_) {},
          onReorder: reordered.add,
        ),
      );
      expect(find.text("Qu'est-ce qu'on mange ?"), findsOneWidget);
      expect(find.text('Recommander tes courses'), findsOneWidget);
      expect(find.text('Étal de Kodjo · 3 articles'), findsOneWidget);
      expect(find.text('Les plus demandés près de toi'), findsOneWidget);
      expect(find.text('Nouveautés'), findsOneWidget);
      await tester.tap(find.text('Recommander'));
      expect(reordered, ['order-1']);
    });

    testWidgets('sans commande ni produits : sections masquées', (
      tester,
    ) async {
      await pump(
        tester,
        DiscoveryHomeView(
          service: memoryDiscovery(),
          onSearch: () {},
          onOpenStore: (_) {},
          onOpenAisle: (_) {},
          onOpenProduct: (_) {},
          onReorder: (_) {},
        ),
      );
      expect(find.text('Recommander tes courses'), findsNothing);
      expect(find.text('Nouveautés'), findsNothing);
    });
  });
}
