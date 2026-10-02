import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/app/client_app.dart';
import 'package:dym_client/app/config_error_app.dart';
import 'package:dym_core/dym_core.dart';
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
  locator
    ..registerSingleton(environment)
    ..registerSingleton(createNeonClient(environment));
  runApp(const ClientApp());
}
