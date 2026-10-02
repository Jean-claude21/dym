import 'package:dym_core/dym_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money.parseMajor', () {
    test('F CFA : entier, espaces de milliers', () {
      expect(Money.parseMajor('1 000', Currency.xof), 1000);
      expect(Money.parseMajor('500', Currency.xof), 500);
      expect(Money.parseMajor('12,5', Currency.xof), isNull);
    });

    test('cedi : deux décimales, virgule ou point', () {
      expect(Money.parseMajor('12,50', Currency.ghs), 1250);
      expect(Money.parseMajor('12.5', Currency.ghs), 1250);
      expect(Money.parseMajor('3', Currency.ghs), 300);
      expect(Money.parseMajor('1.234', Currency.ghs), isNull);
    });

    test('saisie invalide', () {
      expect(Money.parseMajor('', Currency.xof), isNull);
      expect(Money.parseMajor('-5', Currency.xof), isNull);
      expect(Money.parseMajor('abc', Currency.xof), isNull);
    });
  });
}
