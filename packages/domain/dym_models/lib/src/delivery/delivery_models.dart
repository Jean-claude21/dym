import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Moyen de déplacement du livreur (`courier_profiles.vehicle`).
enum CourierVehicle {
  foot,
  bike,
  moto,
  car;

  static CourierVehicle parse(Object? value) =>
      values.where((v) => v.name == value).firstOrNull ?? moto;
}

/// Profil livreur (spec 041) : `my_courier_profile()`.
@immutable
class CourierProfile {
  const new({
    required this.displayName,
    required this.phone,
    required this.vehicle,
    this.suspended = false,
    this.isOnline = false,
    this.zoneIds = const [],
    this.score,
  });

  factory fromJson(Map<String, dynamic> json) => CourierProfile(
    displayName: json['display_name']! as String,
    phone: json['phone']! as String,
    vehicle: CourierVehicle.parse(json['vehicle']),
    suspended: json['status'] == 'suspended',
    isOnline: json['is_online'] as bool? ?? false,
    zoneIds: [
      for (final z in json['zone_ids'] as List? ?? const []) z as String,
    ],
    score: (json['score'] as num?)?.toDouble(),
  );

  final String displayName;
  final String phone;
  final CourierVehicle vehicle;
  final bool suspended;
  final bool isOnline;
  final List<String> zoneIds;

  /// Moyenne des dernières notes (1 à 5) ; null : pas encore noté.
  final double? score;
}

/// Consigne de conservation (`categories.storage`, `products.storage`).
enum StorageHint {
  ambient,
  cool,
  frozen,
  fragile;

  static StorageHint? parse(Object? value) =>
      values.where((v) => v.name == value).firstOrNull;
}

/// Remise par code : issue de la saisie.
@immutable
class HandoverResult {
  const new({required this.ok, this.attemptsLeft = 0, this.mission});

  factory fromJson(Map<String, dynamic> json) => HandoverResult(
    ok: json['ok'] as bool? ?? false,
    attemptsLeft: (json['attempts_left'] as num?)?.toInt() ?? 0,
    mission: switch (json['mission']) {
      final Map<dynamic, dynamic> m => Mission.fromJson(
        m.cast<String, dynamic>(),
      ),
      _ => null,
    },
  );

  final bool ok;
  final int attemptsLeft;
  final Mission? mission;
}

/// Lieu d'une mission (boutique ou cliente). Coordonnées et téléphone :
/// seulement après acceptation.
@immutable
class MissionPlace {
  const new({
    this.name,
    this.zoneName,
    this.landmark,
    this.phone,
    this.latitude,
    this.longitude,
  });

  factory fromJson(Map<String, dynamic> json) => MissionPlace(
    name: (json['name'] ?? json['first_name']) as String?,
    zoneName: json['zone_name'] as String?,
    landmark: json['landmark'] as String?,
    phone: json['phone'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  final String? name;
  final String? zoneName;
  final String? landmark;
  final String? phone;
  final double? latitude;
  final double? longitude;
}

/// Mission de livraison : proposée ou acceptée (`mission_json`).
@immutable
class Mission {
  const new({
    required this.orderId,
    required this.status,
    required this.createdAt,
    required this.deliveryFeeMinor,
    required this.currencyCode,
    required this.itemCount,
    required this.store,
    required this.customer,
    this.etaAt,
    this.acceptedAt,
    this.next = const [],
    this.purchaseId,
    this.runSize = 1,
    this.storage = const [],
  });

  factory fromJson(Map<String, dynamic> json) => Mission(
    orderId: json['order_id']! as String,
    status: json['status']! as String,
    createdAt: DateTime.parse(json['created_at']! as String),
    etaAt: switch (json['eta_at']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
    acceptedAt: switch (json['accepted_at']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
    deliveryFeeMinor: minorFromJson(json['delivery_fee_minor']),
    currencyCode: json['currency_code']! as String,
    itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    store: MissionPlace.fromJson(
      (json['store'] as Map? ?? const {}).cast<String, dynamic>(),
    ),
    customer: MissionPlace.fromJson(
      (json['customer'] as Map? ?? const {}).cast<String, dynamic>(),
    ),
    next: [for (final s in json['next'] as List? ?? const []) s as String],
    purchaseId: json['purchase_id'] as String?,
    runSize: (json['run_size'] as num?)?.toInt() ?? 1,
    storage: [
      for (final s in json['storage'] as List? ?? const [])
        ?StorageHint.parse(s),
    ],
  );

  final String orderId;

  /// Statut de la commande (`accepted`, `preparing`, `ready`,
  /// `out_for_delivery`, `delivered`).
  final String status;
  final DateTime createdAt;
  final DateTime? etaAt;
  final DateTime? acceptedAt;
  final int deliveryFeeMinor;
  final String currencyCode;
  final int itemCount;
  final MissionPlace store;
  final MissionPlace customer;

  /// Gestes permis au livreur (`out_for_delivery`, `delivered`).
  final List<String> next;

  /// Achat de la cliente : une tournée regroupe ses commandes à livrer.
  final String? purchaseId;

  /// Boutiques de la tournée (1 : course simple).
  final int runSize;

  /// Consignes de conservation des articles.
  final List<StorageHint> storage;

  bool get delivered => status == 'delivered';

  /// Encore rendable (pas récupérée).
  bool get releasable =>
      acceptedAt != null &&
      const ['accepted', 'preparing', 'ready'].contains(status);
}

/// Cash détenu par le livreur : dû à une boutique, ou à DYM (boutique nulle).
@immutable
class CourierCashLine {
  const new({required this.amountMinor, this.storeId, this.storeName});

  factory fromJson(Map<String, dynamic> json) => CourierCashLine(
    storeId: json['store_id'] as String?,
    storeName: json['store_name'] as String?,
    amountMinor: minorFromJson(json['amount_minor']),
  );

  final String? storeId;
  final String? storeName;
  final int amountMinor;

  bool get toPlatform => storeId == null;
}

/// Gains du livreur (spec 043) : `courier_earnings()`.
@immutable
class CourierEarnings {
  const new({
    this.todayCount = 0,
    this.todayFeesMinor = 0,
    this.walletMinor = 0,
    this.cash = const [],
  });

  factory fromJson(Map<String, dynamic> json) => CourierEarnings(
    todayCount: (json['today_count'] as num?)?.toInt() ?? 0,
    todayFeesMinor: minorFromJson(json['today_fees_minor']),
    walletMinor: minorFromJson(json['wallet_minor']),
    cash: [
      for (final c in json['cash'] as List? ?? const [])
        CourierCashLine.fromJson((c as Map).cast<String, dynamic>()),
    ],
  );

  final int todayCount;
  final int todayFeesMinor;
  final int walletMinor;
  final List<CourierCashLine> cash;

  int get cashTotalMinor => cash.fold(0, (sum, c) => sum + c.amountMinor);
}

/// Cash qu'un livreur doit à la boutique : `store_courier_cash()`.
@immutable
class StoreCourierCash {
  const new({
    required this.courierId,
    required this.amountMinor,
    this.courierName,
  });

  factory fromJson(Map<String, dynamic> json) => StoreCourierCash(
    courierId: json['courier_id']! as String,
    courierName: json['courier_name'] as String?,
    amountMinor: minorFromJson(json['amount_minor']),
  );

  final String courierId;
  final String? courierName;
  final int amountMinor;
}

/// Demande d'une zone : missions en attente d'un livreur (`zone_demand()`).
@immutable
class ZoneDemand {
  const new({
    required this.zoneName,
    required this.waiting,
    this.high = false,
    this.bonusMinor = 0,
  });

  factory fromJson(Map<String, dynamic> json) => ZoneDemand(
    zoneName: json['zone_name']! as String,
    waiting: (json['waiting'] as num?)?.toInt() ?? 0,
    high: json['high'] as bool? ?? false,
    bonusMinor: minorFromJson(json['bonus_minor']),
  );

  final String zoneName;
  final int waiting;
  final bool high;
  final int bonusMinor;
}

/// Suivi en direct pour la cliente (`order_live()`).
@immutable
class OrderLive {
  const new({
    required this.courierName,
    this.simulated = false,
    this.distanceM,
    this.etaAt,
  });

  factory fromJson(Map<String, dynamic> json) => OrderLive(
    courierName: json['courier_name']! as String,
    simulated: json['simulated'] as bool? ?? false,
    distanceM: (json['distance_m'] as num?)?.toInt(),
    etaAt: switch (json['eta_at']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
  );

  final String courierName;

  /// Position simulée, faute de GPS (décision 0015).
  final bool simulated;

  /// Distance à vol d'oiseau ; null : position ou adresse sans coordonnées.
  final int? distanceM;
  final DateTime? etaAt;
}

/// Livreur d'une commande livrée, et note donnée (nulle : à noter).
@immutable
class CourierRating {
  const new({required this.courierName, this.rating});

  factory fromJson(Map<String, dynamic> json) => CourierRating(
    courierName: json['courier_name']! as String,
    rating: (json['rating'] as num?)?.toInt(),
  );

  final String courierName;
  final int? rating;
}
