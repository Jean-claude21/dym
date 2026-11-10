/// Ajustements d'une commande (spec 034) : remplacement, garantie fraîcheur.
library;

import 'package:dym_models/src/json.dart';

enum AdjustmentKind { substitution, freshness }

enum AdjustmentStatus { pending, accepted, refused, credited, unknown }

class OrderAdjustment {
  const new({
    required this.id,
    required this.kind,
    required this.variantId,
    required this.itemName,
    required this.photoKey,
    required this.status,
    this.proposedVariantId,
    this.proposedName,
    this.note,
    this.creditedMinor = 0,
    this.createdAt,
  });

  factory fromJson(Map<String, dynamic> json) => OrderAdjustment(
    id: json['id'] as String,
    kind: json['kind'] == 'freshness'
        ? AdjustmentKind.freshness
        : AdjustmentKind.substitution,
    variantId: json['variant_id'] as String,
    itemName: json['item_name'] as String? ?? '',
    photoKey: json['photo_key'] as String,
    status: switch (json['status']) {
      'pending' => AdjustmentStatus.pending,
      'accepted' => AdjustmentStatus.accepted,
      'refused' => AdjustmentStatus.refused,
      'credited' => AdjustmentStatus.credited,
      _ => AdjustmentStatus.unknown,
    },
    proposedVariantId: json['proposed_variant_id'] as String?,
    proposedName: json['proposed_name'] as String?,
    note: json['note'] as String?,
    creditedMinor: minorFromJson(json['credited_minor'] ?? 0),
    createdAt: switch (json['created_at']) {
      final String d => DateTime.parse(d),
      _ => null,
    },
  );

  final String id;
  final AdjustmentKind kind;

  /// Ligne visée (variante d'origine).
  final String variantId;
  final String itemName;
  final String? proposedVariantId;
  final String? proposedName;
  final String photoKey;
  final String? note;
  final AdjustmentStatus status;

  /// Montant rendu sur le wallet (refus, fraîcheur).
  final int creditedMinor;
  final DateTime? createdAt;

  bool get awaitingAnswer =>
      kind == AdjustmentKind.substitution && status == AdjustmentStatus.pending;
}

/// Ajustements lus dans le JSON d'une commande.
List<OrderAdjustment> adjustmentsFromJson(Object? json) => [
  for (final a in json as List? ?? const [])
    OrderAdjustment.fromJson((a as Map).cast<String, dynamic>()),
];
