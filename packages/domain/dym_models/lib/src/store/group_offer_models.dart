import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Offre d'achat groupé entre voisins (spec 051).
@immutable
class GroupOffer {
  const new({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.groupPriceMinor,
    required this.priceMinor,
    required this.minQuantity,
    required this.closesAt,
    required this.status,
    this.memberDeliveryFeeMinor,
    this.committed = 0,
    this.members = 0,
    this.myQuantity,
    this.ordered = false,
    this.reached = false,
    this.photoKey,
  });

  factory fromJson(Map<String, dynamic> json) => GroupOffer(
    id: json['id']! as String,
    storeId: json['store_id']! as String,
    storeName: json['store_name']! as String,
    productId: json['product_id']! as String,
    productName: json['product_name']! as String,
    variantId: json['variant_id']! as String,
    groupPriceMinor: minorFromJson(json['group_price_minor']),
    priceMinor: minorFromJson(json['price_minor']),
    minQuantity: (json['min_quantity']! as num).toInt(),
    closesAt: DateTime.parse(json['closes_at']! as String),
    status: json['status']! as String,
    memberDeliveryFeeMinor: nullableMinorFromJson(
      json['member_delivery_fee_minor'],
    ),
    committed: (json['committed'] as num?)?.toInt() ?? 0,
    members: (json['members'] as num?)?.toInt() ?? 0,
    myQuantity: (json['my_quantity'] as num?)?.toInt(),
    ordered: json['ordered'] as bool? ?? false,
    reached: json['reached'] as bool? ?? false,
    photoKey: json['photo_key'] as String?,
  );

  final String id;
  final String storeId;
  final String storeName;
  final String productId;
  final String productName;
  final String variantId;
  final int groupPriceMinor;

  /// Prix du jour.
  final int priceMinor;
  final int minQuantity;
  final DateTime closesAt;

  /// `open`, `closed` (date passée), `cancelled`.
  final String status;

  /// Frais de livraison des membres (livraison partagée) ; nul : frais normaux.
  final int? memberDeliveryFeeMinor;
  final int committed;
  final int members;
  final int? myQuantity;

  /// L'avantage a déjà servi à une commande.
  final bool ordered;

  /// Minimum atteint : prix de groupe débloqué.
  final bool reached;
  final String? photoKey;

  bool get open => status == 'open';
  bool get joined => myQuantity != null;

  /// Prix de groupe à mettre au panier.
  bool get canOrder => reached && joined && !ordered && status != 'cancelled';
  double get progress => (committed / minQuantity).clamp(0, 1).toDouble();
}
