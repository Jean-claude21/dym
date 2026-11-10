import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Offre d'achat de gros groupé (spec 049).
@immutable
class WholesaleOffer {
  const new({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.unitPriceMinor,
    required this.minQuantity,
    required this.closesAt,
    required this.status,
    this.committed = 0,
    this.buyers = 0,
    this.myQuantity,
    this.mine = false,
    this.note,
    this.photoKey,
    this.commitments = const [],
  });

  factory fromJson(Map<String, dynamic> json) => WholesaleOffer(
    id: json['id']! as String,
    productName: json['product_name']! as String,
    storeName: json['store_name']! as String,
    unitPriceMinor: minorFromJson(json['unit_price_minor']),
    minQuantity: (json['min_quantity']! as num).toInt(),
    closesAt: DateTime.parse(json['closes_at']! as String),
    status: json['status']! as String,
    committed: (json['committed'] as num?)?.toInt() ?? 0,
    buyers: (json['buyers'] as num?)?.toInt() ?? 0,
    myQuantity: (json['my_quantity'] as num?)?.toInt(),
    mine: json['mine'] as bool? ?? false,
    note: json['note'] as String?,
    photoKey: json['photo_key'] as String?,
    commitments: [
      for (final c in json['commitments'] as List? ?? const [])
        (
          storeName: (c as Map)['store_name'] as String,
          quantity: (c['quantity'] as num).toInt(),
        ),
    ],
  );

  final String id;
  final String productName;
  final String storeName;
  final int unitPriceMinor;
  final int minQuantity;
  final DateTime closesAt;

  /// `open`, `closed` (date passée), `confirmed`, `cancelled`.
  final String status;
  final int committed;
  final int buyers;
  final int? myQuantity;
  final bool mine;
  final String? note;
  final String? photoKey;

  /// Acheteuses (grossiste seulement).
  final List<({String storeName, int quantity})> commitments;

  bool get open => status == 'open';
  bool get reached => committed >= minQuantity;
  double get progress => (committed / minQuantity).clamp(0, 1).toDouble();
}

/// Tableau des achats de gros (`wholesale_board()`).
@immutable
class WholesaleBoard {
  const new({
    this.isWholesaler = false,
    this.open = const [],
    this.mine = const [],
  });

  factory fromJson(Map<String, dynamic> json) => WholesaleBoard(
    isWholesaler: json['is_wholesaler'] as bool? ?? false,
    open: [
      for (final o in json['open'] as List? ?? const [])
        WholesaleOffer.fromJson((o as Map).cast<String, dynamic>()),
    ],
    mine: [
      for (final o in json['mine'] as List? ?? const [])
        WholesaleOffer.fromJson((o as Map).cast<String, dynamic>()),
    ],
  );

  final bool isWholesaler;
  final List<WholesaleOffer> open;
  final List<WholesaleOffer> mine;
}
