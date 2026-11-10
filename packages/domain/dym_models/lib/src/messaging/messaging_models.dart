import 'package:dym_models/src/discovery/discovery_models.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'messaging_models.g.dart';

Object? _self(Map<dynamic, dynamic> json, String key) => json;

/// Nature d'un message.
@JsonEnum(fieldRename: FieldRename.snake)
enum MessageKind { text, image, product, audio, call, unknown }

/// Rôle dans une conversation.
enum ChatRole {
  client,
  vendor;

  String get code => name;
}

/// Message d'une conversation (spec 015).
@immutable
@JsonSerializable()
class ChatMessage {
  const new({
    required this.id,
    required this.conversationId,
    required this.authorRole,
    required this.kind,
    required this.createdAt,
    this.body,
    this.hasMedia = false,
    this.product,
    this.productId,
    this.durationMs,
    this.call,
  });

  factory fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  final String id;
  final String conversationId;

  /// `client` ou `vendor`.
  final String authorRole;
  @JsonKey(unknownEnumValue: MessageKind.unknown)
  final MessageKind kind;
  final String? body;

  /// Image privée : lien signé demandé à part.
  final bool hasMedia;

  /// Fiche publique du produit partagé (nulle s'il n'est plus en vente).
  final CatalogItem? product;
  final String? productId;
  final DateTime createdAt;

  /// Vocal (spec 035) : durée en millisecondes.
  final int? durationMs;

  /// Résumé d'un appel (spec 035).
  @JsonKey(fromJson: CallSummary.maybeFromJson)
  final CallSummary? call;

  bool fromMe(ChatRole me) => authorRole == me.code;
}

/// Conversation entre une cliente et une boutique.
@immutable
@JsonSerializable()
class Conversation {
  const new({
    required this.id,
    required this.storeId,
    required this.storeName,
    this.storeOrigin,
    this.storeActive = true,
    this.clientFirstName,
    this.lastMessageAt,
    this.lastMessage,
    this.unread = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

  final String id;
  final String storeId;
  final String storeName;
  final String? storeOrigin;
  final bool storeActive;
  final String? clientFirstName;
  final DateTime? lastMessageAt;
  final ChatMessage? lastMessage;
  final int unread;
}

/// Conversation ouverte : fil des messages (du plus ancien au plus récent).
@immutable
@JsonSerializable()
class ConversationThread {
  const new({
    required this.conversation,
    required this.role,
    this.messages = const [],
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$ConversationThreadFromJson(json);

  @JsonKey(readValue: _self)
  final Conversation conversation;

  /// Rôle de la lectrice.
  final String role;
  final List<ChatMessage> messages;
}

/// Type d'appel (spec 035).
enum CallKind { audio, video }

/// État d'un appel, tenu par la base.
enum CallStatus { ringing, ongoing, declined, missed, ended, unknown }

CallStatus _callStatus(Object? value) => switch (value) {
  'ringing' => CallStatus.ringing,
  'ongoing' => CallStatus.ongoing,
  'declined' => CallStatus.declined,
  'missed' => CallStatus.missed,
  'ended' => CallStatus.ended,
  _ => CallStatus.unknown,
};

/// Résumé d'appel affiché dans la conversation.
@immutable
class CallSummary {
  const new({required this.kind, required this.status, this.durationS});

  static CallSummary? maybeFromJson(Object? json) => switch (json) {
    final Map<dynamic, dynamic> m => CallSummary(
      kind: m['kind'] == 'video' ? CallKind.video : CallKind.audio,
      status: _callStatus(m['status']),
      durationS: (m['duration_s'] as num?)?.toInt(),
    ),
    _ => null,
  };

  final CallKind kind;
  final CallStatus status;
  final int? durationS;
}

/// Appel en cours ou entrant (spec 035).
@immutable
class CallSession {
  const new({
    required this.id,
    required this.conversationId,
    required this.kind,
    required this.status,
    this.outgoing = false,
    this.callerName,
    this.provider = 'simulated',
    this.durationS,
  });

  factory fromJson(Map<String, dynamic> json) => CallSession(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    kind: json['kind'] == 'video' ? CallKind.video : CallKind.audio,
    status: _callStatus(json['status']),
    outgoing: json['outgoing'] as bool? ?? false,
    callerName: json['caller_name'] as String?,
    provider: json['provider'] as String? ?? 'simulated',
    durationS: (json['duration_s'] as num?)?.toInt(),
  );

  final String id;
  final String conversationId;
  final CallKind kind;
  final CallStatus status;

  /// Appel lancé par la personne qui regarde.
  final bool outgoing;
  final String? callerName;

  /// Fournisseur média (`simulated` tant que le vrai n'est pas branché).
  final String provider;
  final int? durationS;

  bool get active =>
      status == CallStatus.ringing || status == CallStatus.ongoing;
  bool get simulated => provider == 'simulated';
}
