import 'dart:async';

import 'package:dym_chat/src/chat_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:stacked/stacked.dart';

/// Conversations (écran 61 ; « Mes messages » côté cliente), relues toutes
/// les [refreshEvery] ; la liste déjà chargée reste affichée hors ligne.
class ConversationsViewModel extends BaseViewModel {
  new({required this.service, this.refreshEvery = const Duration(seconds: 20)});

  final ChatService service;
  final Duration? refreshEvery;

  List<Conversation>? _conversations;
  Failure? _failure;
  Timer? _timer;

  List<Conversation> get conversations => _conversations ?? const [];
  Failure? get failure => _failure;
  bool get ready => _conversations != null;
  bool get offline => _failure is NetworkFailure;
  int get unread => conversations.fold(0, (sum, c) => sum + c.unread);

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
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Conversation ouverte (écrans 60 et 62) : fil relu toutes les
/// [refreshEvery], envois idempotents, images par liens signés.
class ChatViewModel extends BaseViewModel {
  new({
    required this.service,
    required this.conversationId,
    this.refreshEvery = const Duration(seconds: 8),
    String? initialProductId,
  }) : _pendingProductId = initialProductId;

  final ChatService service;
  final String conversationId;
  final Duration? refreshEvery;

  ConversationThread? _thread;
  CountryConfig? _config;
  Failure? _failure;
  Failure? _sendFailure;
  bool _sending = false;
  String? _pendingProductId;
  String? _textKey;
  Timer? _timer;
  final _media = <String, String>{};

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
  Failure? get sendFailure => _sendFailure;
  bool get ready => _thread != null && _config != null;
  bool get offline => _failure is NetworkFailure;
  bool get sending => _sending;
  ChatRole get role => service.role;

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

  Future<void> load() async {
    if (_thread == null) setBusy(true);
    if (_config == null) {
      if (await service.countryConfig() case Ok(:final value)) {
        _config = value;
      }
    }
    final result = await service.thread(conversationId);
    switch (result) {
      case Ok(:final value):
        _thread = value;
        _failure = null;
        await _signMedia();
      case Err(:final failure):
        _failure = failure;
    }
    setBusy(false);
    final every = refreshEvery;
    if (every != null) {
      _timer ??= Timer.periodic(every, (_) => unawaited(load()));
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
    _thread = ConversationThread(
      conversation: t.conversation,
      role: t.role,
      messages: [...t.messages, message],
    );
  }

  /// Envoie [body] ; `true` si envoyé (le champ peut être vidé). Une même
  /// saisie renvoyée après un échec réseau garde sa clé (aucun doublon).
  Future<bool> sendText(String body) async {
    final text = body.trim();
    if (text.isEmpty || _sending) return false;
    final key = _textKey ??= Uuid.v4();
    final ok = await _send(
      () => service.sendText(conversationId, text, idempotencyKey: key),
    );
    if (ok) _textKey = null;
    return ok;
  }

  /// La saisie a changé : un nouvel envoi aura sa propre clé.
  void textChanged() => _textKey = null;

  Future<bool> sendProduct(String productId) => _send(
    () => service.sendProduct(
      conversationId,
      productId,
      idempotencyKey: Uuid.v4(),
    ),
  );

  Future<bool> sendPendingProduct() async {
    final id = _pendingProductId;
    if (id == null) return false;
    final ok = await sendProduct(id);
    if (ok) {
      _pendingProductId = null;
      notifyListeners();
    }
    return ok;
  }

  void dismissPendingProduct() {
    _pendingProductId = null;
    notifyListeners();
  }

  /// Photo prise ou choisie, envoyée compressée. Annulé : rien.
  Future<bool> sendPhoto(PhotoSource source) async {
    if (_sending) return false;
    final picked = await service.pickPhoto(source);
    switch (picked) {
      case Err(:final failure):
        _sendFailure = failure;
        notifyListeners();
        return false;
      case Ok(value: null):
        return false;
      case Ok(value: final PickedPhoto photo):
        final key = Uuid.v4();
        final ok = await _send(
          () => service.sendImage(conversationId, photo, idempotencyKey: key),
        );
        if (ok) await _signMedia();
        notifyListeners();
        return ok;
    }
  }

  /// Micro ouvert ; refus (micro bloqué) : signalé.
  Future<void> startRecording() async {
    final recorder = service.recorder;
    if (recorder == null || recording || _sending) return;
    switch (await recorder.start()) {
      case Ok():
        recording = true;
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
        final key = Uuid.v4();
        final ok = await _send(
          () => service.sendAudio(conversationId, audio, idempotencyKey: key),
        );
        if (ok) await _signMedia();
        notifyListeners();
        return ok;
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

  Future<bool> _send(Future<Result<ChatMessage>> Function() gesture) async {
    if (_sending) return false;
    _sending = true;
    _sendFailure = null;
    notifyListeners();
    final result = await gesture();
    switch (result) {
      case Ok(:final value):
        _append(value);
      case Err(:final failure):
        _sendFailure = failure;
    }
    _sending = false;
    notifyListeners();
    return result.isOk;
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_playing?.cancel());
    if (recording) unawaited(service.recorder?.cancel());
    super.dispose();
  }
}
