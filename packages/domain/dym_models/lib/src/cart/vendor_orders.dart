import 'package:dym_models/src/cart/adjustment_models.dart';
import 'package:dym_models/src/cart/cart_models.dart';
import 'package:dym_models/src/cart/order_tracking.dart';
import 'package:dym_models/src/json.dart';
import 'package:dym_models/src/reference/reference_models.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'vendor_orders.g.dart';

/// Livraison d'une commande, vue par sa vendeuse (jamais l'email).
@immutable
@JsonSerializable()
class VendorOrderDelivery {
  const new({
    this.zoneName,
    this.cityName,
    this.landmark,
    this.phone,
    this.latitude,
    this.longitude,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$VendorOrderDeliveryFromJson(json);

  final String? zoneName;
  final String? cityName;
  final String? landmark;

  /// Téléphone donné par la cliente pour la livraison.
  final String? phone;
  final double? latitude;
  final double? longitude;
}

/// Paiement reçu (V-PAY-04).
@immutable
@JsonSerializable()
class VendorOrderPayment {
  const new({
    required this.status,
    required this.providerCode,
    required this.amountMinor,
    required this.reference,
    this.completedAt,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$VendorOrderPaymentFromJson(json);

  @JsonKey(unknownEnumValue: PaymentAttemptStatus.unknown)
  final PaymentAttemptStatus status;
  final String providerCode;
  @JsonKey(fromJson: minorFromJson)
  final int amountMinor;
  final String reference;
  final DateTime? completedAt;
}

/// Commande de la boutique (`my_store_orders`, `my_store_order`) : payée ou
/// en cash seulement.
@immutable
@JsonSerializable()
class VendorOrder {
  const new({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.fulfillment,
    required this.currencyCode,
    required this.subtotalMinor,
    required this.deliveryFeeMinor,
    required this.totalMinor,
    required this.paymentStatus,
    required this.paymentMethod,
    this.itemCount = 0,
    this.customerFirstName,
    this.zoneName,
    this.substitutionAllowed = true,
    this.items = const [],
    this.delivery,
    this.payment,
    this.etaAt,
    this.scheduledStart,
    this.scheduledEnd,
    this.adjustments = const [],
    this.acceptedAt,
    this.deliveredAt,
    this.cashCollectedAt,
    this.statusReason,
    this.statusNote,
    this.refundDue = false,
    this.history = const [],
    this.nextStatuses = const [],
    this.courier,
    this.respondBy,
  });

  factory fromJson(Map<String, dynamic> json) => _$VendorOrderFromJson(json);

  /// Heure limite de réponse avant le refus automatique (spec 075) ; nulle
  /// une fois la commande acceptée ou refusée.
  final DateTime? respondBy;

  /// Minutes restantes pour répondre (0 : délai dépassé ; nul : sans objet).
  int? minutesToRespond(DateTime now) {
    final by = respondBy;
    if (by == null) return null;
    final m = by.difference(now).inMinutes;
    return m < 0 ? 0 : m;
  }

  /// Livreur de la commande, une fois assigné (spec 068).
  final OrderCourier? courier;

  final String id;
  final DateTime createdAt;
  @JsonKey(unknownEnumValue: OrderStatus.unknown)
  final OrderStatus status;
  final Fulfillment fulfillment;
  final String currencyCode;
  @JsonKey(fromJson: minorFromJson)
  final int subtotalMinor;
  @JsonKey(fromJson: minorFromJson)
  final int deliveryFeeMinor;
  @JsonKey(fromJson: minorFromJson)
  final int totalMinor;
  final int itemCount;
  final String? customerFirstName;
  final String? zoneName;
  @JsonKey(unknownEnumValue: PaymentStatus.unknown)
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final bool substitutionAllowed;

  /// Détail seulement.
  final List<OrderLine> items;
  final VendorOrderDelivery? delivery;
  final VendorOrderPayment? payment;

  final DateTime? etaAt;

  /// Créneau choisi (spec 033).
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;

  /// Remplacements et garantie fraîcheur (spec 034).
  @JsonKey(fromJson: adjustmentsFromJson)
  final List<OrderAdjustment> adjustments;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final DateTime? cashCollectedAt;
  @JsonKey(unknownEnumValue: RefusalReason.unknown)
  final RefusalReason? statusReason;
  final String? statusNote;
  final bool refundDue;

  /// Détail seulement.
  final List<OrderStatusEvent> history;

  /// Étapes que la vendeuse peut déclencher maintenant.
  @JsonKey(unknownEnumValue: OrderStatus.unknown)
  final List<OrderStatus> nextStatuses;

  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isCash => paymentStatus == PaymentStatus.cashOnDelivery;

  /// Cash à encaisser : livrée, pas encore confirmé.
  bool get awaitsCash =>
      isCash && status == OrderStatus.delivered && cashCollectedAt == null;
}
