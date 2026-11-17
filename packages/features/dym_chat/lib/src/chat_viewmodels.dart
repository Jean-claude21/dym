import 'dart:async';

import 'package:dym_chat/src/chat_commerce.dart';
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

  /// Filtre de la liste (spec 111).
  ConversationFilter filter = ConversationFilter.all;

  void setFilter(ConversationFilter value) {
    filter = value;
    notifyListeners();
  }

  /// Fils de commande proposés en filtre (au moins un dans la liste).
  bool get hasOrderThreads => conversations.any((c) => c.isOrderThread);

  /// Groupes (spec 112) : filtre dès qu'il y en a un.
  bool get hasGroups => conversations.any((c) => c.isGroup);

  /// Seule une cliente crée un groupe famille.
  bool get canCreateGroups => service.role == ChatRole.client;

  /// Crée un groupe famille ; son identifiant (nul : échec).
  Future<String?> createFamilyGroup(String title) async {
    final result = await service.createFamilyGroup(title);
    switch (result) {
      case Ok(:final value):
        await load();
        return value.id;
      case Err(:final failure):
        _failure = failure;
        notifyListeners();
        return null;
    }
  }

  bool _delivered = false;
  Failure? get failure => _failure;
  bool get ready => _conversations != null;
  bool get offline => _failure is NetworkFailure;
  int get unread => conversations.fold(0, (sum, c) => sum + c.unread);
  bool get searchable => conversations.length >= searchFrom;
  String get query => _query;

  /// Conversations filtrées (nom, non lues, commandes) ; les fils d'une
  /// commande en cours restent en tête.
  List<Conversation> get shown {
    final q = _query.trim().toLowerCase();
    final list = [
      for (final c in conversations)
        if ((q.isEmpty || c.title(service.role).toLowerCase().contains(q)) &&
            switch (filter) {
              ConversationFilter.all => true,
              ConversationFilter.unread => c.unread > 0,
              ConversationFilter.orders => c.isOrderThread,
              ConversationFilter.groups => c.isGroup,
            })
          c,
    ];
    final pinned = [
      for (final c in list)
        if (c.isOrderThread && !c.closed) c,
    ];
    return [...pinned, ...list.where((c) => !pinned.contains(c))];
  }

  /// Fil d'une commande en cours : épinglé en tête.
  bool pinned(Conversation c) => c.isOrderThread && !c.closed;

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
        // App ouverte : les messages reçus passent « reçus » chez l'autre.
        if (!_delivered) {
          _delivered = true;
          unawaited(service.markDelivered());
        }
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

/// Filtres de la liste des conversations (spec 111).
enum ConversationFilter { all, unread, orders, groups }

/// Réactions proposées d'un appui long (spec 111).
const quickReactions = ['👍', '💚', '😂', '😮', '😢', '🙏'];

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
  thanksOrder,
  onMyWay,
  atTheDoor,
  cantFind;

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

  /// Livreur (spec 109).
  static const List<QuickReply> courier = [onMyWay, atTheDoor, cantFind];
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
    this.document,
    this.replyTo,
  });

  final String key;

  /// Document (spec 111).
  final PickedDocument? document;

  /// Message cité.
  final ChatMessage? replyTo;
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

/// « Nouveaux messages » : premier message reçu depuis ma dernière lecture.
final class ChatNewEntry extends ChatEntry {
  const new(this.count);

  final int count;
}

final class ChatMessageEntry extends ChatEntry {
  const new(
    this.message, {
    required this.continued,
    required this.seen,
    this.delivered = false,
  });

  final ChatMessage message;

  /// Suite d'un message de la même personne, à moins de 5 minutes.
  final bool continued;

  /// Mon message, ouvert par l'autre personne (✓✓ en couleur).
  final bool seen;

  /// Mon message, reçu par l'app de l'autre personne (✓✓ gris).
  final bool delivered;
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

  /// Appels vidéo ouverts dans le pays (flag `calls_video`, spec 089).
  bool get videoCalls => _config?.isEnabled('calls_video') ?? false;
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
  List<QuickReply> get quickReplies => !_draftEmpty || recording || isGroup
      ? const []
      : switch (role) {
          ChatRole.vendor => QuickReply.vendor,
          ChatRole.courier => QuickReply.courier,
          ChatRole.client => QuickReply.client,
        };

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
    final newFrom = _newFromId;
    for (final m in messages) {
      dayOf(m.createdAt);
      if (m.id == newFrom) {
        out.add(ChatNewEntry(_newCount));
        lastAuthor = null;
      }
      final mine = m.fromMe(role);
      out.add(
        ChatMessageEntry(
          m,
          continued: continues(m.authorRole, m.createdAt),
          seen: mine && t != null && t.seen(m),
          delivered: mine && t != null && t.delivered(m),
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
        // Fil ouvert (aussi depuis une notification) : « reçu » signalé.
        if (!_newMarked) unawaited(service.markDelivered());
        _markNew(value);
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
      // « Écrit… » (spec 111) : affiché 5 s après le dernier signal.
      _typingSub ??= service.live
          .where((s) => s.kind == 'typing' && s.entityId == conversationId)
          .listen((s) {
            typingRole = s.payload['role'] as String? ?? '';
            _typingFrom = s.payload['name'] as String?;
            _typingTimer?.cancel();
            _typingTimer = Timer(const Duration(seconds: 5), () {
              typingRole = null;
              if (!_disposed) notifyListeners();
            });
            if (!_disposed) notifyListeners();
          });
    }
  }

  // ---------------------------------------------------------------- spec 111

  String? _newFromId;
  int _newCount = 0;
  bool _newMarked = false;

  /// Au premier chargement : premier message reçu après ma dernière lecture.
  void _markNew(ConversationThread t) {
    if (_newMarked) return;
    _newMarked = true;
    final since = t.myReadAt;
    final fresh = [
      for (final m in t.messages)
        if (!m.fromMe(role) && (since == null || m.createdAt.isAfter(since))) m,
    ];
    // Première ouverture d'une conversation : pas de séparateur.
    if (fresh.isEmpty || since == null) return;
    _newFromId = fresh.first.id;
    _newCount = fresh.length;
  }

  /// Rôle de la personne en train d'écrire (nul : personne).
  String? typingRole;

  /// Prénom envoyé avec « écrit… » (groupe, spec 112).
  String? _typingFrom;
  StreamSubscription<LiveSignal>? _typingSub;
  Timer? _typingTimer;
  DateTime? _typingSentAt;

  /// Nom affiché dans « … écrit ».
  String get typingName {
    final r = typingRole;
    final conv = _thread?.conversation;
    if (r == null || conv == null) return '';
    if (conv.isGroup && r == 'client') return _typingFrom ?? '';
    return conv.authorName(r);
  }

  // ---------------------------------------------------------------- spec 112

  /// Conversation de groupe (famille, achat groupé).
  bool get isGroup => _thread?.conversation.isGroup ?? false;

  /// Détail du groupe (page « Infos du groupe »).
  GroupInfo? group;

  Future<void> loadGroup() async {
    if (await service.groupInfo(conversationId) case Ok(:final value)) {
      group = value;
      if (!_disposed) notifyListeners();
    }
  }

  /// Ajoute un proche par son code ; nul si c'est fait, sinon la raison
  /// (`recipient_unknown`, `group_full`, autre).
  Future<String?> addMember(String code) async {
    switch (await service.addGroupMember(conversationId, code)) {
      case Ok(:final value):
        group = value;
        notifyListeners();
        return null;
      case Err(failure: NotFoundFailure()):
        return 'recipient_unknown';
      case Err(:final failure) when failure.message.contains('group_full'):
        return 'group_full';
      case Err():
        return 'error';
    }
  }

  Future<void> removeMember(String userId) async {
    if (await service.removeGroupMember(conversationId, userId) case Ok()) {
      await loadGroup();
    }
  }

  /// Quitter le groupe (pas l'administratrice).
  Future<bool> leaveGroup() async {
    final me = group?.members.where((m) => m.me).firstOrNull;
    if (me == null) return false;
    return (await service.removeGroupMember(conversationId, me.userId)).isOk;
  }

  Future<void> renameGroup(String title) async {
    if (await service.renameGroup(conversationId, title) case Ok(
      :final value,
    )) {
      group = value;
      notifyListeners();
      await load();
    }
  }

  /// Message auquel je réponds (glisser ou « Répondre »).
  ChatMessage? replyingTo;

  void startReply(ChatMessage m) {
    if (m.deleted) return;
    replyingTo = m;
    notifyListeners();
  }

  void cancelReply() {
    replyingTo = null;
    notifyListeners();
  }

  /// Retrouve un message du fil (citation touchée).
  ChatMessage? messageById(String id) =>
      messages.where((m) => m.id == id).firstOrNull;

  void _replaceMessage(ChatMessage updated) {
    final t = _thread;
    if (t == null) return;
    _thread = t.copyWith(
      messages: [
        for (final m in t.messages)
          if (m.id == updated.id) updated else m,
      ],
    );
  }

  /// Réaction : la même retire, une autre remplace.
  Future<void> react(ChatMessage m, String emoji) async {
    final next = m.reactionOf(role) == emoji ? null : emoji;
    final result = await service.react(m.id, next);
    if (_disposed) return;
    switch (result) {
      case Ok(:final value):
        _replaceMessage(value);
      case Err(:final failure):
        _sendFailure = failure;
    }
    notifyListeners();
  }

  /// Mon message, envoyé il y a moins d'une heure.
  bool canDeleteForAll(ChatMessage m) =>
      m.fromMe(role) &&
      !m.deleted &&
      _clock().toUtc().difference(m.createdAt.toUtc()) <
          const Duration(hours: 1);

  Future<bool> deleteMessage(ChatMessage m, {required bool forAll}) async {
    final result = await service.deleteMessage(m.id, forAll: forAll);
    if (_disposed) return result.isOk;
    if (result case Err(:final failure)) {
      _sendFailure = failure;
      notifyListeners();
      return false;
    }
    if (replyingTo?.id == m.id) replyingTo = null;
    await load();
    return true;
  }

  /// Conversations où transférer (toutes sauf celle-ci).
  Future<List<Conversation>> forwardTargets() async {
    final result = await service.conversations();
    return [
      for (final c in result.valueOrNull ?? const <Conversation>[])
        if (c.id != conversationId && !c.closed) c,
    ];
  }

  Future<bool> forward(ChatMessage m, String target) async {
    final result = await service.forward(
      m.id,
      target,
      idempotencyKey: Uuid.v4(),
    );
    if (_disposed) return result.isOk;
    if (result case Err(:final failure)) _sendFailure = failure;
    notifyListeners();
    return result.isOk;
  }

  /// Envoi de documents possible.
  bool get canSendDocuments => service.documents != null;

  /// Document choisi puis envoyé (10 Mo au plus).
  Future<bool> sendDocument() async {
    final picker = service.documents;
    if (picker == null) return false;
    switch (await picker.pick()) {
      case Err(:final failure):
        _sendFailure = failure;
        notifyListeners();
        return false;
      case Ok(value: null):
        return false;
      case Ok(value: final PickedDocument document):
        _sendFailure = null;
        return await _queue(
          OutgoingMessage(
            key: Uuid.v4(),
            kind: MessageKind.file,
            document: document,
            createdAt: _clock().toUtc(),
            replyTo: _takeReply(),
          ),
        );
    }
  }

  /// Ouvre un document reçu (lien signé du moment).
  Future<void> openDocument(ChatMessage m) async {
    final url = _media[m.id];
    final opener = service.opener;
    if (url == null || opener == null) return;
    await opener.open(Uri.parse(url));
  }

  ChatMessage? _takeReply() {
    final r = replyingTo;
    replyingTo = null;
    return r;
  }

  /// Recherche dans la conversation (textes et noms de documents).
  String searchQuery = '';
  bool searching = false;

  void openSearch() {
    searching = true;
    notifyListeners();
  }

  void closeSearch() {
    searching = false;
    searchQuery = '';
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value;
    notifyListeners();
  }

  List<ChatMessage> get searchResults {
    final q = searchQuery.trim().toLowerCase();
    if (q.length < 2) return const [];
    return [
      for (final m in messages.reversed)
        if (!m.deleted &&
            ((m.body ?? '').toLowerCase().contains(q) ||
                (m.fileName ?? '').toLowerCase().contains(q) ||
                (m.product?.name ?? '').toLowerCase().contains(q)))
          m,
    ];
  }

  /// Photos et vidéos du fil (galerie), du plus récent au plus ancien.
  List<ChatMessage> get mediaMessages => [
    for (final m in messages.reversed)
      if (!m.deleted &&
          (m.kind == MessageKind.image || m.kind == MessageKind.video))
        m,
  ];

  List<ChatMessage> get documentMessages => [
    for (final m in messages.reversed)
      if (!m.deleted && m.kind == MessageKind.file) m,
  ];

  // ------------------------------------------------- vocal : temps et niveau

  /// Durée de l'enregistrement en cours (affichée à la seconde).
  Duration recordElapsed = Duration.zero;

  /// Niveaux récents du micro (onde), entre 0 et 1.
  final recordLevels = <double>[];

  /// Enregistrement verrouillé (plus besoin de garder le doigt appuyé).
  bool recordLocked = false;
  Timer? _recordTimer;
  StreamSubscription<double>? _levelSub;
  DateTime? _recordStart;

  /// Vocal limité à une minute (comme la base).
  static const maxRecord = Duration(seconds: 60);

  void _startRecordClock() {
    _recordStart = _clock();
    recordElapsed = Duration.zero;
    recordLevels.clear();
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final start = _recordStart;
      if (start == null) return;
      recordElapsed = _clock().difference(start);
      if (recordElapsed >= maxRecord) {
        unawaited(stopAndSendRecording());
        return;
      }
      if (!_disposed) notifyListeners();
    });
    _levelSub = service.recorder?.level.listen((l) {
      recordLevels.add(l.clamp(0, 1));
      if (recordLevels.length > 40) recordLevels.removeAt(0);
    });
  }

  void _stopRecordClock() {
    _recordTimer?.cancel();
    _recordTimer = null;
    unawaited(_levelSub?.cancel());
    _levelSub = null;
    _recordStart = null;
    recordLocked = false;
  }

  void lockRecording() {
    if (!recording || recordLocked) return;
    recordLocked = true;
    notifyListeners();
  }

  // ---------------------------------------------- vocal : lecture, vitesse

  /// Position du vocal en cours de lecture.
  Duration playPosition = Duration.zero;
  bool playPaused = false;

  /// Vitesse de lecture des vocaux (1, 1.5, 2).
  double playSpeed = 1;
  StreamSubscription<Duration>? _positionSub;

  Future<void> cycleSpeed() async {
    playSpeed = switch (playSpeed) {
      1 => 1.5,
      1.5 => 2,
      _ => 1,
    };
    await service.playback?.setSpeed(playSpeed);
    notifyListeners();
  }

  /// Progression (0 à 1) du vocal [m] en cours de lecture.
  double progressOf(ChatMessage m) {
    if (playingId != m.id) return 0;
    final total = m.durationMs ?? 0;
    if (total <= 0) return 0;
    return (playPosition.inMilliseconds / total).clamp(0, 1);
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
    if (!empty) _signalTyping();
    if (empty == _draftEmpty) return;
    _draftEmpty = empty;
    notifyListeners();
  }

  /// « Écrit… » : un signal toutes les 3 s au plus pendant la saisie.
  void _signalTyping() {
    final now = _clock();
    final last = _typingSentAt;
    if (last != null && now.difference(last) < const Duration(seconds: 3)) {
      return;
    }
    _typingSentAt = now;
    unawaited(service.typing(conversationId));
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
        replyTo: _takeReply(),
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
  // ---------------------------------------------------------------- spec 099

  /// Chat de commerce ; nul : menu réduit (texte, photo, produit, vocal).
  ChatCommerce? get commerce => service.commerce;

  /// Textes des vocaux transcrits, par message.
  final transcripts = <String, String>{};

  /// Vocaux dont la transcription est simulée (aucun fournisseur).
  final simulatedTranscripts = <String>{};

  /// Geste de commerce en cours (envoi, acceptation, paiement).
  bool commerceBusy = false;

  Timer? _liveTimer;
  String? _liveMessageId;

  /// Position en direct partagée depuis cet appareil.
  String? get liveMessageId => _liveMessageId;

  Future<bool> _commerceSend(
    Future<Result<ChatMessage>> Function(ChatCommerce c) work,
  ) async {
    final c = commerce;
    if (c == null || commerceBusy) return false;
    commerceBusy = true;
    _sendFailure = null;
    notifyListeners();
    final result = await work(c);
    commerceBusy = false;
    if (_disposed) return result.isOk;
    switch (result) {
      case Ok(:final value):
        _append(value);
        if (value.hasMedia) await _signMedia();
      case Err(:final failure):
        _sendFailure = failure;
    }
    notifyListeners();
    return result.isOk;
  }

  Future<bool> _commerceAct(
    Future<Result<void>> Function(ChatCommerce c) work,
  ) async {
    final c = commerce;
    if (c == null || commerceBusy) return false;
    commerceBusy = true;
    _sendFailure = null;
    notifyListeners();
    final result = await work(c);
    commerceBusy = false;
    if (_disposed) return result.isOk;
    if (result case Err(:final failure)) _sendFailure = failure;
    await load();
    return result.isOk;
  }

  /// Vidéo enregistrée ou choisie (une minute au plus).
  Future<bool> sendVideo(PhotoSource source) async {
    final c = commerce;
    if (c == null) return false;
    final picked = await c.pickVideo(source);
    switch (picked) {
      case Err(:final failure):
        _sendFailure = failure;
        notifyListeners();
        return false;
      case Ok(value: null):
        return false;
      case Ok(value: final video?):
        return await _commerceSend(
          (c) => c.sendVideo(conversationId, video, idempotencyKey: Uuid.v4()),
        );
    }
  }

  /// Position de l'appareil ; [liveMinutes] > 0 : relue toutes les 30 s
  /// tant que le fil est ouvert et le partage actif.
  Future<bool> shareLocation({int liveMinutes = 0}) async {
    final ok = await _commerceSend(
      (c) => c.sendLocation(
        conversationId,
        idempotencyKey: Uuid.v4(),
        liveMinutes: liveMinutes,
      ),
    );
    if (ok && liveMinutes > 0) {
      final live = messages.lastWhere((m) => m.isLive && m.fromMe(role));
      _liveMessageId = live.id;
      _liveTimer?.cancel();
      _liveTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        final id = _liveMessageId;
        final c = commerce;
        if (id == null || c == null) return;
        if (await c.refreshLocation(id) case Err()) {
          _liveTimer?.cancel();
          _liveMessageId = null;
        }
      });
      notifyListeners();
    }
    return ok;
  }

  Future<void> stopLiveLocation() async {
    final id = _liveMessageId;
    _liveTimer?.cancel();
    _liveMessageId = null;
    if (id != null) await commerce?.stopLocation(id);
    await load();
  }

  Future<List<QuoteChoice>> quoteChoices() async =>
      (await commerce?.quoteChoices())?.valueOrNull ?? const [];

  Future<bool> sendQuote(List<QuoteLine> lines, {String? note}) =>
      _commerceSend(
        (c) => c.sendQuote(
          conversationId,
          lines,
          idempotencyKey: Uuid.v4(),
          note: note,
        ),
      );

  Future<bool> sendPaymentRequest(int amountMinor, {String? label}) =>
      _commerceSend(
        (c) => c.sendPaymentRequest(
          conversationId,
          amountMinor: amountMinor,
          idempotencyKey: Uuid.v4(),
          label: label,
        ),
      );

  Future<bool> sendCoupon(int percent, int days) => _commerceSend(
    (c) => c.sendCoupon(
      conversationId,
      percent: percent,
      days: days,
      idempotencyKey: Uuid.v4(),
    ),
  );

  /// Devis accepté : les articles passent au panier, aux prix du devis.
  Future<bool> acceptQuote(ChatMessage m) async {
    final id = m.payloadText('quote_id');
    if (id == null) return false;
    return await _commerceAct((c) => c.acceptQuote(id));
  }

  /// Demande de paiement réglée avec le wallet.
  Future<bool> payRequest(ChatMessage m) async {
    final code = m.payloadText('code');
    if (code == null) return false;
    return await _commerceAct(
      (c) => c.payRequest(code, idempotencyKey: Uuid.v4()),
    );
  }

  /// Coupon gardé : il s'applique à la prochaine commande de la boutique.
  Future<bool> claimCoupon(ChatMessage m) async {
    final id = m.payloadText('coupon_id');
    if (id == null) return false;
    return await _commerceAct((c) => c.claimCoupon(id));
  }

  /// Transcription d'un vocal, à la demande.
  Future<void> transcribe(ChatMessage m) async {
    if (m.transcript case final t?) {
      transcripts[m.id] = t;
      notifyListeners();
      return;
    }
    final c = commerce;
    if (c == null) return;
    if (await c.transcribe(m.id) case Ok(:final value)) {
      if (value.simulated) {
        simulatedTranscripts.add(m.id);
      } else if (value.text case final text?) {
        transcripts[m.id] = text;
      }
      if (!_disposed) notifyListeners();
    }
  }

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
            replyTo: _takeReply(),
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
        _startRecordClock();
      case Err(:final failure):
        _sendFailure = failure;
    }
    notifyListeners();
  }

  Future<void> cancelRecording() async {
    if (!recording) return;
    recording = false;
    _stopRecordClock();
    await service.recorder?.cancel();
    notifyListeners();
  }

  /// Fin de l'enregistrement et envoi ; trop court : rien.
  Future<bool> stopAndSendRecording() async {
    final recorder = service.recorder;
    if (recorder == null || !recording) return false;
    recording = false;
    _stopRecordClock();
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
            replyTo: _takeReply(),
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
        playPaused = false;
        playPosition = Duration.zero;
        notifyListeners();
      }
    });
    _positionSub ??= playback.position.listen((p) {
      playPosition = p;
      if (!_disposed && playingId != null) notifyListeners();
    });
    if (playingId == message.id) {
      // Même vocal : pause, puis reprise là où il s'était arrêté.
      if (playPaused) {
        playPaused = false;
        await playback.resume();
      } else {
        playPaused = true;
        await playback.pause();
      }
      notifyListeners();
    } else {
      playPaused = false;
      playPosition = Duration.zero;
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
      replyTo: o.replyTo?.id,
    ),
    MessageKind.audio => service.sendAudio(
      conversationId,
      o.audio!,
      idempotencyKey: o.key,
      replyTo: o.replyTo?.id,
    ),
    MessageKind.file => service.sendFile(
      conversationId,
      o.document!,
      idempotencyKey: o.key,
      replyTo: o.replyTo?.id,
    ),
    _ => service.sendText(
      conversationId,
      o.body!,
      idempotencyKey: o.key,
      replyTo: o.replyTo?.id,
    ),
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
    _liveTimer?.cancel();
    _timer?.cancel();
    _typingTimer?.cancel();
    _recordTimer?.cancel();
    unawaited(_levelSub?.cancel());
    unawaited(_typingSub?.cancel());
    unawaited(_positionSub?.cancel());
    unawaited(_live?.cancel());
    unawaited(_playing?.cancel());
    if (recording) unawaited(service.recorder?.cancel());
    super.dispose();
  }
}
