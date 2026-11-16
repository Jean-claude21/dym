import 'dart:async';

import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Choix du checkout : adresse, mode par boutique, paiement, remplacement.
@immutable
class CheckoutSelection {
  const new({
    this.addressId,
    this.modes = const {},
    this.paymentMethodId,
    this.substitutionAllowed = true,
    this.slot,
  });

  final String? addressId;
  final Map<String, Fulfillment> modes;
  final String? paymentMethodId;
  final bool substitutionAllowed;

  /// Créneau choisi (spec 033) ; nul : dès que possible.
  final SlotChoice? slot;

  CheckoutSelection copyWith({
    String? addressId,
    Map<String, Fulfillment>? modes,
    String? paymentMethodId,
    bool? substitutionAllowed,
  }) => CheckoutSelection(
    addressId: addressId ?? this.addressId,
    modes: modes ?? this.modes,
    paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    substitutionAllowed: substitutionAllowed ?? this.substitutionAllowed,
    slot: slot,
  );

  /// Même sélection avec un autre créneau (nul : dès que possible).
  CheckoutSelection withSlot(SlotChoice? value) => CheckoutSelection(
    addressId: addressId,
    modes: modes,
    paymentMethodId: paymentMethodId,
    substitutionAllowed: substitutionAllowed,
    slot: value,
  );
}

/// Position de l'appareil et quartier le plus proche (`null` : hors zone).
@immutable
class LocatedPlace {
  const new(this.point, this.match);

  final GeoPoint point;
  final ZoneMatch? match;
}

/// Panier, adresses et commande de l'app cliente. Le panier courant est
/// partagé (mini-panier, panier, livraison). Montants et refus viennent de la
/// base. Remplaçable en test.
abstract interface class CartService {
  /// Changements en direct (statut des commandes envoyées, spec 068).
  Stream<LiveSignal> get live;

  /// Quartier choisi à l'inscription, s'il existe.
  String? get profileZoneId;

  /// Dernier panier lu (vide avant la première lecture).
  ValueListenable<CartView> get cart;

  CheckoutSelection get selection;

  /// Relit le panier avec la sélection courante.
  Future<Result<CartView>> refresh();

  /// Ajoute une variante ; enregistre `cart_item_added`.
  Future<Result<CartView>> add(String variantId, {int quantity = 1});

  /// 0 retire la ligne.
  Future<Result<CartView>> setQuantity(String variantId, int quantity);

  /// Change la sélection du checkout, puis relit le panier.
  Future<Result<CartView>> select({
    String? addressId,
    Map<String, Fulfillment>? modes,
    String? paymentMethodId,
    bool? substitutionAllowed,
  });

  /// Référentiel du pays (devise, quartiers, origines).
  Future<Result<CountryConfig>> countryConfig();

  /// Créneaux proposés pour le panier (spec 033).
  Future<Result<DeliverySlots>> slots();

  /// Créneau de la prochaine commande (nul : dès que possible).
  void selectSlot(SlotChoice? slot);

  Future<Result<List<CustomerAddress>>> addresses();

  Future<Result<List<CustomerAddress>>> saveAddress(AddressInput address);

  Future<Result<List<CustomerAddress>>> deleteAddress(String id);

  Future<Result<List<CustomerAddress>>> setDefaultAddress(String id);

  /// Position de l'appareil et quartier proposé ; `Ok(null)` : refusée.
  Future<Result<LocatedPlace?>> locate();

  /// Quartier d'un point placé sur la carte (« Placer ma porte », spec 095).
  Future<Result<ZoneMatch?>> zoneAt(GeoPoint point);

  /// Commande le panier avec la sélection courante. Une nouvelle tentative
  /// après une erreur réseau réutilise la même clé d'idempotence.
  Future<Result<Purchase>> placeOrder();

  /// Achat relu (état de paiement à jour).
  Future<Result<Purchase>> purchase(String id);

  /// Nouvelle tentative de paiement ; la même clé sert aux nouvelles
  /// tentatives réseau de ce geste.
  Future<Result<Purchase>> retryPayment(String purchaseId);

  /// Passage au paiement à la livraison.
  Future<Result<Purchase>> payOnDelivery(String purchaseId);

  /// Ouvre la page de paiement du fournisseur ; `Ok(false)` : impossible.
  Future<Result<bool>> openPaymentPage(String url);

  /// `checkout_started` (ouverture de l'étape livraison).
  void checkoutStarted();

  ImageProvider photo(String objectKey);

  /// Nouvel identifiant (adresse).
  String newId();
}

/// Implémentation Neon.
class NeonCartService implements CartService {
  new({
    required this._cart,
    required this._addresses,
    required this._orders,
    required this._reference,
    required this._discovery,
    required this._events,
    required this._auth,
    required this._location,
    required this._environment,
    this._pages = const PluginPaymentPageOpener(),
    this._live = LiveFeed.none,
  });

  final LiveFeed _live;

  @override
  Stream<LiveSignal> get live => _live.signals;

  final CartRepository _cart;
  final AddressRepository _addresses;
  final OrderRepository _orders;
  final ReferenceRepository _reference;
  final DiscoveryRepository _discovery;
  final EventsRepository _events;
  final AuthService _auth;
  final LocationProvider _location;
  final DymEnvironment _environment;
  final ExternalPageOpener _pages;
  final _retryKeys = <String, String>{};
  final ValueNotifier<CartView> _view = ValueNotifier(CartView.empty);
  CheckoutSelection _selection = const CheckoutSelection();
  CountryConfig? _config;
  String? _orderKey;

  @override
  String? get profileZoneId => _auth.me?.profile?.zoneId;

  @override
  ValueListenable<CartView> get cart => _view;

  @override
  CheckoutSelection get selection => _selection;

  Result<CartView> _keep(Result<CartView> result) {
    if (result case Ok(:final value)) _view.value = value;
    return result;
  }

  @override
  Future<Result<CartView>> refresh() async => _keep(
    await _cart.cart(
      addressId: _selection.addressId,
      modes: _selection.modes,
      paymentMethodId: _selection.paymentMethodId,
      slot: _selection.slot,
    ),
  );

  /// Visiteuse sans compte (spec 093) : appelé quand un geste demande un
  /// compte (ajout au panier) ; l'app ouvre la connexion.
  VoidCallback? onAccountNeeded;

  @override
  Future<Result<CartView>> add(String variantId, {int quantity = 1}) async {
    if (_auth.me == null) {
      onAccountNeeded?.call();
      return const Err(UnauthenticatedFailure('visiteuse'));
    }
    final result = _keep(await _cart.add(variantId, quantity: quantity));
    if (result case Ok(:final value)) {
      unawaited(
        _events.track(
          'cart_item_added',
          countryCode: value.countryCode,
          entityType: 'product_variant',
          entityId: variantId,
          props: {'quantity': quantity, 'stores_count': value.storeCount},
        ),
      );
    }
    // Les modes et le paiement restent ceux choisis : relecture avec eux.
    return _selection.modes.isEmpty && _selection.addressId == null
        ? result
        : await refresh();
  }

  @override
  Future<Result<CartView>> setQuantity(String variantId, int quantity) async {
    final result = _keep(await _cart.setQuantity(variantId, quantity));
    return _selection.modes.isEmpty && _selection.addressId == null
        ? result
        : await refresh();
  }

  @override
  Future<Result<CartView>> select({
    String? addressId,
    Map<String, Fulfillment>? modes,
    String? paymentMethodId,
    bool? substitutionAllowed,
  }) {
    _selection = _selection.copyWith(
      addressId: addressId,
      modes: modes,
      paymentMethodId: paymentMethodId,
      substitutionAllowed: substitutionAllowed,
    );
    return refresh();
  }

  @override
  Future<Result<CountryConfig>> countryConfig() async {
    final cached = _config;
    if (cached != null) return Ok(cached);
    final code = _view.value.countryCode ?? _auth.me?.profile?.countryCode;
    if (code == null) return const Err(UnauthenticatedFailure('profil'));
    final result = await _reference.countryConfig(code);
    if (result case Ok(:final value)) _config = value;
    return result;
  }

  @override
  Future<Result<List<CustomerAddress>>> addresses() => _addresses.addresses();

  @override
  Future<Result<List<CustomerAddress>>> saveAddress(AddressInput address) =>
      _addresses.save(address);

  @override
  Future<Result<List<CustomerAddress>>> deleteAddress(String id) async {
    if (_selection.addressId == id) {
      _selection = CheckoutSelection(
        modes: _selection.modes,
        paymentMethodId: _selection.paymentMethodId,
        substitutionAllowed: _selection.substitutionAllowed,
      );
    }
    return await _addresses.delete(id);
  }

  @override
  Future<Result<List<CustomerAddress>>> setDefaultAddress(String id) =>
      _addresses.setDefault(id);

  @override
  Future<Result<ZoneMatch?>> zoneAt(GeoPoint point) => _discovery.nearestZone(
    point.latitude,
    point.longitude,
    countryCode: _view.value.countryCode,
  );

  @override
  Future<Result<LocatedPlace?>> locate() async {
    switch (await _location.current()) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: null):
        return const Ok(null);
      case Ok(value: final point?):
        final match = await _discovery.nearestZone(
          point.latitude,
          point.longitude,
          countryCode: _view.value.countryCode,
        );
        if (match case Ok(value: final m?) when !m.covered) {
          unawaited(trackOutsideCoverage(_events, m));
        }
        return switch (match) {
          Ok(:final value) => Ok(LocatedPlace(point, value)),
          Err(:final failure) => Err(failure),
        };
    }
  }

  @override
  Future<Result<DeliverySlots>> slots() => _orders.slots();

  @override
  void selectSlot(SlotChoice? slot) => _selection = _selection.withSlot(slot);

  @override
  Future<Result<Purchase>> placeOrder() async {
    final view = _view.value;
    final method = _selection.paymentMethodId ?? view.paymentMethodId;
    if (method == null) {
      return const Err(ValidationFailure('payment_not_accepted'));
    }
    final key = _orderKey ??= Uuid.v4();
    final result = await _orders.place(
      OrderRequest(
        addressId: view.addressId,
        modes: view.modes,
        paymentMethodId: method,
        substitutionAllowed: _selection.substitutionAllowed,
        expectedTotalMinor: view.totalMinor,
        slot: _selection.slot,
      ),
      idempotencyKey: key,
    );
    switch (result) {
      case Ok():
        _orderKey = null;
        _selection = CheckoutSelection(addressId: _selection.addressId);
        unawaited(refresh());
      case Err(:final failure) when !failure.isTransient:
        // Refus de la base : le prochain geste est une nouvelle commande.
        _orderKey = null;
        unawaited(refresh());
      case Err():
        break; // réseau ou 5xx : même clé à la prochaine tentative
    }
    return result;
  }

  @override
  Future<Result<Purchase>> purchase(String id) => _orders.purchase(id);

  @override
  Future<Result<Purchase>> retryPayment(String purchaseId) async {
    final key = _retryKeys[purchaseId] ??= Uuid.v4();
    final result = await _orders.retryPayment(purchaseId, idempotencyKey: key);
    switch (result) {
      case Ok():
        _retryKeys.remove(purchaseId);
      case Err(:final failure) when !failure.isTransient:
        _retryKeys.remove(purchaseId);
      case Err():
        break; // réseau : même clé à la prochaine tentative
    }
    return result;
  }

  @override
  Future<Result<Purchase>> payOnDelivery(String purchaseId) =>
      _orders.payOnDelivery(purchaseId);

  @override
  Future<Result<bool>> openPaymentPage(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return Future.value(const Ok(false));
    return _pages.open(uri);
  }

  @override
  void checkoutStarted() {
    final view = _view.value;
    unawaited(
      _events.track(
        'checkout_started',
        countryCode: view.countryCode,
        props: {'stores_count': view.storeCount, 'items': view.itemCount},
      ),
    );
  }

  @override
  ImageProvider photo(String objectKey) =>
      dymNetworkImage(_environment.media(objectKey).toString());

  @override
  String newId() => Uuid.v4();
}
