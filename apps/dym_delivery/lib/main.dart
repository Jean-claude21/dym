import 'dart:async';

import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_delivery/app/app.locator.dart';
import 'package:dym_delivery/app/config_error_app.dart';
import 'package:dym_delivery/app/delivery_app.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/ui/navigation.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_notifications/dym_notifications.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final DymEnvironment environment;
  try {
    environment = DymEnvironment.fromDefines();
  } on DymConfigurationException {
    // Compilation sans configuration valide : l'app refuse de démarrer.
    runApp(const ConfigErrorApp());
    return;
  }
  await runWithErrorReporting(
    environment: environment,
    app: 'delivery',
    body: () => _start(environment),
  );
}

Future<void> _start(DymEnvironment environment) async {
  await configureServices(environment);
  runApp(const DeliveryApp());
}

/// Enregistre les services de l'app. Séparé du lancement pour être vérifié
/// en test (câblage complet, sans réseau).
Future<void> configureServices(DymEnvironment environment) async {
  await setupLocator();
  final neon = createNeonClient(environment);
  final reference = ReferenceRepository(neon.data);
  final locale = LocalePreference();
  final auth = NeonAuthService(
    neon: neon,
    account: AccountRepository(neon.data),
    reference: reference,
    google: PluginGoogleIdTokenProvider.fromDefines(),
    app: AccountApp.delivery,
    locale: locale,
  );
  // Temps réel (spec 067) : ouvert tant qu'un écran écoute, au premier plan.
  final live = LiveConnection(neon.live)..attach();
  locator
    ..registerSingleton(environment)
    ..registerSingleton(neon)
    ..registerSingleton<LiveFeed>(live)
    // Notifications du téléphone (spec 069) : démarrées à l'accueil, une fois
    // la personne connectée ; le toucher ouvre l'écran concerné.
    ..registerSingleton(
      PushNotifications(
        channels: _pushChannels,
        labels: _pushLabels,
        register: (token, platform) async =>
            (await NotificationRepository(neon.data).registerDevice(
              token: token,
              platform: platform,
              app: 'delivery',
            )).isOk,
        onOpened: (data) => unawaited(_openPush(data)),
      ),
    )
    ..registerSingleton<NotificationInboxService>(
      NeonNotificationInboxService(
        NotificationRepository(neon.data),
        app: 'delivery',
      ),
    )
    ..registerSingleton(locale)
    ..registerSingleton<AuthService>(auth)
    // Connexion WhatsApp (spec 105).
    ..registerSingleton<WhatsAppSignIn>(NeonWhatsAppSignIn(auth))
    ..registerSingleton<MissionsService>(
      NeonMissionsService(
        couriers: CourierRepository(neon.data),
        reference: reference,
        auth: auth,
        wallet: WalletRepository(neon.data),
        live: live,
        delivery: DeliveryRepository(neon.data),
        location: const PluginLocationProvider(),
        trackingBase: environment.functionsUrl,
      ),
    );
}

/// Noms des canaux de notification (spec 072), dans la langue du téléphone.
PushChannels _pushChannels() {
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final supported = DymLocalizations.supportedLocales.any(
    (l) => l.languageCode == device,
  );
  final t = lookupDymLocalizations(Locale(supported ? device : 'fr'));
  return PushChannels(
    orders: t.pushChannelOrders,
    messages: t.pushChannelMessages,
    missions: t.pushChannelMissions,
    general: t.pushChannelGeneral,
    calls: t.pushChannelCalls,
  );
}

/// Libellés des boutons des notifications (spec 097), langue du téléphone.
PushLabels _pushLabels() {
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final supported = DymLocalizations.supportedLocales.any(
    (l) => l.languageCode == device,
  );
  final t = lookupDymLocalizations(Locale(supported ? device : 'fr'));
  return PushLabels(
    accept: t.pushActionAccept,
    view: t.pushActionView,
    reply: t.pushActionReply,
    replyHint: t.pushActionReplyHint,
    answer: t.pushActionAnswer,
    decline: t.pushActionDecline,
  );
}

/// Notification touchée ou bouton (spec 097) : « Accepter » prend la course.
Future<void> _openPush(Map<String, String> data) async {
  final order = data['order_id'];
  if (data['action'] == 'accept' &&
      data['kind'] == 'mission_available' &&
      order != null) {
    final missions = locator<MissionsService>();
    if (await missions.available() case Ok(:final value)) {
      final mission = value.where((m) => m.orderId == order).firstOrNull;
      if (mission != null) await missions.accept(mission);
    }
  }
  StackedAppNavigator().toHome();
}
