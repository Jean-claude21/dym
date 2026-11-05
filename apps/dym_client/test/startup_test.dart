import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_client/main.dart' as app;
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
      locator.get<DiscoveryService>,
      locator.get<SearchAiService>,
      locator.get<CopilotService>,
      locator.get<ContentService>,
      locator.get<SupportService>,
      locator.get<OrdersService>,
      locator.get<ChatService>,
      locator.get<CartService>,
      locator.get<LocalePreference>,
    ]) {
      expect(resolve, returnsNormally);
    }
  });
}
