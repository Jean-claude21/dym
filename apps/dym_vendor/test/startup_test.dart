import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/features/broadcast/broadcast_view.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/content/contents_views.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:dym_vendor/features/reviews/reviews_view.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:dym_vendor/main.dart' as app;
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
      locator.get<StoreService>,
      locator.get<DashboardService>,
      locator.get<VendorBroadcastService>,
      locator.get<VendorContentService>,
      locator.get<VendorReviewsService>,
      locator.get<SupportService>,
      locator.get<ChatService>,
      locator.get<OrdersService>,
      locator.get<CatalogService>,
      locator.get<LocalePreference>,
    ]) {
      expect(resolve, returnsNormally);
    }
  });
}
