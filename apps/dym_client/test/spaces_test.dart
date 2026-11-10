import 'package:dym_client/features/spaces/spaces_viewmodels.dart';
import 'package:dym_client/features/spaces/spaces_views.dart';
import 'package:dym_client/features/spaces/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

void main() {
  Widget app(Widget home) => MaterialApp(
    theme: DymTheme.light(),
    locale: const Locale('fr'),
    localizationsDelegates: DymLocalizations.localizationsDelegates,
    supportedLocales: DymLocalizations.supportedLocales,
    home: home,
  );

  Space home({
    SpaceRole role = SpaceRole.payer,
    int? budget,
    int spent = 0,
    int quantity = 4,
  }) => Space(
    id: 'sp1',
    name: 'Maison',
    joinCode: 'ABCD2345',
    myRole: role,
    isOwner: role == SpaceRole.payer,
    currencyCode: 'XOF',
    monthlyBudgetMinor: budget,
    spentMonthMinor: spent,
    totalMinor: 500 * quantity,
    members: [
      SpaceMember(
        userId: 'u1',
        firstName: 'Awa',
        role: SpaceRole.payer,
        isOwner: true,
        isMe: role == SpaceRole.payer,
      ),
      SpaceMember(
        userId: 'u2',
        firstName: 'Kofi',
        role: SpaceRole.member,
        isMe: role == SpaceRole.member,
      ),
    ],
    items: [
      SpaceItem(
        variantId: 'v1',
        productId: 'p1',
        name: 'Tomates',
        quantity: quantity,
        unitPriceMinor: 500,
        available: true,
        addedBy: 'Kofi',
      ),
    ],
  );

  group('espaces (spec 031)', () {
    test('création : nom requis, budget lu dans la devise', () async {
      final service = MemorySpacesService(discovery: memoryDiscovery());
      final vm = SpacesViewModel(service: service);
      await vm.load();
      expect(await vm.create(' ', ''), isNull);
      expect(vm.problem, SpaceError.name);
      expect(await vm.create('Maison', 'abc'), isNull);
      expect(vm.problem, SpaceError.budget);
      final space = await vm.create('Maison', '30 000');
      expect(space!.monthlyBudgetMinor, 30000);
    });

    test('refus du serveur traduits', () {
      expect(
        spaceErrorOf(const NotFoundFailure('unknown_code')),
        SpaceError.unknownCode,
      );
      expect(
        spaceErrorOf(const ValidationFailure('budget_exceeded')),
        SpaceError.budgetExceeded,
      );
      expect(
        spaceErrorOf(const ForbiddenFailure('not_payer')),
        SpaceError.notPayer,
      );
    });

    testWidgets('membre : voit le panier commun, ne valide pas', (
      tester,
    ) async {
      final service = MemorySpacesService(
        discovery: memoryDiscovery(),
        spaces: [home(role: SpaceRole.member)],
      );
      await tester.pumpWidget(
        app(
          SpaceView(
            service: service,
            spaceId: 'sp1',
            onBack: () {},
            onValidated: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Maison'), findsOneWidget);
      expect(find.text('ABCD2345'), findsOneWidget);
      expect(find.text('Kofi (moi)'), findsOneWidget);
      expect(find.textContaining('ajouté par Kofi'), findsOneWidget);
      expect(find.text('Valider et passer au panier'), findsNothing);
      expect(find.textContaining('Une personne qui valide'), findsOneWidget);
    });

    testWidgets('payeuse : budget dépassé signalé, puis validation', (
      tester,
    ) async {
      final service = MemorySpacesService(
        discovery: memoryDiscovery(),
        spaces: [home(budget: 3000, spent: 1000, quantity: 6)],
      );
      var validated = 0;
      await tester.pumpWidget(
        app(
          SpaceView(
            service: service,
            spaceId: 'sp1',
            onBack: () {},
            onValidated: () => validated++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Budget du mois'), findsOneWidget);
      expect(find.text('Ce panier dépasse le budget du mois.'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Valider et passer au panier'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider et passer au panier'));
      await tester.pumpAndSettle();
      expect(validated, 0, reason: 'budget dépassé : refusé');

      await service.setItem('sp1', 'v1', 4);
      await tester.pumpWidget(
        app(
          SpaceView(
            key: const ValueKey('2'),
            service: service,
            spaceId: 'sp1',
            onBack: () {},
            onValidated: () => validated++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('Valider et passer au panier'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider et passer au panier'));
      await tester.pumpAndSettle();
      expect(validated, 1);
      expect(service.validated, ['sp1']);
    });

    testWidgets('liste : vide, puis espace avec rôle', (tester) async {
      final service = MemorySpacesService(discovery: memoryDiscovery());
      await tester.pumpWidget(
        app(SpacesView(service: service, onBack: () {}, onOpen: (_) async {})),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining("Pas encore d'espace"), findsOneWidget);

      service.stored.add(home());
      await tester.pumpWidget(
        app(
          SpacesView(
            key: const ValueKey('2'),
            service: service,
            onBack: () {},
            onOpen: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Maison'), findsOneWidget);
      expect(find.textContaining('2 membres'), findsOneWidget);
    });
  });
}
