import 'dart:async';

import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:stacked/stacked.dart';

/// Base : chargement, échec, hors ligne ; référentiel du pays.
abstract class _CartLoadingViewModel extends BaseViewModel {
  new(this.service);

  final CartService service;
  Failure? _failure;
  CountryConfig? _config;

  Failure? get failure => _failure;
  bool get offline => _failure is NetworkFailure;
  bool get failed => _failure != null;
  CountryConfig? get config => _config;

  /// Montant dans la devise du pays (`null` avant le chargement).
  Money? money(int? minor) =>
      minor == null || _config == null ? null : _config!.money(minor);

  Future<void> load();

  /// Exécute [work] ; tout échec est conservé pour l'écran de reprise.
  Future<void> run(Future<Failure?> Function() work) async {
    _failure = null;
    setBusy(true);
    final config = await service.countryConfig();
    switch (config) {
      case Err(:final failure):
        _failure = failure;
      case Ok(:final value):
        _config = value;
        _failure = await work();
    }
    setBusy(false);
  }
}

/// Refus d'une commande, traduit par la vue.
enum OrderError {
  empty,
  blocked,
  addressRequired,
  totalChanged,
  paymentUnavailable,
  offline,
  generic,
}

OrderError orderErrorOf(Failure failure) => switch (failure) {
  NetworkFailure() => OrderError.offline,
  ValidationFailure(message: 'cart_empty') => OrderError.empty,
  ValidationFailure(message: 'cart_blocked') => OrderError.blocked,
  ValidationFailure(message: 'address_required') => OrderError.addressRequired,
  ValidationFailure(message: 'total_changed') => OrderError.totalChanged,
  ValidationFailure(message: 'payment_not_accepted' || 'payment_unavailable') =>
    OrderError.paymentUnavailable,
  _ => OrderError.generic,
};

// ------------------------------------------------------------------ panier

/// Panier (écran 05) : sous-paniers, quantités, paiement, total, commande.
class CartViewModel extends _CartLoadingViewModel {
  new({required CartService service, required this.onOrdered})
    : super(service) {
    service.cart.addListener(notifyListeners);
  }

  /// Commande créée : écran 37.
  final void Function(Purchase purchase) onOrdered;

  bool _ordering = false;
  OrderError? _orderError;

  CartView get cart => service.cart.value;
  bool get ready => _config != null && !failed;
  bool get ordering => _ordering;
  OrderError? get orderError => _orderError;
  bool get substitutionAllowed => service.selection.substitutionAllowed;

  bool get canOrder => !cart.isEmpty && !cart.blocking && !_ordering && !isBusy;

  /// Progression vers la livraison offerte (nulle sans seuil).
  double? get freeDeliveryProgress {
    final threshold = cart.freeThresholdMinor;
    final remaining = cart.remainingForFreeMinor;
    if (threshold == null || remaining == null || threshold == 0) return null;
    return ((threshold - remaining) / threshold).clamp(0, 1);
  }

  @override
  Future<void> load() => run(() async {
    final result = await service.refresh();
    return result.failureOrNull;
  });

  Future<void> setQuantity(String variantId, int quantity) async {
    _orderError = null;
    final result = await service.setQuantity(variantId, quantity);
    if (result case Err(:final failure)) _orderError = orderErrorOf(failure);
    notifyListeners();
  }

  Future<void> selectPayment(String id) async {
    await service.select(paymentMethodId: id);
    notifyListeners();
  }

  Future<void> setSubstitution({required bool allowed}) async {
    await service.select(substitutionAllowed: allowed);
    notifyListeners();
  }

  Future<void> order() async {
    if (_ordering) return;
    _ordering = true;
    _orderError = null;
    notifyListeners();
    final result = await service.placeOrder();
    _ordering = false;
    switch (result) {
      case Ok(:final value):
        onOrdered(value);
      case Err(:final failure):
        _orderError = orderErrorOf(failure);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    service.cart.removeListener(notifyListeners);
    super.dispose();
  }
}

// ------------------------------------------------------------------ livraison

/// Livraison (écran 34) : adresse, mode par boutique, remplacement.
class DeliveryViewModel extends _CartLoadingViewModel {
  new({required CartService service}) : super(service) {
    service.cart.addListener(notifyListeners);
  }

  List<CustomerAddress> _addresses = const [];

  CartView get cart => service.cart.value;
  List<CustomerAddress> get addresses => _addresses;
  bool get ready => _config != null && !failed;
  String? get addressId => cart.addressId;
  bool get substitutionAllowed => service.selection.substitutionAllowed;

  @override
  Future<void> load() => run(() async {
    service.checkoutStarted();
    return await _reload();
  });

  Future<Failure?> _reload() async {
    final list = await service.addresses();
    if (list case Err(:final failure)) return failure;
    _addresses = list.valueOrNull!;
    return (await service.refresh()).failureOrNull;
  }

  /// Après l'écran « nouvelle adresse ».
  Future<void> reloadAddresses() => run(_reload);

  Future<void> selectAddress(String id) async {
    await service.select(addressId: id);
    notifyListeners();
  }

  Future<void> setMode(String storeId, Fulfillment mode) async {
    await service.select(modes: {...cart.modes, storeId: mode});
    notifyListeners();
  }

  Future<void> setSubstitution({required bool allowed}) async {
    await service.select(substitutionAllowed: allowed);
    notifyListeners();
  }

  @override
  void dispose() {
    service.cart.removeListener(notifyListeners);
    super.dispose();
  }
}

// ------------------------------------------------------------------ adresses

/// Mes adresses (écran 35).
class AddressesViewModel extends _CartLoadingViewModel {
  new({required CartService service}) : super(service);

  List<CustomerAddress> _addresses = const [];
  Failure? _actionFailure;

  List<CustomerAddress> get addresses => _addresses;
  bool get ready => _config != null && !failed;
  Failure? get actionFailure => _actionFailure;

  @override
  Future<void> load() => run(() async {
    final result = await service.addresses();
    _addresses = result.valueOrNull ?? const [];
    return result.failureOrNull;
  });

  Future<void> setDefault(String id) =>
      _act(() => service.setDefaultAddress(id));

  Future<void> delete(String id) => _act(() => service.deleteAddress(id));

  Future<void> _act(
    Future<Result<List<CustomerAddress>>> Function() action,
  ) async {
    _actionFailure = null;
    final result = await runBusyFuture(action());
    switch (result) {
      case Ok(:final value):
        _addresses = value;
      case Err(:final failure):
        _actionFailure = failure;
    }
    notifyListeners();
  }
}

/// Résultat d'une demande de position pour une adresse.
enum AddressLocation { found, unavailable }

/// Nouvelle adresse ou modification (écran 36). La position de l'appareil,
/// si elle est donnée, est conservée avec l'adresse.
class AddressFormViewModel extends _CartLoadingViewModel {
  new({required CartService service, this.initial}) : super(service) {
    final a = initial;
    if (a != null) {
      _kind = a.kind;
      label = a.label ?? '';
      _zoneId = a.zoneId;
      landmark = a.landmark;
      phone = a.phone;
      _latitude = a.latitude;
      _longitude = a.longitude;
      _isDefault = a.isDefault;
    }
  }

  /// Adresse modifiée (nulle : nouvelle).
  final CustomerAddress? initial;

  static final _phonePattern = RegExp(r'^\+?[0-9 ]{8,20}$');

  AddressKind _kind = AddressKind.home;
  String label = '';
  String? _zoneId;
  String landmark = '';
  String phone = '';
  double? _latitude;
  double? _longitude;
  bool _isDefault = false;
  bool _locating = false;
  AddressLocation? _location;
  bool _submitted = false;
  Failure? _saveFailure;

  AddressKind get kind => _kind;
  String? get zoneId => _zoneId;
  bool get isDefault => _isDefault;
  bool get locating => _locating;
  AddressLocation? get location => _location;
  bool get hasPosition => _latitude != null;
  bool get ready => _config != null && !failed;
  Failure? get saveFailure => _saveFailure;
  bool get editing => initial != null;

  List<Zone> get zones => _config?.zones ?? const [];

  String? cityNameOf(Zone zone) =>
      _config?.cities.where((c) => c.id == zone.cityId).firstOrNull?.name;

  bool get landmarkValid {
    final n = landmark.trim().length;
    return n >= 3 && n <= 200;
  }

  bool get phoneValid => _phonePattern.hasMatch(phone.trim());

  /// Erreurs affichées seulement après une tentative d'enregistrement.
  bool get showErrors => _submitted;

  bool get canSave => !isBusy && !_locating;

  @override
  Future<void> load() => run(() async => null);

  void setKind(AddressKind value) {
    _kind = value;
    notifyListeners();
  }

  void setLandmark(String value) {
    landmark = value;
    notifyListeners();
  }

  void setPhone(String value) {
    phone = value;
    notifyListeners();
  }

  void setDefault({required bool value}) {
    _isDefault = value;
    notifyListeners();
  }

  /// Quartier choisi dans la recherche : la position n'y correspond plus.
  void selectZone(String id) {
    _zoneId = id;
    _latitude = null;
    _longitude = null;
    notifyListeners();
  }

  Future<void> locate() async {
    if (_locating) return;
    _locating = true;
    _location = null;
    notifyListeners();
    final result = await service.locate();
    _locating = false;
    switch (result) {
      case Ok(value: final place?) when place.match != null:
        _zoneId = place.match!.zoneId;
        _latitude = place.point.latitude;
        _longitude = place.point.longitude;
        _location = AddressLocation.found;
      case Ok() || Err():
        _location = AddressLocation.unavailable;
    }
    notifyListeners();
  }

  /// Enregistre ; `true` si l'adresse est enregistrée.
  Future<bool> save() async {
    _submitted = true;
    _saveFailure = null;
    notifyListeners();
    final zone = _zoneId;
    if (zone == null || !landmarkValid || !phoneValid) return false;
    final result = await runBusyFuture(
      service.saveAddress(
        AddressInput(
          id: initial?.id ?? service.newId(),
          kind: _kind,
          label: label.trim().isEmpty ? null : label.trim(),
          zoneId: zone,
          landmark: landmark.trim(),
          phone: phone.trim(),
          latitude: _latitude,
          longitude: _longitude,
          isDefault: _isDefault,
        ),
      ),
    );
    if (result case Err(:final failure)) {
      _saveFailure = failure;
      notifyListeners();
      return false;
    }
    return true;
  }
}

// ------------------------------------------------------------------ envoyée

/// Commande envoyée (écran 37) : récapitulatif de l'achat.
class OrderSentViewModel extends _CartLoadingViewModel {
  new({required CartService service, required this.purchase}) : super(service);

  final Purchase purchase;

  bool get ready => _config != null && !failed;

  @override
  Future<void> load() => run(() async => null);
}
