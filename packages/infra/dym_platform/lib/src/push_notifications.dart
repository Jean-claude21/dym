import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Données d'une notification ouverte : `kind` (`new_order`,
/// `mission_available`…), `order_id`, `purchase_id` ; avec un bouton
/// d'action (spec 097) : `action` (`accept`, `view`, `reply`, `answer`,
/// `decline`) et, pour une réponse, `reply`.
typedef PushOpened = void Function(Map<String, String> data);

/// Enregistre le jeton du téléphone (sous la session de la personne).
typedef PushRegister = Future<bool> Function(String token, String platform);

/// Noms des canaux Android (visibles dans les réglages du téléphone),
/// traduits par l'app (spec 072).
class PushChannels {
  const new({
    this.orders = 'DYM',
    this.messages = 'DYM',
    this.missions = 'DYM',
    this.general = 'DYM',
    this.calls = 'DYM',
  });

  factory fromJson(Map<String, dynamic> j) => PushChannels(
    orders: j['orders'] as String? ?? 'DYM',
    messages: j['messages'] as String? ?? 'DYM',
    missions: j['missions'] as String? ?? 'DYM',
    general: j['general'] as String? ?? 'DYM',
    calls: j['calls'] as String? ?? 'DYM',
  );

  final String orders;
  final String messages;
  final String missions;
  final String general;
  final String calls;

  /// Identifiants partagés avec la Function (`pushChannel`). Spec 097 :
  /// nouveaux canaux, chacun avec son son (un canal ne change pas de son).
  static const ordersId = 'dym_orders_v2';
  static const messagesId = 'dym_messages_v2';
  static const missionsId = 'dym_missions_v2';
  static const generalId = 'dym_general_v2';
  static const callsId = 'dym_calls_v2';

  /// Canaux d'avant la spec 097, retirés au démarrage.
  static const legacyIds = [
    'dym_orders',
    'dym_messages',
    'dym_missions',
    'dym_general',
  ];

  String nameOf(String id) => switch (id) {
    messagesId => messages,
    missionsId => missions,
    generalId => general,
    callsId => calls,
    _ => orders,
  };

  Map<String, String> toJson() => {
    'orders': orders,
    'messages': messages,
    'missions': missions,
    'general': general,
    'calls': calls,
  };
}

/// Libellés des boutons d'action, traduits par l'app (spec 097). Gardés sur
/// le téléphone pour l'affichage en arrière-plan.
class PushLabels {
  const new({
    this.accept = 'Accepter',
    this.view = 'Voir',
    this.reply = 'Répondre',
    this.replyHint = 'Message',
    this.answer = 'Répondre',
    this.decline = 'Refuser',
  });

  factory fromJson(Map<String, dynamic> j) => PushLabels(
    accept: j['accept'] as String? ?? 'Accepter',
    view: j['view'] as String? ?? 'Voir',
    reply: j['reply'] as String? ?? 'Répondre',
    replyHint: j['reply_hint'] as String? ?? 'Message',
    answer: j['answer'] as String? ?? 'Répondre',
    decline: j['decline'] as String? ?? 'Refuser',
  );

  final String accept;
  final String view;
  final String reply;
  final String replyHint;
  final String answer;
  final String decline;

  Map<String, String> toJson() => {
    'accept': accept,
    'view': view,
    'reply': reply,
    'reply_hint': replyHint,
    'answer': answer,
    'decline': decline,
  };
}

const _storageKey = 'dym.push.texts';
const _android = AndroidInitializationSettings('@mipmap/ic_launcher');

/// Son et importance de chaque canal (sons dans `res/raw` des apps).
const List<(String, String?, Importance)> _channelSpecs = [
  (PushChannels.ordersId, 'dym_order', Importance.high),
  (PushChannels.messagesId, 'dym_message', Importance.high),
  (PushChannels.missionsId, 'dym_mission', Importance.max),
  (PushChannels.generalId, null, Importance.defaultImportance),
  (PushChannels.callsId, 'dym_ring', Importance.max),
];

/// Boutons proposés pour un type de notification (spec 097).
@visibleForTesting
List<String> pushActionsFor(String kind) => switch (kind) {
  'new_order' || 'mission_available' => const ['accept', 'view'],
  'incoming_call' || 'incoming_call_vendor' => const ['answer', 'decline'],
  final k when k.startsWith('new_message') => const ['reply', 'view'],
  _ => const [],
};

bool _isCall(String kind) => kind.startsWith('incoming_call');

/// Affiche une notification construite par l'app (données seules) :
/// boutons d'action, son du canal, appel en plein écran qui sonne.
Future<void> _display(
  FlutterLocalNotificationsPlugin plugin,
  Map<String, dynamic> data,
  PushChannels names,
  PushLabels labels,
  int id,
) async {
  final kind = '${data['kind'] ?? ''}';
  final channel = '${data['channel'] ?? PushChannels.ordersId}';
  final spec = _channelSpecs.where((c) => c.$1 == channel).firstOrNull;
  final call = _isCall(kind);
  final actions = [
    for (final a in pushActionsFor(kind))
      AndroidNotificationAction(
        a,
        switch (a) {
          'accept' => labels.accept,
          'reply' => labels.reply,
          'answer' => labels.answer,
          'decline' => labels.decline,
          _ => labels.view,
        },
        // Le geste se termine dans l'app (session, confirmation).
        showsUserInterface: a != 'decline',
        inputs: a == 'reply'
            ? [AndroidNotificationActionInput(label: labels.replyHint)]
            : const [],
      ),
  ];
  await plugin.show(
    data['tag'] is String ? (data['tag'] as String).hashCode : id,
    data['title'] as String?,
    data['body'] as String?,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        names.nameOf(channel),
        importance: spec?.$3 ?? Importance.high,
        priority: call ? Priority.max : Priority.high,
        sound: spec?.$2 == null
            ? null
            : RawResourceAndroidNotificationSound(spec!.$2),
        tag: data['tag'] as String?,
        actions: actions,
        category: call
            ? AndroidNotificationCategory.call
            : AndroidNotificationCategory.message,
        // Appel : plein écran même verrouillé, sonne jusqu'à la réponse
        // (60 s au plus, comme l'appel côté serveur).
        fullScreenIntent: call,
        ongoing: call,
        timeoutAfter: call ? 60000 : null,
        audioAttributesUsage: call
            ? AudioAttributesUsage.notificationRingtone
            : AudioAttributesUsage.notification,
        additionalFlags: call ? Int32List.fromList(const [4]) : null,
      ),
      // iPhone (spec 108) : son de l'événement (WAV de l'app), sujet.
      iOS: DarwinNotificationDetails(
        sound: spec?.$2 == null ? null : '${spec!.$2}.wav',
        threadIdentifier: data['tag'] as String?,
        interruptionLevel: call
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    ),
    payload: jsonEncode(data),
  );
}

Future<(PushChannels, PushLabels)> _readTexts() async {
  try {
    final raw = await const FlutterSecureStorage().read(key: _storageKey);
    if (raw != null) {
      final j = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return (
        PushChannels.fromJson((j['channels'] as Map).cast()),
        PushLabels.fromJson((j['labels'] as Map).cast()),
      );
    }
  } on Object {
    // Rien de gardé : libellés par défaut.
  }
  return (const PushChannels(), const PushLabels());
}

/// Réception en arrière-plan (app fermée ou en fond) : les notifications à
/// boutons arrivent en données seules ; l'app les affiche elle-même.
@pragma('vm:entry-point')
Future<void> dymPushBackground(RemoteMessage message) async {
  if (message.notification != null || message.data['title'] == null) return;
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(const InitializationSettings(android: _android));
  final (names, labels) = await _readTexts();
  await _display(
    plugin,
    message.data,
    names,
    labels,
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}

/// Bouton « Refuser » touché sans ouvrir l'app : rien à faire ici, l'appel
/// sonnera 60 s au plus côté serveur (l'app relit l'état à l'ouverture).
@pragma('vm:entry-point')
void dymPushActionBackground(NotificationResponse response) {}

/// Notifications du téléphone (FCM, spec 069 ; sons et boutons, spec 097).
///
/// - [start] après la connexion : autorisation (Android 13+), canaux avec
///   leur son, jeton enregistré puis réenregistré à chaque renouvellement ;
/// - app ouverte ou fermée : les notifications à boutons sont affichées par
///   l'app (données seules), les autres par le système ;
/// - toucher ou bouton : [onOpened] reçoit les données et l'action.
///
/// Sans configuration Firebase (web, tests), rien ne se passe.
class PushNotifications {
  new({
    required this._register,
    required this.onOpened,
    this.channels,
    this.labels,
  });

  final PushRegister _register;

  /// Ouverture d'une notification touchée (ou d'un bouton).
  final PushOpened onOpened;

  /// Noms des canaux Android, demandés au démarrage (langue du moment).
  final PushChannels Function()? channels;

  /// Libellés des boutons, demandés au démarrage (langue du moment).
  final PushLabels Function()? labels;

  PushChannels _names = const PushChannels();
  PushLabels _labels = const PushLabels();

  final _local = FlutterLocalNotificationsPlugin();
  final _subs = <StreamSubscription<Object?>>[];
  bool _ready = false;
  int _shown = 0;

  /// Plateforme reconnue par `register_push_token`.
  static String get platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    _ => 'android',
  };

  void _respond(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final data = (jsonDecode(payload) as Map).map(
      (k, v) => MapEntry('$k', '$v'),
    );
    if (response.actionId case final action? when action.isNotEmpty) {
      data['action'] = action;
    }
    if (response.input case final input? when input.trim().isNotEmpty) {
      data['reply'] = input.trim();
    }
    onOpened(data);
  }

  /// Démarre (une seule fois) ; sans erreur si Firebase n'est pas configuré.
  Future<void> start() async {
    if (_ready || kIsWeb) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } on Object catch (error) {
      debugPrint('[push] Firebase absent : $error');
      return;
    }
    _ready = true;
    // App fermée : les notifications à boutons et les appels sont affichés
    // par l'app elle-même (spec 097).
    FirebaseMessaging.onBackgroundMessage(dymPushBackground);
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await _local.initialize(
      const InitializationSettings(
        android: _android,
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _respond,
      onDidReceiveBackgroundNotificationResponse: dymPushActionBackground,
    );
    _names = channels?.call() ?? const PushChannels();
    _labels = labels?.call() ?? const PushLabels();
    // Libellés gardés pour l'affichage en arrière-plan (autre isolat).
    try {
      await const FlutterSecureStorage().write(
        key: _storageKey,
        value: jsonEncode({
          'channels': _names.toJson(),
          'labels': _labels.toJson(),
        }),
      );
    } on Object {
      // Stockage indisponible : libellés par défaut en arrière-plan.
    }
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final id in PushChannels.legacyIds) {
      await android?.deleteNotificationChannel(id);
    }
    for (final (id, sound, importance) in _channelSpecs) {
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          id,
          _names.nameOf(id),
          importance: importance,
          sound: sound == null
              ? null
              : RawResourceAndroidNotificationSound(sound),
          audioAttributesUsage: id == PushChannels.callsId
              ? AudioAttributesUsage.notificationRingtone
              : AudioAttributesUsage.notification,
        ),
      );
    }
    // Plein écran pour les appels (Android 14+ : autorisation demandée).
    await android?.requestFullScreenIntentPermission();

    // Jeton d'enregistrement classique : cible de l'envoi FCM v1.
    // ignore: deprecated_member_use
    if (await messaging.getToken() case final token?) {
      await _register(token, platform);
    }
    _subs
      ..add(
        // Même raison que getToken ci-dessus.
        // ignore: deprecated_member_use
        messaging.onTokenRefresh.listen(
          (t) => unawaited(_register(t, platform)),
        ),
      )
      ..add(FirebaseMessaging.onMessage.listen(_showForeground))
      ..add(
        FirebaseMessaging.onMessageOpenedApp.listen(
          (m) => onOpened(m.data.cast()),
        ),
      );
    // Ouverte depuis une notification (ou un bouton) alors que l'app était
    // fermée.
    if (await messaging.getInitialMessage() case final message?) {
      onOpened(message.data.cast());
    }
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      if (launch?.notificationResponse case final response?) {
        _respond(response);
      }
    }
  }

  /// App au premier plan : FCM n'affiche rien, on le fait.
  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) {
      // Données seules (boutons, appel) : affichées par l'app.
      if (message.data['title'] != null) {
        await _display(_local, message.data, _names, _labels, _shown++);
      }
      return;
    }
    final channel = n.android?.channelId ?? PushChannels.ordersId;
    final spec = _channelSpecs.where((c) => c.$1 == channel).firstOrNull;
    // Même sujet (commande, conversation) : la notification est remplacée.
    final tag = n.android?.tag;
    await _local.show(
      tag?.hashCode ?? _shown++,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          _names.nameOf(channel),
          importance: spec?.$3 ?? Importance.high,
          priority: channel == PushChannels.generalId
              ? Priority.defaultPriority
              : Priority.high,
          sound: spec?.$2 == null
              ? null
              : RawResourceAndroidNotificationSound(spec!.$2),
          tag: tag,
        ),
        iOS: DarwinNotificationDetails(
          sound: spec?.$2 == null ? null : '${spec!.$2}.wav',
          threadIdentifier: tag,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }
}
