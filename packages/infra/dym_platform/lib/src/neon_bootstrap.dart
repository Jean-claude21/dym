import 'package:dym_core/dym_core.dart';
import 'package:dym_platform/src/secure_session_store.dart';
import 'package:neon_kit/neon_kit.dart';

/// Client Neon de l'app pour l'environnement compilé, avec la session dans le
/// stockage sécurisé de l'appareil.
NeonClient createNeonClient(
  DymEnvironment environment, {
  SessionStore? sessionStore,
}) => NeonClient(
  config: NeonConfig(
    authUrl: environment.authUrl,
    dataApiUrl: environment.dataApiUrl,
    functionsUrl: environment.functionsUrl,
  ),
  sessionStore: sessionStore ?? SecureSessionStore(),
);
