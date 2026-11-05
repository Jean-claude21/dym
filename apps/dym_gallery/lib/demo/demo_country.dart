import 'package:dym_core/dym_core.dart';
import 'package:flutter/foundation.dart';

/// Pays de démonstration. En production, pays et devises viendront des
/// tables de référence ; ici ils prouvent que l'interface suit la config.
@immutable
class DemoCountry {
  const new({
    required this.code,
    required this.name,
    required this.currency,
    required this.city,
    required this.zone,
    required this.ratePerXof,
  });

  static final togo = DemoCountry(
    code: 'TG',
    name: 'Togo',
    currency: Currency.xof,
    city: 'Bè, Lomé',
    zone: 'Bè',
    ratePerXof: 1,
  );

  static final ghana = DemoCountry(
    code: 'GH',
    name: 'Ghana',
    currency: Currency.ghs,
    city: 'Osu, Accra',
    zone: 'Osu',
    ratePerXof: 0.0215,
  );

  final String code;
  final String name;
  final Currency currency;
  final String city;
  final String zone;

  /// Taux de démonstration appliqué aux prix saisis en F CFA (démo uniquement).
  final double ratePerXof;

  /// Prix de démonstration saisi en F CFA, exprimé dans la devise du pays.
  Money price(int xof) {
    final factor = _pow10(currency.minorUnits);
    return Money((xof * ratePerXof * factor).round(), currency);
  }

  static int _pow10(int n) => n == 0 ? 1 : 10 * _pow10(n - 1);
}

/// Pays sélectionné dans la galerie.
final demoCountry = ValueNotifier<DemoCountry>(DemoCountry.togo);
