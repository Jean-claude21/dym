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

  /// Boutiques où je travaille ; accepte les invitations reçues (spec 087).
  Future<Result<List<StoreAccess>>> myStores() async {
    final result = await _data.rpc<Object?>('my_stores');
    return result.map(_accesses);
  }

  Future<Result<List<StoreAccess>>> setActiveStore(String storeId) async {
    final result = await _data.rpc<Object?>(
      'set_active_store',
      params: {'p_store': storeId},
    );
    return result.map(_accesses);
  }

  Future<Result<List<StoreStaffMember>>> myStaff() async =>
      (await _data.rpc<Object?>('my_store_staff')).map(_staff);

  Future<Result<List<StoreStaffMember>>> inviteStaff(
    String email,
    String role,
  ) async => (await _data.rpc<Object?>(
    'invite_store_staff',
    params: {'p_email': email, 'p_role': role},
  )).map(_staff);

  Future<Result<List<StoreStaffMember>>> removeStaff(String email) async =>
      (await _data.rpc<Object?>(
        'remove_store_staff',
        params: {'p_email': email},
      )).map(_staff);

  static List<StoreAccess> _accesses(Object? json) => [
    for (final s in json! as List)
      StoreAccess.fromJson((s as Map).cast<String, Object?>()),
  ];

  static List<StoreStaffMember> _staff(Object? json) => [
    for (final s in json! as List)
      StoreStaffMember.fromJson((s as Map).cast<String, Object?>()),
  ];

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

  /// Moyens de paiement du pays de la boutique, disponibles ou à venir.
  Future<Result<List<PaymentOption>>> paymentOptions() async {
    final result = await _data.rpc<Object?>('store_payment_options');
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value is! List) {
          return const Err(ServerFailure('moyens de paiement illisibles'));
        }
        return Ok([
          for (final item in value.cast<Map<String, dynamic>>())
            PaymentOption.fromJson(item),
        ]);
    }
  }

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

  /// Vrai si la boutique reçoit des commandes maintenant (interrupteur et
  /// horaires, calculé par la base).
  Future<Result<bool>> openNow() async {
    final result = await _data.rpc<Object?>('my_store_open_now');
    return switch (result) {
      Ok(:final value) => Ok(value == true),
      Err(:final failure) => Err(failure),
    };
  }

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
