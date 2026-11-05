import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/app/config_error_app.dart';
import 'package:dym_vendor/app/vendor_app.dart';
import 'package:dym_vendor/features/store/store_service.dart';
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
  final reference = ReferenceRepository(neon.data);
  final auth = NeonAuthService(
    neon: neon,
    account: AccountRepository(neon.data),
    reference: reference,
    google: PluginGoogleIdTokenProvider.fromDefines(),
    app: AccountApp.vendor,
  );
  locator
    ..registerSingleton(environment)
    ..registerSingleton(neon)
    ..registerSingleton<AuthService>(auth)
    ..registerSingleton<StoreService>(
      NeonStoreService(
        stores: StoreRepository(neon.data),
        reference: reference,
        auth: auth,
      ),
    );
  runApp(const VendorApp());
}
