import 'dart:async';

import 'package:dym_chat/src/chat_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:stacked/stacked.dart';

/// Conversations (écran 61 ; « Mes messages » côté cliente), relues toutes
/// les [refreshEvery] ; la liste déjà chargée reste affichée hors ligne.
class ConversationsViewModel extends BaseViewModel {
  new({required this.service, this.refreshEvery = const Duration(seconds: 60)});

  final ChatService service;

  /// Relecture en filet ; le temps réel (spec 067) prévient d'abord.
  final Duration? refreshEvery;

  /// Au-delà, un champ de recherche apparaît (spec 070).
  static const searchFrom = 6;

  List<Conversation>? _conversations;
  Failure? _failure;
  Timer? _timer;
  StreamSubscription<LiveSignal>? _live;
  String _query = '';

  List<Conversation> get conversations => _conversations ?? const [];
  Failure? get failure => _failure;
  bool get ready => _conversations != null;
  bool get offline => _failure is NetworkFailure;
  int get unread => conversations.fold(0, (sum, c) => sum + c.unread);
  bool get searchable => conversations.length >= searchFrom;
  String get query => _query;

  /// Conversations filtrées par nom (cliente ou boutique).
  List<Conversation> get shown {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    final vendor = service.role == ChatRole.vendor;
    return [
      for (final c in conversations)
        if ((vendor ? (c.clientFirstName ?? '') : c.storeName)
            .toLowerCase()
            .contains(q))
          c,
    ];
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> load() async {
    if (_conversations == null) setBusy(true);
    final result = await service.conversations();
    switch (result) {
      case Ok(:final value):
        _conversations = value;
        _failure = null;
      case Err(:final failure):
        _failure = failure;
    }
    setBusy(false);
    final every = refreshEvery;
    if (every != null) {
      _timer ??= Timer.periodic(every, (_) => unawaited(load()));
      _live ??= watchLive(
        service.live,
        when: (s) => s.kind == 'message',
        reload: () => unawaited(load()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_live?.cancel());
    super.dispose();
  }
}

/// Réponse rapide proposée au-dessus du champ (spec 070). Le texte vient de
/// la localisation ; la liste dépend du rôle.
enum QuickReply {
  isAvailable,
  price,
  deliveryToday,
  thanks,
  yesAvailable,
  soldOut,
  preparing,
  thanksOrder;

  static const List<QuickReply> client = [
    isAvailable,
    price,
    deliveryToday,
    thanks,
  ];
  static const List<QuickReply> vendor = [
    yesAvailable,
    soldOut,
    preparing,
    thanksOrder,
  ];
}

/// État d'un message parti de cet appareil et pas encore confirmé.
enum OutgoingState { sending, failed }

/// Message envoyé depuis cet appareil, affiché aussitôt (spec 070). Sa clé
/// d'idempotence reste la même à chaque nouvel essai : aucun doublon.
class OutgoingMessage {
  new({
    required this.key,
    required this.kind,
    required this.createdAt,
    this.body,
    this.productId,
    this.photo,
    this.audio,
  });

  final String key;
  final MessageKind kind;
  final DateTime createdAt;
  final String? body;
  final String? productId;
  final PickedPhoto? photo;
  final RecordedAudio? audio;
  OutgoingState state = OutgoingState.sending;
  Failure? failure;
}

/// Ligne du fil : séparateur de jour, message reçu ou envoyé, message en
/// cours d'envoi.
sealed class ChatEntry {
  const new();
}

/// Début d'une journée (date locale, sans heure).
final class ChatDayEntry extends ChatEntry {
  const new(this.day);

  final DateTime day;
}

final class ChatMessageEntry extends ChatEntry {
  const new(this.message, {required this.continued, required this.seen});

  final ChatMessage message;

  /// Suite d'un message de la même personne, à moins de 5 minutes.
  final bool continued;

  /// Mon message, ouvert par l'autre personne.
  final bool seen;
}

final class ChatOutgoingEntry extends ChatEntry {
  const new(this.message, {required this.continued});

  final OutgoingMessage message;
  final bool continued;
}

/// Conversation ouverte (écrans 60 et 62) : fil relu toutes les
/// [refreshEvery] et en direct ; envois affichés aussitôt, renvoyés seuls
/// au retour du réseau, avec la même clé.
class ChatViewModel extends BaseViewModel {
  new({
    required this.service,
    required this.conversationId,
    this.refreshEvery = const Duration(seconds: 30),
    String? initialProductId,
    DateTime Function()? clock,
  }) : _pendingProductId = initialProductId,
       _clock = clock ?? DateTime.now;

  final ChatService service;
  final String conversationId;
  final Duration? refreshEvery;
  final DateTime Function() _clock;

  ConversationThread? _thread;
  CountryConfig? _config;
  Failure? _failure;
  Failure? _sendFailure;
  String? _pendingProductId;
  bool _draftEmpty = true;
  bool _disposed = false;
  Timer? _timer;
  StreamSubscription<LiveSignal>? _live;
  final _media = <String, String>{};
  final _outbox = <OutgoingMessage>[];

  /// Vocal en cours d'enregistrement (spec 035).
  bool recording = false;

  /// Message vocal en lecture.
  String? playingId;
  StreamSubscription<String?>? _playing;

  bool get canRecord => service.recorder != null;

  ConversationThread? get thread => _thread;
  List<ChatMessage> get messages => _thread?.messages ?? const [];
  CountryConfig? get config => _config;
  Failure? get failure => _failure;

  /// Dernier échec d'un geste (photo, micro) ; les messages en échec
  /// portent le leur.
  Failure? get sendFailure => _sendFailure;
  bool get ready => _thread != null && _config != null;
  bool get offline => _failure is NetworkFailure;

  /// Un envoi attend la réponse du serveur.
  bool get sending => _outbox.any((o) => o.state == OutgoingState.sending);
  ChatRole get role => service.role;

  /// Messages partis de cet appareil, pas encore confirmés.
  List<OutgoingMessage> get outbox => List.unmodifiable(_outbox);

  /// Commande en cours entre la cliente et la boutique.
  ChatOrder? get activeOrder => _thread?.activeOrder;

  /// Réponses rapides : champ vide, pas d'enregistrement en cours.
  List<QuickReply> get quickReplies => !_draftEmpty || recording
      ? const []
      : (role == ChatRole.vendor ? QuickReply.vendor : QuickReply.client);

  /// Produit à joindre (ouverte depuis une fiche produit).
  String? get pendingProductId => _pendingProductId;

  /// Lien signé de l'image d'un message (nul : pas encore obtenu).
  String? mediaUrl(String messageId) => _media[messageId];

  Money? price(CatalogItem item) {
    final minor = item.displayPriceMinor;
    final config = _config;
    if (minor == null || config == null) return null;
    return config.currency.code == item.currencyCode
        ? config.money(minor)
        : null;
  }

  /// Total de la commande en cours, dans la devise du pays.
  Money? get activeOrderTotal {
    final order = activeOrder;
    final config = _config;
    if (order == null || config == null) return null;
    return config.currency.code == order.currencyCode
        ? config.money(order.totalMinor)
        : null;
  }

  /// Fil prêt à afficher, du plus ancien au plus récent : un séparateur par
  /// jour (heure locale), messages regroupés par personne.
  List<ChatEntry> get entries {
    final out = <ChatEntry>[];
    DateTime? day;
    String? lastAuthor;
    DateTime? lastAt;
    bool continues(String author, DateTime at) {
      final previous = lastAt;
      return lastAuthor == author &&
          previous != null &&
          at.difference(previous).inMinutes < 5;
    }

    void dayOf(DateTime at) {
      final local = at.toLocal();
      final d = DateTime(local.year, local.month, local.day);
      if (d != day) {
        day = d;
        lastAuthor = null;
        out.add(ChatDayEntry(d));
      }
    }

    final t = _thread;
    for (final m in messages) {
      dayOf(m.createdAt);
      out.add(
        ChatMessageEntry(
          m,
          continued: continues(m.authorRole, m.createdAt),
          seen: m.fromMe(role) && t != null && t.seen(m),
        ),
      );
      lastAuthor = m.authorRole;
      lastAt = m.createdAt;
    }
    for (final o in _outbox) {
      dayOf(o.createdAt);
      out.add(
        ChatOutgoingEntry(o, continued: continues(role.code, o.createdAt)),
      );
      lastAuthor = role.code;
      lastAt = o.createdAt;
    }
    return out;
  }

  Future<void> load() async {
    if (_thread == null) setBusy(true);
    if (_config == null) {
      if (await service.countryConfig() case Ok(:final value)) {
        _config = value;
      }
    }
    final result = await service.thread(conversationId);
    if (_disposed) return;
    switch (result) {
      case Ok(:final value):
        _thread = value;
        _failure = null;
        _outbox.removeWhere((o) => value.messages.any((m) => m.id == o.key));
        await _signMedia();
      case Err(:final failure):
        _failure = failure;
    }
    setBusy(false);
    // Réseau revenu : les messages restés en échec repartent seuls.
    if (result.isOk) unawaited(_resendFailed());
    final every = refreshEvery;
    if (every != null) {
      _timer ??= Timer.periodic(every, (_) => unawaited(load()));
      // Message reçu dans cette conversation : fil relu aussitôt (spec 067).
      _live ??= watchLive(
        service.live,
        when: (s) => s.kind == 'message' && s.entityId == conversationId,
        reload: () => unawaited(load()),
        debounce: const Duration(milliseconds: 150),
      );
    }
  }

  Future<void> _resendFailed() async {
    for (final o in [..._outbox]) {
      if (o.state == OutgoingState.failed && (o.failure?.isTransient ?? true)) {
        await _deliver(o);
      }
    }
  }

  Future<void> _signMedia() async {
    final missing = [
      for (final m in messages)
        if (m.hasMedia && !_media.containsKey(m.id)) m.id,
    ];
    if (missing.isEmpty) return;
    if (await service.mediaUrls(missing.take(50).toList()) case Ok(
      :final value,
    )) {
      _media.addAll(value);
    }
  }

  void _append(ChatMessage message) {
    final t = _thread;
    if (t == null || t.messages.any((m) => m.id == message.id)) return;
    _thread = t.copyWith(messages: [...t.messages, message]);
  }

  /// La saisie a changé (les réponses rapides se cachent pendant l'écriture).
  void textChanged([String value = '']) {
    final empty = value.trim().isEmpty;
    if (empty == _draftEmpty) return;
    _draftEmpty = empty;
    notifyListeners();
  }

  /// Envoie [body] : affiché aussitôt, puis confirmé. `true` si le serveur
  /// l'a reçu ; en échec, il reste dans le fil avec « Réessayer ».
  Future<bool> sendText(String body) async {
    final text = body.trim();
    if (text.isEmpty) return false;
    _draftEmpty = true;
    return await _queue(
      OutgoingMessage(
        key: Uuid.v4(),
        kind: MessageKind.text,
        body: text,
        createdAt: _clock().toUtc(),
      ),
    );
  }

  Future<bool> sendProduct(String productId) => _queue(
    OutgoingMessage(
      key: Uuid.v4(),
      kind: MessageKind.product,
      productId: productId,
      createdAt: _clock().toUtc(),
    ),
  );

  /// Plusieurs produits d'un coup (« panier proposé » de la vendeuse).
  Future<bool> sendProducts(List<String> productIds) async {
    var ok = true;
    for (final id in productIds) {
      ok = await sendProduct(id) && ok;
    }
    return ok;
  }

  Future<bool> sendPendingProduct() async {
    final id = _pendingProductId;
    if (id == null) return false;
    _pendingProductId = null;
    notifyListeners();
    return await sendProduct(id);
  }

  void dismissPendingProduct() {
    _pendingProductId = null;
    notifyListeners();
  }

  /// Photo prise ou choisie, envoyée compressée. Annulé : rien.
  Future<bool> sendPhoto(PhotoSource source) async {
    final picked = await service.pickPhoto(source);
    switch (picked) {
      case Err(:final failure):
        _sendFailure = failure;
        notifyListeners();
        return false;
      case Ok(value: null):
        return false;
      case Ok(value: final PickedPhoto photo):
        _sendFailure = null;
        return await _queue(
          OutgoingMessage(
            key: Uuid.v4(),
            kind: MessageKind.image,
            photo: photo,
            createdAt: _clock().toUtc(),
          ),
        );
    }
  }

  /// Nouvel essai d'un message en échec (même clé).
  Future<bool> retry(OutgoingMessage message) async =>
      _outbox.contains(message) && await _deliver(message);

  /// Abandon d'un message en échec.
  void discard(OutgoingMessage message) {
    if (_outbox.remove(message)) notifyListeners();
  }

  /// Micro ouvert ; refus (micro bloqué) : signalé.
  Future<void> startRecording() async {
    final recorder = service.recorder;
    if (recorder == null || recording) return;
    switch (await recorder.start()) {
      case Ok():
        recording = true;
        _sendFailure = null;
      case Err(:final failure):
        _sendFailure = failure;
    }
    notifyListeners();
  }

  Future<void> cancelRecording() async {
    if (!recording) return;
    recording = false;
    await service.recorder?.cancel();
    notifyListeners();
  }

  /// Fin de l'enregistrement et envoi ; trop court : rien.
  Future<bool> stopAndSendRecording() async {
    final recorder = service.recorder;
    if (recorder == null || !recording) return false;
    recording = false;
    notifyListeners();
    switch (await recorder.stop()) {
      case Err(:final failure):
        _sendFailure = failure;
        notifyListeners();
        return false;
      case Ok(value: final audio?)
          when audio.duration >= const Duration(milliseconds: 500):
        return await _queue(
          OutgoingMessage(
            key: Uuid.v4(),
            kind: MessageKind.audio,
            audio: audio,
            createdAt: _clock().toUtc(),
          ),
        );
      case Ok():
        return false;
    }
  }

  /// Lecture d'un vocal (lien signé) ; un second geste l'arrête.
  Future<void> togglePlay(ChatMessage message) async {
    final playback = service.playback;
    final url = _media[message.id];
    if (playback == null || url == null) return;
    _playing ??= playback.playing.listen((u) {
      final id = u == null
          ? null
          : _media.entries.where((e) => e.value == u).firstOrNull?.key;
      if (id != playingId) {
        playingId = id;
        notifyListeners();
      }
    });
    if (playingId == message.id) {
      await playback.stop();
    } else {
      await playback.play(url);
    }
  }

  Future<bool> _queue(OutgoingMessage message) {
    _outbox.add(message);
    return _deliver(message);
  }

  Future<Result<ChatMessage>> _post(OutgoingMessage o) => switch (o.kind) {
    MessageKind.product => service.sendProduct(
      conversationId,
      o.productId!,
      idempotencyKey: o.key,
    ),
    MessageKind.image => service.sendImage(
      conversationId,
      o.photo!,
      idempotencyKey: o.key,
    ),
    MessageKind.audio => service.sendAudio(
      conversationId,
      o.audio!,
      idempotencyKey: o.key,
    ),
    _ => service.sendText(conversationId, o.body!, idempotencyKey: o.key),
  };

  Future<bool> _deliver(OutgoingMessage o) async {
    o
      ..state = OutgoingState.sending
      ..failure = null;
    notifyListeners();
    final result = await _post(o);
    if (_disposed) return result.isOk;
    switch (result) {
      case Ok(:final value):
        _outbox.remove(o);
        _append(value);
        if (value.hasMedia) await _signMedia();
      case Err(:final failure):
        o
          ..state = OutgoingState.failed
          ..failure = failure;
    }
    if (!_disposed) notifyListeners();
    return result.isOk;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_live?.cancel());
    unawaited(_playing?.cancel());
    if (recording) unawaited(service.recorder?.cancel());
    super.dispose();
  }
}
