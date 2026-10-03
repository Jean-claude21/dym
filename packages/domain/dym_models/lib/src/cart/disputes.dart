import 'package:dym_models/src/json.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'disputes.g.dart';

/// Raison d'un signalement.
@JsonEnum(fieldRename: FieldRename.snake)
enum DisputeReason {
  missingItem,
  wrongItem,
  damaged,
  quality,
  notDelivered,
  other,
  unknown;

  String get code => switch (this) {
    missingItem => 'missing_item',
    wrongItem => 'wrong_item',
    notDelivered => 'not_delivered',
    unknown => 'other',
    _ => name,
  };
}

/// Décision de l'équipe.
@JsonEnum(fieldRename: FieldRename.snake)
enum DisputeResolution { noAction, partialRefund, fullRefund, unknown }

/// Message du fil d'un litige.
@immutable
@JsonSerializable()
class DisputeMessage {
  const new({
    required this.id,
    required this.authorRole,
    required this.body,
    required this.createdAt,
  });

  factory fromJson(Map<String, dynamic> json) => _$DisputeMessageFromJson(json);

  final String id;

  /// `client`, `vendor` ou `admin`.
  final String authorRole;
  final String body;
  final DateTime createdAt;
}

/// Litige d'une commande (spec 012).
@immutable
@JsonSerializable()
class Dispute {
  const new({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.currencyCode,
    this.storeName,
    this.resolution,
    this.refundMinor,
    this.vendorWarned = false,
    this.resolvedAt,
    this.messages = const [],
    this.internalNote,
    this.customerFirstName,
  });

  factory fromJson(Map<String, dynamic> json) => _$DisputeFromJson(json);

  final String id;
  final String orderId;
  @JsonKey(unknownEnumValue: DisputeReason.unknown)
  final DisputeReason reason;
  final String description;

  /// `open` ou `resolved`.
  final String status;
  @JsonKey(unknownEnumValue: DisputeResolution.unknown)
  final DisputeResolution? resolution;
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? refundMinor;
  final String currencyCode;
  final bool vendorWarned;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? storeName;
  final List<DisputeMessage> messages;

  /// Équipe seulement.
  final String? internalNote;
  final String? customerFirstName;

  bool get isOpen => status == 'open';
}
