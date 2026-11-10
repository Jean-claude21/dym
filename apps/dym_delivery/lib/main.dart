import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_delivery/app/app.locator.dart';
import 'package:dym_delivery/app/config_error_app.dart';
import 'package:dym_delivery/app/delivery_app.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
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
  locator
    ..registerSingleton(environment)
    ..registerSingleton(neon)
    ..registerSingleton(locale)
    ..registerSingleton<AuthService>(auth)
    ..registerSingleton<MissionsService>(
      NeonMissionsService(
        couriers: CourierRepository(neon.data),
        reference: reference,
        auth: auth,
      ),
    );
}
