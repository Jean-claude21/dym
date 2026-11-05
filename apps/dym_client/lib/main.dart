import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/app/client_app.dart';
import 'package:dym_client/app/config_error_app.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/widgets.dart';

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
  await setupLocator();
  final neon = createNeonClient(environment);
  locator
    ..registerSingleton(environment)
    ..registerSingleton(neon)
    ..registerSingleton<AuthService>(
      NeonAuthService(
        neon: neon,
        account: AccountRepository(neon.data),
        reference: ReferenceRepository(neon.data),
        google: PluginGoogleIdTokenProvider.fromDefines(),
        app: AccountApp.client,
      ),
    );
  runApp(const ClientApp());
}
