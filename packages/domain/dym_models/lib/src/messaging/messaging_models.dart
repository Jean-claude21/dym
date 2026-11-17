import 'package:dym_models/src/cart/order_tracking.dart';
import 'package:dym_models/src/discovery/discovery_models.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'messaging_models.g.dart';

Object? _self(Map<dynamic, dynamic> json, String key) => json;

/// Nature d'un message.
@JsonEnum(fieldRename: FieldRename.snake)
enum MessageKind {
  text,
  image,
  product,
  audio,
  call,
  // Chat de commerce (spec 099).
  video,
  location,
  quote,
  paymentRequest,
  coupon,
  // Chat refait (spec 111).
  file,
  unknown,
}

/// Rôle dans une conversation.
enum ChatRole {
  client,
  vendor,

  /// Livreur, dans le fil d'une commande (spec 109).
  courier;

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
    this.payload,
    this.transcript,
    this.liveUntil,
    this.replyTo,
    this.reactions = const [],
    this.deleted = false,
    this.forwarded = false,
    this.authorName,
    this.mine,
  });

  factory fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  /// Groupe (spec 112) : prénom de l'autrice ou de l'auteur.
  final String? authorName;

  /// Mon message (selon la session) ; nul : déduit du rôle.
  final bool? mine;

  /// Message cité (spec 111).
  @JsonKey(fromJson: MessageQuote.maybeFromJson, includeToJson: false)
  final MessageQuote? replyTo;

  /// Réactions, une par personne (spec 111).
  @JsonKey(fromJson: MessageReaction.listFromJson, includeToJson: false)
  final List<MessageReaction> reactions;

  /// Supprimé pour tout le monde : plus aucun contenu.
  final bool deleted;

  /// Transféré depuis une autre conversation.
  final bool forwarded;

  /// Document (spec 111) : nom, taille et type.
  String? get fileName => payloadText('name');
  int? get fileSize => payloadNumber('size')?.toInt();

  /// Seuls le texte, le produit et la position se transfèrent.
  bool get forwardable =>
      !deleted &&
      (kind == MessageKind.text ||
          kind == MessageKind.product ||
          (kind == MessageKind.location && !isLive));

  /// Réaction posée par [role] (une par personne).
  String? reactionOf(ChatRole role) => reactions
      .where((r) => r.mine ?? r.roles.contains(role.code))
      .firstOrNull
      ?.emoji;

  /// Contenu structuré (spec 099) : position, devis, demande de paiement,
  /// coupon ; l'état (accepté, payé, expiré) est relu en base.
  final Map<String, dynamic>? payload;

  /// Texte d'un vocal, une fois transcrit.
  final String? transcript;

  /// Position en direct : fin du partage.
  final DateTime? liveUntil;

  /// Position partagée en direct, encore active.
  bool get isLive =>
      kind == MessageKind.location &&
      (liveUntil?.isAfter(DateTime.now()) ?? false);

  double? payloadNumber(String key) => switch (payload?[key]) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  String? payloadText(String key) => payload?[key]?.toString();

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

  /// Dans un groupe, plusieurs personnes ont le même rôle : la base dit si
  /// le message est le mien.
  bool fromMe(ChatRole me) => mine ?? authorRole == me.code;
}

/// Message cité dans une réponse (spec 111).
@immutable
class MessageQuote {
  const new({
    required this.id,
    required this.authorRole,
    required this.kind,
    this.body,
    this.deleted = false,
  });

  static MessageQuote? maybeFromJson(Object? json) => switch (json) {
    final Map<dynamic, dynamic> m => MessageQuote(
      id: m['id'] as String,
      authorRole: m['author_role'] as String? ?? '',
      kind: MessageKind.values.firstWhere(
        (k) => _snake(k.name) == m['kind'],
        orElse: () => MessageKind.unknown,
      ),
      body: m['body'] as String?,
      deleted: m['deleted'] as bool? ?? false,
    ),
    _ => null,
  };

  final String id;
  final String authorRole;
  final MessageKind kind;
  final String? body;
  final bool deleted;
}

String _snake(String name) =>
    name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

/// Réaction à un message : emoji, nombre et rôles qui l'ont posée.
@immutable
class MessageReaction {
  const new({
    required this.emoji,
    required this.count,
    this.roles = const [],
    this.mine,
  });

  static List<MessageReaction> listFromJson(Object? json) => switch (json) {
    final List<dynamic> list => [
      for (final r in list.whereType<Map<dynamic, dynamic>>())
        MessageReaction(
          emoji: r['emoji'] as String? ?? '',
          count: (r['count'] as num?)?.toInt() ?? 1,
          roles: [for (final role in r['roles'] as List? ?? const []) '$role'],
          mine: r['mine'] as bool?,
        ),
    ],
    _ => const [],
  };

  final String emoji;
  final int count;
  final List<String> roles;

  /// Ma réaction (groupe : plusieurs personnes du même rôle).
  final bool? mine;
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
    this.orderId,
    this.courierName,
    this.closed = false,
    this.kind = 'direct',
    this.groupTitle,
    this.groupOfferId,
    this.membersCount,
  });

  factory fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

  /// `direct`, `order`, `family` ou `group_buy` (spec 112).
  final String kind;

  /// Nom du groupe (ou du produit de l'offre groupée).
  @JsonKey(name: 'title')
  final String? groupTitle;
  final String? groupOfferId;
  final int? membersCount;

  bool get isGroup => kind == 'family' || kind == 'group_buy';
  bool get isFamily => kind == 'family';
  bool get isGroupBuy => kind == 'group_buy';

  final String id;
  final String storeId;
  final String storeName;
  final String? storeOrigin;
  final bool storeActive;
  final String? clientFirstName;
  final DateTime? lastMessageAt;
  final ChatMessage? lastMessage;
  final int unread;

  /// Fil d'une commande (spec 109) : cliente, boutique et livreur ensemble.
  final String? orderId;
  final String? courierName;

  /// Fil terminé (24 h après la remise) : lecture seule.
  final bool closed;

  bool get isOrderThread => orderId != null;
}

/// Conversation ouverte : fil des messages (du plus ancien au plus récent).
@immutable
@JsonSerializable()
class ConversationThread {
  const new({
    required this.conversation,
    required this.role,
    this.messages = const [],
    this.peerReadAt,
    this.peerDeliveredAt,
    this.myReadAt,
    this.activeOrder,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$ConversationThreadFromJson(json);

  @JsonKey(readValue: _self)
  final Conversation conversation;

  /// Rôle de la lectrice.
  final String role;
  final List<ChatMessage> messages;

  /// Dernière lecture de l'autre personne (spec 070) : mes messages envoyés
  /// avant sont « vus ».
  final DateTime? peerReadAt;

  /// Dernière ouverture de l'app par l'autre personne (spec 111) : mes
  /// messages envoyés avant sont « reçus » (✓✓ gris).
  final DateTime? peerDeliveredAt;

  /// Ma lecture précédente : les messages reçus après sont « nouveaux ».
  final DateTime? myReadAt;

  /// Commande en cours entre la cliente et la boutique (spec 070).
  @JsonKey(fromJson: ChatOrder.maybeFromJson, includeToJson: false)
  final ChatOrder? activeOrder;

  /// Vrai si l'autre personne a ouvert la conversation après [message].
  bool seen(ChatMessage message) {
    final read = peerReadAt;
    return read != null && !message.createdAt.isAfter(read);
  }

  /// Vrai si l'app de l'autre personne a reçu [message].
  bool delivered(ChatMessage message) {
    if (seen(message)) return true;
    final at = peerDeliveredAt;
    return at != null && !message.createdAt.isAfter(at);
  }

  ConversationThread copyWith({List<ChatMessage>? messages}) =>
      ConversationThread(
        conversation: conversation,
        role: role,
        messages: messages ?? this.messages,
        peerReadAt: peerReadAt,
        peerDeliveredAt: peerDeliveredAt,
        myReadAt: myReadAt,
        activeOrder: activeOrder,
      );
}

/// Commande en cours rappelée en tête d'une conversation (spec 070).
@immutable
class ChatOrder {
  const new({
    required this.id,
    required this.status,
    required this.totalMinor,
    required this.currencyCode,
  });

  static ChatOrder? maybeFromJson(Object? json) => switch (json) {
    final Map<dynamic, dynamic> m => ChatOrder(
      id: m['id'] as String,
      status: OrderStatus.values.firstWhere(
        (s) => s.code == m['status'],
        orElse: () => OrderStatus.unknown,
      ),
      totalMinor: (m['total_minor'] as num?)?.toInt() ?? 0,
      currencyCode: m['currency_code'] as String? ?? '',
    ),
    _ => null,
  };

  final String id;
  final OrderStatus status;
  final int totalMinor;
  final String currencyCode;
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

/// Membre d'un groupe (spec 112) : prénom seulement.
@immutable
class GroupMember {
  const new({
    required this.userId,
    required this.firstName,
    this.admin = false,
    this.me = false,
  });

  factory fromJson(Map<String, dynamic> json) => GroupMember(
    userId: json['user_id']! as String,
    firstName: json['first_name'] as String? ?? '',
    admin: json['admin'] as bool? ?? false,
    me: json['me'] as bool? ?? false,
  );

  final String userId;
  final String firstName;
  final bool admin;
  final bool me;
}

/// Détail d'un groupe : nom, membres, suis-je administratrice.
@immutable
class GroupInfo {
  const new({
    required this.id,
    required this.kind,
    required this.title,
    this.meAdmin = false,
    this.members = const [],
    this.storeName,
    this.groupOfferId,
  });

  factory fromJson(Map<String, dynamic> json) => GroupInfo(
    id: json['id']! as String,
    kind: json['kind'] as String? ?? 'family',
    title: json['title'] as String? ?? '',
    meAdmin: json['me_admin'] as bool? ?? false,
    members: [
      for (final m in json['members'] as List? ?? const [])
        GroupMember.fromJson((m as Map).cast<String, dynamic>()),
    ],
    storeName: json['store_name'] as String?,
    groupOfferId: json['group_offer_id'] as String?,
  );

  final String id;
  final String kind;
  final String title;
  final bool meAdmin;
  final List<GroupMember> members;
  final String? storeName;
  final String? groupOfferId;

  bool get isFamily => kind == 'family';
}
