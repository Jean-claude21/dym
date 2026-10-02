import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Boutique de la vendeuse connectée. Toutes les écritures passent par les
/// fonctions SQL (statut, pays et complétude décidés en base).
class StoreRepository {
  new(this._data);

  final NeonDataClient _data;

  /// Ma boutique, ou `null` si elle n'existe pas encore.
  Future<Result<MyStore?>> myStore() => _store('my_store');

  /// Étape 1 : crée la boutique en brouillon (ou la renomme).
  Future<Result<MyStore?>> start({required String name, String? description}) =>
      _store('start_store', {'p_name': name, 'p_description': description});

  /// Champs libres (`name`, `description`, `origin`, `zone_id`,
  /// `main_category_id`, `prep_time_minutes`, `offers_pickup`,
  /// `delivery_fee_minor`, `onboarding_step`).
  Future<Result<MyStore?>> update(Map<String, Object?> patch) =>
      _store('update_store', {'p_patch': patch});

  Future<Result<MyStore?>> setPickupAddress(PickupAddress address) =>
      _store('set_store_pickup_address', {
        'p_address': address.address,
        'p_landmark': address.landmark,
        'p_latitude': address.latitude,
        'p_longitude': address.longitude,
        'p_contact_phone': address.contactPhone,
      });

  Future<Result<MyStore?>> setDeliveryZones(List<String> zoneIds) =>
      _store('set_store_delivery_zones', {'p_zone_ids': zoneIds});

  Future<Result<MyStore?>> setPaymentMethods(List<String> methodIds) =>
      _store('set_store_payment_methods', {'p_method_ids': methodIds});

  Future<Result<MyStore?>> setHours(List<StoreHours> hours) =>
      _store('set_store_hours', {
        'p_hours': [for (final h in hours) h.toJson()],
      });

  /// Ouvre la boutique (refusé si incomplète ou suspendue).
  Future<Result<MyStore?>> publish() => _store('publish_store');

  /// Ouvre ou ferme en un geste.
  Future<Result<MyStore?>> setOpen({required bool open}) =>
      _store('set_store_open', {'p_open': open});

  Future<Result<MyStore?>> _store(
    String fn, [
    Map<String, Object?>? params,
  ]) async {
    final result = await _data.rpc<Object?>(fn, params: params);
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value == null) return const Ok(null);
        if (value is! Map<String, dynamic>) {
          return const Err(ServerFailure('boutique illisible'));
        }
        try {
          return Ok(MyStore.fromJson(value));
        } on Object catch (error) {
          return Err(
            ServerFailure('boutique illisible : ${error.runtimeType}'),
          );
        }
    }
  }
}
