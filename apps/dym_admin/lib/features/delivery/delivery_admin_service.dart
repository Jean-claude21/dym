import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Tarif de livraison d'un pays (spec 096) : au km ou par tranches.
class DeliveryPricing {
  const new({
    this.mode = 'per_km',
    this.baseFeeMinor = 0,
    this.includedM = 0,
    this.perKmMinor = 0,
    this.minFeeMinor = 0,
    this.maxFeeMinor,
    this.roundingMinor = 1,
    this.longDistanceSurchargeMinor = 0,
  });

  factory fromJson(Map<String, dynamic> j) => DeliveryPricing(
    mode: j['mode'] as String? ?? 'per_km',
    baseFeeMinor: (j['base_fee_minor'] as num?)?.toInt() ?? 0,
    includedM: (j['included_m'] as num?)?.toInt() ?? 0,
    perKmMinor: (j['per_km_minor'] as num?)?.toInt() ?? 0,
    minFeeMinor: (j['min_fee_minor'] as num?)?.toInt() ?? 0,
    maxFeeMinor: (j['max_fee_minor'] as num?)?.toInt(),
    roundingMinor: (j['rounding_minor'] as num?)?.toInt() ?? 1,
    longDistanceSurchargeMinor:
        (j['long_distance_surcharge_minor'] as num?)?.toInt() ?? 0,
  );

  final String mode;
  final int baseFeeMinor;
  final int includedM;
  final int perKmMinor;
  final int minFeeMinor;
  final int? maxFeeMinor;
  final int roundingMinor;
  final int longDistanceSurchargeMinor;

  Map<String, Object?> toJson() => {
    'mode': mode,
    'base_fee_minor': baseFeeMinor,
    'included_m': includedM,
    'per_km_minor': perKmMinor,
    'min_fee_minor': minFeeMinor,
    'max_fee_minor': maxFeeMinor,
    'rounding_minor': roundingMinor,
    'long_distance_surcharge_minor': longDistanceSurchargeMinor,
  };
}

/// Majoration horaire (soir, week-end…), heure locale du pays.
class DeliverySurcharge {
  const new({
    required this.label,
    required this.startsAt,
    required this.endsAt,
    required this.percent,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
  });

  factory fromJson(Map<String, dynamic> j) => DeliverySurcharge(
    label: j['label'] as String? ?? '',
    startsAt: (j['starts_at'] as String? ?? '00:00').substring(0, 5),
    endsAt: (j['ends_at'] as String? ?? '00:00').substring(0, 5),
    percent: (j['percent'] as num?)?.toInt() ?? 0,
    weekdays: [
      for (final d in j['weekdays'] as List? ?? const [1, 2, 3, 4, 5, 6, 7])
        (d as num).toInt(),
    ],
  );

  final String label;
  final String startsAt;
  final String endsAt;
  final int percent;
  final List<int> weekdays;

  Map<String, Object> toJson() => {
    'label': label,
    'starts_at': startsAt,
    'ends_at': endsAt,
    'percent': percent,
    'weekdays': weekdays,
  };
}

/// Rayon proposé aux nouvelles boutiques d'une ville.
class CityRadius {
  const new({required this.cityId, required this.name, this.meters});

  final String cityId;
  final String name;
  final int? meters;
}

/// Réglages de livraison d'un pays.
class DeliveryConfig {
  const new({
    required this.countryCode,
    required this.maxDistanceM,
    this.pricing,
    this.surcharges = const [],
    this.bands = const [],
    this.cities = const [],
  });

  factory fromJson(Map<String, dynamic> j) => DeliveryConfig(
    countryCode: j['country_code'] as String? ?? '',
    maxDistanceM: (j['max_distance_m'] as num?)?.toInt() ?? 20000,
    pricing: switch (j['pricing']) {
      final Map<dynamic, dynamic> m => DeliveryPricing.fromJson(
        m.cast<String, dynamic>(),
      ),
      _ => null,
    },
    surcharges: [
      for (final s in j['surcharges'] as List? ?? const [])
        DeliverySurcharge.fromJson((s as Map).cast<String, dynamic>()),
    ],
    bands: [
      for (final b in j['bands'] as List? ?? const [])
        FeeBand.fromJson((b as Map).cast<String, dynamic>()),
    ],
    cities: [
      for (final c in j['cities'] as List? ?? const [])
        CityRadius(
          cityId: (c as Map)['id'] as String,
          name: c['name'] as String? ?? '',
          meters: (c['default_delivery_radius_m'] as num?)?.toInt(),
        ),
    ],
  );

  final String countryCode;
  final int maxDistanceM;
  final DeliveryPricing? pricing;
  final List<DeliverySurcharge> surcharges;
  final List<FeeBand> bands;
  final List<CityRadius> cities;
}

/// Livraison côté équipe (spec 096) : tarif, majorations, distances,
/// comptes à valider, incidents. Toutes les règles sont en SQL et auditées.
abstract interface class DeliveryAdminService {
  Future<Result<List<Country>>> countries();

  Future<Result<DeliveryConfig>> config(String countryCode);

  Future<Result<void>> savePricing(String countryCode, DeliveryPricing p);

  Future<Result<void>> saveSurcharges(
    String countryCode,
    List<DeliverySurcharge> surcharges,
  );

  Future<Result<void>> saveBands(String countryCode, List<FeeBand> bands);

  Future<Result<void>> saveMaxDistance(String countryCode, int meters);

  Future<Result<void>> saveCityRadius(String cityId, int meters);

  /// Frais simulés (unités mineures), majoration en vigueur.
  Future<Result<(int?, int)>> preview(
    String countryCode, {
    required int meters,
    required bool longDistance,
    DateTime? at,
  });

  Future<Result<List<PendingAccount>>> pendingAccounts();

  Future<Result<void>> review(
    PendingAccount account, {
    required bool approve,
    String? note,
  });

  Future<Result<List<DeliveryIncident>>> incidents();

  Future<Result<void>> resolve(DeliveryIncident incident);
}

class NeonDeliveryAdminService implements DeliveryAdminService {
  new({required this._data, required this._delivery, required this._reference});

  final NeonDataClient _data;
  final DeliveryRepository _delivery;
  final ReferenceRepository _reference;

  @override
  Future<Result<List<Country>>> countries() => _reference.countries();

  @override
  Future<Result<DeliveryConfig>> config(String countryCode) async =>
      (await _data.rpc<Object?>(
        'admin_delivery_config',
        params: {'p_country': countryCode},
      )).map((j) => DeliveryConfig.fromJson((j! as Map).cast()));

  @override
  Future<Result<void>> savePricing(String countryCode, DeliveryPricing p) =>
      _data.rpc<void>(
        'admin_set_delivery_pricing',
        params: {
          'p_country': countryCode,
          'p_city': null,
          'p_pricing': p.toJson(),
        },
      );

  @override
  Future<Result<void>> saveSurcharges(
    String countryCode,
    List<DeliverySurcharge> surcharges,
  ) => _data.rpc<void>(
    'admin_set_delivery_surcharges',
    params: {
      'p_country': countryCode,
      'p_city': null,
      'p_surcharges': [for (final s in surcharges) s.toJson()],
    },
  );

  @override
  Future<Result<void>> saveBands(
    String countryCode,
    List<FeeBand> bands,
  ) async => (await _delivery.setFeeBands(countryCode, bands)).map((_) {});

  @override
  Future<Result<void>> saveMaxDistance(String countryCode, int meters) =>
      _data.rpc<void>(
        'admin_set_delivery_settings',
        params: {'p_country': countryCode, 'p_max_distance_m': meters},
      );

  @override
  Future<Result<void>> saveCityRadius(String cityId, int meters) =>
      _data.rpc<void>(
        'admin_set_city_delivery_radius',
        params: {'p_city': cityId, 'p_meters': meters},
      );

  @override
  Future<Result<(int?, int)>> preview(
    String countryCode, {
    required int meters,
    required bool longDistance,
    DateTime? at,
  }) async =>
      (await _data.rpc<Object?>(
        'admin_preview_delivery_fee',
        params: {
          'p_country': countryCode,
          'p_city': null,
          'p_meters': meters,
          'p_long': longDistance,
          'p_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
        },
      )).map((j) {
        final m = (j! as Map).cast<String, dynamic>();
        return (
          (m['fee_minor'] as num?)?.toInt(),
          (m['surcharge_percent'] as num?)?.toInt() ?? 0,
        );
      });

  @override
  Future<Result<List<PendingAccount>>> pendingAccounts() =>
      _delivery.pendingAccounts();

  @override
  Future<Result<void>> review(
    PendingAccount account, {
    required bool approve,
    String? note,
  }) => _delivery.reviewAccount(
    kind: account.kind,
    id: account.id,
    approve: approve,
    note: note,
  );

  @override
  Future<Result<List<DeliveryIncident>>> incidents() => _delivery.incidents();

  @override
  Future<Result<void>> resolve(DeliveryIncident incident) =>
      _delivery.resolveIncident(incident.id);
}
