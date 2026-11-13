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
    this.serviceRadiusM = 15000,
    this.zones = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminCityFromJson(json);

  final String id;
  final String name;
  final bool isActive;
  final int deliveryMinutes;

  /// Distance maximale à un quartier pour être desservi (spec 065).
  final int serviceRadiusM;
  final List<AdminZone> zones;
}

/// Livraisons sur une période (spec 066) : livreurs, courses sans livreur,
/// délai de prise, relances, refus automatiques, alertes « prête ».
@immutable
@JsonSerializable()
class AdminDispatch {
  const new({
    this.couriersActive = 0,
    this.couriersOnline = 0,
    this.waiting = 0,
    this.medianAcceptMinutes,
    this.relaunches = 0,
    this.widened = 0,
    this.autoRefused = 0,
    this.readyAlerts = 0,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminDispatchFromJson(json);

  final int couriersActive;
  final int couriersOnline;
  final int waiting;
  final int? medianAcceptMinutes;
  final int relaunches;
  final int widened;
  final int autoRefused;
  final int readyAlerts;
}

/// Échanges sur une période (specs 070 à 072) : messages, conversations,
/// boutiques actives par origine, notifications envoyées ou retenues.
@immutable
@JsonSerializable()
class AdminExchanges {
  const new({
    this.messages = 0,
    this.messagesWithOrder = 0,
    this.conversationsActive = 0,
    this.storesByOrigin = const [],
    this.pushSent = 0,
    this.pushSkipped = 0,
    this.pushFailed = 0,
    this.quietNightUsers = 0,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminExchangesFromJson(json);

  final int messages;
  final int messagesWithOrder;
  final int conversationsActive;
  final List<AdminOriginCount> storesByOrigin;
  final int pushSent;
  final int pushSkipped;
  final int pushFailed;
  final int quietNightUsers;
}

/// Boutiques actives d'une origine (marché, maison, boutique, supermarché…).
@immutable
@JsonSerializable()
class AdminOriginCount {
  const new({required this.code, required this.label, this.stores = 0});

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminOriginCountFromJson(json);

  final String code;
  @LocalizedTextConverter()
  final LocalizedText label;
  final int stores;
}

/// Positions hors zone sur une période, par pays le plus proche (spec 065).
@immutable
@JsonSerializable()
class AdminCoverage {
  const new({required this.total, this.countries = const []});

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminCoverageFromJson(json);

  final int total;
  final List<AdminCoverageCountry> countries;
}

/// Positions hors zone d'un pays et distance médiane au quartier desservi.
@immutable
@JsonSerializable()
class AdminCoverageCountry {
  const new({required this.countryCode, required this.misses, this.medianKm});

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminCoverageCountryFromJson(json);

  final String countryCode;
  final int misses;
  final int? medianKm;
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

// ---------------------------------------------------------- pilote (spec 017)

/// Montant dans une devise (aucun total ne traverse les devises).
@immutable
class CurrencyAmount {
  const new({required this.currencyCode, required this.minor, this.orders = 0});

  factory fromJson(Map<String, dynamic> json) => CurrencyAmount(
    currencyCode: json['currency_code'] as String,
    minor: minorFromJson(json['sales_minor'] ?? json['minor']),
    orders: (json['orders'] as num?)?.toInt() ?? 0,
  );

  final String currencyCode;
  final int minor;
  final int orders;
}

/// Réussites et échecs (paiements, livraisons).
@immutable
class SuccessRate {
  const new({required this.succeeded, required this.failed});

  factory fromJson(Map<String, dynamic> json, String ok, String ko) =>
      SuccessRate(
        succeeded: (json[ok] as num?)?.toInt() ?? 0,
        failed: (json[ko] as num?)?.toInt() ?? 0,
      );

  final int succeeded;
  final int failed;

  /// Taux en pourcentage (nul sans données).
  int? get percent => succeeded + failed == 0
      ? null
      : (succeeded * 100 / (succeeded + failed)).round();
}

/// Jour de la série sur 30 jours.
@immutable
class DashboardDay {
  const new({required this.day, required this.orders, this.sales = const []});

  factory fromJson(Map<String, dynamic> json) => DashboardDay(
    day: DateTime.parse(json['day'] as String),
    orders: (json['orders'] as num?)?.toInt() ?? 0,
    sales: [
      for (final s in (json['sales'] as List? ?? const []))
        CurrencyAmount.fromJson(s as Map<String, dynamic>),
    ],
  );

  final DateTime day;
  final int orders;
  final List<CurrencyAmount> sales;
}

/// Boutique du classement.
@immutable
class TopStore {
  const new({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.orders,
    required this.salesMinor,
    this.rating,
  });

  factory fromJson(Map<String, dynamic> json) => TopStore(
    id: json['id'] as String,
    name: json['name'] as String,
    currencyCode: json['currency_code'] as String,
    orders: (json['orders'] as num).toInt(),
    salesMinor: minorFromJson(json['sales_minor']),
    rating: (json['rating'] as num?)?.toDouble(),
  );

  final String id;
  final String name;
  final String currencyCode;
  final int orders;
  final int salesMinor;
  final double? rating;
}

/// Catégorie ou produit du classement (quantités vendues).
@immutable
class TopItem {
  const new({required this.label, required this.quantity, this.detail});

  final LocalizedText label;
  final String? detail;
  final int quantity;
}

/// Tableau de bord de l'équipe (écran 67).
@immutable
class AdminDashboard {
  const new({
    required this.period,
    this.activeOrders = 0,
    this.stuckOrders = 0,
    this.revenue = const [],
    this.payments1h = const SuccessRate(succeeded: 0, failed: 0),
    this.payments24h = const SuccessRate(succeeded: 0, failed: 0),
    this.deliveries = const SuccessRate(succeeded: 0, failed: 0),
    this.activeClients = 0,
    this.activeVendors = 0,
    this.newSignups = 0,
    this.draftStores = 0,
    this.openDisputes = 0,
    this.lateDisputes = 0,
    this.openTickets = 0,
    this.lateTickets = 0,
    this.pendingRefunds = 0,
    this.series = const [],
    this.topStores = const [],
    this.topCategories = const [],
    this.topProducts = const [],
  });

  factory fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    Map<String, dynamic> m(String k) =>
        (json[k] as Map?)?.cast<String, dynamic>() ?? const {};
    List<dynamic> l(String k) => json[k] as List? ?? const [];
    return AdminDashboard(
      period: json['period'] as String? ?? 'day',
      activeOrders: n('active_orders'),
      stuckOrders: n('stuck_orders'),
      revenue: [
        for (final r in l('revenue'))
          CurrencyAmount.fromJson(r as Map<String, dynamic>),
      ],
      payments1h: SuccessRate.fromJson(m('payments_1h'), 'succeeded', 'failed'),
      payments24h: SuccessRate.fromJson(
        m('payments_24h'),
        'succeeded',
        'failed',
      ),
      deliveries: SuccessRate.fromJson(m('deliveries'), 'delivered', 'failed'),
      activeClients: (m('active_users')['client'] as num?)?.toInt() ?? 0,
      activeVendors: (m('active_users')['vendor'] as num?)?.toInt() ?? 0,
      newSignups: n('new_signups'),
      draftStores: n('draft_stores'),
      openDisputes: n('open_disputes'),
      lateDisputes: n('late_disputes'),
      openTickets: n('open_tickets'),
      lateTickets: n('late_tickets'),
      pendingRefunds: n('pending_refunds'),
      series: [
        for (final d in l('series_30d'))
          DashboardDay.fromJson(d as Map<String, dynamic>),
      ],
      topStores: [
        for (final s in l('top_stores'))
          TopStore.fromJson(s as Map<String, dynamic>),
      ],
      topCategories: [
        for (final c in l('top_categories'))
          TopItem(
            label: LocalizedText.fromJson((c as Map)['label']),
            quantity: (c['quantity'] as num).toInt(),
          ),
      ],
      topProducts: [
        for (final p in l('top_products'))
          TopItem(
            label: LocalizedText({'fr': (p as Map)['name'] as String}),
            detail: p['store_name'] as String?,
            quantity: (p['quantity'] as num).toInt(),
          ),
      ],
    );
  }

  final String period;
  final int activeOrders;
  final int stuckOrders;
  final List<CurrencyAmount> revenue;
  final SuccessRate payments1h;
  final SuccessRate payments24h;
  final SuccessRate deliveries;
  final int activeClients;
  final int activeVendors;
  final int newSignups;
  final int draftStores;
  final int openDisputes;
  final int lateDisputes;
  final int openTickets;
  final int lateTickets;
  final int pendingRefunds;
  final List<DashboardDay> series;
  final List<TopStore> topStores;
  final List<TopItem> topCategories;
  final List<TopItem> topProducts;
}

/// Revenus d'une devise.
@immutable
class RevenueTotal {
  const new({
    required this.currencyCode,
    required this.orders,
    required this.salesMinor,
    required this.commissionMinor,
    required this.netMinor,
    this.refundsMinor = 0,
    this.storeId,
    this.storeName,
  });

  factory fromJson(Map<String, dynamic> json) => RevenueTotal(
    currencyCode: json['currency_code'] as String,
    orders: (json['orders'] as num).toInt(),
    salesMinor: minorFromJson(json['sales_minor']),
    commissionMinor: minorFromJson(json['commission_minor']),
    netMinor: minorFromJson(json['net_minor']),
    refundsMinor: nullableMinorFromJson(json['refunds_minor']) ?? 0,
    storeId: json['id'] as String?,
    storeName: json['name'] as String?,
  );

  final String currencyCode;
  final int orders;
  final int salesMinor;
  final int commissionMinor;
  final int netMinor;
  final int refundsMinor;
  final String? storeId;
  final String? storeName;
}

/// Revenus de la plateforme (écran 70).
@immutable
class AdminRevenue {
  const new({
    required this.period,
    this.totals = const [],
    this.stores = const [],
  });

  factory fromJson(Map<String, dynamic> json) => AdminRevenue(
    period: json['period'] as String,
    totals: [
      for (final t in json['totals'] as List? ?? const [])
        RevenueTotal.fromJson(t as Map<String, dynamic>),
    ],
    stores: [
      for (final s in json['stores'] as List? ?? const [])
        RevenueTotal.fromJson(s as Map<String, dynamic>),
    ],
  );

  final String period;
  final List<RevenueTotal> totals;
  final List<RevenueTotal> stores;
}

/// Feature flag (pays nul : tous les pays).
@immutable
@JsonSerializable()
class AdminFeatureFlag {
  const new({
    required this.id,
    required this.key,
    required this.isEnabled,
    required this.description,
    this.countryCode,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminFeatureFlagFromJson(json);

  final String id;
  final String key;
  final String? countryCode;
  final bool isEnabled;
  final String description;
}

/// Ligne de la liste des clientes.
@immutable
@JsonSerializable()
class AdminClientRow {
  const new({
    required this.id,
    required this.firstName,
    required this.createdAt,
    this.orders = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$AdminClientRowFromJson(json);

  final String id;
  final String firstName;
  final DateTime createdAt;
  final int orders;
}

/// Adresse d'une cliente (vue équipe).
@immutable
@JsonSerializable()
class AdminClientAddress {
  const new({
    required this.kind,
    required this.zoneName,
    required this.landmark,
    this.label,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminClientAddressFromJson(json);

  final String kind;
  final String? label;
  final String zoneName;
  final String landmark;
}

/// Profil d'une cliente (écran 68).
@immutable
class AdminClient {
  const new({
    required this.id,
    required this.firstName,
    required this.createdAt,
    this.email,
    this.countryCode,
    this.zoneName,
    this.cityName,
    this.orders = const [],
    this.spent = const [],
    this.orderCount = 0,
    this.disputeCount = 0,
    this.ticketCount = 0,
    this.addresses = const [],
    this.reviews = const [],
  });

  factory fromJson(Map<String, dynamic> json) => AdminClient(
    id: json['id'] as String,
    firstName: json['first_name'] as String,
    email: json['email'] as String?,
    countryCode: json['country_code'] as String?,
    zoneName: json['zone_name'] as String?,
    cityName: json['city_name'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    orders: [
      for (final o in json['orders'] as List? ?? const [])
        AdminOrderRow.fromJson(o as Map<String, dynamic>),
    ],
    spent: [
      for (final s in json['spent'] as List? ?? const [])
        CurrencyAmount.fromJson(s as Map<String, dynamic>),
    ],
    orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
    disputeCount: (json['dispute_count'] as num?)?.toInt() ?? 0,
    ticketCount: (json['ticket_count'] as num?)?.toInt() ?? 0,
    addresses: [
      for (final a in json['addresses'] as List? ?? const [])
        AdminClientAddress.fromJson(a as Map<String, dynamic>),
    ],
    reviews: [
      for (final r in json['reviews'] as List? ?? const [])
        AdminClientReview(
          storeName: (r as Map)['store_name'] as String? ?? '',
          rating: (r['rating'] as num).toInt(),
          comment: r['comment'] as String?,
        ),
    ],
  );

  final String id;
  final String firstName;
  final String? email;
  final String? countryCode;
  final String? zoneName;
  final String? cityName;
  final DateTime createdAt;
  final List<AdminOrderRow> orders;
  final List<CurrencyAmount> spent;
  final int orderCount;
  final int disputeCount;
  final int ticketCount;
  final List<AdminClientAddress> addresses;
  final List<AdminClientReview> reviews;
}

/// Avis laissé par une cliente (vue équipe).
@immutable
class AdminClientReview {
  const new({required this.storeName, required this.rating, this.comment});

  final String storeName;
  final int rating;
  final String? comment;
}

/// Produit vu par l'équipe (vue de l'app d'une vendeuse).
@immutable
@JsonSerializable()
class AdminVendorProduct {
  const new({
    required this.id,
    required this.name,
    required this.status,
    this.priceMinor,
    this.isAvailable = true,
    this.stock,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$AdminVendorProductFromJson(json);

  final String id;
  final String name;
  final String status;
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? priceMinor;
  final bool isAvailable;
  final int? stock;
}

/// Vue de l'app d'une vendeuse (A-VEN-07), en lecture.
@immutable
class AdminVendorView {
  const new({
    required this.store,
    this.products = const [],
    this.recentOrders = const [],
    this.rating,
    this.reviewCount = 0,
  });

  factory fromJson(Map<String, dynamic> json) => AdminVendorView(
    store: AdminStore.fromJson(json),
    products: [
      for (final p in json['products'] as List? ?? const [])
        AdminVendorProduct.fromJson(p as Map<String, dynamic>),
    ],
    recentOrders: [
      for (final o in json['recent_orders'] as List? ?? const [])
        AdminOrderRow.fromJson(o as Map<String, dynamic>),
    ],
    rating: ((json['rating'] as Map?)?['rating'] as num?)?.toDouble(),
    reviewCount:
        ((json['rating'] as Map?)?['review_count'] as num?)?.toInt() ?? 0,
  );

  final AdminStore store;
  final List<AdminVendorProduct> products;
  final List<AdminOrderRow> recentOrders;
  final double? rating;
  final int reviewCount;
}

/// Poids de classement d'un pays (nul : défaut), réglés par l'équipe.
@immutable
class RankingRule {
  const new({required this.weights, this.countryCode});

  factory fromJson(Map<String, dynamic> json) => RankingRule(
    countryCode: json['country_code'] as String?,
    weights: {for (final key in keys) key: (json[key] as num?)?.toInt() ?? 0},
  );

  /// Clés des poids, dans l'ordre d'affichage.
  static const keys = [
    'weight_text',
    'weight_same_store',
    'weight_open',
    'weight_rating',
    'weight_price',
    'weight_same_zone',
  ];

  final String? countryCode;
  final Map<String, int> weights;
}

/// Nom local et ses équivalents (« gboma » → épinard, feuille).
@immutable
class SearchSynonym {
  const new({
    required this.id,
    required this.term,
    required this.synonyms,
    this.countryCode,
  });

  factory fromJson(Map<String, dynamic> json) => SearchSynonym(
    id: json['id']! as String,
    countryCode: json['country_code'] as String?,
    term: json['term']! as String,
    synonyms: [for (final s in json['synonyms'] as List? ?? const []) '$s'],
  );

  final String id;
  final String? countryCode;
  final String term;
  final List<String> synonyms;
}

/// Réglages de la recherche (`public.admin_search_settings`).
@immutable
class AdminSearchSettings {
  const new({this.rules = const [], this.synonyms = const []});

  factory fromJson(Map<String, dynamic> json) => AdminSearchSettings(
    rules: [
      for (final r
          in (json['rules'] as List? ?? const []).cast<Map<String, dynamic>>())
        RankingRule.fromJson(r),
    ],
    synonyms: [
      for (final s
          in (json['synonyms'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
        SearchSynonym.fromJson(s),
    ],
  );

  final List<RankingRule> rules;
  final List<SearchSynonym> synonyms;

  /// Poids effectifs d'un pays : les siens, sinon ceux par défaut.
  RankingRule ruleFor(String? country) =>
      rules.where((r) => r.countryCode == country).firstOrNull ??
      rules.where((r) => r.countryCode == null).firstOrNull ??
      const RankingRule(weights: {});
}
