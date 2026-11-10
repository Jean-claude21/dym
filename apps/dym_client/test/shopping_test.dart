import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/shopping/shopping_service.dart';
import 'package:dym_client/features/shopping/shopping_viewmodels.dart';
import 'package:dym_client/features/shopping/shopping_views.dart';
import 'package:dym_client/features/shopping/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

void main() {
  MemoryShoppingService service({
    List<ShoppingItem> habits = const [],
    List<ShoppingItem>? suggested,
  }) => MemoryShoppingService(
    copilot: MemoryCopilotService(discovery: memoryDiscovery()),
    habitItems: habits,
    suggested: suggested,
  );

  Widget app(Widget home) => MaterialApp(
    theme: DymTheme.light(),
    locale: const Locale('fr'),
    localizationsDelegates: DymLocalizations.localizationsDelegates,
    supportedLocales: DymLocalizations.supportedLocales,
    home: home,
  );

  group('assistant de courses (spec 029)', () {
    test('liste habituelle : brouillon, ou message sans habitudes', () async {
      final none = ShoppingListsViewModel(service: service());
      expect(await none.fromHabits('Ma liste habituelle'), isNull);
      expect(none.noHabits, isTrue);

      final vm = ShoppingListsViewModel(
        service: service(
          habits: const [ShoppingItem(label: 'Tomates', quantity: 3)],
        ),
      );
      final draft = await vm.fromHabits('Ma liste habituelle');
      expect(draft!.items.single.quantity, 3);
      expect(draft.name, 'Ma liste habituelle');
    });

    test("IA : brouillon nommé d'après la description, ou échec", () async {
      final vm = ShoppingListsViewModel(
        service: service(suggested: const [ShoppingItem(label: 'Riz')]),
      );
      final draft = await vm.describe('  La semaine pour 4 personnes ');
      expect(draft!.name, 'La semaine pour 4 personnes');
      expect(draft.items.single.label, 'Riz');

      expect(
        shortName('Les courses de la semaine pour 4 personnes, sauce gombo'),
        'Les courses de la semaine pour 4',
      );

      final failing = ShoppingListsViewModel(service: service());
      expect(await failing.describe('la semaine'), isNull);
      expect(failing.aiFailed, isTrue);
    });

    test('édition : quantités bornées, rappel hebdomadaire, refus', () async {
      final s = service();
      final vm = ShoppingEditViewModel(
        service: s,
        draft: const ShoppingDraft(),
        today: DateTime(2026, 11, 10, 15),
      );
      expect(await vm.save(), isNull);
      expect(vm.problem, ShoppingError.name);
      vm.setName('Samedi');
      expect(await vm.save(), isNull);
      expect(vm.problem, ShoppingError.items);
      vm
        ..add('  Tomates  fraîches ')
        ..setQuantity(0, 40)
        ..setPeriod(ShoppingPeriod.weekly);
      expect(vm.items.single.label, 'Tomates fraîches');
      expect(vm.items.single.quantity, ShoppingItem.maxQuantity);
      expect(vm.firstReminder, DateTime(2026, 11, 17));
      final saved = await vm.save();
      expect(saved!.period, ShoppingPeriod.weekly);
      expect(s.lastSaved!.startsOn, DateTime(2026, 11, 17));

      s.nextFailure = const ValidationFailure('too_many_lists');
      expect(await vm.save(), isNull);
      expect(vm.problem, ShoppingError.tooMany);
    });

    test('sans rappel : aucune date envoyée', () async {
      final s = service();
      final vm =
          ShoppingEditViewModel(
              service: s,
              draft: const ShoppingDraft(
                name: 'Fête',
                items: [ShoppingItem(label: 'Riz')],
              ),
            )
            ..setPeriod(ShoppingPeriod.monthly)
            ..setPeriod(null);
      await vm.save();
      expect(s.lastSaved!.period, isNull);
      expect(s.lastSaved!.startsOn, isNull);
    });

    test('panier de la liste : lignes refusées et mesure', () async {
      final measured = <(int, int)>[];
      final copilot = ListCopilotService(
        base: MemoryCopilotService(discovery: memoryDiscovery()),
        proposeList: () async => const Ok(CopilotProposal()),
        addToCart: (variant, _) async => variant != 'v2',
        onAdded: (added, refused) async => measured.add((added, refused)),
      );
      const line = CopilotLine(
        variantId: 'v1',
        productId: 'p1',
        name: 'Tomates',
        quantity: 2,
        unitPriceMinor: 500,
        lineMinor: 1000,
      );
      const refusedLine = CopilotLine(
        variantId: 'v2',
        productId: 'p2',
        name: 'Riz',
        quantity: 1,
        unitPriceMinor: 900,
        lineMinor: 900,
      );
      final refused = await copilot.addAll(
        const CopilotProposal(
          stores: [
            CopilotStoreLines(
              id: 's1',
              name: 'Kodjo',
              lines: [line, refusedLine],
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(refused.single.variantId, 'v2');
      expect(measured, [(1, 1)]);
      expect(await copilot.enabled(), isTrue);
    });

    testWidgets('écran : vide, puis liste avec son rappel', (tester) async {
      final s = service();
      ShoppingDraft? edited;
      ShoppingList? opened;
      await tester.pumpWidget(
        app(
          ShoppingListsView(
            service: s,
            onBack: () {},
            onEdit: (draft) async {
              edited = draft;
              await s.save(
                name: 'Courses du samedi',
                items: const [ShoppingItem(label: 'Tomates', quantity: 2)],
                period: ShoppingPeriod.weekly,
                startsOn: DateTime(2026, 11, 14),
              );
              return true;
            },
            onOpen: (list) => opened = list,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mes courses'), findsWidgets);
      expect(find.textContaining('Pas encore de liste'), findsOneWidget);
      expect(find.text('Décrire mes courses'), findsOneWidget);

      await tester.tap(find.text('Nouvelle liste'));
      await tester.pumpAndSettle();
      expect(edited!.list, isNull);
      expect(find.text('Courses du samedi'), findsOneWidget);
      expect(find.text('· Chaque semaine'), findsOneWidget);

      await tester.tap(find.text('Composer mon panier'));
      expect(opened!.name, 'Courses du samedi');
    });

    testWidgets('écran : liste habituelle absente expliquée', (tester) async {
      await tester.pumpWidget(
        app(
          ShoppingListsView(
            service: service(),
            onBack: () {},
            onEdit: (_) async => false,
            onOpen: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ma liste habituelle'));
      await tester.pumpAndSettle();
      expect(find.textContaining("Pas encore d'habitudes"), findsOneWidget);
    });

    testWidgets('édition : ajout, rappel et enregistrement', (tester) async {
      final s = service();
      ShoppingList? saved;
      await tester.pumpWidget(
        app(
          ShoppingEditView(
            service: s,
            draft: const ShoppingDraft(name: 'Samedi'),
            today: DateTime(2026, 11, 10),
            onBack: () {},
            onSaved: (list) => saved = list,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Gombo');
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();
      expect(find.text('Gombo'), findsOneWidget);
      await tester.tap(find.text('Chaque semaine'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Premier rappel le'), findsOneWidget);
      await tester.ensureVisible(find.text('Enregistrer la liste'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer la liste'));
      await tester.pumpAndSettle();
      expect(saved!.items.single.label, 'Gombo');
      expect(saved!.period, ShoppingPeriod.weekly);
    });
  });
}
