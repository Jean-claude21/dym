import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_delivery/app/app.locator.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

/// Démarrage : le câblage réel des services se résout (environnement local,
/// sans réseau).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(locator.reset);

  test('câblage des services au démarrage', () async {
    await app.configureServices(DymEnvironment.resolve(env: 'dev'));
    expect(locator.get<AuthService>().app.name, 'delivery');
    expect(locator.get<MissionsService>(), isA<NeonMissionsService>());
  });
}
