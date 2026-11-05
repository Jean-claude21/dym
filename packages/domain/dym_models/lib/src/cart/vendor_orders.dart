import 'package:dym_models/src/cart/cart_models.dart';
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
  });

  factory fromJson(Map<String, dynamic> json) => _$VendorOrderFromJson(json);

  final String id;
  final DateTime createdAt;
  final String status;
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

  bool get isPaid => paymentStatus == PaymentStatus.paid;
}
