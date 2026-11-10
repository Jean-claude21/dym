import 'package:dym_core/dym_core.dart';
import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Formule (spec 052) : DYM+, vendeuse Pro, visibilité. Avantages lus en base.
@immutable
class MembershipPlan {
  const new({
    required this.id,
    required this.code,
    required this.name,
    required this.priceMinor,
    required this.periodDays,
    this.description,
    this.benefits = const {},
    this.activeUntil,
  });

  factory fromJson(Map<String, dynamic> json) => MembershipPlan(
    id: json['id']! as String,
    code: json['code']! as String,
    name: LocalizedText.fromJson(json['name']),
    description: json['description'] == null
        ? null
        : LocalizedText.fromJson(json['description']),
    priceMinor: minorFromJson(json['price_minor']),
    periodDays: (json['period_days']! as num).toInt(),
    benefits: (json['benefits'] as Map?)?.cast<String, Object?>() ?? const {},
    activeUntil: switch (json['active_until']) {
      final String s => DateTime.parse(s),
      _ => null,
    },
  );

  final String id;
  final String code;
  final LocalizedText name;
  final LocalizedText? description;
  final int priceMinor;
  final int periodDays;

  /// `delivery_refund`, `cashback_bonus_bps`, `commission_discount_bps`,
  /// `sponsored`.
  final Map<String, Object?> benefits;

  /// Fin de la formule en cours (nulle : pas abonnée).
  final DateTime? activeUntil;

  bool get active => activeUntil != null;

  bool flag(String key) => benefits[key] == true;

  /// Avantage en points de base (0 : aucun).
  int bps(String key) => (benefits[key] as num?)?.toInt() ?? 0;
}

/// Formules proposées et solde du wallet (`membership_offer()`).
@immutable
class MembershipOffer {
  const new({this.plans = const [], this.walletBalanceMinor = 0});

  factory fromJson(Map<String, dynamic> json) => MembershipOffer(
    plans: [
      for (final p in json['plans'] as List? ?? const [])
        MembershipPlan.fromJson((p as Map).cast<String, dynamic>()),
    ],
    walletBalanceMinor: minorFromJson(json['wallet_balance_minor'] ?? 0),
  );

  final List<MembershipPlan> plans;
  final int walletBalanceMinor;
}
