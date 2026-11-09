import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';

/// Accès de l'app vendeuse à sa boutique et au référentiel de son pays.
/// Remplaçable en test.
abstract interface class StoreService {
  /// Quartier du profil (quartier proposé par défaut, aperçu).
  String? get profileZoneId;

  /// Configuration du pays de la vendeuse (quartiers, rayons, origines).
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<MyStore?>> myStore();

  Future<Result<MyStore?>> start({required String name, String? description});

  Future<Result<MyStore?>> update(Map<String, Object?> patch);

  Future<Result<MyStore?>> setPickupAddress(PickupAddress address);

  Future<Result<MyStore?>> setDeliveryZones(List<String> zoneIds);

  Future<Result<List<PaymentOption>>> paymentOptions();

  Future<Result<MyStore?>> setPaymentMethods(List<String> methodIds);

  Future<Result<MyStore?>> setHours(List<StoreHours> hours);

  Future<Result<MyStore?>> publish();

  Future<Result<MyStore?>> setOpen({required bool open});

  /// Vrai si la boutique reçoit des commandes maintenant.
  Future<Result<bool>> openNow();
}

/// Implémentation Neon : dépôts `dym_data`, pays lu du profil.
class NeonStoreService implements StoreService {
  new({required this._stores, required this._reference, required this._auth});

  final StoreRepository _stores;
  final ReferenceRepository _reference;
  final AuthService _auth;
  CountryConfig? _config;

  @override
  String? get profileZoneId => _auth.me?.profile?.zoneId;

  @override
  Future<Result<CountryConfig>> countryConfig() async {
    final cached = _config;
    if (cached != null) return Ok(cached);
    final code = _auth.me?.profile?.countryCode;
    if (code == null) {
      return const Err(UnauthenticatedFailure('profil incomplet'));
    }
    final result = await _reference.countryConfig(code);
    if (result case Ok(:final value)) _config = value;
    return result;
  }

  @override
  Future<Result<MyStore?>> myStore() => _stores.myStore();

  @override
  Future<Result<MyStore?>> start({required String name, String? description}) =>
      _stores.start(name: name, description: description);

  @override
  Future<Result<MyStore?>> update(Map<String, Object?> patch) =>
      _stores.update(patch);

  @override
  Future<Result<MyStore?>> setPickupAddress(PickupAddress address) =>
      _stores.setPickupAddress(address);

  @override
  Future<Result<MyStore?>> setDeliveryZones(List<String> zoneIds) =>
      _stores.setDeliveryZones(zoneIds);

  @override
  Future<Result<List<PaymentOption>>> paymentOptions() =>
      _stores.paymentOptions();

  @override
  Future<Result<MyStore?>> setPaymentMethods(List<String> methodIds) =>
      _stores.setPaymentMethods(methodIds);

  @override
  Future<Result<MyStore?>> setHours(List<StoreHours> hours) =>
      _stores.setHours(hours);

  @override
  Future<Result<MyStore?>> publish() => _stores.publish();

  @override
  Future<Result<MyStore?>> setOpen({required bool open}) =>
      _stores.setOpen(open: open);

  @override
  Future<Result<bool>> openNow() => _stores.openNow();
}
