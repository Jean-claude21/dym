import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'pilot_models.g.dart';

/// Étiquette rapide d'un avis.
@JsonEnum(fieldRename: FieldRename.snake)
enum ReviewTag {
  fresh,
  wellPacked,
  fast,
  friendly,
  unknown;

  String get code => switch (this) {
    wellPacked => 'well_packed',
    _ => name,
  };
}

/// Avis d'une cliente sur une commande livrée (spec 016).
@immutable
@JsonSerializable()
class Review {
  const new({
    required this.id,
    required this.orderId,
    required this.storeId,
    required this.rating,
    required this.createdAt,
    this.tags = const [],
    this.comment,
    this.reply,
    this.repliedAt,
    this.authorFirstName,
    this.status = 'published',
  });

  factory fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);

  final String id;
  final String orderId;
  final String storeId;
  final int rating;
  @JsonKey(unknownEnumValue: ReviewTag.unknown)
  final List<ReviewTag> tags;
  final String? comment;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime createdAt;
  final String? authorFirstName;
  final String status;
}

/// Avis d'une boutique et sa note.
@immutable
@JsonSerializable()
class StoreReviews {
  const new({
    this.rating,
    this.reviewCount = 0,
    this.distribution = const {},
    this.reviews = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$StoreReviewsFromJson(json);

  /// Note moyenne sur 5 (nulle sans avis).
  final double? rating;
  final int reviewCount;

  /// Nombre d'avis par note (« 5 » → 32).
  final Map<String, int> distribution;
  final List<Review> reviews;
}

/// Résultat d'un réachat.
@immutable
@JsonSerializable()
class ReorderResult {
  const new({required this.added, this.skipped = const []});

  factory fromJson(Map<String, dynamic> json) => _$ReorderResultFromJson(json);

  final int added;

  /// Articles écartés (plus en vente) : noms figés de la commande.
  final List<String> skipped;
}

/// Sujet d'une demande d'aide.
@JsonEnum(fieldRename: FieldRename.snake)
enum TicketSubject {
  order,
  payment,
  account,
  store,
  other,
  unknown;

  String get code => this == unknown ? 'other' : name;
}

/// État d'une demande.
@JsonEnum(fieldRename: FieldRename.snake)
enum TicketStatus { open, pending, closed, unknown }

/// Message d'une demande.
@immutable
@JsonSerializable()
class TicketMessage {
  const new({
    required this.id,
    required this.authorRole,
    required this.body,
    required this.createdAt,
  });

  factory fromJson(Map<String, dynamic> json) => _$TicketMessageFromJson(json);

  final String id;

  /// `user` ou `team`.
  final String authorRole;
  final String body;
  final DateTime createdAt;
}

/// Demande d'aide (ticket) d'une cliente ou d'une vendeuse.
@immutable
@JsonSerializable()
class SupportTicket {
  const new({
    required this.id,
    required this.app,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.lastActivityAt,
    this.orderId,
    this.orderReference,
    this.firstResponseAt,
    this.closedAt,
    this.messages = const [],
    this.userFirstName,
    this.userId,
    this.storeName,
  });

  factory fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);

  final String id;

  /// `client` ou `vendor`.
  final String app;
  @JsonKey(unknownEnumValue: TicketSubject.unknown)
  final TicketSubject subject;
  @JsonKey(unknownEnumValue: TicketStatus.unknown)
  final TicketStatus status;
  final String? orderId;
  final String? orderReference;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final DateTime? firstResponseAt;
  final DateTime? closedAt;
  final List<TicketMessage> messages;

  /// Équipe seulement.
  final String? userFirstName;
  final String? userId;
  final String? storeName;
}
