import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Un marchandage (spec 050) : offre de la cliente, prix conclu ou contre-prix.
@immutable
class Haggle {
  const new({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.listPriceMinor,
    required this.offerMinor,
    required this.priceMinor,
    required this.status,
    required this.expiresAt,
    this.attemptsLeft = 0,
  });

  factory fromJson(Map<String, dynamic> json) => Haggle(
    id: json['id']! as String,
    productName: json['product_name']! as String,
    quantity: (json['quantity']! as num).toInt(),
    listPriceMinor: minorFromJson(json['list_price_minor']),
    offerMinor: minorFromJson(json['offer_minor']),
    priceMinor: minorFromJson(json['price_minor']),
    status: json['status']! as String,
    expiresAt: DateTime.parse(json['expires_at']! as String),
    attemptsLeft: (json['attempts_left'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String productName;
  final int quantity;
  final int listPriceMinor;
  final int offerMinor;

  /// Prix conclu, ou contre-prix proposé.
  final int priceMinor;

  /// `accepted`, `countered`, `used`, `expired`.
  final String status;
  final DateTime expiresAt;
  final int attemptsLeft;

  bool get accepted => status == 'accepted';
  bool get countered => status == 'countered';
}

/// Réglages et suivi du marchandage de la vendeuse (`my_haggling()`).
@immutable
class HagglingSettings {
  const new({
    this.storePercent,
    this.products = const [],
    this.recent = const [],
    this.concludedWeek = 0,
  });

  factory fromJson(Map<String, dynamic> json) => HagglingSettings(
    storePercent: (json['store_percent'] as num?)?.toInt(),
    products: [
      for (final p in json['products'] as List? ?? const [])
        (
          id: (p as Map)['id'] as String,
          name: p['name'] as String,
          percent: (p['percent'] as num?)?.toInt(),
        ),
    ],
    recent: [
      for (final h in json['recent'] as List? ?? const [])
        Haggle.fromJson((h as Map).cast<String, dynamic>()),
    ],
    concludedWeek: (json['concluded_week'] as num?)?.toInt() ?? 0,
  );

  /// Remise maximale de la boutique (nulle : pas de marchandage).
  final int? storePercent;

  /// Limite par produit : nulle = celle de la boutique, 0 = jamais.
  final List<({String id, String name, int? percent})> products;
  final List<Haggle> recent;
  final int concludedWeek;
}
