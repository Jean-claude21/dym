import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/app/config_error_app.dart';
import 'package:dym_vendor/app/vendor_app.dart';
import 'package:dym_vendor/features/broadcast/broadcast_view.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/content/contents_views.dart';
import 'package:dym_vendor/features/credit/credit_service.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';
import 'package:dym_vendor/features/group_buy/group_offers_view.dart';
import 'package:dym_vendor/features/haggle/haggling_view.dart';
import 'package:dym_vendor/features/orders/adjustments_panel.dart';
import 'package:dym_vendor/features/orders/courier_cash_view.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:dym_vendor/features/reviews/reviews_view.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:dym_vendor/features/till/till_service.dart';
import 'package:dym_vendor/features/wholesale/wholesale_view.dart';
import 'package:dym_vendor/ui/navigation.dart';
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
    app: 'vendor',
    body: () => _start(environment),
  );
}

/// Services de l'app, puis premier écran.
Future<void> _start(DymEnvironment environment) async {
  await configureServices(environment);
  runApp(const VendorApp());
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
    app: AccountApp.vendor,
    locale: locale,
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
  // Temps réel (spec 067) : ouvert tant qu'un écran écoute, au premier plan.
  final live = LiveConnection(neon.live)..attach();
  locator
    ..registerSingleton(environment)
    ..registerSingleton(neon)
    ..registerSingleton<LiveFeed>(live)
    // Notifications du téléphone (spec 069) : démarrées à l'accueil, une fois
    // la personne connectée ; le toucher ouvre l'écran concerné.
    ..registerSingleton(
      PushNotifications(
        channels: _pushChannels,
        register: (token, platform) async => (await NotificationRepository(
          neon.data,
        ).registerDevice(token: token, platform: platform, app: 'vendor')).isOk,
        onOpened: (data) {
          final nav = StackedAppNavigator();
          final order = data['order_id'];
          final conversation = data['conversation_id'];
          if (conversation != null) {
            nav.toChat(conversation);
          } else if (order != null) {
            nav.toOrder(order);
          }
        },
      ),
    )
    ..registerSingleton(locale)
    ..registerSingleton<AuthService>(auth)
    ..registerSingleton<StoreService>(stores)
    ..registerSingleton<DashboardService>(
      NeonDashboardService(
        repository: VendorDashboardRepository(neon.data),
        stores: stores,
        messages: messaging,
        liveFeed: live,
      ),
    )
    ..registerLazySingleton<VendorBroadcastService>(
      () => NeonVendorBroadcastService(
        repository: BroadcastRepository(
          data: neon.data,
          functions: neon.functions,
        ),
        products: () => locator<CatalogService>().products(),
        config: stores.countryConfig,
        photo: (key) => dymNetworkImage(environment.media(key).toString()),
      ),
    )
    ..registerLazySingleton<VendorContentService>(
      () => NeonVendorContentService(
        repository: ContentRepository(
          data: neon.data,
          functions: neon.functions,
          uploads: neon.uploads,
        ),
        photos: PluginPhotoPicker(),
        videos: PluginVideoPicker(),
        products: () => locator<CatalogService>().products(),
        config: stores.countryConfig,
        photo: (key) => dymNetworkImage(environment.media(key).toString()),
      ),
    )
    ..registerSingleton<MembershipService>(
      NeonMembershipService(
        repository: MembershipRepository(neon.data),
        audience: 'vendor',
        config: stores.countryConfig,
      ),
    )
    ..registerSingleton<GroupOffersService>(
      NeonGroupOffersService(
        repository: GroupBuyRepository(neon.data),
        config: stores.countryConfig,
        products: () => locator<CatalogService>().products(),
      ),
    )
    ..registerSingleton<HagglingService>(
      NeonHagglingService(
        repository: HaggleRepository(neon.data),
        config: stores.countryConfig,
      ),
    )
    ..registerSingleton<WholesaleService>(
      NeonWholesaleService(
        repository: WholesaleRepository(neon.data),
        config: stores.countryConfig,
        products: () => locator<CatalogService>().products(),
      ),
    )
    ..registerSingleton<CreditService>(
      NeonCreditService(
        credits: CreditRepository(neon.data),
        config: stores.countryConfig,
      ),
    )
    ..registerSingleton<TillService>(
      NeonTillService(
        till: TillRepository(neon.data),
        qr: QrPaymentRepository(neon.data),
        search: SearchAiRepository(data: neon.data, functions: neon.functions),
        recorder: PluginVoiceRecorder(),
        config: stores.countryConfig,
        shareBase: environment.functionsUrl,
        storeId: () async => (await stores.myStore()).valueOrNull?.id,
      ),
    )
    ..registerSingleton<CourierCashService>(
      NeonCourierCashService(
        couriers: CourierRepository(neon.data),
        config: stores.countryConfig,
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
        productPhoto: (key) =>
            dymNetworkImage(environment.media(key).toString()),
        recorder: PluginVoiceRecorder(),
        playback: PluginAudioPlayback(),
        calls: _callService(
          CallRepository(neon.data, functions: neon.functions),
        ),
        liveFeed: live,
      ),
    )
    ..registerLazySingleton<VendorAdjustmentsService>(
      () => NeonVendorAdjustmentsService(
        repository: OrderAdjustmentRepository(
          data: neon.data,
          functions: neon.functions,
          uploads: neon.uploads,
        ),
        photos: PluginPhotoPicker(),
        products: () => locator<CatalogService>().products(),
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
        live: live,
        delivery: DeliveryRepository(neon.data),
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
}

/// Noms des canaux de notification (spec 072), dans la langue du téléphone.
PushChannels _pushChannels() {
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final supported = DymLocalizations.supportedLocales.any(
    (l) => l.languageCode == device,
  );
  final t = lookupDymLocalizations(Locale(supported ? device : 'fr'));
  return PushChannels(
    orders: t.pushChannelOrders,
    messages: t.pushChannelMessages,
    missions: t.pushChannelMissions,
    general: t.pushChannelGeneral,
  );
}

/// Appels du chat : états en base, média LiveKit quand la base le choisit
/// (spec 084), jeton émis par la Function.
CallService _callService(CallRepository calls) {
  return NeonCallService(
    repository: calls,
    livekit: LiveKitCallProvider(credentials: calls.mediaCredentials),
  );
}
