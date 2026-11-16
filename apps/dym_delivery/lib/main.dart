import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_delivery/app/app.locator.dart';
import 'package:dym_delivery/app/config_error_app.dart';
import 'package:dym_delivery/app/delivery_app.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/ui/navigation.dart';
import 'package:dym_l10n/dym_l10n.dart';
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
        register: (token, platform) async =>
            (await NotificationRepository(neon.data).registerDevice(
              token: token,
              platform: platform,
              app: 'delivery',
            )).isOk,
        onOpened: (_) => StackedAppNavigator().toHome(),
      ),
    )
    ..registerSingleton(locale)
    ..registerSingleton<AuthService>(auth)
    ..registerSingleton<MissionsService>(
      NeonMissionsService(
        couriers: CourierRepository(neon.data),
        reference: reference,
        auth: auth,
        wallet: WalletRepository(neon.data),
        live: live,
        delivery: DeliveryRepository(neon.data),
        location: const PluginLocationProvider(),
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
  );
}
