import 'package:dym_core/dym_core.dart';
import 'package:dym_models/src/cart/cart_models.dart';
import 'package:dym_models/src/cart/disputes.dart';
import 'package:dym_models/src/cart/order_tracking.dart';
import 'package:dym_models/src/json.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'admin_models.g.dart';

Object? _self(Map<dynamic, dynamic> json, String key) => json;

// ------------------------------------------------------------------ commandes

/// Filtre de la liste des commandes (écran 52).
enum AdminOrderFilter {
  all,
  pending,
  active,
  stuck,
  delivered,
  closed;

  String get code => name;
}

/// Ligne de la liste des commandes.
@immutable
@JsonSerializable()
class AdminOrderRow {
  const new({
    required this.id,
    required this.reference,
    required this.status,
    required this.fulfillment,
    required this.paymentStatus,
    required this.storeId,
    required this.storeName,
    required this.totalMinor,
    required this.currencyCode,
    required this.createdAt,
    required this.lastChangeAt,
    this.customerFirstName,
    this.stuck = false,
    this.refundDue = false,
    this.hasOpenDispute = false,
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminOrderRowFromJson(json);

  final String id;
  final String reference;
  @JsonKey(unknownEnumValue: OrderStatus.unknown)
  final OrderStatus status;
  final Fulfillment fulfillment;
  @JsonKey(unknownEnumValue: PaymentStatus.unknown)
  final PaymentStatus paymentStatus;
  final String storeId;
  final String storeName;
  final String? customerFirstName;
  @JsonKey(fromJson: minorFromJson)
  final int totalMinor;
  final String currencyCode;
  final DateTime createdAt;
  final DateTime lastChangeAt;
  final bool stuck;
  final bool refundDue;
  final bool hasOpenDispute;
}

/// Page de la liste des commandes.
@immutable
@JsonSerializable()
class AdminOrderPage {
  const new({
    required this.total,
    required this.stuckCount,
    required this.orders,
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminOrderPageFromJson(json);

  final int total;
  final int stuckCount;
  final List<AdminOrderRow> orders;
}

/// Étape de la chronologie, avec la raison d'un geste de l'équipe.
@immutable
@JsonSerializable()
class AdminTimelineEvent {
  const new({
    required this.toStatus,
    required this.actorRole,
    required this.occurredAt,
    this.fromStatus,
    this.reason,
    this.note,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminTimelineEventFromJson(json);

  @JsonKey(unknownEnumValue: OrderStatus.unknown)
  final OrderStatus? fromStatus;
  @JsonKey(unknownEnumValue: OrderStatus.unknown)
  final OrderStatus toStatus;

  /// `client`, `vendor`, `admin` ou `system`.
  final String actorRole;
  final String? reason;
  final String? note;
  final DateTime occurredAt;
}

/// Tentative de paiement d'un achat.
@immutable
@JsonSerializable()
class AdminPayment {
  const new({
    required this.id,
    required this.reference,
    required this.providerCode,
    required this.status,
    required this.amountMinor,
    required this.currencyCode,
    required this.createdAt,
    this.lastError,
    this.completedAt,
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminPaymentFromJson(json);

  final String id;
  final String reference;
  final String providerCode;

  /// `pending`, `succeeded`, `failed` ou `cancelled`.
  final String status;
  @JsonKey(fromJson: minorFromJson)
  final int amountMinor;
  final String currencyCode;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? completedAt;
}

/// État d'un remboursement.
@JsonEnum(fieldRename: FieldRename.snake)
enum RefundStatus { pending, processing, succeeded, failed, unknown }

/// Remboursement (litige ou annulation par l'équipe).
@immutable
@JsonSerializable()
class AdminRefund {
  const new({
    required this.id,
    required this.method,
    required this.amountMinor,
    required this.status,
    required this.createdAt,
    this.orderId,
    this.orderReference,
    this.disputeId,
    this.reason,
    this.providerCode,
    this.currencyCode,
    this.lastError,
    this.storeName,
    this.completedAt,
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminRefundFromJson(json);

  final String id;
  final String? orderId;
  final String? orderReference;
  final String? disputeId;

  /// `dispute` ou `cancellation`.
  final String? reason;

  /// `provider` ou `cash`.
  final String method;
  final String? providerCode;
  @JsonKey(fromJson: minorFromJson)
  final int amountMinor;
  final String? currencyCode;
  @JsonKey(unknownEnumValue: RefundStatus.unknown)
  final RefundStatus status;
  final String? lastError;
  final String? storeName;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get isCash => method == 'cash';

  /// À exécuter (ou à relancer).
  bool get actionable =>
      status == RefundStatus.pending || status == RefundStatus.failed;
}

/// Litige d'une commande (résumé).
@immutable
@JsonSerializable()
class AdminDisputeRef {
  const new({
    required this.id,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminDisputeRefFromJson(json);

  final String id;
  final String status;
  @JsonKey(unknownEnumValue: DisputeReason.unknown)
  final DisputeReason reason;
  final DateTime createdAt;

  bool get isOpen => status == 'open';
}

/// Livreur externe assigné.
@immutable
@JsonSerializable()
class OrderCourier {
  const new({required this.name, required this.phone, this.assignedAt});

  factory fromJson(Map<String, dynamic> json) => _$OrderCourierFromJson(json);

  final String name;
  final String phone;
  final DateTime? assignedAt;
}

/// Entrée du journal d'audit.
@immutable
@JsonSerializable()
class AdminAuditEntry {
  const new({
    required this.action,
    required this.occurredAt,
    this.id,
    this.actorId,
    this.actorFirstName,
    this.entityType,
    this.entityId,
    this.before,
    this.after,
    this.reason,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminAuditEntryFromJson(json);

  final int? id;
  final DateTime occurredAt;
  final String? actorId;
  final String? actorFirstName;
  final String action;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final String? reason;
}

/// Cliente d'une commande (vue équipe).
@immutable
@JsonSerializable()
class AdminCustomer {
  const new({this.firstName, this.phone});

  factory fromJson(Map<String, dynamic> json) => _$AdminCustomerFromJson(json);

  final String? firstName;
  final String? phone;
}

/// Détail d'une commande (écran 53).
@immutable
@JsonSerializable()
class AdminOrder {
  const new({
    required this.order,
    required this.reference,
    required this.storeName,
    required this.lastChangeAt,
    this.customer = const AdminCustomer(),
    this.stuck = false,
    this.hasOpenDispute = false,
    this.statusNote,
    this.timeline = const [],
    this.payments = const [],
    this.refunds = const [],
    this.dispute,
    this.courier,
    this.audit = const [],
    this.forceableStatuses = const [],
    this.canCancel = false,
    this.canAssignCourier = false,
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminOrderFromJson(json);

  /// Champs communs avec le suivi de la cliente.
  @JsonKey(readValue: _self)
  final CustomerOrder order;
  final String reference;
  final String storeName;
  final AdminCustomer customer;
  final DateTime lastChangeAt;
  final bool stuck;
  final bool hasOpenDispute;
  final String? statusNote;
  final List<AdminTimelineEvent> timeline;
  final List<AdminPayment> payments;
  final List<AdminRefund> refunds;
  final AdminDisputeRef? dispute;
  final OrderCourier? courier;
  final List<AdminAuditEntry> audit;
  @JsonKey(unknownEnumValue: OrderStatus.unknown)
  final List<OrderStatus> forceableStatuses;
  final bool canCancel;
  final bool canAssignCourier;

  String get id => order.id;
  OrderStatus get status => order.status;
}

/// Paiement en attente (A-FIN-03).
@immutable
@JsonSerializable()
class AdminPendingPayment {
  const new({
    required this.id,
    required this.reference,
    required this.providerCode,
    required this.amountMinor,
    required this.currencyCode,
    required this.createdAt,
    this.orders = const [],
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminPendingPaymentFromJson(json);

  final String id;
  final String reference;
  final String providerCode;
  @JsonKey(fromJson: minorFromJson)
  final int amountMinor;
  final String currencyCode;
  final DateTime createdAt;
  final List<AdminOrderRef> orders;
}

/// Commande citée (référence et boutique).
@immutable
@JsonSerializable()
class AdminOrderRef {
  const new({
    required this.id,
    required this.reference,
    required this.storeName,
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminOrderRefFromJson(json);

  final String id;
  final String reference;
  final String storeName;
}

// ------------------------------------------------------------------ litiges

/// Ligne de la liste des litiges (écran 54).
@immutable
@JsonSerializable()
class AdminDisputeRow {
  const new({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.storeName,
    required this.orderTotalMinor,
    required this.currencyCode,
    this.customerFirstName,
    this.messageCount = 0,
    this.lastMessageAt,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminDisputeRowFromJson(json);

  final String id;
  final String orderId;
  @JsonKey(unknownEnumValue: DisputeReason.unknown)
  final DisputeReason reason;
  final String status;
  final DateTime createdAt;
  final String storeName;
  final String? customerFirstName;
  @JsonKey(fromJson: minorFromJson)
  final int orderTotalMinor;
  final String currencyCode;
  final int messageCount;
  final DateTime? lastMessageAt;
}

/// Litige vu par l'équipe : conversation, décision et commande.
@immutable
@JsonSerializable()
class AdminDispute {
  const new({required this.dispute, required this.order});

  factory fromJson(Map<String, dynamic> json) => _$AdminDisputeFromJson(json);

  @JsonKey(readValue: _self)
  final Dispute dispute;
  final CustomerOrder order;
}

// ------------------------------------------------------------------ boutiques

/// Statut d'une boutique.
@JsonEnum(fieldRename: FieldRename.snake)
enum AdminStoreStatus {
  active,
  draft,
  suspended,
  unknown;

  String get code => name;
}

/// Ligne de la liste des boutiques (écran 55).
@immutable
@JsonSerializable()
class AdminStoreRow {
  const new({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    this.isOpen = false,
    this.origin,
    this.originLabel,
    this.ownerFirstName,
    this.zoneName,
    this.cityName,
    this.countryCode,
    this.publishedAt,
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminStoreRowFromJson(json);

  final String id;
  final String name;
  @JsonKey(unknownEnumValue: AdminStoreStatus.unknown)
  final AdminStoreStatus status;
  final bool isOpen;
  final String? origin;

  /// Libellé de l'origine (référentiel).
  @NullableLocalizedTextConverter()
  final LocalizedText? originLabel;
  final String? ownerFirstName;
  final String? zoneName;
  final String? cityName;
  final String? countryCode;
  final DateTime createdAt;
  final DateTime? publishedAt;
}

/// Page de la liste des boutiques.
@immutable
@JsonSerializable()
class AdminStorePage {
  const new({required this.counts, required this.stores});

  factory fromJson(Map<String, dynamic> json) => _$AdminStorePageFromJson(json);

  final Map<String, int> counts;
  final List<AdminStoreRow> stores;

  int count(AdminStoreStatus s) => counts[s.code] ?? 0;
}

/// Profil d'une boutique (écran 55).
@immutable
@JsonSerializable()
class AdminStore {
  const new({
    required this.row,
    this.description,
    this.zoneId,
    this.currencyCode,
    this.prepTimeMinutes = 30,
    this.offersPickup = false,
    this.orders7d = 0,
    this.sales7dMinor = 0,
    this.publishedProducts = 0,
    this.openDisputes = 0,
    this.audit = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminStoreFromJson(json);

  @JsonKey(readValue: _self)
  final AdminStoreRow row;
  final String? description;
  final String? zoneId;
  final String? currencyCode;
  final int prepTimeMinutes;
  final bool offersPickup;
  @JsonKey(name: 'orders_7d')
  final int orders7d;
  @JsonKey(name: 'sales_7d_minor', fromJson: minorFromJson)
  final int sales7dMinor;
  final int publishedProducts;
  final int openDisputes;
  final List<AdminAuditEntry> audit;

  String get id => row.id;
}

// ------------------------------------------------------------------ réglages

/// Pays et ce qui lui manque pour être activé (écran 56).
@immutable
@JsonSerializable()
class AdminCountry {
  const new({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.dialCode,
    required this.timezone,
    required this.isActive,
    this.missing = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminCountryFromJson(json);

  final String code;
  @LocalizedTextConverter()
  final LocalizedText name;
  final String currencyCode;
  final String dialCode;
  final String timezone;
  final bool isActive;

  /// `zones`, `payment_methods`, `delivery_fees`.
  final List<String> missing;

  bool get ready => missing.isEmpty;
}

/// Quartier (saisi par l'équipe).
@immutable
@JsonSerializable()
class AdminZone {
  const new({
    required this.id,
    required this.name,
    required this.isActive,
    this.latitude,
    this.longitude,
    this.storeCount = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminZoneFromJson(json);

  final String id;
  final String name;
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final int storeCount;
}

/// Ville et ses quartiers.
@immutable
@JsonSerializable()
class AdminCity {
  const new({
    required this.id,
    required this.name,
    required this.isActive,
    this.deliveryMinutes = 30,
    this.zones = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminCityFromJson(json);

  final String id;
  final String name;
  final bool isActive;
  final int deliveryMinutes;
  final List<AdminZone> zones;
}

/// Fournisseur de paiement.
@immutable
@JsonSerializable()
class AdminPaymentProvider {
  const new({
    required this.code,
    required this.label,
    required this.kind,
    required this.isActive,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminPaymentProviderFromJson(json);

  final String code;
  @LocalizedTextConverter()
  final LocalizedText label;
  final String kind;
  final bool isActive;
}

/// Moyen de paiement d'un pays.
@immutable
@JsonSerializable()
class AdminPaymentMethod {
  const new({
    required this.id,
    required this.countryCode,
    required this.providerCode,
    required this.label,
    required this.isActive,
    this.operatorCode,
    this.sort = 0,
    this.providerActive = true,
    this.kind,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminPaymentMethodFromJson(json);

  final String id;
  final String countryCode;
  final String providerCode;
  final String? operatorCode;
  @LocalizedTextConverter()
  final LocalizedText label;
  final int sort;
  final bool isActive;
  final bool providerActive;
  final String? kind;
}

/// Moyens d'un pays et fournisseurs disponibles.
@immutable
@JsonSerializable()
class AdminPaymentSettings {
  const new({required this.methods, required this.providers});

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminPaymentSettingsFromJson(json);

  final List<AdminPaymentMethod> methods;
  final List<AdminPaymentProvider> providers;
}

/// Commission en vigueur (pays, ou catégorie).
@immutable
@JsonSerializable()
class AdminCommission {
  const new({
    required this.id,
    required this.rateBps,
    this.categoryId,
    this.categoryLabel,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminCommissionFromJson(json);

  final String id;
  final String? categoryId;
  @NullableLocalizedTextConverter()
  final LocalizedText? categoryLabel;
  final int rateBps;
}

/// Frais de livraison par défaut en vigueur (pays, ou ville).
@immutable
@JsonSerializable()
class AdminDeliveryFee {
  const new({
    required this.id,
    required this.baseFeeMinor,
    required this.extraPickupFeeMinor,
    this.cityId,
    this.cityName,
    this.freeThresholdMinor,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminDeliveryFeeFromJson(json);

  final String id;
  final String? cityId;
  final String? cityName;
  @JsonKey(fromJson: minorFromJson)
  final int baseFeeMinor;
  @JsonKey(fromJson: minorFromJson)
  final int extraPickupFeeMinor;
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? freeThresholdMinor;
}

/// Commission et frais d'un pays.
@immutable
@JsonSerializable()
class AdminPricing {
  const new({
    required this.currencyCode,
    this.commissions = const [],
    this.deliveryFees = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminPricingFromJson(json);

  final String currencyCode;
  final List<AdminCommission> commissions;
  final List<AdminDeliveryFee> deliveryFees;
}

/// Catégorie générale.
@immutable
@JsonSerializable()
class AdminCategory {
  const new({
    required this.id,
    required this.slug,
    required this.label,
    required this.isActive,
    this.parentId,
    this.icon,
    this.sort = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminCategoryFromJson(json);

  final String id;
  final String? parentId;
  final String slug;
  @LocalizedTextConverter()
  final LocalizedText label;
  final String? icon;
  final int sort;
  final bool isActive;
}

// ------------------------------------------------------------------ journal

/// Page du journal d'audit (écran 58).
@immutable
@JsonSerializable()
class AdminAuditPage {
  const new({
    required this.total,
    required this.entries,
    this.actions = const [],
    this.entityTypes = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminAuditPageFromJson(json);

  final int total;
  final List<AdminAuditEntry> entries;
  final List<String> actions;
  final List<String> entityTypes;
}
