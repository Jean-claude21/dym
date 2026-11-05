import 'package:dym_core/dym_core.dart';
import 'package:dym_models/src/json.dart';
import 'package:dym_models/src/reference/reference_models.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'cart_models.g.dart';

/// Livraison par DYM ou retrait sur place.
@JsonEnum(fieldRename: FieldRename.snake)
enum Fulfillment { delivery, pickup }

/// Problème d'une ligne. Les deux premiers bloquent la commande.
@JsonEnum(fieldRename: FieldRename.snake)
enum CartLineIssue { unavailable, stock, priceChanged, unknown }

/// Problème d'une boutique : tous bloquent la commande.
@JsonEnum(fieldRename: FieldRename.snake)
enum CartStoreIssue {
  suspended,
  closed,
  notDelivered,
  pickupUnavailable,
  paymentNotAccepted,
  unknown,
}

/// Ligne du panier, au prix courant calculé par la base.
@immutable
@JsonSerializable()
class CartLine {
  const new({
    required this.variantId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPriceMinor,
    required this.amountMinor,
    this.variantLabel,
    this.unitLabel,
    this.photoKey,
    this.stockQuantity,
    this.issues = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$CartLineFromJson(json);

  final String variantId;
  final String productId;
  final String name;
  final String? variantLabel;
  @NullableLocalizedTextConverter()
  final LocalizedText? unitLabel;
  final String? photoKey;
  final int quantity;
  @JsonKey(fromJson: minorFromJson)
  final int unitPriceMinor;
  @JsonKey(fromJson: minorFromJson)
  final int amountMinor;

  /// Stock suivi (nul : non suivi).
  final int? stockQuantity;
  @JsonKey(unknownEnumValue: CartLineIssue.unknown)
  final List<CartLineIssue> issues;

  bool get blocking =>
      issues.contains(CartLineIssue.unavailable) ||
      issues.contains(CartLineIssue.stock);
}

/// Sous-panier d'une boutique.
@immutable
@JsonSerializable()
class CartStoreGroup {
  const new({
    required this.id,
    required this.name,
    required this.zoneName,
    required this.fulfillment,
    required this.subtotalMinor,
    required this.deliveryFeeMinor,
    required this.lines,
    this.origin,
    this.offersPickup = false,
    this.isOpen = true,
    this.prepTimeMinutes = 0,
    this.issues = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$CartStoreGroupFromJson(json);

  final String id;
  final String name;
  final String? origin;
  final String zoneName;
  final Fulfillment fulfillment;
  final bool offersPickup;
  final bool isOpen;
  final int prepTimeMinutes;
  @JsonKey(unknownEnumValue: CartStoreIssue.unknown)
  final List<CartStoreIssue> issues;
  @JsonKey(fromJson: minorFromJson)
  final int subtotalMinor;
  @JsonKey(fromJson: minorFromJson)
  final int deliveryFeeMinor;
  final List<CartLine> lines;

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  bool get blocking => issues.isNotEmpty || lines.any((l) => l.blocking);
}

/// Panier tel que calculé par la base (`my_cart`) : les montants ne sont
/// jamais recalculés dans l'app.
@immutable
@JsonSerializable()
class CartView {
  const new({
    this.countryCode,
    this.currencyCode,
    this.currency,
    this.stores = const [],
    this.paymentMethods = const [],
    this.paymentMethodId,
    this.itemCount = 0,
    this.pickupCount = 0,
    this.deliveryMinutes = 0,
    this.subtotalMinor = 0,
    this.deliveryFeeMinor = 0,
    this.totalMinor = 0,
    this.freeThresholdMinor,
    this.remainingForFreeMinor,
    this.blocking = false,
    this.addressId,
    this.zoneId,
  });

  factory fromJson(Map<String, dynamic> json) => _$CartViewFromJson(json);

  static const empty = CartView();

  final String? countryCode;
  final String? currencyCode;

  /// Devise du référentiel (décimales et symbole).
  final CurrencyInfo? currency;
  final List<CartStoreGroup> stores;

  /// Moyens actifs du pays acceptés par toutes les boutiques du panier.
  final List<PaymentMethod> paymentMethods;
  final String? paymentMethodId;
  final int itemCount;

  /// Ramassages : boutiques livrées.
  final int pickupCount;
  final int deliveryMinutes;
  @JsonKey(fromJson: minorFromJson)
  final int subtotalMinor;
  @JsonKey(fromJson: minorFromJson)
  final int deliveryFeeMinor;
  @JsonKey(fromJson: minorFromJson)
  final int totalMinor;
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? freeThresholdMinor;
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? remainingForFreeMinor;
  final bool blocking;

  /// Adresse retenue pour le devis (choisie, sinon par défaut).
  final String? addressId;
  final String? zoneId;

  bool get isEmpty => stores.isEmpty;
  int get storeCount => stores.length;
  bool get hasDelivery =>
      stores.any((s) => s.fulfillment == Fulfillment.delivery);

  PaymentMethod? get paymentMethod =>
      paymentMethods.where((m) => m.id == paymentMethodId).firstOrNull;

  /// Modes choisis, pour relire le devis ou commander.
  Map<String, Fulfillment> get modes => {
    for (final s in stores) s.id: s.fulfillment,
  };
}

/// Nom d'une adresse.
@JsonEnum(fieldRename: FieldRename.snake)
enum AddressKind { home, work, other }

/// Adresse de livraison d'une cliente (privée).
@immutable
@JsonSerializable()
class CustomerAddress {
  const new({
    required this.id,
    required this.kind,
    required this.zoneId,
    required this.zoneName,
    required this.cityName,
    required this.landmark,
    required this.phone,
    this.label,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$CustomerAddressFromJson(json);

  final String id;
  final AddressKind kind;
  final String? label;
  final String zoneId;
  final String zoneName;
  final String cityName;
  final String? countryCode;
  final String landmark;
  final String phone;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  bool get hasPosition => latitude != null && longitude != null;
}

/// Adresse à enregistrer (`save_address`) ; l'identifiant vient de l'app.
@immutable
class AddressInput {
  const new({
    required this.id,
    required this.kind,
    required this.zoneId,
    required this.landmark,
    required this.phone,
    this.label,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final String id;
  final AddressKind kind;
  final String? label;
  final String zoneId;
  final String landmark;
  final String phone;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'label': label,
    'zone_id': zoneId,
    'landmark': landmark,
    'phone': phone,
    'latitude': latitude,
    'longitude': longitude,
    'is_default': isDefault,
  };
}

/// Adresse copiée dans un achat.
@immutable
@JsonSerializable()
class PurchaseAddress {
  const new({
    required this.kind,
    required this.zoneName,
    required this.cityName,
    required this.landmark,
    this.label,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$PurchaseAddressFromJson(json);

  final AddressKind kind;
  final String? label;
  final String zoneName;
  final String cityName;
  final String landmark;
}

/// Boutique d'une commande.
@immutable
@JsonSerializable()
class OrderStoreRef {
  const new({required this.id, required this.name, this.origin, this.zoneName});

  factory fromJson(Map<String, dynamic> json) => _$OrderStoreRefFromJson(json);

  final String id;
  final String name;
  final String? origin;
  final String? zoneName;
}

/// Ligne figée d'une commande.
@immutable
@JsonSerializable()
class OrderLine {
  const new({
    required this.productId,
    required this.variantId,
    required this.name,
    required this.unitPriceMinor,
    required this.quantity,
    required this.amountMinor,
    this.variantLabel,
    this.unitLabel,
  });

  factory fromJson(Map<String, dynamic> json) => _$OrderLineFromJson(json);

  final String productId;
  final String variantId;
  final String name;
  final String? variantLabel;
  @NullableLocalizedTextConverter()
  final LocalizedText? unitLabel;
  @JsonKey(fromJson: minorFromJson)
  final int unitPriceMinor;
  final int quantity;
  @JsonKey(fromJson: minorFromJson)
  final int amountMinor;
}

/// État de paiement d'un achat, décidé par la base.
@JsonEnum(fieldRename: FieldRename.snake)
enum PaymentStatus { cashOnDelivery, awaitingPayment, paid, failed, unknown }

/// État d'une tentative de paiement.
@JsonEnum(fieldRename: FieldRename.snake)
enum PaymentAttemptStatus { pending, succeeded, failed, cancelled, unknown }

/// Tentative de paiement courante d'un achat (moyen en ligne).
@immutable
@JsonSerializable()
class PurchasePayment {
  const new({
    required this.id,
    required this.status,
    required this.providerCode,
    required this.amountMinor,
    required this.reference,
    this.checkoutUrl,
    this.completedAt,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$PurchasePaymentFromJson(json);

  final String id;
  @JsonKey(unknownEnumValue: PaymentAttemptStatus.unknown)
  final PaymentAttemptStatus status;
  final String providerCode;

  /// Page de paiement du fournisseur (nulle tant qu'elle n'est pas créée).
  final String? checkoutUrl;
  @JsonKey(fromJson: minorFromJson)
  final int amountMinor;

  /// Référence courte (PA-XXXXXX).
  final String reference;
  final DateTime? completedAt;
}

/// Commande d'une boutique dans un achat.
@immutable
@JsonSerializable()
class PurchaseOrder {
  const new({
    required this.id,
    required this.status,
    required this.fulfillment,
    required this.store,
    required this.subtotalMinor,
    required this.deliveryFeeMinor,
    required this.totalMinor,
    this.itemCount = 0,
    this.items = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$PurchaseOrderFromJson(json);

  final String id;

  /// `pending` : en attente d'acceptation (la suite : order-lifecycle).
  final String status;
  final Fulfillment fulfillment;
  final OrderStoreRef store;
  @JsonKey(fromJson: minorFromJson)
  final int subtotalMinor;
  @JsonKey(fromJson: minorFromJson)
  final int deliveryFeeMinor;
  @JsonKey(fromJson: minorFromJson)
  final int totalMinor;
  final int itemCount;
  final List<OrderLine> items;
}

/// Achat : une commande par boutique, un paiement.
@immutable
@JsonSerializable()
class Purchase {
  const new({
    required this.id,
    required this.createdAt,
    required this.currencyCode,
    required this.paymentMethod,
    required this.subtotalMinor,
    required this.deliveryFeeMinor,
    required this.totalMinor,
    required this.orders,
    this.countryCode,
    this.address,
    this.substitutionAllowed = true,
    this.paymentStatus = PaymentStatus.cashOnDelivery,
    this.payment,
  });

  factory fromJson(Map<String, dynamic> json) => _$PurchaseFromJson(json);

  final String id;
  final DateTime createdAt;
  final String? countryCode;
  final String currencyCode;
  final PaymentMethod paymentMethod;
  final PurchaseAddress? address;
  final bool substitutionAllowed;
  @JsonKey(fromJson: minorFromJson)
  final int subtotalMinor;
  @JsonKey(fromJson: minorFromJson)
  final int deliveryFeeMinor;
  @JsonKey(fromJson: minorFromJson)
  final int totalMinor;
  final List<PurchaseOrder> orders;
  @JsonKey(unknownEnumValue: PaymentStatus.unknown)
  final PaymentStatus paymentStatus;

  /// Tentative courante (moyen en ligne seulement).
  final PurchasePayment? payment;

  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get awaitingPayment => paymentStatus == PaymentStatus.awaitingPayment;
  bool get paymentFailed => paymentStatus == PaymentStatus.failed;
}

/// Demande de commande (`POST /v1/orders`). Aucun montant n'est pris en
/// compte : [expectedTotalMinor] sert seulement de garde (total vu).
@immutable
class OrderRequest {
  const new({
    required this.paymentMethodId,
    required this.modes,
    this.addressId,
    this.substitutionAllowed = true,
    this.expectedTotalMinor,
  });

  final String? addressId;
  final Map<String, Fulfillment> modes;
  final String paymentMethodId;
  final bool substitutionAllowed;
  final int? expectedTotalMinor;

  Map<String, Object?> toJson() => {
    'address_id': addressId,
    'modes': {for (final e in modes.entries) e.key: e.value.name},
    'payment_method_id': paymentMethodId,
    'substitution_allowed': substitutionAllowed,
    'expected_total_minor': expectedTotalMinor,
  };
}
