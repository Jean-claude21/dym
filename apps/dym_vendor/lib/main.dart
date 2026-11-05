import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/app/config_error_app.dart';
import 'package:dym_vendor/app/vendor_app.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:dym_vendor/features/reviews/reviews_view.dart';
import 'package:dym_vendor/features/store/store_service.dart';
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
  final stores = NeonStoreService(
    stores: StoreRepository(neon.data),
    reference: reference,
    auth: auth,
  );
  final messaging = MessagingRepository(
    data: neon.data,
    functions: neon.functions,
    uploads: neon.uploads,
  );
  locator
    ..registerSingleton(environment)
    ..registerSingleton(neon)
    ..registerSingleton<AuthService>(auth)
    ..registerSingleton<StoreService>(stores)
    ..registerSingleton<DashboardService>(
      NeonDashboardService(
        repository: VendorDashboardRepository(neon.data),
        stores: stores,
        messages: messaging,
      ),
    )
    ..registerSingleton<VendorReviewsService>(
      NeonVendorReviewsService(
        ReviewRepository(data: neon.data, functions: neon.functions),
      ),
    )
    ..registerLazySingleton<SupportService>(
      () => NeonSupportService(
        repository: SupportRepository(neon.data),
        app: 'vendor',
        recentOrders: () async => [
          for (final o
              in (await locator<OrdersService>().orders()).valueOrNull ??
                  const <VendorOrder>[])
            (
              id: o.id,
              label:
                  '${o.id.substring(0, 8).toUpperCase()} · '
                  '${o.customerFirstName ?? ''}',
            ),
        ].take(10).toList(),
      ),
    )
    ..registerSingleton<ChatService>(
      NeonChatService(
        repository: messaging,
        role: ChatRole.vendor,
        countryConfig: stores.countryConfig,
        photos: PluginPhotoPicker(),
        productPhoto: (key) => NetworkImage(environment.media(key).toString()),
      ),
    )
    ..registerSingleton<OrdersService>(
      NeonOrdersService(
        orders: VendorOrderRepository(
          data: neon.data,
          functions: neon.functions,
        ),
        disputes: DisputeRepository(data: neon.data, functions: neon.functions),
        stores: stores,
      ),
    )
    ..registerSingleton<CatalogService>(
      NeonCatalogService(
        catalog: CatalogRepository(neon.data),
        media: CatalogMediaRepository(
          functions: neon.functions,
          uploads: neon.uploads,
        ),
        events: EventsRepository(neon.data, app: EventApp.vendor),
        stores: stores,
        picker: PluginPhotoPicker(),
        environment: environment,
      ),
    );
  runApp(const VendorApp());
}
