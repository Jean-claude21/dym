import 'package:dym_models/src/cart/adjustment_models.dart';
import 'package:dym_models/src/cart/cart_models.dart';
import 'package:dym_models/src/json.dart';
import 'package:dym_models/src/reference/reference_models.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'order_tracking.g.dart';

/// Statut d'une commande (machine à états en base, spec 011).
@JsonEnum(fieldRename: FieldRename.snake)
enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  outForDelivery,
  delivered,
  refused,
  cancelled,
  unknown;

  /// En cours (ni livrée, ni refusée, ni annulée).
  bool get isActive =>
      this != delivered &&
      this != refused &&
      this != cancelled &&
      this != unknown;

  /// Code envoyé à la Function.
  String get code => switch (this) {
    outForDelivery => 'out_for_delivery',
    _ => name,
  };
}

/// Raison d'un refus.
@JsonEnum(fieldRename: FieldRename.snake)
enum RefusalReason {
  outOfStock,
  tooBusy,
  areaNotServed,
  other,

  /// Refus automatique : la boutique n'a pas répondu à temps (spec 066).
  noResponse,
  unknown,
}

extension RefusalReasonCode on RefusalReason {
  String get code => switch (this) {
    RefusalReason.outOfStock => 'out_of_stock',
    RefusalReason.tooBusy => 'too_busy',
    RefusalReason.areaNotServed => 'area_not_served',
    RefusalReason.noResponse => 'no_response',
    _ => 'other',
  };
}

/// Étape de l'historique d'une commande.
@immutable
@JsonSerializable()
class OrderStatusEvent {
  const new({
    required this.toStatus,
    required this.actorRole,
    required this.occurredAt,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$OrderStatusEventFromJson(json);

  @JsonKey(unknownEnumValue: OrderStatus.unknown)
  final OrderStatus toStatus;
  final String actorRole;
  final DateTime occurredAt;
}

/// Commande d'une cliente (liste « Mes commandes » et suivi).
@immutable
@JsonSerializable()
class CustomerOrder {
  const new({
    required this.id,
    required this.purchaseId,
    required this.status,
    required this.fulfillment,
    required this.createdAt,
    required this.currencyCode,
    required this.totalMinor,
    required this.store,
    this.subtotalMinor = 0,
    this.deliveryFeeMinor = 0,
    this.itemCount = 0,
    this.etaAt,
    this.scheduledStart,
    this.scheduledEnd,
    this.adjustments = const [],
    this.acceptedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.refusedAt,
    this.cancelledBy,
    this.statusReason,
    this.cashCollectedAt,
    this.refundDue = false,
    this.paymentStatus = PaymentStatus.cashOnDelivery,
    this.paymentMethod,
    this.items = const [],
    this.history = const [],
    this.nextStatuses = const [],
    this.address,
  });

  factory fromJson(Map<String, dynamic> json) => _$CustomerOrderFromJson(json);

  final String id;
  final String purchaseId;
  @JsonKey(unknownEnumValue: OrderStatus.unknown)
  final OrderStatus status;
  final Fulfillment fulfillment;
  final DateTime createdAt;
  final DateTime? etaAt;

  /// Créneau choisi (spec 033).
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;

  /// Remplacements et garantie fraîcheur (spec 034).
  @JsonKey(fromJson: adjustmentsFromJson)
  final List<OrderAdjustment> adjustments;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? refusedAt;
  final String? cancelledBy;
  @JsonKey(unknownEnumValue: RefusalReason.unknown)
  final RefusalReason? statusReason;
  final DateTime? cashCollectedAt;
  final bool refundDue;
  final String currencyCode;
  @JsonKey(fromJson: minorFromJson)
  final int subtotalMinor;
  @JsonKey(fromJson: minorFromJson)
  final int deliveryFeeMinor;
  @JsonKey(fromJson: minorFromJson)
  final int totalMinor;
  final int itemCount;
  @JsonKey(unknownEnumValue: PaymentStatus.unknown)
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final OrderStoreRef store;
  final List<OrderLine> items;
  final List<OrderStatusEvent> history;

  /// Gestes permis à la cliente maintenant (annulation).
  @JsonKey(unknownEnumValue: OrderStatus.unknown)
  final List<OrderStatus> nextStatuses;
  final PurchaseAddress? address;

  bool get canCancel => nextStatuses.contains(OrderStatus.cancelled);

  /// Reste à payer à la livraison (cash non encore encaissé).
  bool get payOnDelivery =>
      paymentStatus == PaymentStatus.cashOnDelivery && status.isActive;

  /// Moment où une étape a été atteinte (historique).
  DateTime? reachedAt(OrderStatus s) =>
      history.where((e) => e.toStatus == s).firstOrNull?.occurredAt;
}

/// Catégorie de notification (préférences de push).
@JsonEnum(fieldRename: FieldRename.snake)
enum NotificationCategory { orders, payments, messages, promotions, unknown }

/// Notification du centre (type + paramètres ; texte traduit par l'app).
@immutable
@JsonSerializable()
class AppNotification {
  const new({
    required this.id,
    required this.kind,
    required this.category,
    required this.createdAt,
    this.orderId,
    this.purchaseId,
    this.params = const {},
    this.readAt,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  final String id;
  final String kind;
  @JsonKey(unknownEnumValue: NotificationCategory.unknown)
  final NotificationCategory category;
  final String? orderId;
  final String? purchaseId;
  final Map<String, dynamic> params;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get unread => readAt == null;

  /// Paramètre texte (nom de boutique, prénom…).
  String? param(String key) => params[key]?.toString();
}

/// Préférence d'envoi push d'une catégorie.
@immutable
@JsonSerializable()
class NotificationPreference {
  const new({required this.category, required this.pushEnabled});

  factory fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferenceFromJson(json);

  @JsonKey(unknownEnumValue: NotificationCategory.unknown)
  final NotificationCategory category;
  final bool pushEnabled;
}
