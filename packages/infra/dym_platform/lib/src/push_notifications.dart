import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Données d'une notification ouverte : `kind` (`new_order`,
/// `mission_available`…), `order_id`, `purchase_id`.
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
  });

  final String orders;
  final String messages;
  final String missions;
  final String general;

  /// Identifiants partagés avec la Function (`pushChannel`).
  static const ordersId = 'dym_orders';
  static const messagesId = 'dym_messages';
  static const missionsId = 'dym_missions';
  static const generalId = 'dym_general';

  String nameOf(String id) => switch (id) {
    messagesId => messages,
    missionsId => missions,
    generalId => general,
    _ => orders,
  };
}

/// Notifications du téléphone (FCM, spec 069).
///
/// - [start] après la connexion : autorisation (Android 13+), jeton
///   enregistré puis réenregistré à chaque renouvellement ;
/// - app ouverte : la notification s'affiche quand même (FCM ne le fait pas) ;
/// - toucher : [onOpened] reçoit les données pour ouvrir le bon écran.
///
/// Sans configuration Firebase (web, tests), rien ne se passe : l'app
/// fonctionne, le temps réel et la relecture prennent le relais.
class PushNotifications {
  new({required this._register, required this.onOpened, this.channels});

  final PushRegister _register;

  /// Ouverture d'une notification touchée.
  final PushOpened onOpened;

  /// Noms des canaux Android, demandés au démarrage (langue du moment).
  final PushChannels Function()? channels;
  PushChannels _names = const PushChannels();

  final _local = FlutterLocalNotificationsPlugin();
  final _subs = <StreamSubscription<Object?>>[];
  bool _ready = false;
  int _shown = 0;

  /// Plateforme reconnue par `register_push_token`.
  static String get platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    _ => 'android',
  };

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
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        final data = (jsonDecode(payload) as Map).map(
          (k, v) => MapEntry('$k', '$v'),
        );
        onOpened(data);
      },
    );
    // Un canal par type (spec 072) : commandes et paiements, messages,
    // courses du livreur (importance haute), le reste (normale).
    _names = channels?.call() ?? const PushChannels();
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final (id, importance) in const [
      (PushChannels.ordersId, Importance.high),
      (PushChannels.messagesId, Importance.high),
      (PushChannels.missionsId, Importance.max),
      (PushChannels.generalId, Importance.defaultImportance),
    ]) {
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          id,
          _names.nameOf(id),
          importance: importance,
        ),
      );
    }

    // Jeton d'enregistrement classique : c'est la cible attendue par l'envoi
    // FCM v1 de la Function (`message.token`). L'identifiant d'installation
    // de `register()` demandera de changer l'envoi en même temps.
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
    // Ouverte depuis une notification alors que l'app était fermée.
    if (await messaging.getInitialMessage() case final message?) {
      onOpened(message.data.cast());
    }
  }

  /// App au premier plan : FCM n'affiche rien, on le fait.
  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    final channel = n.android?.channelId ?? PushChannels.ordersId;
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
          importance: channel == PushChannels.generalId
              ? Importance.defaultImportance
              : Importance.high,
          priority: channel == PushChannels.generalId
              ? Priority.defaultPriority
              : Priority.high,
          tag: tag,
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
