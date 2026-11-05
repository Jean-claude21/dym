import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_screen.dart';

const _phone = Size(412, 915);
const _tablet = Size(800, 1280);
const _tabletLandscape = Size(1280, 800);
const _desktop = Size(1440, 900);

List<Rect> _rects(WidgetTester tester, Finder finder) => [
  for (final e in finder.evaluate())
    tester.getRect(find.byElementPredicate((x) => x == e)),
];

/// Colonnes de la première ligne d'une grille de cartes.
int _firstRowColumns(WidgetTester tester, Finder cards) {
  final rects = _rects(tester, cards);
  final top = rects.first.top;
  return rects.where((r) => (r.top - top).abs() < 1).length;
}

void main() {
  group('bornes sur bureau (SC-003)', () {
    for (final id in ['06', '07', '08']) {
      testWidgets('écran $id : formulaire ≤ 600, centré', (tester) async {
        await pumpScreen(tester, screenById(id), size: _desktop);
        final rects = _rects(
          tester,
          find.descendant(
            of: find.byType(ListView),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DymButton ||
                  w is DymSelectableCard ||
                  w is DymTimeline ||
                  w is ClipRRect,
            ),
          ),
        );
        expect(rects, isNotEmpty);
        final left = rects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
        final right = rects.map((r) => r.right).reduce((a, b) => a > b ? a : b);
        expect(right - left, lessThanOrEqualTo(DymTokenLayout.formMax));
        expect((left + right) / 2, closeTo(720, 1));
      });
    }

    for (final id in ['02', '03', '04']) {
      testWidgets('écran $id : contenu ≤ 1 200, mini-panier ≤ 560', (
        tester,
      ) async {
        await pumpScreen(tester, screenById(id), size: _desktop);
        final cards = _rects(tester, find.byType(DymProductCard));
        final left = cards.map((r) => r.left).reduce((a, b) => a < b ? a : b);
        final right = cards.map((r) => r.right).reduce((a, b) => a > b ? a : b);
        expect(right - left, lessThanOrEqualTo(DymTokenLayout.contentMax));
        final bar = tester.getRect(
          find.descendant(
            of: find.byType(DymMiniCartBar),
            matching: find.byType(Material),
          ),
        );
        expect(bar.width, lessThanOrEqualTo(DymTokenLayout.floatingMax));
      });
    }
  });

  group('le contenu profite de la place (US2)', () {
    final expected = <Size, Matcher>{
      _phone: equals(2),
      _tablet: greaterThanOrEqualTo(3),
      _tabletLandscape: greaterThanOrEqualTo(4),
      _desktop: greaterThanOrEqualTo(4),
    };
    for (final MapEntry(key: size, value: matcher) in expected.entries) {
      testWidgets('rayon : colonnes à ${size.width.toInt()} (SC-004)', (
        tester,
      ) async {
        await pumpScreen(tester, screenById('03'), size: size);
        expect(_firstRowColumns(tester, find.byType(DymProductCard)), matcher);
      });
    }

    testWidgets("rayons de l'accueil : 4 sur téléphone, plus sur bureau", (
      tester,
    ) async {
      await pumpScreen(tester, screenById('02'), size: _phone);
      expect(_firstRowColumns(tester, find.byType(DymAisleTile)), 4);
      await pumpScreen(tester, screenById('02'), size: _desktop);
      expect(
        _firstRowColumns(tester, find.byType(DymAisleTile)),
        greaterThan(4),
      );
    });

    testWidgets('panier : une colonne sur téléphone', (tester) async {
      await pumpScreen(tester, screenById('05'), size: _phone);
      final gauge = tester.getRect(find.byType(DymFreeDeliveryGauge));
      final pay = tester.getRect(find.byType(DymPaymentOption).first);
      expect(pay.top, greaterThan(gauge.bottom));
    });

    testWidgets('panier : deux colonnes sur bureau (FR-009)', (tester) async {
      await pumpScreen(tester, screenById('05'), size: _desktop);
      final gauge = tester.getRect(find.byType(DymFreeDeliveryGauge));
      final pay = tester.getRect(find.byType(DymPaymentOption).first);
      final order = tester.getRect(find.byType(DymButton));
      expect(pay.left, greaterThan(gauge.right));
      expect(order.left, greaterThan(gauge.right));
      expect(order.bottom, lessThanOrEqualTo(_desktop.height));
    });
  });

  group("navigation adaptative de l'accueil (US3)", () {
    testWidgets('téléphone : barre basse', (tester) async {
      await pumpScreen(tester, screenById('02'), size: _phone);
      expect(find.byType(DymBottomNav), findsOneWidget);
      expect(find.byType(DymNavRail), findsNothing);
    });

    testWidgets('tablette : rail', (tester) async {
      await pumpScreen(tester, screenById('02'), size: _tablet);
      expect(find.byType(DymBottomNav), findsNothing);
      expect(
        tester.widget<DymNavRail>(find.byType(DymNavRail)).extended,
        isFalse,
      );
    });

    testWidgets('bureau : rail étendu', (tester) async {
      await pumpScreen(tester, screenById('02'), size: _desktop);
      expect(
        tester.widget<DymNavRail>(find.byType(DymNavRail)).extended,
        isTrue,
      );
    });
  });
}
