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

  /// Fil d'une commande (spec 109) : cliente, boutique et livreur ; ouvert
  /// dès qu'un livreur est affecté. Refus : `no_courier`.
  Future<Result<Conversation>> orderThread(String orderId) async => _decode(
    await _data.rpc<Object?>('order_thread', params: {'p_order': orderId}),
    (json) => Conversation.fromJson(json! as Map<String, dynamic>),
  );

  /// Texte ; [replyTo] : message cité (spec 111).
  Future<Result<ChatMessage>> sendText(
    String conversationId,
    String body, {
    required String idempotencyKey,
    String? replyTo,
  }) => _send(conversationId, {
    'kind': 'text',
    'body': body,
    'reply_to': ?replyTo,
  }, idempotencyKey);

  /// Document (spec 111) : PDF, Word, Excel… 10 Mo au plus, espace privé de
  /// la conversation.
  Future<Result<ChatMessage>> sendFile(
    String conversationId,
    List<int> bytes, {
    required String name,
    required String contentType,
    required String idempotencyKey,
    String? replyTo,
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
          'kind': 'file',
          'media_key': value['object_key'],
          'file': {'name': name, 'size': bytes.length, 'mime': contentType},
          'reply_to': ?replyTo,
        }, idempotencyKey);
    }
  }

  /// Réaction (une par personne) ; `null` la retire. Message relu.
  Future<Result<ChatMessage>> react(String messageId, String? emoji) async =>
      _message(
        await _data.rpc<Object?>(
          'react_message',
          params: {'p_message': messageId, 'p_emoji': emoji},
        ),
      );

  /// Supprimer pour moi, ou pour tout le monde (mon message, dans l'heure).
  /// Refus : `too_late`, interdit pour le message d'un autre.
  Future<Result<void>> delete(String messageId, {required bool forAll}) async =>
      (await _data.rpc<Object?>(
        'delete_message',
        params: {'p_message': messageId, 'p_for_all': forAll},
      )).map((_) {});

  /// Transfère un texte, un produit ou une position vers une autre
  /// conversation. Refus : `forward_not_allowed`.
  Future<Result<ChatMessage>> forward(
    String messageId,
    String conversationId, {
    required String idempotencyKey,
  }) async => _message(
    await _data.rpc<Object?>(
      'forward_message',
      params: {
        'p_message': messageId,
        'p_conversation': conversationId,
        'p_key': idempotencyKey,
      },
    ),
  );

  /// L'app est ouverte : les messages reçus passent « reçus » (✓✓ gris).
  Future<Result<void>> markDelivered(ChatRole role) async =>
      (await _data.rpc<Object?>(
        'mark_delivered',
        params: {'p_role': role.code},
      )).map((_) {});

  /// « Écrit… » : signal envoyé aux autres personnes (3 s au plus souvent).
  Future<Result<void>> typing(String conversationId) async =>
      (await _data.rpc<Object?>(
        'chat_typing',
        params: {'p_conversation': conversationId},
      )).map((_) {});

  Future<Result<ChatMessage>> sendProduct(
    String conversationId,
    String productId, {
    required String idempotencyKey,
  }) => _send(conversationId, {
    'kind': 'product',
    'product_id': productId,
  }, idempotencyKey);

  /// Envoie un vocal (spec 035) dans l'espace privé de la conversation.
  Future<Result<ChatMessage>> sendAudio(
    String conversationId,
    List<int> bytes, {
    required String contentType,
    required int durationMs,
    required String idempotencyKey,
    String? replyTo,
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
          'kind': 'audio',
          'media_key': value['object_key'],
          'duration_ms': durationMs,
          'reply_to': ?replyTo,
        }, idempotencyKey);
    }
  }

  /// Envoie une image compressée dans l'espace privé de la conversation.
  Future<Result<ChatMessage>> sendImage(
    String conversationId,
    List<int> bytes, {
    required String contentType,
    required String idempotencyKey,
    String? replyTo,
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
          'reply_to': ?replyTo,
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

  /// Vidéo enregistrée ou partagée (spec 099), une minute au plus.
  Future<Result<ChatMessage>> sendVideo(
    String conversationId,
    List<int> bytes, {
    required String contentType,
    required String idempotencyKey,
    int? durationMs,
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
          'kind': 'video',
          'media_key': value['object_key'],
          'duration_ms': ?durationMs,
        }, idempotencyKey);
    }
  }

  /// Position ponctuelle (0) ou en direct ([liveMinutes], 60 au plus).
  Future<Result<ChatMessage>> sendLocation(
    String conversationId, {
    required double latitude,
    required double longitude,
    required String idempotencyKey,
    int liveMinutes = 0,
  }) async => _message(
    await _data.rpc<Object?>(
      'chat_send_location',
      params: {
        'p_conversation': conversationId,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_live_minutes': liveMinutes,
        'p_key': idempotencyKey,
      },
    ),
  );

  Future<Result<ChatMessage>> updateLocation(
    String messageId, {
    required double latitude,
    required double longitude,
  }) async => _message(
    await _data.rpc<Object?>(
      'chat_update_location',
      params: {
        'p_message': messageId,
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    ),
  );

  Future<Result<ChatMessage>> stopLocation(String messageId) async => _message(
    await _data.rpc<Object?>(
      'chat_stop_location',
      params: {'p_message': messageId},
    ),
  );

  /// Devis de la boutique : lignes `variant_id`, `quantity`, `price_minor`.
  Future<Result<ChatMessage>> sendQuote(
    String conversationId,
    List<Map<String, Object>> lines, {
    required String idempotencyKey,
    String? note,
  }) async => _message(
    await _data.rpc<Object?>(
      'send_quote',
      params: {
        'p_conversation': conversationId,
        'p_lines': lines,
        'p_note': note,
        'p_key': idempotencyKey,
      },
    ),
  );

  /// Devis accepté : les lignes passent au panier, aux prix du devis.
  Future<Result<void>> acceptQuote(String quoteId) async =>
      (await _data.rpc<Object?>(
        'accept_quote',
        params: {'p_quote': quoteId},
      )).map((_) {});

  Future<Result<ChatMessage>> sendPaymentRequest(
    String conversationId, {
    required int amountMinor,
    required String idempotencyKey,
    String? label,
  }) async => _message(
    await _data.rpc<Object?>(
      'send_payment_request',
      params: {
        'p_conversation': conversationId,
        'p_amount_minor': amountMinor,
        'p_label': label,
        'p_key': idempotencyKey,
      },
    ),
  );

  /// Paiement d'une demande avec le wallet (spec 046).
  Future<Result<void>> payRequest(
    String code, {
    required String idempotencyKey,
  }) async => (await _data.rpc<Object?>(
    'pay_payment_request',
    params: {'p_code': code, 'p_key': idempotencyKey},
  )).map((_) {});

  Future<Result<ChatMessage>> sendCoupon(
    String conversationId, {
    required int percent,
    required int days,
    required String idempotencyKey,
  }) async => _message(
    await _data.rpc<Object?>(
      'send_coupon',
      params: {
        'p_conversation': conversationId,
        'p_percent': percent,
        'p_days': days,
        'p_key': idempotencyKey,
      },
    ),
  );

  Future<Result<void>> claimCoupon(String couponId) async =>
      (await _data.rpc<Object?>(
        'claim_coupon',
        params: {'p_coupon': couponId},
      )).map((_) {});

  /// Texte d'un vocal ; `simulated` : pas de fournisseur (signalé à l'écran).
  Future<Result<({String? text, bool simulated})>> transcribe(
    String messageId,
  ) => _functions.post(
    '/v1/chat-media/transcribe',
    body: {'message_id': messageId},
    decode: (json) {
      final m = json! as Map<String, dynamic>;
      return (
        text: m['transcript'] as String?,
        simulated: m['simulated'] as bool? ?? false,
      );
    },
  );

  Result<ChatMessage> _message(Result<Object?> result) => _decode(
    result,
    (json) => ChatMessage.fromJson((json! as Map).cast<String, dynamic>()),
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
