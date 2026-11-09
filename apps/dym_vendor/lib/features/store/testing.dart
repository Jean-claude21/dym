import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/store_service.dart';

/// Boutique en mémoire pour les tests et la galerie : reproduit les règles
/// des fonctions SQL (étape qui ne recule pas, complétude, ouverture). N'est
/// jamais branchée en production (`main.dart` utilise `NeonStoreService`).
class MemoryStoreService implements StoreService {
  new({
    required this.config,
    this.paymentOptionsList = const [],
    this.profileZoneId,
    MyStore? initial,
  }) {
    if (initial != null) _load(initial);
  }

  final CountryConfig config;
  final List<PaymentOption> paymentOptionsList;

  /// Résultat de [openNow] (horaires simulés).
  bool openNowValue = true;

  @override
  Future<Result<bool>> openNow() async => Ok(openNowValue);

  @override
  final String? profileZoneId;

  /// Prochain appel en échec (une fois).
  Failure? failNext;

  /// Appels reçus, dans l'ordre.
  final calls = <String>[];

  bool _exists = false;
  String _name = '';
  String? _description;
  String? _origin;
  String? _zoneId;
  String? _categoryId;
  int _prep = 30;
  bool _pickup = false;
  StoreStatus _status = StoreStatus.draft;
  bool _open = false;
  int _step = 1;
  PickupAddress? _address;
  List<String> _zones = const [];
  List<String> _methods = const [];
  List<StoreHours> _hours = const [];

  void _load(MyStore s) {
    _exists = true;
    _name = s.name;
    _description = s.description;
    _origin = s.origin;
    _zoneId = s.zoneId;
    _categoryId = s.mainCategoryId;
    _prep = s.prepTimeMinutes;
    _pickup = s.offersPickup;
    _status = s.status;
    _open = s.isOpen;
    _step = s.onboardingStep;
    _address = s.pickupAddress;
    _zones = s.deliveryZoneIds;
    _methods = s.paymentMethodIds;
    _hours = s.hours;
  }

  MyStore? get current => _exists ? _build() : null;

  MyStore _build() => MyStore(
    id: 'store',
    name: _name,
    description: _description,
    origin: _origin,
    zoneId: _zoneId,
    countryCode: _zoneId == null ? null : config.country.code,
    currencyCode: _zoneId == null ? null : config.currency.code,
    mainCategoryId: _categoryId,
    prepTimeMinutes: _prep,
    offersPickup: _pickup,
    status: _status,
    isOpen: _open,
    onboardingStep: _step,
    pickupAddress: _address,
    deliveryZoneIds: _zones,
    paymentMethodIds: _methods,
    hours: _hours,
    missing: [
      if (_origin == null) 'origin',
      if (_zoneId == null) 'zone',
      if (_categoryId == null) 'category',
      if (_address == null) 'pickup_address',
      if (_zones.isEmpty) 'delivery_zones',
      if (_methods.isEmpty) 'payment_methods',
      if (_hours.isEmpty) 'hours',
    ],
  );

  Result<MyStore?> _run(String name, void Function() change) {
    calls.add(name);
    final failure = failNext;
    if (failure != null) {
      failNext = null;
      return Err(failure);
    }
    if (!_exists && name != 'start' && name != 'myStore') {
      return const Err(NotFoundFailure('aucune boutique'));
    }
    change();
    return Ok(current);
  }

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(config);

  @override
  Future<Result<MyStore?>> myStore() async => _run('myStore', () {});

  @override
  Future<Result<MyStore?>> start({
    required String name,
    String? description,
  }) async => _run('start', () {
    _exists = true;
    _name = name;
    _description = description;
    if (_step < 2) _step = 2;
  });

  @override
  Future<Result<MyStore?>> update(Map<String, Object?> patch) async =>
      _run('update', () {
        for (final MapEntry(:key, :value) in patch.entries) {
          switch (key) {
            case 'origin':
              _origin = value as String?;
            case 'zone_id':
              _zoneId = value as String?;
            case 'main_category_id':
              _categoryId = value as String?;
            case 'prep_time_minutes':
              _prep = value! as int;
            case 'offers_pickup':
              _pickup = value! as bool;
            case 'onboarding_step':
              if ((value! as int) > _step) _step = value as int;
          }
        }
      });

  @override
  Future<Result<MyStore?>> setPickupAddress(PickupAddress address) async =>
      _run('setPickupAddress', () => _address = address);

  @override
  Future<Result<MyStore?>> setDeliveryZones(List<String> zoneIds) async =>
      _run('setDeliveryZones', () => _zones = List.of(zoneIds));

  @override
  Future<Result<List<PaymentOption>>> paymentOptions() async {
    calls.add('paymentOptions');
    return Ok(paymentOptionsList);
  }

  @override
  Future<Result<MyStore?>> setPaymentMethods(List<String> methodIds) async =>
      _run('setPaymentMethods', () => _methods = List.of(methodIds));

  @override
  Future<Result<MyStore?>> setHours(List<StoreHours> hours) async =>
      _run('setHours', () => _hours = List.of(hours));

  @override
  Future<Result<MyStore?>> publish() async {
    if (_exists && _status == StoreStatus.suspended) {
      calls.add('publish');
      return const Err(ForbiddenFailure('boutique suspendue'));
    }
    if (_exists && _build().missing.isNotEmpty) {
      calls.add('publish');
      return const Err(ValidationFailure('boutique incomplète'));
    }
    return _run('publish', () {
      _status = StoreStatus.active;
      _open = true;
      _step = 7;
    });
  }

  @override
  Future<Result<MyStore?>> setOpen({required bool open}) async {
    if (_exists && _status != StoreStatus.active) {
      calls.add('setOpen');
      return const Err(ForbiddenFailure('boutique non active'));
    }
    return _run('setOpen', () => _open = open);
  }
}
