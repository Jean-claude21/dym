import 'package:dym_core/dym_core.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('DymWindowClass (FR-001)', () {
    test('seuils : un seuil appartient à la classe supérieure', () {
      expect(DymWindowClass.fromWidth(360), DymWindowClass.compact);
      expect(DymWindowClass.fromWidth(599.9), DymWindowClass.compact);
      expect(DymWindowClass.fromWidth(600), DymWindowClass.medium);
      expect(DymWindowClass.fromWidth(839), DymWindowClass.medium);
      expect(DymWindowClass.fromWidth(840), DymWindowClass.expanded);
      expect(DymWindowClass.fromWidth(1199), DymWindowClass.expanded);
      expect(DymWindowClass.fromWidth(1200), DymWindowClass.large);
      expect(DymWindowClass.fromWidth(2560), DymWindowClass.large);
    });

    test('classes ordonnées', () {
      expect(DymWindowClass.large >= DymWindowClass.expanded, isTrue);
      expect(DymWindowClass.medium >= DymWindowClass.expanded, isFalse);
      expect(DymWindowClass.compact < DymWindowClass.medium, isTrue);
    });

    testWidgets('of(context) suit la taille de la fenêtre', (tester) async {
      late DymWindowClass seen;
      await pumpDym(
        tester,
        Builder(
          builder: (context) {
            seen = DymWindowClass.of(context);
            return const SizedBox();
          },
        ),
        size: const Size(800, 1280),
      );
      expect(seen, DymWindowClass.medium);
    });
  });

  group('DymLayout', () {
    test('marges 16 / 24 / 32 / 32', () {
      expect(DymLayout.gutterFor(DymWindowClass.compact), 16);
      expect(DymLayout.gutterFor(DymWindowClass.medium), 24);
      expect(DymLayout.gutterFor(DymWindowClass.expanded), 32);
      expect(DymLayout.gutterFor(DymWindowClass.large), 32);
    });

    test('colonnes de produits : 2 sur téléphone, ≥ 3 tablette, ≥ 4 large', () {
      int products(double w) =>
          DymLayout.columns(w, minTileWidth: 168, spacing: 12, min: 2, max: 6);
      expect(products(360 - 32), 2);
      expect(products(412 - 32), 2);
      expect(products(800 - 48), greaterThanOrEqualTo(3));
      expect(products(1280 - 64), greaterThanOrEqualTo(4));
      expect(products(5000), 6);
    });

    test('sideInset : marge sur téléphone, centrage au-delà du maximum', () {
      expect(DymLayout.sideInset(412, gutter: 16), 16);
      expect(DymLayout.sideInset(1440, gutter: 32), 120);
      expect(
        DymLayout.sideInset(1440, gutter: 32, maxWidth: DymTokenLayout.formMax),
        420,
      );
    });

    test('lignes équilibrées avec itemCount', () {
      int aisles(double w) => DymLayout.columns(
        w,
        minTileWidth: 104,
        spacing: 8,
        min: 4,
        max: 8,
        itemCount: 8,
      );
      expect(aisles(380), 4);
      expect(aisles(664), 4);
      expect(aisles(1156), 8);
      expect(DymLayout.columns(700, minTileWidth: 90, itemCount: 9), 5);
    });

    test('minimum garanti même si la place manque', () {
      expect(DymLayout.columns(100, minTileWidth: 168, min: 2), 2);
    });
  });

  group('DymContentWidth (FR-004)', () {
    testWidgets('identité sur téléphone', (tester) async {
      await pumpDym(
        tester,
        const DymContentWidth(child: SizedBox(key: Key('c'), height: 10)),
      );
      expect(tester.getSize(find.byKey(const Key('c'))).width, 412);
    });

    testWidgets('borné et centré sur bureau', (tester) async {
      await pumpDym(
        tester,
        const DymContentWidth.form(child: SizedBox(key: Key('c'), height: 10)),
        size: const Size(1440, 900),
      );
      final rect = tester.getRect(find.byKey(const Key('c')));
      expect(rect.width, DymTokenLayout.formMax);
      expect(rect.center.dx, closeTo(720, 0.5));
    });

    testWidgets('padded applique la marge de la classe', (tester) async {
      await pumpDym(
        tester,
        const DymContentWidth(
          padded: true,
          child: SizedBox(key: Key('c'), height: 10),
        ),
        size: const Size(800, 1280),
      );
      expect(tester.getSize(find.byKey(const Key('c'))).width, 800 - 48);
    });
  });

  group('DymMiniCartBar borné (FR-006)', () {
    Widget bar() => DymMiniCartBar(
      key: const Key('bar'),
      itemCount: 2,
      total: Money(1500, Currency.xof),
      summary: '2 articles · 1 500 F CFA',
      actionLabel: 'Voir le panier',
      onTap: () {},
    );

    testWidgets('pleine largeur sur téléphone', (tester) async {
      await pumpDym(
        tester,
        Padding(padding: const EdgeInsets.all(16), child: bar()),
      );
      expect(tester.getSize(find.byType(Material).last).width, 412 - 32);
    });

    testWidgets('≤ 560 et centré sur bureau', (tester) async {
      await pumpDym(tester, bar(), size: const Size(1440, 900));
      final rect = tester.getRect(find.byType(Material).last);
      expect(rect.width, DymTokenLayout.floatingMax);
      expect(rect.center.dx, closeTo(720, 0.5));
    });
  });
}
