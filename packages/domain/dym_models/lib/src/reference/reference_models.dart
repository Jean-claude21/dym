import 'package:dym_core/dym_core.dart';
import 'package:dym_models/src/json.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'reference_models.g.dart';

/// Devise du référentiel (`currencies`).
@immutable
@JsonSerializable()
class CurrencyInfo {
  const new({
    required this.code,
    required this.minorUnits,
    required this.symbol,
    required this.formatLocale,
  });

  factory fromJson(Map<String, dynamic> json) => _$CurrencyInfoFromJson(json);

  final String code;
  final int minorUnits;
  final String symbol;
  final String formatLocale;

  /// Devise utilisable par `Money`.
  Currency toCurrency() => Currency(
    code: code,
    minorUnits: minorUnits,
    symbol: symbol,
    locale: formatLocale,
  );
}

/// Pays (`countries`).
@immutable
@JsonSerializable()
class Country {
  const new({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.dialCode,
    required this.defaultLocale,
    required this.timezone,
    this.sort = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$CountryFromJson(json);

  final String code;
  @LocalizedTextConverter()
  final LocalizedText name;
  final String currencyCode;
  final String dialCode;
  final String defaultLocale;
  final String timezone;
  final int sort;
}

/// Ville (`cities`).
@immutable
@JsonSerializable()
class City {
  const new({
    required this.id,
    required this.countryCode,
    required this.slug,
    required this.name,
    this.sort = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$CityFromJson(json);

  final String id;
  final String countryCode;
  final String slug;
  final String name;
  final int sort;
}

/// Quartier (`zones`).
@immutable
@JsonSerializable()
class Zone {
  const new({
    required this.id,
    required this.cityId,
    required this.slug,
    required this.name,
    this.sort = 0,
    this.latitude,
    this.longitude,
  });

  factory fromJson(Map<String, dynamic> json) => _$ZoneFromJson(json);

  final String id;
  final String cityId;
  final String slug;
  final String name;
  final int sort;

  /// Centre du quartier (carte, spec 095).
  final double? latitude;
  final double? longitude;
}

/// Rayon (`categories`), deux niveaux.
@immutable
@JsonSerializable()
class Category {
  const new({
    required this.id,
    required this.slug,
    required this.label,
    this.parentId,
    this.icon,
    this.sort = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  final String id;
  final String? parentId;
  final String slug;
  @LocalizedTextConverter()
  final LocalizedText label;
  final String? icon;
  final int sort;

  bool get isTopLevel => parentId == null;
}

/// Origine de boutique (`store_origins`) : `marche`, `maison`, `magasin`…
@immutable
@JsonSerializable()
class StoreOriginInfo {
  const new({
    required this.code,
    required this.label,
    this.description,
    this.sort = 0,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$StoreOriginInfoFromJson(json);

  final String code;
  @LocalizedTextConverter()
  final LocalizedText label;
  @NullableLocalizedTextConverter()
  final LocalizedText? description;
  final int sort;
}

/// Nature d'une unité du marché.
enum UnitKind { piece, weight, volume, bundle }

/// Unité du marché (`units`) : le tas, la botte, l'olonka…
@immutable
@JsonSerializable()
class MarketUnit {
  const new({
    required this.id,
    required this.countryCode,
    required this.code,
    required this.label,
    required this.kind,
    this.indicativeGrams,
    this.indicativeMl,
    this.sort = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$MarketUnitFromJson(json);

  final String id;
  final String countryCode;
  final String code;
  @LocalizedTextConverter()
  final LocalizedText label;
  final UnitKind kind;
  final int? indicativeGrams;
  final int? indicativeMl;
  final int sort;
}

/// Type de fournisseur de paiement.
enum PaymentKind {
  cash,
  @JsonValue('mobile_money')
  mobileMoney,
  card,
  digital,
}

/// Moyen de paiement proposé dans un pays (`payment_methods` + fournisseur).
@immutable
@JsonSerializable()
class PaymentMethod {
  const new({
    required this.id,
    required this.countryCode,
    required this.providerCode,
    required this.label,
    this.operatorCode,
    this.sort = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$PaymentMethodFromJson(json);

  final String id;
  final String countryCode;
  final String providerCode;
  final String? operatorCode;
  @LocalizedTextConverter()
  final LocalizedText label;
  final int sort;

  bool get isCash => providerCode == 'cash';
}

/// Frais de livraison par défaut (`delivery_fee_defaults`), en unités
/// mineures de la devise du pays. Indicatifs : le serveur recalcule.
@immutable
@JsonSerializable()
class DeliveryFeeDefault {
  const new({
    required this.countryCode,
    required this.currencyCode,
    required this.baseFeeMinor,
    required this.extraPickupFeeMinor,
    this.cityId,
    this.freeThresholdMinor,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$DeliveryFeeDefaultFromJson(json);

  final String countryCode;
  final String? cityId;
  final String currencyCode;
  @JsonKey(fromJson: minorFromJson)
  final int baseFeeMinor;
  @JsonKey(fromJson: minorFromJson)
  final int extraPickupFeeMinor;
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? freeThresholdMinor;
}

/// Règle de commission (`commission_rules`) en points de base (1 % = 100).
@immutable
@JsonSerializable()
class CommissionRule {
  const new({
    required this.countryCode,
    required this.rateBps,
    this.categoryId,
  });

  factory fromJson(Map<String, dynamic> json) => _$CommissionRuleFromJson(json);

  final String countryCode;
  final String? categoryId;
  final int rateBps;
}

/// Fonction activable (`feature_flags`) ; `countryCode` nul = globale.
@immutable
@JsonSerializable()
class FeatureFlag {
  const new({required this.key, required this.isEnabled, this.countryCode});

  factory fromJson(Map<String, dynamic> json) => _$FeatureFlagFromJson(json);

  final String key;
  final String? countryCode;
  final bool isEnabled;
}
