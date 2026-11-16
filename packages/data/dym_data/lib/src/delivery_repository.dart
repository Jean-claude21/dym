import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Livraison suivie (spec 096) : suivi et lien partagé, position et outils du
/// livreur, livreurs de la boutique, code de récupération, et côté équipe :
/// tranches de frais, incidents, comptes à valider. Règles en SQL.
class DeliveryRepository {
  new(this._data);

  final NeonDataClient _data;

  // ---------------------------------------------------------------- suivi

  Future<Result<LiveTracking>> tracking(String orderId) async =>
      (await _data.rpc<Object?>(
        'order_tracking',
        params: {'p_order': orderId},
      )).map(_tracking);

  Future<Result<TrackingShare>> share(String orderId) async =>
      (await _data.rpc<Object?>(
        'share_tracking',
        params: {'p_order': orderId},
      )).map((j) => TrackingShare.fromJson(_map(j)));

  /// Lien public (sans compte) ; `null` si expiré ou inconnu.
  Future<Result<LiveTracking?>> byToken(String token) async =>
      (await _data.rpc<Object?>(
        'tracking_by_token',
        params: {'p_token': token},
      )).map((j) => j == null ? null : _tracking(j));

  // ---------------------------------------------------------------- livreur

  Future<Result<void>> ping(double latitude, double longitude) =>
      _data.rpc<void>(
        'courier_ping',
        params: {'p_latitude': latitude, 'p_longitude': longitude},
      );

  Future<Result<String>> pickupCode(String orderId) async =>
      (await _data.rpc<Object?>(
        'my_pickup_code',
        params: {'p_order': orderId},
      )).map((j) => j! as String);

  /// Cliente injoignable : minutes d'attente conseillées.
  Future<Result<int>> reportUnreachable(String orderId) async =>
      (await _data.rpc<Object?>(
        'courier_report_unreachable',
        params: {'p_order': orderId},
      )).map((j) => (_map(j)['wait_minutes'] as num?)?.toInt() ?? 10);

  Future<Result<void>> sos({
    String? orderId,
    double? latitude,
    double? longitude,
    String? note,
  }) async => (await _data.rpc<Object?>(
    'courier_sos',
    params: {
      'p_order': orderId,
      'p_latitude': latitude,
      'p_longitude': longitude,
      'p_note': note,
    },
  )).map((_) {});

  // ---------------------------------------------------------------- boutique

  Future<Result<List<StoreCourierInfo>>> storeCouriers() async =>
      (await _data.rpc<Object?>('my_store_couriers')).map(_couriers);

  Future<Result<List<StoreCourierInfo>>> addStoreCourier(String phone) async =>
      (await _data.rpc<Object?>(
        'store_add_courier',
        params: {'p_phone': phone},
      )).map(_couriers);

  Future<Result<List<StoreCourierInfo>>> removeStoreCourier(
    String courierId,
  ) async => (await _data.rpc<Object?>(
    'store_remove_courier',
    params: {'p_courier': courierId},
  )).map(_couriers);

  Future<Result<void>> assignCourier(String orderId, String courierId) async =>
      (await _data.rpc<Object?>(
        'store_assign_courier',
        params: {'p_order': orderId, 'p_courier': courierId},
      )).map((_) {});

  /// Scan du QR du livreur par la vendeuse.
  Future<Result<CodeCheck>> confirmPickup(String orderId, String code) async =>
      (await _data.rpc<Object?>(
        'store_confirm_pickup',
        params: {'p_order': orderId, 'p_code': code},
      )).map((j) => CodeCheck.fromJson(_map(j)));

  // ---------------------------------------------------------------- équipe

  Future<Result<List<FeeBand>>> feeBands(
    String countryCode, {
    String? cityId,
  }) => _data.run((db) async {
    var query = db
        .from('delivery_fee_bands')
        .select('max_distance_m, fee_minor')
        .eq('country_code', countryCode);
    query = cityId == null
        ? query.isFilter('city_id', null)
        : query.eq('city_id', cityId);
    final rows = await query.order('max_distance_m');
    return [for (final r in rows as List) FeeBand.fromJson(_map(r))];
  });

  Future<Result<List<FeeBand>>> setFeeBands(
    String countryCode,
    List<FeeBand> bands, {
    String? cityId,
  }) async =>
      (await _data.rpc<Object?>(
        'admin_set_delivery_fee_bands',
        params: {
          'p_country': countryCode,
          'p_city': cityId,
          'p_bands': [for (final b in bands) b.toJson()],
        },
      )).map(
        (j) => [
          for (final b in j as List? ?? const []) FeeBand.fromJson(_map(b)),
        ],
      );

  Future<Result<List<DeliveryIncident>>> incidents({
    bool openOnly = true,
  }) async =>
      (await _data.rpc<Object?>(
        'admin_delivery_incidents',
        params: {'p_open_only': openOnly},
      )).map(
        (j) => [
          for (final i in j as List? ?? const [])
            DeliveryIncident.fromJson(_map(i)),
        ],
      );

  Future<Result<void>> resolveIncident(String id) =>
      _data.rpc<void>('admin_resolve_incident', params: {'p_incident': id});

  Future<Result<List<PendingAccount>>> pendingAccounts() async =>
      (await _data.rpc<Object?>('admin_pending_accounts'))
          .map((j) => PendingAccount.listFromJson(_map(j)));

  Future<Result<void>> reviewAccount({
    required String kind,
    required String id,
    required bool approve,
    String? note,
  }) => _data.rpc<void>(
    'admin_review_account',
    params: {'p_kind': kind, 'p_id': id, 'p_approve': approve, 'p_note': note},
  );

  static Map<String, dynamic> _map(Object? json) =>
      (json! as Map).cast<String, dynamic>();

  static LiveTracking _tracking(Object? json) =>
      LiveTracking.fromJson(_map(json));

  static List<StoreCourierInfo> _couriers(Object? json) => [
    for (final c in json as List? ?? const [])
      StoreCourierInfo.fromJson(_map(c)),
  ];
}
