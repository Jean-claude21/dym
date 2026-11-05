import 'package:dym_admin/app/admin_app.dart';
import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_admin/app/config_error_app.dart';
import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_auth/dym_auth.dart';
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
  await runWithErrorReporting(
    environment: environment,
    app: 'admin',
    body: () => _start(environment),
  );
}

/// Services de l'app, puis premier écran.
Future<void> _start(DymEnvironment environment) async {
  await configureServices(environment);
  runApp(const AdminApp());
}

/// Enregistre les services de l'app (Neon, dépôts, plugins). Séparé du
/// lancement pour être vérifié en test (câblage complet, sans réseau).
Future<void> configureServices(DymEnvironment environment) async {
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
        app: AccountApp.admin,
      ),
    )
    ..registerSingleton<AdminService>(
      NeonAdminService(
        admin: AdminRepository(data: neon.data, functions: neon.functions),
        reference: ReferenceRepository(neon.data),
      ),
    );
}
