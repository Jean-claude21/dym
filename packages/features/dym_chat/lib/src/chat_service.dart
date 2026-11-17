import 'package:dym_chat/src/call_service.dart';
import 'package:dym_chat/src/chat_commerce.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/widgets.dart';

/// Messagerie d'une app (cliente ou vendeuse). Remplaçable en test.
/// Nom affiché d'une conversation selon qui la regarde. Fil d'une commande
/// (spec 109) : la boutique et la cliente, avec le livreur.
extension ConversationTitle on Conversation {
  String title(ChatRole role) {
    final client = clientFirstName ?? '';
    final courier = courierName;
    if (!isOrderThread) {
      return role == ChatRole.vendor ? client : storeName;
    }
    return switch (role) {
      ChatRole.client => [storeName, ?courier].join(' · '),
      ChatRole.vendor => [client, ?courier].join(' · '),
      ChatRole.courier => [storeName, client].join(' → '),
    };
  }

  /// Nom de l'auteur d'un message (fil à plusieurs).
  String authorName(String authorRole) => switch (authorRole) {
    'vendor' => storeName,
    'courier' => courierName ?? '',
    _ => clientFirstName ?? '',
  };
}

abstract interface class ChatService {
  /// Nouveaux messages en direct (spec 067).
  Stream<LiveSignal> get live;

  /// Rôle de l'app dans les conversations.
  ChatRole get role;

  /// Devise du pays (prix des produits partagés).
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<List<Conversation>>> conversations();

  /// Cliente : ouvrir (ou retrouver) la conversation avec une boutique.
  /// Refus : `store_unavailable`, `own_store`.
  Future<Result<Conversation>> start(String storeId);

  /// Fil d'une commande : cliente, boutique et livreur (spec 109).
  Future<Result<Conversation>> orderThread(String orderId);

  /// Fil d'une conversation ; l'ouvrir la marque lue.
  Future<Result<ConversationThread>> thread(String id);

  Future<Result<int>> unreadCount();

  Future<Result<ChatMessage>> sendText(
    String conversationId,
    String body, {
    required String idempotencyKey,
  });

  Future<Result<ChatMessage>> sendProduct(
    String conversationId,
    String productId, {
    required String idempotencyKey,
  });

  Future<Result<ChatMessage>> sendImage(
    String conversationId,
    PickedPhoto photo, {
    required String idempotencyKey,
  });

  /// Vocal (spec 035), envoyé dans l'espace privé de la conversation.
  Future<Result<ChatMessage>> sendAudio(
    String conversationId,
    RecordedAudio audio, {
    required String idempotencyKey,
  });

  /// Micro (spec 035) ; absent : pas de vocaux.
  VoiceRecorder? get recorder;

  /// Lecture des vocaux (spec 035) ; absente : bulle sans lecture.
  AudioPlayback? get playback;

  /// Appels (spec 035) ; absents : pas de bouton d'appel.
  CallService? get calls;

  /// Chat de commerce (spec 099) ; absent : texte, photo, produit, vocal.
  ChatCommerce? get commerce;

  /// Liens de lecture signés des images et vocaux, par message.
  Future<Result<Map<String, String>>> mediaUrls(List<String> messageIds);

  Future<Result<PickedPhoto?>> pickPhoto(PhotoSource source);

  /// Photo publique d'un produit partagé.
  ImageProvider productPhoto(String objectKey);

  /// Image d'un message, à partir de son lien signé.
  ImageProvider mediaImage(String url);
}

/// Implémentation Neon.
class NeonChatService implements ChatService {
  new({
    required this._repository,
    required this.role,
    required this._countryConfig,
    required this._photos,
    required this._productPhoto,
    this.recorder,
    this.playback,
    this.calls,
    this.commerce,
    this.liveFeed = LiveFeed.none,
  });

  @override
  final ChatCommerce? commerce;

  /// Source temps réel de l'app (spec 067).
  final LiveFeed liveFeed;

  @override
  Stream<LiveSignal> get live => liveFeed.signals;

  @override
  final VoiceRecorder? recorder;

  @override
  final AudioPlayback? playback;

  @override
  final CallService? calls;

  final MessagingRepository _repository;
  final Future<Result<CountryConfig>> Function() _countryConfig;
  final PhotoPicker _photos;
  final ImageProvider Function(String objectKey) _productPhoto;

  @override
  final ChatRole role;

  @override
  Future<Result<CountryConfig>> countryConfig() => _countryConfig();

  @override
  Future<Result<List<Conversation>>> conversations() =>
      _repository.conversations(role);

  @override
  Future<Result<Conversation>> start(String storeId) =>
      _repository.start(storeId);

  @override
  Future<Result<Conversation>> orderThread(String orderId) =>
      _repository.orderThread(orderId);

  @override
  Future<Result<ConversationThread>> thread(String id) =>
      _repository.thread(id);

  @override
  Future<Result<int>> unreadCount() => _repository.unreadCount(role);

  @override
  Future<Result<ChatMessage>> sendText(
    String conversationId,
    String body, {
    required String idempotencyKey,
  }) => _repository.sendText(
    conversationId,
    body,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Result<ChatMessage>> sendProduct(
    String conversationId,
    String productId, {
    required String idempotencyKey,
  }) => _repository.sendProduct(
    conversationId,
    productId,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Result<ChatMessage>> sendImage(
    String conversationId,
    PickedPhoto photo, {
    required String idempotencyKey,
  }) => _repository.sendImage(
    conversationId,
    photo.bytes,
    contentType: photo.contentType,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Result<ChatMessage>> sendAudio(
    String conversationId,
    RecordedAudio audio, {
    required String idempotencyKey,
  }) => _repository.sendAudio(
    conversationId,
    audio.bytes,
    contentType: audio.contentType,
    durationMs: audio.duration.inMilliseconds,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Result<Map<String, String>>> mediaUrls(List<String> messageIds) =>
      _repository.mediaUrls(messageIds);

  @override
  Future<Result<PickedPhoto?>> pickPhoto(PhotoSource source) =>
      _photos.pick(source);

  @override
  ImageProvider productPhoto(String objectKey) => _productPhoto(objectKey);

  @override
  ImageProvider mediaImage(String url) => dymNetworkImage(url);
}
