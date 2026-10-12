import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/main.dart' as app;
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Démarrage : le câblage réel des services se résout entièrement (types
/// enregistrés, dépendances entre services, plugins créés sans erreur),
/// avec l'environnement local et sans réseau.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(locator.reset);

  test('câblage des services au démarrage', () async {
    await app.configureServices(DymEnvironment.resolve(env: 'dev'));
    for (final resolve in <Object Function()>[
      locator.get<AuthService>,
      locator.get<AdminService>,
    ]) {
      expect(resolve, returnsNormally);
    }
  });
}
