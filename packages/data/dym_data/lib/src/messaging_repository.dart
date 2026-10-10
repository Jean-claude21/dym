import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Messagerie (spec 015) : lectures par la Data API, envois et images par la
/// Function (participation vérifiée en base).
class MessagingRepository {
  new({required this._data, required this._functions, required this._uploads});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;
  final NeonObjectUploader _uploads;

  Future<Result<List<Conversation>>> conversations(ChatRole role) async =>
      _decode(
        await _data.rpc<Object?>(
          'my_conversations',
          params: {'p_role': role.code},
        ),
        (json) => [
          for (final c in json! as List)
            Conversation.fromJson(c as Map<String, dynamic>),
        ],
      );

  /// Fil d'une conversation ; l'ouvrir la marque lue.
  Future<Result<ConversationThread>> thread(String id) async => _decode(
    await _data.rpc<Object?>('conversation', params: {'p_id': id}),
    (json) => ConversationThread.fromJson(json! as Map<String, dynamic>),
  );

  Future<Result<int>> unreadCount(ChatRole role) async => _decode(
    await _data.rpc<Object?>(
      'unread_messages_count',
      params: {'p_role': role.code},
    ),
    (json) => (json! as num).toInt(),
  );

  /// Ouvre (ou retrouve) la conversation avec une boutique. Refus :
  /// `store_unavailable`, `own_store`.
  Future<Result<Conversation>> start(String storeId) => _functions.post(
    '/v1/conversations',
    body: {'store_id': storeId},
    decode: (json) => Conversation.fromJson(json! as Map<String, dynamic>),
  );

  Future<Result<ChatMessage>> sendText(
    String conversationId,
    String body, {
    required String idempotencyKey,
  }) => _send(conversationId, {'kind': 'text', 'body': body}, idempotencyKey);

  Future<Result<ChatMessage>> sendProduct(
    String conversationId,
    String productId, {
    required String idempotencyKey,
  }) => _send(conversationId, {
    'kind': 'product',
    'product_id': productId,
  }, idempotencyKey);

  /// Envoie une image compressée dans l'espace privé de la conversation.
  Future<Result<ChatMessage>> sendImage(
    String conversationId,
    List<int> bytes, {
    required String contentType,
    required String idempotencyKey,
  }) async {
    final grant = await _functions.post<Map<String, dynamic>>(
      '/v1/conversations/$conversationId/media-uploads',
      body: {'content_type': contentType},
      decode: (json) => json! as Map<String, dynamic>,
    );
    switch (grant) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final sent = await _uploads.put(
          Uri.parse(value['upload_url'] as String),
          bytes,
          contentType: contentType,
        );
        if (sent case Err(:final failure)) return Err(failure);
        return await _send(conversationId, {
          'kind': 'image',
          'media_key': value['object_key'],
        }, idempotencyKey);
    }
  }

  /// Liens de lecture signés (5 min) des images visibles, par message.
  Future<Result<Map<String, String>>> mediaUrls(List<String> messageIds) =>
      _functions.post(
        '/v1/chat-media/urls',
        body: {'message_ids': messageIds},
        decode: (json) => {
          for (final e
              in ((json! as Map<String, dynamic>)['urls'] as Map).entries)
            '${e.key}': '${e.value}',
        },
      );

  Future<Result<ChatMessage>> _send(
    String conversationId,
    Map<String, Object?> body,
    String idempotencyKey,
  ) => _functions.post(
    '/v1/conversations/$conversationId/messages',
    body: body,
    idempotencyKey: idempotencyKey,
    decode: (json) => ChatMessage.fromJson(json! as Map<String, dynamic>),
  );

  Result<T> _decode<T>(Result<Object?> result, T Function(Object? json) f) {
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        try {
          return Ok(f(value));
        } on Object {
          return const Err(ServerFailure('réponse illisible'));
        }
    }
  }
}
