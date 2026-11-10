import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/app/client_app.dart';
import 'package:dym_client/app/config_error_app.dart';
import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/creator/creator_service.dart';
import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_client/features/favorites/favorites_service.dart';
import 'package:dym_client/features/orders/adjustments_view.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_client/features/shopping/shopping_service.dart';
import 'package:dym_client/features/spaces/spaces_service.dart';
import 'package:dym_client/features/wallet/wallet_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
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
  await runWithErrorReporting(
    environment: environment,
    app: 'client',
    body: () => _start(environment),
  );
}

/// Services de l'app, puis premier écran.
Future<void> _start(DymEnvironment environment) async {
  await configureServices(environment);
  runApp(const ClientApp());
}

/// Enregistre les services de l'app (Neon, dépôts, plugins). Séparé du
/// lancement pour être vérifié en test (câblage complet, sans réseau).
Future<void> configureServices(DymEnvironment environment) async {
  await setupLocator();
  final neon = createNeonClient(environment);
  final reference = ReferenceRepository(neon.data);
  final locale = LocalePreference();
  final auth = NeonAuthService(
    neon: neon,
    account: AccountRepository(neon.data),
    reference: reference,
    google: PluginGoogleIdTokenProvider.fromDefines(),
    app: AccountApp.client,
    locale: locale,
  );
  locator
    ..registerSingleton(environment)
    ..registerSingleton(neon)
    ..registerSingleton(locale)
    ..registerSingleton<AuthService>(auth)
    ..registerLazySingleton<DiscoveryService>(
      () => NeonDiscoveryService(
        discovery: DiscoveryRepository(neon.data),
        reference: reference,
        events: EventsRepository(neon.data, app: EventApp.client),
        auth: auth,
        location: const PluginLocationProvider(),
        environment: environment,
        reviews: ReviewRepository(data: neon.data, functions: neon.functions),
      ),
    )
    ..registerLazySingleton<SearchAiService>(
      () => NeonSearchAiService(
        repository: SearchAiRepository(
          data: neon.data,
          functions: neon.functions,
        ),
        discovery: locator<DiscoveryService>(),
        auth: auth,
        recorder: PluginVoiceRecorder(),
        photos: PluginPhotoPicker(),
      ),
    )
    ..registerLazySingleton<CopilotService>(
      () => NeonCopilotService(
        repository: CopilotRepository(
          data: neon.data,
          functions: neon.functions,
        ),
        discovery: locator<DiscoveryService>(),
        cart: locator<CartService>(),
        events: EventsRepository(neon.data, app: EventApp.client),
      ),
    )
    ..registerLazySingleton<ContentService>(
      () => NeonContentService(
        repository: ContentRepository(
          data: neon.data,
          functions: neon.functions,
          uploads: neon.uploads,
        ),
        discovery: locator<DiscoveryService>(),
        cart: locator<CartService>(),
        media: environment.media,
      ),
    )
    ..registerLazySingleton<SupportService>(
      () => NeonSupportService(
        repository: SupportRepository(neon.data),
        app: 'client',
        recentOrders: () async => [
          for (final o
              in (await locator<OrdersService>().orders()).valueOrNull ??
                  const <CustomerOrder>[])
            (
              id: o.id,
              label: '${o.id.substring(0, 8).toUpperCase()} · ${o.store.name}',
            ),
        ].take(10).toList(),
      ),
    )
    ..registerLazySingleton<OrdersService>(
      () => NeonOrdersService(
        orders: OrderTrackingRepository(
          data: neon.data,
          functions: neon.functions,
        ),
        notifications: NotificationRepository(neon.data),
        disputes: DisputeRepository(data: neon.data, functions: neon.functions),
        reviews: ReviewRepository(data: neon.data, functions: neon.functions),
        reorders: ReorderRepository(neon.data),
        reference: reference,
        auth: auth,
      ),
    )
    ..registerLazySingleton<ChatService>(
      () => NeonChatService(
        repository: MessagingRepository(
          data: neon.data,
          functions: neon.functions,
          uploads: neon.uploads,
        ),
        role: ChatRole.client,
        countryConfig: () => locator<OrdersService>().countryConfig(),
        photos: PluginPhotoPicker(),
        productPhoto: (key) =>
            dymNetworkImage(environment.media(key).toString()),
        recorder: PluginVoiceRecorder(),
        playback: PluginAudioPlayback(),
        calls: NeonCallService(repository: CallRepository(neon.data)),
      ),
    )
    ..registerLazySingleton<CreatorService>(
      () => NeonCreatorService(
        repository: ContentRepository(
          data: neon.data,
          functions: neon.functions,
          uploads: neon.uploads,
        ),
        discovery: locator<DiscoveryService>(),
        photos: PluginPhotoPicker(),
        videos: PluginVideoPicker(),
        lists: ShoppingListRepository(
          data: neon.data,
          functions: neon.functions,
        ),
      ),
    )
    ..registerLazySingleton<AdjustmentsService>(
      () => NeonAdjustmentsService(
        repository: OrderAdjustmentRepository(
          data: neon.data,
          functions: neon.functions,
          uploads: neon.uploads,
        ),
        photos: PluginPhotoPicker(),
      ),
    )
    ..registerLazySingleton<SpacesService>(
      () => NeonSpacesService(
        repository: SpaceRepository(neon.data),
        discovery: locator<DiscoveryService>(),
        cart: locator<CartService>(),
      ),
    )
    ..registerLazySingleton<FavoritesService>(
      () => NeonFavoritesService(FavoritesRepository(neon.data)),
    )
    ..registerLazySingleton<ShoppingService>(
      () => NeonShoppingService(
        repository: ShoppingListRepository(
          data: neon.data,
          functions: neon.functions,
        ),
        copilot: locator<CopilotService>(),
        discovery: locator<DiscoveryService>(),
        cart: locator<CartService>(),
        events: EventsRepository(neon.data, app: EventApp.client),
      ),
    )
    ..registerLazySingleton<WalletService>(
      () => NeonWalletService(
        wallet: WalletRepository(neon.data),
        reference: reference,
        auth: auth,
      ),
    )
    ..registerLazySingleton<CartService>(
      () => NeonCartService(
        cart: CartRepository(neon.data),
        addresses: AddressRepository(neon.data),
        orders: OrderRepository(functions: neon.functions, data: neon.data),
        reference: reference,
        discovery: DiscoveryRepository(neon.data),
        events: EventsRepository(neon.data, app: EventApp.client),
        auth: auth,
        location: const PluginLocationProvider(),
        environment: environment,
      ),
    );
}
