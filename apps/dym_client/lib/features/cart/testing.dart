import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Boutique connue du panier en mémoire.
@immutable
class MemoryCartStore {
  const new({
    required this.id,
    required this.name,
    required this.zoneName,
    this.origin,
    this.offersPickup = false,
    this.isOpen = true,
    this.prepTimeMinutes = 30,
    this.ownFeeMinor,
    this.servedZoneIds = const {},
  });

  final String id;
  final String name;
  final String? origin;
  final String zoneName;
  final bool offersPickup;
  final bool isOpen;
  final int prepTimeMinutes;
  final int? ownFeeMinor;
  final Set<String> servedZoneIds;
}

/// Variante vendue dans le panier en mémoire.
@immutable
class MemoryCartVariant {
  const new({
    required this.id,
    required this.productId,
    required this.storeId,
    required this.name,
    required this.priceMinor,
    this.variantLabel,
    this.unitLabel,
    this.photoKey,
    this.stockQuantity,
    this.available = true,
  });

  final String id;
  final String productId;
  final String storeId;
  final String name;
  final String? variantLabel;
  final LocalizedText? unitLabel;
  final String? photoKey;
  final int priceMinor;
  final int? stockQuantity;
  final bool available;
}

/// Panier en mémoire pour les tests et la galerie : reproduit les règles de
/// `app.cart_quote` (frais : base portée par le plus gros sous-total livré,
/// supplément pour les autres, gratuité au seuil). Jamais en production.
class MemoryCartService implements CartService {
  new({
    required this.config,
    required this.stores,
    required this.variants,
    this.baseFeeMinor = 500,
    this.extraPickupFeeMinor = 200,
    this.freeThresholdMinor = 4000,
    this.cityDeliveryMinutes = 20,
    this.paymentMethods = const [],
    List<CustomerAddress> addresses = const [],
    Map<String, int> initialLines = const {},
    this.located,
    this.photoResolver,
  }) : _addresses = [...addresses],
       _lines = {...initialLines} {
    _view.value = _quote();
  }

  final CountryConfig config;
  final Map<String, MemoryCartStore> stores;
  final Map<String, MemoryCartVariant> variants;
  final int baseFeeMinor;
  final int extraPickupFeeMinor;
  final int? freeThresholdMinor;
  final int cityDeliveryMinutes;
  final List<PaymentMethod> paymentMethods;
  final LocatedPlace? located;
  final ImageProvider Function(String key)? photoResolver;

  final List<CustomerAddress> _addresses;
  final Map<String, int> _lines;
  final ValueNotifier<CartView> _view = ValueNotifier(CartView.empty);
  CheckoutSelection _selection = const CheckoutSelection();
  final _purchases = <String, Purchase>{};
  int _ids = 0;

  /// Prochain appel en échec (une fois).
  Failure? failNext;

  final calls = <String>[];
  final events = <String>[];
  final orderKeys = <String>[];

  /// Pages de paiement ouvertes.
  final openedPages = <String>[];
  int _payments = 0;

  Result<T>? _fail<T>(String name) {
    calls.add(name);
    final failure = failNext;
    if (failure == null) return null;
    failNext = null;
    return Err(failure);
  }

  @override
  String? profileZoneId;

  @override
  ValueListenable<CartView> get cart => _view;

  @override
  CheckoutSelection get selection => _selection;

  CustomerAddress? get _address =>
      _addresses.where((a) => a.id == _selection.addressId).firstOrNull ??
      _addresses.where((a) => a.isDefault).firstOrNull;

  CartView _quote() {
    final address = _address;
    final groups = <String, List<CartLine>>{};
    for (final MapEntry(key: id, value: quantity) in _lines.entries) {
      final v = variants[id]!;
      groups
          .putIfAbsent(v.storeId, () => [])
          .add(
            CartLine(
              variantId: v.id,
              productId: v.productId,
              name: v.name,
              variantLabel: v.variantLabel,
              unitLabel: v.unitLabel,
              photoKey: v.photoKey,
              quantity: quantity,
              unitPriceMinor: v.priceMinor,
              amountMinor: v.priceMinor * quantity,
              stockQuantity: v.stockQuantity,
              issues: [
                if (!v.available || v.stockQuantity == 0)
                  CartLineIssue.unavailable,
                if ((v.stockQuantity ?? 99) > 0 &&
                    quantity > (v.stockQuantity ?? 99))
                  CartLineIssue.stock,
              ],
            ),
          );
    }
    final raw = [
      for (final MapEntry(key: storeId, value: lines) in groups.entries)
        (storeId, lines, lines.fold(0, (sum, l) => sum + l.amountMinor)),
    ];
    final delivered =
        raw
            .where(
              (g) =>
                  (_selection.modes[g.$1] ?? Fulfillment.delivery) ==
                  Fulfillment.delivery,
            )
            .toList()
          ..sort((a, b) => b.$3.compareTo(a.$3));
    final deliveredSubtotal = delivered.fold(0, (sum, g) => sum + g.$3);
    final free =
        freeThresholdMinor != null && deliveredSubtotal >= freeThresholdMinor!;
    final groupsOut = [
      for (final (storeId, lines, subtotal) in raw)
        () {
          final store = stores[storeId]!;
          final mode = _selection.modes[storeId] ?? Fulfillment.delivery;
          final rank = delivered.indexWhere((g) => g.$1 == storeId);
          return CartStoreGroup(
            id: storeId,
            name: store.name,
            origin: store.origin,
            zoneName: store.zoneName,
            fulfillment: mode,
            offersPickup: store.offersPickup,
            isOpen: store.isOpen,
            prepTimeMinutes: store.prepTimeMinutes,
            issues: [
              if (!store.isOpen) CartStoreIssue.closed,
              if (mode == Fulfillment.delivery &&
                  address != null &&
                  store.servedZoneIds.isNotEmpty &&
                  !store.servedZoneIds.contains(address.zoneId))
                CartStoreIssue.notDelivered,
              if (mode == Fulfillment.pickup && !store.offersPickup)
                CartStoreIssue.pickupUnavailable,
            ],
            subtotalMinor: subtotal,
            deliveryFeeMinor: mode == Fulfillment.pickup || free
                ? 0
                : rank == 0
                ? store.ownFeeMinor ?? baseFeeMinor
                : extraPickupFeeMinor,
            lines: lines,
          );
        }(),
    ];
    final subtotal = groupsOut.fold(0, (sum, g) => sum + g.subtotalMinor);
    final fees = groupsOut.fold(0, (sum, g) => sum + g.deliveryFeeMinor);
    final methodId =
        paymentMethods
            .where((m) => m.id == _selection.paymentMethodId)
            .firstOrNull
            ?.id ??
        paymentMethods.firstOrNull?.id;
    return CartView(
      countryCode: config.country.code,
      currencyCode: config.currency.code,
      currency: CurrencyInfo(
        code: config.currency.code,
        minorUnits: config.currency.minorUnits,
        symbol: config.currency.symbol,
        formatLocale: config.currency.locale,
      ),
      stores: groupsOut,
      paymentMethods: groupsOut.isEmpty ? const [] : paymentMethods,
      paymentMethodId: groupsOut.isEmpty ? null : methodId,
      itemCount: groupsOut.fold(0, (sum, g) => sum + g.itemCount),
      pickupCount: delivered.length,
      deliveryMinutes: groupsOut.isEmpty
          ? 0
          : cityDeliveryMinutes +
                groupsOut
                    .map((g) => g.prepTimeMinutes)
                    .reduce((a, b) => a > b ? a : b),
      subtotalMinor: subtotal,
      deliveryFeeMinor: fees,
      totalMinor: subtotal + fees,
      freeThresholdMinor: freeThresholdMinor,
      remainingForFreeMinor: freeThresholdMinor == null
          ? null
          : (freeThresholdMinor! - deliveredSubtotal).clamp(0, 1 << 31),
      blocking: groupsOut.any((g) => g.blocking),
      addressId: address?.id,
      zoneId: address?.zoneId,
    );
  }

  Result<CartView> _publish() => Ok(_view.value = _quote());

  @override
  Future<Result<CartView>> refresh() async =>
      _fail<CartView>('refresh') ?? _publish();

  @override
  Future<Result<CartView>> add(String variantId, {int quantity = 1}) async {
    final failed = _fail<CartView>('add');
    if (failed != null) return failed;
    final v = variants[variantId];
    if (v == null || !v.available || v.stockQuantity == 0) {
      return const Err(ValidationFailure('unavailable'));
    }
    _lines[variantId] = ((_lines[variantId] ?? 0) + quantity).clamp(
      1,
      v.stockQuantity ?? 99,
    );
    events.add('cart_item_added');
    return _publish();
  }

  @override
  Future<Result<CartView>> setQuantity(String variantId, int quantity) async {
    final failed = _fail<CartView>('setQuantity');
    if (failed != null) return failed;
    if (quantity == 0) {
      _lines.remove(variantId);
    } else {
      _lines[variantId] = quantity;
    }
    return _publish();
  }

  @override
  Future<Result<CartView>> select({
    String? addressId,
    Map<String, Fulfillment>? modes,
    String? paymentMethodId,
    bool? substitutionAllowed,
  }) async {
    _selection = _selection.copyWith(
      addressId: addressId,
      modes: modes,
      paymentMethodId: paymentMethodId,
      substitutionAllowed: substitutionAllowed,
    );
    return await refresh();
  }

  @override
  Future<Result<CountryConfig>> countryConfig() async =>
      _fail<CountryConfig>('countryConfig') ?? Ok(config);

  List<CustomerAddress> get _sorted => [
    ..._addresses.where((a) => a.isDefault),
    ..._addresses.where((a) => !a.isDefault),
  ];

  @override
  Future<Result<List<CustomerAddress>>> addresses() async =>
      _fail<List<CustomerAddress>>('addresses') ?? Ok(_sorted);

  @override
  Future<Result<List<CustomerAddress>>> saveAddress(
    AddressInput address,
  ) async {
    final failed = _fail<List<CustomerAddress>>('saveAddress');
    if (failed != null) return failed;
    final isDefault =
        address.isDefault || _addresses.every((a) => a.id == address.id);
    final zone = config.zones.firstWhere((z) => z.id == address.zoneId);
    final saved = CustomerAddress(
      id: address.id,
      kind: address.kind,
      label: address.label,
      zoneId: zone.id,
      zoneName: zone.name,
      cityName:
          config.cities.where((c) => c.id == zone.cityId).firstOrNull?.name ??
          '',
      countryCode: config.country.code,
      landmark: address.landmark,
      phone: address.phone,
      latitude: address.latitude,
      longitude: address.longitude,
      isDefault: isDefault,
    );
    if (isDefault) _clearDefault();
    _addresses
      ..removeWhere((a) => a.id == address.id)
      ..insert(0, saved);
    _publish();
    return Ok(_sorted);
  }

  void _clearDefault() {
    for (final (i, a) in _addresses.indexed) {
      if (a.isDefault) _addresses[i] = _withDefault(a, value: false);
    }
  }

  CustomerAddress _withDefault(CustomerAddress a, {required bool value}) =>
      CustomerAddress(
        id: a.id,
        kind: a.kind,
        label: a.label,
        zoneId: a.zoneId,
        zoneName: a.zoneName,
        cityName: a.cityName,
        countryCode: a.countryCode,
        landmark: a.landmark,
        phone: a.phone,
        latitude: a.latitude,
        longitude: a.longitude,
        isDefault: value,
      );

  @override
  Future<Result<List<CustomerAddress>>> deleteAddress(String id) async {
    final failed = _fail<List<CustomerAddress>>('deleteAddress');
    if (failed != null) return failed;
    final removed = _addresses.where((a) => a.id == id).firstOrNull;
    _addresses.removeWhere((a) => a.id == id);
    if ((removed?.isDefault ?? false) && _addresses.isNotEmpty) {
      _addresses[0] = _withDefault(_addresses[0], value: true);
    }
    if (_selection.addressId == id) {
      _selection = CheckoutSelection(
        modes: _selection.modes,
        paymentMethodId: _selection.paymentMethodId,
        substitutionAllowed: _selection.substitutionAllowed,
      );
    }
    _publish();
    return Ok(_sorted);
  }

  @override
  Future<Result<List<CustomerAddress>>> setDefaultAddress(String id) async {
    final failed = _fail<List<CustomerAddress>>('setDefaultAddress');
    if (failed != null) return failed;
    _clearDefault();
    final i = _addresses.indexWhere((a) => a.id == id);
    _addresses[i] = _withDefault(_addresses[i], value: true);
    _publish();
    return Ok(_sorted);
  }

  @override
  Future<Result<LocatedPlace?>> locate() async =>
      _fail<LocatedPlace?>('locate') ?? Ok(located);

  /// Créneaux renvoyés (spec 033).
  DeliverySlots deliverySlots = const DeliverySlots();

  @override
  Future<Result<DeliverySlots>> slots() async => Ok(deliverySlots);

  @override
  void selectSlot(SlotChoice? slot) => _selection = _selection.withSlot(slot);

  @override
  Future<Result<Purchase>> placeOrder() async {
    final view = _view.value;
    final key = 'k${orderKeys.length}';
    final failed = _fail<Purchase>('placeOrder');
    orderKeys.add(key);
    if (failed != null) return failed;
    if (view.isEmpty) return const Err(ValidationFailure('cart_empty'));
    if (view.hasDelivery && view.addressId == null) {
      return const Err(ValidationFailure('address_required'));
    }
    if (view.blocking) return const Err(ValidationFailure('cart_blocked'));
    if (deliverySlots.required && _selection.slot == null) {
      return const Err(ValidationFailure('slot_required'));
    }
    final address = _address;
    final online = view.paymentMethod?.isCash == false;
    final purchase = Purchase(
      paymentStatus: online
          ? PaymentStatus.awaitingPayment
          : PaymentStatus.cashOnDelivery,
      payment: online ? _attempt(view.paymentMethod!, view.totalMinor) : null,
      id: 'pu${_purchases.length + 1}',
      createdAt: DateTime.utc(2026, 10, 5, 10),
      countryCode: view.countryCode,
      currencyCode: view.currencyCode!,
      paymentMethod: view.paymentMethod!,
      address: address == null || !view.hasDelivery
          ? null
          : PurchaseAddress(
              kind: address.kind,
              label: address.label,
              zoneName: address.zoneName,
              cityName: address.cityName,
              landmark: address.landmark,
            ),
      substitutionAllowed: _selection.substitutionAllowed,
      subtotalMinor: view.subtotalMinor,
      deliveryFeeMinor: view.deliveryFeeMinor,
      totalMinor: view.totalMinor,
      orders: [
        for (final g in view.stores)
          PurchaseOrder(
            id: 'o-${g.id}',
            status: 'pending',
            fulfillment: g.fulfillment,
            store: OrderStoreRef(id: g.id, name: g.name, origin: g.origin),
            subtotalMinor: g.subtotalMinor,
            deliveryFeeMinor: g.deliveryFeeMinor,
            totalMinor: g.subtotalMinor + g.deliveryFeeMinor,
            itemCount: g.itemCount,
            items: [
              for (final l in g.lines)
                OrderLine(
                  productId: l.productId,
                  variantId: l.variantId,
                  name: l.name,
                  variantLabel: l.variantLabel,
                  unitLabel: l.unitLabel,
                  unitPriceMinor: l.unitPriceMinor,
                  quantity: l.quantity,
                  amountMinor: l.amountMinor,
                ),
            ],
          ),
      ],
    );
    _purchases[purchase.id] = purchase;
    _lines.clear();
    _selection = CheckoutSelection(addressId: _selection.addressId);
    events.add('order_created');
    _publish();
    return Ok(purchase);
  }

  PurchasePayment _attempt(PaymentMethod method, int amount) {
    final id = 'pay${++_payments}';
    return PurchasePayment(
      id: id,
      status: PaymentAttemptStatus.pending,
      providerCode: method.providerCode,
      amountMinor: amount,
      reference: 'PA-${id.toUpperCase()}',
      checkoutUrl: 'https://paiement.example/$id',
    );
  }

  Purchase _with(
    Purchase p, {
    required PaymentStatus status,
    PurchasePayment? payment,
    PaymentMethod? method,
  }) => _purchases[p.id] = Purchase(
    id: p.id,
    createdAt: p.createdAt,
    countryCode: p.countryCode,
    currencyCode: p.currencyCode,
    paymentMethod: method ?? p.paymentMethod,
    address: p.address,
    substitutionAllowed: p.substitutionAllowed,
    subtotalMinor: p.subtotalMinor,
    deliveryFeeMinor: p.deliveryFeeMinor,
    totalMinor: p.totalMinor,
    orders: p.orders,
    paymentStatus: status,
    payment: payment,
  );

  /// Issue choisie sur la page du fournisseur simulé (tests, galerie).
  void simulatePayment(String purchaseId, PaymentAttemptStatus outcome) {
    final p = _purchases[purchaseId]!;
    final attempt = p.payment!;
    _with(
      p,
      status: outcome == PaymentAttemptStatus.succeeded
          ? PaymentStatus.paid
          : PaymentStatus.failed,
      payment: PurchasePayment(
        id: attempt.id,
        status: outcome,
        providerCode: attempt.providerCode,
        amountMinor: attempt.amountMinor,
        reference: attempt.reference,
        checkoutUrl: attempt.checkoutUrl,
        completedAt: DateTime.utc(2026, 10, 5, 10, 1),
      ),
    );
  }

  @override
  Future<Result<Purchase>> purchase(String id) async =>
      _fail<Purchase>('purchase') ??
      (_purchases[id] == null
          ? const Err(NotFoundFailure('achat'))
          : Ok(_purchases[id]!));

  @override
  Future<Result<Purchase>> retryPayment(String purchaseId) async {
    final failed = _fail<Purchase>('retryPayment');
    if (failed != null) return failed;
    final p = _purchases[purchaseId]!;
    if (p.isPaid) return const Err(ValidationFailure('already_paid'));
    return Ok(
      _with(
        p,
        status: PaymentStatus.awaitingPayment,
        payment: _attempt(p.paymentMethod, p.totalMinor),
      ),
    );
  }

  @override
  Future<Result<Purchase>> payOnDelivery(String purchaseId) async {
    final failed = _fail<Purchase>('payOnDelivery');
    if (failed != null) return failed;
    final p = _purchases[purchaseId]!;
    final cash = paymentMethods.where((m) => m.isCash).firstOrNull;
    if (cash == null) return const Err(ValidationFailure('cash_not_accepted'));
    return Ok(_with(p, status: PaymentStatus.cashOnDelivery, method: cash));
  }

  @override
  Future<Result<bool>> openPaymentPage(String url) async {
    openedPages.add(url);
    return const Ok(true);
  }

  @override
  void checkoutStarted() => events.add('checkout_started');

  @override
  ImageProvider photo(String objectKey) =>
      photoResolver?.call(objectKey) ??
      const AssetImage('assets/aisles/legumes.webp', package: 'dym_ui');

  @override
  String newId() => 'id${++_ids}';
}

/// Position simulée (tests et galerie).
const memoryPoint = GeoPoint(6.13, 1.239);
