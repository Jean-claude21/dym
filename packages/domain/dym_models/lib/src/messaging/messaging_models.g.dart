// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ChatMessage',
  json,
  ($checkedConvert) {
    final val = ChatMessage(
      id: $checkedConvert('id', (v) => v as String),
      conversationId: $checkedConvert('conversation_id', (v) => v as String),
      authorRole: $checkedConvert('author_role', (v) => v as String),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(
          _$MessageKindEnumMap,
          v,
          unknownValue: MessageKind.unknown,
        ),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      body: $checkedConvert('body', (v) => v as String?),
      hasMedia: $checkedConvert('has_media', (v) => v as bool? ?? false),
      product: $checkedConvert(
        'product',
        (v) =>
            v == null ? null : CatalogItem.fromJson(v as Map<String, dynamic>),
      ),
      productId: $checkedConvert('product_id', (v) => v as String?),
      durationMs: $checkedConvert('duration_ms', (v) => (v as num?)?.toInt()),
      call: $checkedConvert('call', (v) => CallSummary.maybeFromJson(v)),
      payload: $checkedConvert('payload', (v) => v as Map<String, dynamic>?),
      transcript: $checkedConvert('transcript', (v) => v as String?),
      liveUntil: $checkedConvert(
        'live_until',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'conversationId': 'conversation_id',
    'authorRole': 'author_role',
    'createdAt': 'created_at',
    'hasMedia': 'has_media',
    'productId': 'product_id',
    'durationMs': 'duration_ms',
    'liveUntil': 'live_until',
  },
);

const _$MessageKindEnumMap = {
  MessageKind.text: 'text',
  MessageKind.image: 'image',
  MessageKind.product: 'product',
  MessageKind.audio: 'audio',
  MessageKind.call: 'call',
  MessageKind.video: 'video',
  MessageKind.location: 'location',
  MessageKind.quote: 'quote',
  MessageKind.paymentRequest: 'payment_request',
  MessageKind.coupon: 'coupon',
  MessageKind.unknown: 'unknown',
};

Conversation _$ConversationFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'Conversation',
  json,
  ($checkedConvert) {
    final val = Conversation(
      id: $checkedConvert('id', (v) => v as String),
      storeId: $checkedConvert('store_id', (v) => v as String),
      storeName: $checkedConvert('store_name', (v) => v as String),
      storeOrigin: $checkedConvert('store_origin', (v) => v as String?),
      storeActive: $checkedConvert('store_active', (v) => v as bool? ?? true),
      clientFirstName: $checkedConvert(
        'client_first_name',
        (v) => v as String?,
      ),
      lastMessageAt: $checkedConvert(
        'last_message_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      lastMessage: $checkedConvert(
        'last_message',
        (v) =>
            v == null ? null : ChatMessage.fromJson(v as Map<String, dynamic>),
      ),
      unread: $checkedConvert('unread', (v) => (v as num?)?.toInt() ?? 0),
      orderId: $checkedConvert('order_id', (v) => v as String?),
      courierName: $checkedConvert('courier_name', (v) => v as String?),
      closed: $checkedConvert('closed', (v) => v as bool? ?? false),
    );
    return val;
  },
  fieldKeyMap: const {
    'storeId': 'store_id',
    'storeName': 'store_name',
    'storeOrigin': 'store_origin',
    'storeActive': 'store_active',
    'clientFirstName': 'client_first_name',
    'lastMessageAt': 'last_message_at',
    'lastMessage': 'last_message',
    'orderId': 'order_id',
    'courierName': 'courier_name',
  },
);

ConversationThread _$ConversationThreadFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ConversationThread',
      json,
      ($checkedConvert) {
        final val = ConversationThread(
          conversation: $checkedConvert(
            'conversation',
            (v) => Conversation.fromJson(v as Map<String, dynamic>),
            readValue: _self,
          ),
          role: $checkedConvert('role', (v) => v as String),
          messages: $checkedConvert(
            'messages',
            (v) =>
                (v as List<dynamic>?)
                    ?.map(
                      (e) => ChatMessage.fromJson(e as Map<String, dynamic>),
                    )
                    .toList() ??
                const [],
          ),
          peerReadAt: $checkedConvert(
            'peer_read_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          activeOrder: $checkedConvert(
            'active_order',
            (v) => ChatOrder.maybeFromJson(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'peerReadAt': 'peer_read_at',
        'activeOrder': 'active_order',
      },
    );
