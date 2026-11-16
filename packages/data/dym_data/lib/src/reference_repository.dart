import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Lecture du référentiel (Data API, RLS : actifs seulement, aucun droit
/// d'écriture). Fonctionne sans session (rôle anonyme).
class ReferenceRepository {
  new(this._data);

  final NeonDataClient _data;

  /// Pays ouverts, triés.
  Future<Result<List<Country>>> countries() => _list(
    'countries',
    'code, name, currency_code, dial_code, default_locale, timezone, sort',
    Country.fromJson,
    order: 'sort',
  );

  /// Devises du référentiel (affichage des montants de tous les pays).
  Future<Result<List<CurrencyInfo>>> currencies() => _list(
    'currencies',
    'code, minor_units, symbol, format_locale',
    CurrencyInfo.fromJson,
    order: 'code',
  );

  /// Configuration complète d'un pays, en lectures parallèles.
  Future<Result<CountryConfig>> countryConfig(String countryCode) async {
    final country = await _data.run(
      (db) => db
          .from('countries')
          .select(
            'code, name, currency_code, dial_code, default_locale, timezone, '
            'sort, '
            'currency:currencies(code, minor_units, symbol, format_locale), '
            'delivery_settings(max_distance_m)',
          )
          .eq('code', countryCode)
          .maybeSingle(),
    );
    if (country case Err(:final failure)) return Err(failure);
    final row = country.valueOrNull;
    if (row == null) {
      return Err(NotFoundFailure('pays $countryCode inactif ou inconnu'));
    }

    final results = await Future.wait<Result<List<Object>>>([
      _list(
        'cities',
        'id, country_code, slug, name, sort',
        City.fromJson,
        eq: {'country_code': countryCode},
        order: 'sort',
      ),
      _list(
        'zones',
        'id, city_id, slug, name, sort, latitude, longitude, '
            'city:cities!inner(country_code)',
        Zone.fromJson,
        eq: {'city.country_code': countryCode},
        order: 'sort',
      ),
      _list(
        'categories',
        'id, parent_id, slug, label, icon, sort',
        Category.fromJson,
        order: 'sort',
      ),
      _list(
        'store_origins',
        'code, label, description, sort',
        StoreOriginInfo.fromJson,
        order: 'sort',
      ),
      _list(
        'units',
        'id, country_code, code, label, kind, indicative_grams, '
            'indicative_ml, sort',
        MarketUnit.fromJson,
        eq: {'country_code': countryCode},
        order: 'sort',
      ),
      _list(
        'payment_methods',
        'id, country_code, provider_code, operator_code, label, sort',
        PaymentMethod.fromJson,
        eq: {'country_code': countryCode},
        order: 'sort',
      ),
      _list(
        'delivery_fee_defaults',
        'country_code, city_id, currency_code, base_fee_minor, '
            'extra_pickup_fee_minor, free_threshold_minor',
        DeliveryFeeDefault.fromJson,
        eq: {'country_code': countryCode},
        isNull: 'valid_to',
      ),
      _list(
        'feature_flags',
        'key, country_code, is_enabled',
        FeatureFlag.fromJson,
      ),
    ]);
    for (final r in results) {
      if (r case Err(:final failure)) return Err(failure);
    }
    List<T> at<T>(int i) => results[i].valueOrNull!.cast<T>();

    try {
      final currencyJson = row['currency'];
      if (currencyJson is! Map<String, dynamic>) {
        throw const FormatException('devise absente');
      }
      return Ok(
        CountryConfig(
          country: Country.fromJson(row),
          currency: CurrencyInfo.fromJson(currencyJson).toCurrency(),
          cities: at<City>(0),
          zones: at<Zone>(1),
          categories: at<Category>(2),
          storeOrigins: at<StoreOriginInfo>(3),
          units: at<MarketUnit>(4),
          paymentMethods: at<PaymentMethod>(5),
          deliveryFees: at<DeliveryFeeDefault>(6),
          maxDeliveryDistanceM: _maxDistance(row['delivery_settings']),
          featureFlags: at<FeatureFlag>(7)
              .where(
                (f) => f.countryCode == null || f.countryCode == countryCode,
              )
              .toList(),
        ),
      );
    } on Object catch (error) {
      return Err(failureFrom(error));
    }
  }

  Future<Result<List<T>>> _list<T extends Object>(
    String table,
    String columns,
    T Function(Map<String, dynamic>) decode, {
    Map<String, Object>? eq,
    String? isNull,
    String? order,
  }) async {
    final result = await _data.run((db) {
      var query = db.from(table).select(columns);
      for (final e in (eq ?? const {}).entries) {
        query = query.eq(e.key, e.value);
      }
      if (isNull != null) query = query.isFilter(isNull, null);
      return order == null ? query : query.order(order, ascending: true);
    });
    return switch (result) {
      Ok(:final value) => _decodeAll(value, decode),
      Err(:final failure) => Err(failure),
    };
  }

  Result<List<T>> _decodeAll<T>(
    List<Map<String, dynamic>> rows,
    T Function(Map<String, dynamic>) decode,
  ) {
    try {
      return Ok([for (final row in rows) decode(row)]);
    } on Object catch (error) {
      return Err(ServerFailure('donnée illisible : ${error.runtimeType}'));
    }
  }

  /// Distance maximale du pays (spec 096) ; 20 km sans réglage.
  static int _maxDistance(Object? json) {
    final row = switch (json) {
      final List<dynamic> l when l.isNotEmpty => l.first,
      final Map<dynamic, dynamic> m => m,
      _ => null,
    };
    return switch (row) {
      {'max_distance_m': final num m} => m.toInt(),
      _ => 20000,
    };
  }
}
