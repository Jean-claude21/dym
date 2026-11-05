import 'package:dym_core/dym_core.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('micro-interactions ≤ 450 ms (FR-010)', () {
    expect(DymMotion.fast.inMilliseconds, lessThanOrEqualTo(450));
    expect(DymMotion.medium.inMilliseconds, lessThanOrEqualTo(450));
    expect(DymMotion.slow.inMilliseconds, lessThanOrEqualTo(450));
  });

  testWidgets('« réduire les animations » : durée nulle', (tester) async {
    late Duration resolved;
    await pumpDym(
      tester,
      Builder(
        builder: (context) {
          resolved = DymMotion.of(context, DymMotion.slow);
          return const SizedBox();
        },
      ),
      disableAnimations: true,
    );
    expect(resolved, Duration.zero);
  });

  testWidgets('ajout au panier : animation terminée en ≤ 450 ms', (
    tester,
  ) async {
    var quantity = 0;
    await pumpDym(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 180,
          height: 300,
          child: DymProductCard(
            image: testImage,
            name: 'Gombo frais',
            unit: 'le tas',
            price: Money(300, Currency.xof),
            quantity: quantity,
            onQuantityChanged: (q) => setState(() => quantity = q),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Ajouter Gombo frais'));
    await tester.pump();
    await tester.pump(DymMotion.slow);
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(DymQuantityStepper), findsOneWidget);
  });

  testWidgets('mini-panier : apparition terminée en ≤ 450 ms', (tester) async {
    Widget bar(int n) => SizedBox(
      width: 380,
      child: DymMiniCartBar(
        itemCount: n,
        total: Money(500, Currency.xof) * n,
        summary: '$n articles',
        actionLabel: 'Voir le panier',
        onTap: () {},
      ),
    );
    await pumpDym(tester, bar(0));
    await pumpDym(tester, bar(1));
    await tester.pump();
    await tester.pump(DymMotion.slow);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
