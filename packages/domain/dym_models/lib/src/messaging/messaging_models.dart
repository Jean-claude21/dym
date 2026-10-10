import 'package:dym_models/src/discovery/discovery_models.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'messaging_models.g.dart';

Object? _self(Map<dynamic, dynamic> json, String key) => json;

/// Nature d'un message.
@JsonEnum(fieldRename: FieldRename.snake)
enum MessageKind { text, image, product, unknown }

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
