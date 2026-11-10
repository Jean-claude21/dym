import 'package:dym_core/dym_core.dart';
import 'package:dym_models/src/cart/order_tracking.dart';
import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Statut de commande depuis sa valeur en base (`out_for_delivery`…).
OrderStatus orderStatusFromWire(String? wire) => OrderStatus.values.firstWhere(
  (s) =>
      s.name.replaceAllMapped(
        RegExp('[A-Z]'),
        (m) => '_${m[0]!.toLowerCase()}',
      ) ==
      wire,
  orElse: () => OrderStatus.unknown,
);

/// Commande en retard (centre d'opérations, spec 053).
@immutable
class OpsAlert {
  const new({
    required this.orderId,
    required this.storeName,
    required this.status,
    required this.minutes,
    this.delivery = false,
    this.hasCourier = false,
  });

  factory fromJson(Map<String, dynamic> json) => OpsAlert(
    orderId: json['order_id']! as String,
    storeName: json['store_name']! as String,
    status: orderStatusFromWire(json['status'] as String?),
    minutes: (json['minutes']! as num).toInt(),
    delivery: json['fulfillment'] == 'delivery',
    hasCourier: json['has_courier'] as bool? ?? false,
  );

  final String orderId;
  final String storeName;
  final OrderStatus status;
  final int minutes;
  final bool delivery;
  final bool hasCourier;
}

/// Cash d'un livreur dû à DYM.
@immutable
class CourierCashDue {
  const new({
    required this.courierId,
    required this.name,
    required this.phone,
    required this.amountMinor,
    required this.currencyCode,
  });

  factory fromJson(Map<String, dynamic> json) => CourierCashDue(
    courierId: json['courier_id']! as String,
    name: json['name']! as String,
    phone: json['phone']! as String,
    amountMinor: minorFromJson(json['amount_minor']),
    currencyCode: json['currency_code']! as String,
  );

  final String courierId;
  final String name;
  final String phone;
  final int amountMinor;
  final String currencyCode;
}

/// Vue en direct d'un pays (`ops_live`).
@immutable
class OpsLive {
  const new({
    required this.countryCode,
    required this.currencyCode,
    this.countries = const [],
    this.ordersByStatus = const {},
    this.deliveredMinor = 0,
    this.alerts = const [],
    this.couriersOnline = 0,
    this.missionsWaiting = 0,
    this.openDisputes = 0,
    this.openTickets = 0,
    this.openReports = 0,
    this.courierCash = const [],
    this.fraudOpen = 0,
  });

  factory fromJson(Map<String, dynamic> json) => OpsLive(
    countryCode: json['country_code']! as String,
    currencyCode: json['currency_code']! as String,
    countries: [
      for (final c in json['countries'] as List? ?? const []) c as String,
    ],
    ordersByStatus: {
      for (final e in ((json['orders_by_status'] as Map?) ?? const {}).entries)
        orderStatusFromWire(e.key as String): (e.value as num).toInt(),
    },
    deliveredMinor: minorFromJson(json['delivered_minor'] ?? 0),
    alerts: [
      for (final a in json['alerts'] as List? ?? const [])
        OpsAlert.fromJson((a as Map).cast<String, dynamic>()),
    ],
    couriersOnline: (json['couriers_online'] as num?)?.toInt() ?? 0,
    missionsWaiting: (json['missions_waiting'] as num?)?.toInt() ?? 0,
    openDisputes: (json['open_disputes'] as num?)?.toInt() ?? 0,
    openTickets: (json['open_tickets'] as num?)?.toInt() ?? 0,
    openReports: (json['open_reports'] as num?)?.toInt() ?? 0,
    fraudOpen: (json['fraud_open'] as num?)?.toInt() ?? 0,
    courierCash: [
      for (final c in json['courier_cash'] as List? ?? const [])
        CourierCashDue.fromJson((c as Map).cast<String, dynamic>()),
    ],
  );

  final String countryCode;
  final String currencyCode;

  /// Pays du périmètre de l'admin.
  final List<String> countries;

  /// Commandes des dernières 24 h.
  final Map<OrderStatus, int> ordersByStatus;
  final int deliveredMinor;
  final List<OpsAlert> alerts;
  final int couriersOnline;
  final int missionsWaiting;
  final int openDisputes;
  final int openTickets;
  final int openReports;
  final List<CourierCashDue> courierCash;

  /// Signaux de fraude ouverts (spec 054).
  final int fraudOpen;
}

/// Signal de fraude repéré par une règle (spec 054) ; l'équipe décide.
@immutable
class FraudSignal {
  const new({
    required this.id,
    required this.kind,
    required this.subjectType,
    required this.createdAt,
    this.subject,
    this.detail = const {},
    this.status = 'open',
  });

  factory fromJson(Map<String, dynamic> json) => FraudSignal(
    id: json['id']! as String,
    kind: json['kind']! as String,
    subjectType: json['subject_type']! as String,
    subject: json['subject'] as String?,
    createdAt: DateTime.parse(json['created_at']! as String),
    detail: (json['detail'] as Map?)?.cast<String, Object?>() ?? const {},
    status: json['status'] as String? ?? 'open',
  );

  final String id;

  /// Règle : `client_cancel_burst`, `store_refusal_burst`, `shared_device`,
  /// `handover_code_failures`, `haggle_burst`.
  final String kind;

  /// `user` ou `store`.
  final String subjectType;
  final String? subject;
  final DateTime createdAt;
  final Map<String, Object?> detail;
  final String status;

  /// Nombre relevé par la règle (comptes, refus, essais…).
  int get count =>
      ((detail['count'] ?? detail['accounts']) as num?)?.toInt() ?? 0;
}

/// Formule vue par l'équipe.
@immutable
class OpsPlan {
  const new({
    required this.id,
    required this.code,
    required this.audience,
    required this.name,
    required this.priceMinor,
    required this.periodDays,
    this.isActive = true,
  });

  factory fromJson(Map<String, dynamic> json) => OpsPlan(
    id: json['id']! as String,
    code: json['code']! as String,
    audience: json['audience']! as String,
    name: LocalizedText.fromJson(json['name']),
    priceMinor: minorFromJson(json['price_minor']),
    periodDays: (json['period_days']! as num).toInt(),
    isActive: json['is_active'] as bool? ?? true,
  );

  final String id;
  final String code;

  /// `client` ou `vendor`.
  final String audience;
  final LocalizedText name;
  final int priceMinor;
  final int periodDays;
  final bool isActive;
}

/// Réglages des opérations d'un pays (`admin_ops_settings`).
@immutable
class OpsSettings {
  const new({
    required this.countryCode,
    required this.currencyCode,
    this.thresholds = const {},
    this.feedWeights = const {},
    this.plans = const [],
    this.canManageScopes = false,
    this.scopes = const [],
  });

  factory fromJson(Map<String, dynamic> json) => OpsSettings(
    countryCode: json['country_code']! as String,
    currencyCode: json['currency_code']! as String,
    thresholds: {
      for (final e in ((json['thresholds'] as Map?) ?? const {}).entries)
        e.key as String: (e.value as num).toInt(),
    },
    feedWeights: {
      for (final e in ((json['feed_weights'] as Map?) ?? const {}).entries)
        if (e.value is num) e.key as String: (e.value as num).toInt(),
    },
    plans: [
      for (final p in json['plans'] as List? ?? const [])
        OpsPlan.fromJson((p as Map).cast<String, dynamic>()),
    ],
    canManageScopes: json['can_manage_scopes'] as bool? ?? false,
    scopes: [
      for (final s in json['scopes'] as List? ?? const [])
        (
          email: (s as Map)['email'] as String,
          countries: [
            for (final c in s['countries'] as List? ?? const []) c as String,
          ],
        ),
    ],
  );

  final String countryCode;
  final String currencyCode;

  /// Minutes : `pending`, `ready`, `transit`.
  final Map<String, int> thresholds;

  /// Poids du fil (`weight_recency`…).
  final Map<String, int> feedWeights;
  final List<OpsPlan> plans;

  /// Admin sans limite de pays : gère les limites des autres.
  final bool canManageScopes;
  final List<({String email, List<String> countries})> scopes;
}
