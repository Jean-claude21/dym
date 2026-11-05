import 'package:dym_core/dym_core.dart';
import 'package:test/test.dart';

/// Normalise les espaces insécables (fines ou non) produits par `intl`.
String _plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

void main() {
  group('Currency', () {
    test('refuse un code non ISO 4217', () {
      expect(
        () => Currency(code: 'xof', minorUnits: 0, symbol: 'F', locale: 'fr'),
        throwsArgumentError,
      );
    });

    test('refuse plus de 3 décimales', () {
      expect(
        () => Currency(code: 'ABC', minorUnits: 4, symbol: 'A', locale: 'en'),
        throwsArgumentError,
      );
    });
  });

  group('Money', () {
    final xof = Currency.xof;
    final ghs = Currency.ghs;

    test('formate le franc CFA sans décimale', () {
      expect(_plain(Money(4100, xof).format()), '4 100 F CFA');
      expect(_plain(Money(1250000, xof).format()), '1 250 000 F CFA');
      expect(_plain(Money(500, xof).format()), '500 F CFA');
    });

    test('formate le cedi avec deux décimales', () {
      final text = _plain(Money(8815, ghs).format());
      expect(text, contains('GH₵'));
      expect(text, contains('88.15'));
    });

    test('additionne et multiplie dans la même devise', () {
      final line = Money(500, xof) * 2;
      expect(line, Money(1000, xof));
      expect(line + Money(300, xof), Money(1300, xof));
    });

    test('refuse de mélanger deux devises', () {
      expect(() => Money(100, xof) + Money(100, ghs), throwsArgumentError);
      expect(
        () => Money(100, xof).compareTo(Money(100, ghs)),
        throwsArgumentError,
      );
    });

    test('refuse une quantité négative', () {
      expect(() => Money(100, xof) * -1, throwsArgumentError);
    });

    test('compare et détecte le zéro', () {
      expect(Money.zero(xof).isZero, isTrue);
      expect(Money(700, xof).compareTo(Money(600, xof)), greaterThan(0));
    });

    test('panier de démonstration : 3 400 + 700 = 4 100 F CFA', () {
      final subtotal =
          Money(500, xof) * 2 +
          Money(300, xof) +
          Money(700, xof) * 2 +
          Money(700, xof);
      expect(subtotal, Money(3400, xof));
      expect(_plain((subtotal + Money(700, xof)).format()), '4 100 F CFA');
    });
  });
}
