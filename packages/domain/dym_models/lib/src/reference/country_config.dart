import 'package:dym_core/dym_core.dart';
import 'package:dym_models/src/reference/reference_models.dart';
import 'package:meta/meta.dart';

/// Configuration complète d'un pays, lue en une série de requêtes.
@immutable
class CountryConfig {
  const new({
    required this.country,
    required this.currency,
    required this.cities,
    required this.zones,
    required this.categories,
    required this.storeOrigins,
    required this.units,
    required this.paymentMethods,
    required this.deliveryFees,
    required this.featureFlags,
  });

  final Country country;
  final Currency currency;
  final List<City> cities;
  final List<Zone> zones;
  final List<Category> categories;
  final List<StoreOriginInfo> storeOrigins;
  final List<MarketUnit> units;
  final List<PaymentMethod> paymentMethods;
  final List<DeliveryFeeDefault> deliveryFees;
  final List<FeatureFlag> featureFlags;

  /// Quartiers d'une ville.
  List<Zone> zonesOf(String cityId) =>
      zones.where((z) => z.cityId == cityId).toList();

  /// Rayons de premier niveau.
  List<Category> get topCategories =>
      categories.where((c) => c.isTopLevel).toList();

  /// Sous-rayons d'un rayon.
  List<Category> subCategoriesOf(String parentId) =>
      categories.where((c) => c.parentId == parentId).toList();

  /// Une fonction est active si un flag propre au pays l'active, ou à défaut
  /// le flag global. Absente : inactive.
  bool isEnabled(String key) {
    final local = featureFlags
        .where((f) => f.key == key && f.countryCode == country.code)
        .firstOrNull;
    if (local != null) return local.isEnabled;
    return featureFlags
            .where((f) => f.key == key && f.countryCode == null)
            .firstOrNull
            ?.isEnabled ??
        false;
  }

  /// Frais par défaut d'une ville (ou du pays à défaut).
  DeliveryFeeDefault? deliveryFeeFor(String? cityId) =>
      deliveryFees.where((f) => f.cityId == cityId).firstOrNull ??
      deliveryFees.where((f) => f.cityId == null).firstOrNull;

  /// Montant en devise du pays.
  Money money(int amountMinor) => Money(amountMinor, currency);
}
