import 'dart:math' as math;

import 'package:dym_core/src/money/currency.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

/// Montant en unités mineures et devise. Jamais de nombre à virgule.
@immutable
class Money implements Comparable<Money> {
  /// Crée un montant de [amountMinor] unités mineures dans [currency].
  const new(this.amountMinor, this.currency);

  /// Montant nul dans [currency].
  const new zero(this.currency) : amountMinor = 0;

  /// Lit un montant saisi en unités principales (« 1 000 », « 12,50 »,
  /// « 12.5 ») et le renvoie en unités mineures, sans calcul en virgule
  /// flottante. `null` si la saisie est invalide ou porte trop de décimales.
  static int? parseMajor(String input, Currency currency) {
    final text = input.replaceAll(RegExp(r'[\s  ]'), '');
    final match = RegExp(r'^(\d+)(?:[.,](\d+))?$').firstMatch(text);
    if (match == null) return null;
    final whole = match.group(1)!;
    final fraction = match.group(2) ?? '';
    if (fraction.length > currency.minorUnits || whole.length > 12) return null;
    return int.parse(whole + fraction.padRight(currency.minorUnits, '0'));
  }

  /// Montant en unités mineures (4100 = 4 100 F CFA ; 8815 = GH₵88,15).
  final int amountMinor;

  /// Devise du montant.
  final Currency currency;

  /// Vrai si le montant est nul.
  bool get isZero => amountMinor == 0;

  /// Additionne deux montants de même devise.
  ///
  /// Lève une [ArgumentError] si les devises diffèrent.
  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(amountMinor + other.amountMinor, currency);
  }

  /// Soustrait deux montants de même devise.
  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(amountMinor - other.amountMinor, currency);
  }

  /// Multiplie par une quantité entière positive ou nulle.
  Money operator *(int quantity) {
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'doit être ≥ 0');
    }
    return Money(amountMinor * quantity, currency);
  }

  /// Formate le montant selon la devise : « 4 100 F CFA », « GH₵88.15 ».
  String format() {
    final value = amountMinor / math.pow(10, currency.minorUnits);
    final pattern = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: currency.minorUnits,
    );
    return pattern.format(value);
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return amountMinor.compareTo(other.amountMinor);
  }

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Devises différentes : ${currency.code} et ${other.currency.code}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amountMinor == amountMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amountMinor, currency);

  @override
  String toString() => '$amountMinor ${currency.code}';
}
