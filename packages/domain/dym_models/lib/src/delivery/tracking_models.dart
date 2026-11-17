import 'package:meta/meta.dart';

double? _d(Object? v) => switch (v) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};

DateTime? _t(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// Point d'un suivi (degrés décimaux).
@immutable
class TrackPoint {
  const new(this.latitude, this.longitude);

  static TrackPoint? fromJson(Object? json) {
    if (json is! Map) return null;
    final lat = _d(json['latitude']);
    final lng = _d(json['longitude']);
    return lat == null || lng == null ? null : TrackPoint(lat, lng);
  }

  final double latitude;
  final double longitude;
}

/// Livreur vu dans un suivi : prénom, moyen, dernière position.
@immutable
class TrackedCourier {
  const new({required this.name, this.vehicle, this.position, this.updatedAt});

  factory fromJson(Map<String, dynamic> json) => TrackedCourier(
    name: json['name'] as String? ?? '',
    vehicle: json['vehicle'] as String?,
    position: TrackPoint.fromJson(json),
    updatedAt: _t(json['updated_at']),
  );

  final String name;
  final String? vehicle;
  final TrackPoint? position;
  final DateTime? updatedAt;
}

/// Suivi d'une commande (spec 096) : `order_tracking`, `tracking_by_token`.
@immutable
class LiveTracking {
  const new({
    required this.orderId,
    required this.status,
    required this.storeName,
    this.store,
    this.destination,
    this.courier,
    this.etaMinutes,
  });

  factory fromJson(Map<String, dynamic> json) {
    final store = (json['store'] as Map?)?.cast<String, dynamic>() ?? const {};
    return LiveTracking(
      orderId: json['order_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      storeName: store['name'] as String? ?? '',
      store: TrackPoint.fromJson(store),
      destination: TrackPoint.fromJson(json['destination']),
      courier: switch (json['courier']) {
        final Map<dynamic, dynamic> m => TrackedCourier.fromJson(
          m.cast<String, dynamic>(),
        ),
        _ => null,
      },
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
    );
  }

  final String orderId;
  final String status;
  final String storeName;
  final TrackPoint? store;
  final TrackPoint? destination;
  final TrackedCourier? courier;

  /// Minutes restantes (nulles sans position du livreur).
  final int? etaMinutes;

  bool get live =>
      status == 'accepted' ||
      status == 'preparing' ||
      status == 'ready' ||
      status == 'out_for_delivery';
}

/// Lien de suivi partagé (spec 096).
@immutable
class TrackingShare {
  const new({required this.token, required this.expiresAt});

  factory fromJson(Map<String, dynamic> json) => TrackingShare(
    token: json['token']! as String,
    expiresAt: _t(json['expires_at']) ?? DateTime.now(),
  );

  final String token;
  final DateTime expiresAt;
}

/// Livreur d'une boutique (spec 096) : `my_store_couriers`.
@immutable
class StoreCourierInfo {
  const new({
    required this.courierId,
    required this.name,
    required this.phone,
    required this.vehicle,
    this.isOnline = false,
    this.busy = false,
  });

  factory fromJson(Map<String, dynamic> json) => StoreCourierInfo(
    courierId: json['courier_id']! as String,
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    vehicle: json['vehicle'] as String? ?? '',
    isOnline: json['is_online'] as bool? ?? false,
    busy: json['busy'] as bool? ?? false,
  );

  final String courierId;
  final String name;
  final String phone;
  final String vehicle;
  final bool isOnline;
  final bool busy;
}

/// Résultat d'un code (récupération ou remise).
@immutable
class CodeCheck {
  const new({required this.ok, this.attemptsLeft = 0});

  factory fromJson(Map<String, dynamic> json) => CodeCheck(
    ok: json['ok'] as bool? ?? false,
    attemptsLeft: (json['attempts_left'] as num?)?.toInt() ?? 0,
  );

  final bool ok;
  final int attemptsLeft;
}

/// Incident de livraison vu par l'équipe (spec 096).
@immutable
class DeliveryIncident {
  const new({
    required this.id,
    required this.kind,
    required this.courierName,
    required this.courierPhone,
    required this.createdAt,
    this.orderId,
    this.position,
    this.note,
    this.resolvedAt,
  });

  factory fromJson(Map<String, dynamic> json) => DeliveryIncident(
    id: json['id']! as String,
    kind: json['kind'] as String? ?? '',
    courierName: json['courier_name'] as String? ?? '',
    courierPhone: json['courier_phone'] as String? ?? '',
    createdAt: _t(json['created_at']) ?? DateTime.now(),
    orderId: json['order_id'] as String?,
    position: TrackPoint.fromJson(json),
    note: json['note'] as String?,
    resolvedAt: _t(json['resolved_at']),
  );

  final String id;

  /// `sos` ou `unreachable`.
  final String kind;
  final String courierName;
  final String courierPhone;
  final DateTime createdAt;
  final String? orderId;
  final TrackPoint? position;
  final String? note;
  final DateTime? resolvedAt;

  bool get sos => kind == 'sos';
}

/// Compte à valider (boutique ou livreur).
@immutable
class PendingAccount {
  const new({
    required this.id,
    required this.kind,
    required this.name,
    required this.countryCode,
    required this.createdAt,
    this.detail,
    this.contact,
  });

  final String id;

  /// `store` ou `courier`.
  final String kind;
  final String name;
  final String countryCode;
  final DateTime createdAt;

  /// Origine et quartier (boutique), moyen (livreur).
  final String? detail;

  /// Email (boutique), téléphone (livreur).
  final String? contact;

  /// `admin_pending_accounts` : boutiques puis livreurs.
  static List<PendingAccount> listFromJson(Map<String, dynamic> json) {
    List<Map<dynamic, dynamic>> rows(String key) =>
        (json[key] as List? ?? const []).cast<Map<dynamic, dynamic>>();
    return [
      for (final s in rows('stores'))
        PendingAccount(
          id: s['id'] as String,
          kind: 'store',
          name: s['name'] as String? ?? '',
          countryCode: s['country_code'] as String? ?? '',
          createdAt: _t(s['created_at']) ?? DateTime.now(),
          detail: [s['origin'], s['zone_name']].whereType<String>().join(' · '),
          contact: s['owner_email'] as String?,
        ),
      for (final c in rows('couriers'))
        PendingAccount(
          id: c['id'] as String,
          kind: 'courier',
          name: c['name'] as String? ?? '',
          countryCode: c['country_code'] as String? ?? '',
          createdAt: _t(c['created_at']) ?? DateTime.now(),
          detail: c['vehicle'] as String?,
          contact: c['phone'] as String?,
        ),
    ];
  }
}

/// Tranche de frais par distance (spec 096).
@immutable
class FeeBand {
  const new({required this.maxDistanceM, required this.feeMinor});

  factory fromJson(Map<String, dynamic> json) => FeeBand(
    maxDistanceM: (json['max_distance_m'] as num).toInt(),
    feeMinor: (json['fee_minor'] as num).toInt(),
  );

  final int maxDistanceM;
  final int feeMinor;

  Map<String, Object> toJson() => {
    'max_distance_m': maxDistanceM,
    'fee_minor': feeMinor,
  };
}

/// Itinéraire tracé sur la carte (spec 109) : points, distance, durée.
@immutable
class DeliveryRoute {
  const new({
    required this.points,
    this.distanceM = 0,
    this.durationS = 0,
    this.approximate = false,
  });

  factory fromJson(Map<String, dynamic> json) => DeliveryRoute(
    points: [
      for (final p in json['coordinates'] as List? ?? const [])
        if (p is List && p.length == 2)
          TrackPoint((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ],
    distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
    durationS: (json['duration_s'] as num?)?.toInt() ?? 0,
  );

  final List<TrackPoint> points;
  final int distanceM;
  final int durationS;

  /// Ligne droite (itinéraire inconnu) : tracée en pointillés.
  final bool approximate;
}
