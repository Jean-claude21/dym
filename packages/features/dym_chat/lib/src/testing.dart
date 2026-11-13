import 'dart:async';

import 'dart:typed_data';

import 'package:dym_chat/src/call_service.dart';
import 'package:dym_chat/src/chat_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/widgets.dart';

/// Image unie d'un pixel (tests, galerie) : aucun accès réseau.
final MemoryImage chatPlaceholderImage = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
    0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

/// Messagerie en mémoire (tests, galerie). Jamais en production.
class MemoryChatService implements ChatService {
  new({
    required this.role,
    required this.config,
    List<ConversationThread> threads = const [],
    this.now,
    this.photoImage,
    this.productImage,
  }) {
    for (final t in threads) {
      _threads[t.conversation.id] = t;
    }
  }

  /// Conversations de démonstration (lieux génériques) : Awa et une boutique
  /// échangent un texte, une réponse, une fiche produit et une photo ; trois
  /// autres conversations pour la liste de la vendeuse.
  factory demo({
    required ChatRole role,
    required CountryConfig config,
    ImageProvider? photoImage,
    ImageProvider? productImage,
  }) {
    final day = DateTime.utc(2026, 10, 5, 10);
    final gombo = CatalogItem(
      id: 'p-gombo',
      name: 'Gombo frais',
      currencyCode: config.currency.code,
      priceMinor: 300 * _unitOf(config.currency),
      unitLabel: const LocalizedText({'fr': 'le tas', 'en': 'the heap'}),
      photoKey: 'demo/gombo.jpg',
      defaultVariantId: 'v-gombo',
      store: const CatalogItemStore(
        id: 's1',
        name: "Étal d'Akossiwa",
        zoneName: 'Quartier 1',
        origin: 'marche',
      ),
    );
    ChatMessage msg(
      String id,
      String author,
      int minutes,
      MessageKind kind, {
      String? body,
      CatalogItem? product,
    }) => ChatMessage(
      id: id,
      conversationId: 'c1',
      authorRole: author,
      kind: kind,
      body: body,
      hasMedia: kind == MessageKind.image,
      product: product,
      productId: product?.id,
      createdAt: day.add(Duration(minutes: minutes)),
    );
    ConversationThread other(
      String id,
      String name,
      String body,
      int hoursAgo,
      int unread,
    ) => ConversationThread(
      conversation: Conversation(
        id: id,
        storeId: 's1',
        storeName: "Étal d'Akossiwa",
        clientFirstName: name,
        unread: unread,
      ),
      role: role.code,
      messages: [
        ChatMessage(
          id: '$id-m0',
          conversationId: id,
          authorRole: 'client',
          kind: MessageKind.text,
          body: body,
          createdAt: day.subtract(Duration(hours: hoursAgo)),
        ),
      ],
    );
    return MemoryChatService(
      role: role,
      config: config,
      photoImage: photoImage,
      productImage: productImage,
      threads: [
        ConversationThread(
          conversation: const Conversation(
            id: 'c1',
            storeId: 's1',
            storeName: "Étal d'Akossiwa",
            storeOrigin: 'marche',
            clientFirstName: 'Awa',
            unread: 1,
          ),
          role: role.code,
          // Lu jusqu'à la fiche produit ; une commande en préparation.
          peerReadAt: day.add(const Duration(minutes: 5)),
          activeOrder: ChatOrder(
            id: 'o1',
            status: OrderStatus.preparing,
            totalMinor: 3500 * _unitOf(config.currency),
            currencyCode: config.currency.code,
          ),
          messages: [
            msg(
              'm0',
              'client',
              2,
              MessageKind.text,
              body: 'Bonjour, vous avez encore du gombo frais ?',
            ),
            msg(
              'm1',
              'vendor',
              4,
              MessageKind.text,
              body: "Oui ! Je viens d'en recevoir ce matin.",
            ),
            msg('m2', 'vendor', 5, MessageKind.product, product: gombo),
            msg('m3', 'client', 6, MessageKind.image),
          ],
        ),
        if (role == ChatRole.vendor) ...[
          other('c2', 'Kossi', 'Merci, à demain !', 1, 0),
          other('c3', 'Mariam', 'Il me faut 3 tas pour samedi.', 2, 1),
          other('c4', 'Yao', "D'accord pour 2 tas", 26, 0),
        ],
      ],
    );
  }

  /// Signaux en direct simulés (tests).
  final liveSignals = StreamController<LiveSignal>.broadcast();

  @override
  Stream<LiveSignal> get live => liveSignals.stream;

  static int _unitOf(Currency c) => switch (c.minorUnits) {
    0 => 1,
    1 => 10,
    2 => 100,
    _ => 1000,
  };

  @override
  final ChatRole role;
  final CountryConfig config;
  final DateTime? now;

  /// Image servie pour les photos et les produits (galerie).
  final ImageProvider? photoImage;
  final ImageProvider? productImage;

  final _threads = <String, ConversationThread>{};
  final _read = <String>{};

  /// Prochain appel en échec (une fois).
  Failure? failNext;
  final sent = <String>[];

  /// Photo renvoyée par le sélecteur (nulle : annulé).
  PickedPhoto? photo;

  Result<T>? _fail<T>() {
    final failure = failNext;
    if (failure == null) return null;
    failNext = null;
    return Err(failure);
  }

  DateTime get _now => now ?? DateTime.utc(2026, 10, 5, 10, 10);

  int _unread(ConversationThread t) => _read.contains(t.conversation.id)
      ? 0
      : t.messages
            .where((m) => !m.fromMe(role))
            .length
            .clamp(0, t.conversation.unread);

  Conversation _summary(ConversationThread t) => Conversation(
    id: t.conversation.id,
    storeId: t.conversation.storeId,
    storeName: t.conversation.storeName,
    storeOrigin: t.conversation.storeOrigin,
    storeActive: t.conversation.storeActive,
    clientFirstName: t.conversation.clientFirstName,
    lastMessageAt: t.messages.isEmpty ? null : t.messages.last.createdAt,
    lastMessage: t.messages.isEmpty ? null : t.messages.last,
    unread: _unread(t),
  );

  @override
  Future<Result<CountryConfig>> countryConfig() async =>
      _fail<CountryConfig>() ?? Ok(config);

  @override
  Future<Result<List<Conversation>>> conversations() async =>
      _fail<List<Conversation>>() ??
      Ok(
        [for (final t in _threads.values) _summary(t)]..sort(
          (a, b) =>
              (b.lastMessageAt ?? _now).compareTo(a.lastMessageAt ?? _now),
        ),
      );

  @override
  Future<Result<Conversation>> start(String storeId) async {
    final failed = _fail<Conversation>();
    if (failed != null) return failed;
    final existing = _threads.values
        .where((t) => t.conversation.storeId == storeId)
        .firstOrNull;
    if (existing != null) return Ok(existing.conversation);
    final created = Conversation(
      id: 'c-$storeId',
      storeId: storeId,
      storeName: storeId,
    );
    _threads[created.id] = ConversationThread(
      conversation: created,
      role: role.code,
    );
    return Ok(created);
  }

  @override
  Future<Result<ConversationThread>> thread(String id) async {
    final failed = _fail<ConversationThread>();
    if (failed != null) return failed;
    final t = _threads[id];
    if (t == null) return const Err(NotFoundFailure('conversation'));
    _read.add(id);
    return Ok(t);
  }

  @override
  Future<Result<int>> unreadCount() async =>
      _fail<int>() ?? Ok(_threads.values.fold(0, (sum, t) => sum + _unread(t)));

  Future<Result<ChatMessage>> _add(
    String conversationId,
    MessageKind kind, {
    required String key,
    String? body,
    String? productId,
    bool media = false,
  }) async {
    final failed = _fail<ChatMessage>();
    if (failed != null) return failed;
    final t = _threads[conversationId]!;
    final existing = t.messages.where((m) => m.id == key).firstOrNull;
    if (existing != null) return Ok(existing);
    final product = productId == null
        ? null
        : t.messages
              .map((m) => m.product)
              .whereType<CatalogItem>()
              .where((p) => p.id == productId)
              .firstOrNull;
    final message = ChatMessage(
      id: key,
      conversationId: conversationId,
      authorRole: role.code,
      kind: kind,
      body: body,
      hasMedia: media,
      product: product,
      productId: productId,
      createdAt: _now,
    );
    _threads[conversationId] = t.copyWith(messages: [...t.messages, message]);
    sent.add('${kind.name}:${body ?? productId ?? 'photo'}');
    return Ok(message);
  }

  @override
  Future<Result<ChatMessage>> sendText(
    String conversationId,
    String body, {
    required String idempotencyKey,
  }) => _add(conversationId, MessageKind.text, key: idempotencyKey, body: body);

  @override
  Future<Result<ChatMessage>> sendProduct(
    String conversationId,
    String productId, {
    required String idempotencyKey,
  }) => _add(
    conversationId,
    MessageKind.product,
    key: idempotencyKey,
    productId: productId,
  );

  @override
  Future<Result<ChatMessage>> sendImage(
    String conversationId,
    PickedPhoto photo, {
    required String idempotencyKey,
  }) =>
      _add(conversationId, MessageKind.image, key: idempotencyKey, media: true);

  @override
  Future<Result<ChatMessage>> sendAudio(
    String conversationId,
    RecordedAudio audio, {
    required String idempotencyKey,
  }) =>
      _add(conversationId, MessageKind.audio, key: idempotencyKey, media: true);

  @override
  VoiceRecorder? recorder;

  @override
  AudioPlayback? playback;

  @override
  CallService? calls;

  @override
  Future<Result<Map<String, String>>> mediaUrls(
    List<String> messageIds,
  ) async =>
      _fail<Map<String, String>>() ??
      Ok({for (final id in messageIds) id: 'memory://$id'});

  @override
  Future<Result<PickedPhoto?>> pickPhoto(PhotoSource source) async => Ok(photo);

  @override
  ImageProvider productPhoto(String objectKey) =>
      productImage ?? chatPlaceholderImage;

  /// Image d'un message (galerie : image fournie, sinon pixel uni).
  @override
  ImageProvider mediaImage(String url) => photoImage ?? chatPlaceholderImage;
}
