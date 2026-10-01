import 'package:dym_core/dym_core.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final price = Money(500, Currency.xof);

  testWidgets('DymButton : hauteur ≥ 48, libellé lisible, désactivé', (
    tester,
  ) async {
    var taps = 0;
    await pumpDym(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DymButton(label: 'Commander', onPressed: () => taps++),
          const DymButton(label: 'Indisponible', onPressed: null),
        ],
      ),
    );
    expect(
      tester.getSize(find.byType(DymButton).first).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.bySemanticsLabel('Commander'), findsOneWidget);
    await tester.tap(find.text('Commander'));
    await tester.tap(find.text('Indisponible'));
    expect(taps, 1);
  });

  testWidgets('DymFilterChip : zone tactile 48 et état sélectionné', (
    tester,
  ) async {
    await pumpDym(
      tester,
      DymFilterChip(label: 'Tous', selected: true, onTap: () {}),
    );
    expect(tester.getSize(find.byType(DymFilterChip)).height, 48);
    expect(
      tester.getSemantics(find.byType(DymFilterChip)),
      isSemantics(label: 'Tous', isButton: true, isSelected: true),
    );
  });

  testWidgets('DymOriginBadge : libellé et couleurs de l’origine', (
    tester,
  ) async {
    await pumpDym(
      tester,
      const DymOriginBadge(origin: StoreOrigin.maison, label: 'Fait maison'),
    );
    expect(find.text('Fait maison'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Fait maison'));
    expect(text.style?.color, DymColors.light.originMaisonFg);
  });

  testWidgets('DymProductCard : « + » ajoute, puis compteur', (tester) async {
    var quantity = 0;
    await pumpDym(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 180,
          height: 300,
          child: DymProductCard(
            image: testImage,
            name: 'Tomates fraîches',
            unit: 'le tas',
            price: price,
            quantity: quantity,
            onQuantityChanged: (q) => setState(() => quantity = q),
          ),
        ),
      ),
    );
    expect(find.byType(DymQuantityStepper), findsNothing);
    final add = find.bySemanticsLabel('Ajouter Tomates fraîches');
    expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(quantity, 1);
    expect(find.byType(DymQuantityStepper), findsOneWidget);
  });

  testWidgets('DymQuantityStepper : bornes min et max', (tester) async {
    var q = 1;
    await pumpDym(
      tester,
      StatefulBuilder(
        builder: (context, setState) => DymQuantityStepper(
          quantity: q,
          min: 1,
          max: 2,
          dense: true,
          onChanged: (v) => setState(() => q = v),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DymQuantityStepper)).height, 48);
    await tester.tap(find.byIcon(Icons.remove_rounded));
    expect(q, 1);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(q, 2);
    await tester.tap(find.byIcon(Icons.add_rounded));
    expect(q, 2);
  });

  testWidgets('DymMiniCartBar : caché à 0 article, visible ensuite', (
    tester,
  ) async {
    Widget bar(int n) => SizedBox(
      width: 380,
      child: DymMiniCartBar(
        itemCount: n,
        total: price * n,
        summary: '$n articles',
        actionLabel: 'Voir le panier',
        onTap: () {},
      ),
    );
    await pumpDym(tester, bar(0), disableAnimations: true);
    await tester.pump();
    final hidden = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byType(DymMiniCartBar),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(hidden.ignoring, isTrue);
    await pumpDym(tester, bar(3), disableAnimations: true);
    await tester.pump();
    expect(find.text('3 articles'), findsOneWidget);
  });

  final widgets = <String, Widget>{
    'DymTimeline': const DymTimeline(
      steps: [
        DymStep('Confirmée', DymStepState.done),
        DymStep('En route', DymStepState.current),
        DymStep('Livrée', DymStepState.todo),
      ],
    ),
    'DymPaymentOption': DymPaymentOption(
      title: 'Cash à la livraison',
      selected: true,
      onTap: () {},
    ),
    'DymSelectableCard': DymSelectableCard(
      image: testImage,
      title: 'Depuis chez moi',
      description: 'Tu prépares ou vends depuis ta maison.',
      selected: true,
      onTap: () {},
      footer: const Text('Ton adresse reste privée'),
    ),
    'DymStateView': const DymStateView(
      kind: DymStateKind.offline,
      title: 'Tu es hors ligne',
      message: 'On reprend dès le retour du réseau.',
    ),
    'DymBottomNav': DymBottomNav(
      currentIndex: 1,
      onTap: (_) {},
      items: const [
        DymNavItem(icon: Icons.home_rounded, label: 'Accueil'),
        DymNavItem(icon: Icons.grid_view_rounded, label: 'Rayons'),
      ],
    ),
  };
  for (final MapEntry(key: name, value: widget) in widgets.entries) {
    testWidgets('$name s’affiche sans erreur', (tester) async {
      await pumpDym(
        tester,
        SizedBox(width: 380, child: widget),
        disableAnimations: true,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
