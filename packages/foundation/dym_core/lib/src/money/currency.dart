import 'package:meta/meta.dart';

/// Devise ISO 4217 et règles d'affichage.
///
/// En production, les devises viennent de la table de référence `currencies` ;
/// les constantes [xof] et [ghs] servent aux tests et à la démonstration.
@immutable
class Currency {
  /// Crée une devise. [code] : 3 lettres majuscules ; [minorUnits] : 0 à 3.
  new({
    required this.code,
    required this.minorUnits,
    required this.symbol,
    required this.locale,
  }) {
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      throw ArgumentError.value(code, 'code', 'ISO 4217 attendu');
    }
    if (minorUnits < 0 || minorUnits > 3) {
      throw ArgumentError.value(minorUnits, 'minorUnits', '0 à 3');
    }
  }

  /// Franc CFA (UEMOA) : aucune décimale.
  static final Currency xof = Currency(
    code: 'XOF',
    minorUnits: 0,
    symbol: 'F CFA',
    locale: 'fr',
  );

  /// Cedi ghanéen : deux décimales.
  static final Currency ghs = Currency(
    code: 'GHS',
    minorUnits: 2,
    symbol: 'GH₵',
    locale: 'en',
  );

  /// Code ISO 4217 (ex. `XOF`).
  final String code;

  /// Nombre de décimales de la devise (0 pour XOF, 2 pour GHS).
  final int minorUnits;

  /// Symbole affiché (ex. `F CFA`).
  final String symbol;

  /// Locale de formatage des nombres (ex. `fr`).
  final String locale;

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
