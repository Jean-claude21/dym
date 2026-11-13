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
  new({required this._register, required this.onOpened, this.channelName});

  final PushRegister _register;

  /// Ouverture d'une notification touchée.
  final PushOpened onOpened;

  /// Nom du canal Android (traduit par l'app).
  final String? channelName;

  final _local = FlutterLocalNotificationsPlugin();
  final _subs = <StreamSubscription<Object?>>[];
  bool _ready = false;
  int _shown = 0;

  static const _channelId = 'dym_orders';

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
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            channelName ?? 'DYM',
            importance: Importance.high,
          ),
        );

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
    await _local.show(
      _shown++,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          channelName ?? 'DYM',
          importance: Importance.high,
          priority: Priority.high,
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
