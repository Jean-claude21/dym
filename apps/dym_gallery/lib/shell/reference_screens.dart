import 'package:dym_account/dym_account.dart';
import 'package:dym_admin/features/audit/audit_view.dart';
import 'package:dym_admin/features/clients/clients_view.dart';
import 'package:dym_admin/features/dashboard/dashboard_view.dart';
import 'package:dym_admin/features/disputes/disputes_view.dart' as admin;
import 'package:dym_admin/features/finance/finance_view.dart';
import 'package:dym_admin/features/ops/testing.dart' as admin;
import 'package:dym_admin/features/orders/orders_views.dart' as admin;
import 'package:dym_admin/features/settings/settings_view.dart';
import 'package:dym_admin/features/stores/stores_view.dart';
import 'package:dym_admin/features/support/support_view.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_client/features/cart/addresses/address_form_view.dart';
import 'package:dym_client/features/cart/addresses/addresses_view.dart';
import 'package:dym_client/features/cart/cart/cart_view.dart';
import 'package:dym_client/features/cart/delivery/delivery_view.dart';
import 'package:dym_client/features/cart/payment/payment_view.dart';
import 'package:dym_client/features/cart/sent/order_sent_view.dart';
import 'package:dym_client/features/discovery/aisle/aisle_view.dart';
import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/discovery/copilot/copilot_view.dart';
import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/product/product_page_view.dart';
import 'package:dym_client/features/discovery/search/search_view.dart';
import 'package:dym_client/features/discovery/search/voice_search_view.dart';
import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_client/features/discovery/store/store_page_view.dart';
import 'package:dym_client/features/orders/disputes_views.dart';
import 'package:dym_client/features/orders/orders_views.dart' as client_orders;
import 'package:dym_client/features/reviews/review_views.dart';
import 'package:dym_client/ui/views/home/home_view.dart' as client;
import 'package:dym_data/dym_data.dart';
import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_auth_service.dart';
import 'package:dym_gallery/demo/demo_checkout.dart';
import 'package:dym_gallery/demo/demo_client_navigator.dart';
import 'package:dym_gallery/demo/demo_client_orders.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/demo/demo_discovery.dart';
import 'package:dym_gallery/demo/demo_store.dart';
import 'package:dym_gallery/demo/demo_vendor_catalog.dart';
import 'package:dym_gallery/demo/demo_vendor_dashboard.dart';
import 'package:dym_gallery/demo/demo_vendor_navigator.dart';
import 'package:dym_gallery/demo/demo_vendor_orders.dart';
import 'package:dym_gallery/screens/s01_splash.dart';
import 'package:dym_gallery/screens/s02_home.dart';
import 'package:dym_gallery/screens/s03_aisle.dart';
import 'package:dym_gallery/screens/s04_store.dart';
import 'package:dym_gallery/screens/s05_cart.dart';
import 'package:dym_gallery/screens/s06_tracking.dart';
import 'package:dym_gallery/screens/s07_seller_origin.dart';
import 'package:dym_gallery/screens/s08_seller_new_order.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/features/catalog/categories/store_categories_view.dart';
import 'package:dym_vendor/features/catalog/editor/product_editor_view.dart';
import 'package:dym_vendor/features/dashboard/dashboard_view.dart';
import 'package:dym_vendor/features/orders/orders_views.dart';
import 'package:dym_vendor/features/reviews/reviews_view.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_view.dart';
import 'package:dym_vendor/features/store/opened/store_opened_view.dart';
import 'package:dym_vendor/ui/views/home/home_view.dart';
import 'package:flutter/material.dart';

/// Écran validé et sa reproduction avec dym_ui.
@immutable
class ReferenceScreen {
  const new({
    required this.id,
    required this.title,
    required this.surface,
    required this.referenceFile,
    required this.builder,
  });

  final String id;
  final String title;
  final String surface;
  final String referenceFile;
  final Widget Function(DemoCountry country) builder;
}

final referenceScreens = <ReferenceScreen>[
  ReferenceScreen(
    id: '01',
    title: 'Splash',
    surface: 'Cliente',
    referenceFile: '01-splash.webp',
    builder: (c) => SplashScreen(country: c),
  ),
  ReferenceScreen(
    id: '02',
    title: 'Accueil',
    surface: 'Cliente',
    referenceFile: '02-accueil.webp',
    builder: (c) => HomeScreen(country: c),
  ),
  ReferenceScreen(
    id: '03',
    title: 'Rayon Légumes',
    surface: 'Cliente',
    referenceFile: '03-rayon-legumes.webp',
    builder: (c) => AisleScreen(country: c),
  ),
  ReferenceScreen(
    id: '04',
    title: "Page boutique · Les jus d'Esi",
    surface: 'Cliente',
    referenceFile: '04-page-boutique.webp',
    builder: (c) => StoreScreen(country: c),
  ),
  ReferenceScreen(
    id: '05',
    title: 'Panier multi-boutiques',
    surface: 'Cliente',
    referenceFile: '05-panier.webp',
    builder: (c) => CartScreen(country: c),
  ),
  ReferenceScreen(
    id: '06',
    title: 'Suivi de livraison',
    surface: 'Cliente',
    referenceFile: '06-suivi.webp',
    builder: (c) => TrackingScreen(country: c),
  ),
  ReferenceScreen(
    id: '07',
    title: 'Où vends-tu ?',
    surface: 'Vendeuse',
    referenceFile: '07-vendeuse-ou-vends-tu.webp',
    builder: (c) => SellerOriginScreen(country: c),
  ),
  ReferenceScreen(
    id: '08',
    title: 'Commande reçue',
    surface: 'Vendeuse',
    referenceFile: '08-vendeuse-commande-recue.webp',
    builder: (c) => SellerNewOrderScreen(country: c),
  ),
  // Spec 005 : connexion et compte (maquettes générées dans la direction
  // validée, à valider par le porteur produit).
  ReferenceScreen(
    id: '09',
    title: 'Bienvenue',
    surface: 'Cliente',
    referenceFile: '09-bienvenue.webp',
    builder: (c) => AuthFlowView(
      service: DemoAuthService(country: c),
      onReady: (_) {},
    ),
  ),
  ReferenceScreen(
    id: '10',
    title: 'Ton email',
    surface: 'Cliente',
    referenceFile: '10-email.webp',
    builder: (c) => AuthFlowView(
      service: DemoAuthService(country: c),
      onReady: (_) {},
      initialStep: AuthStep.email,
      initialEmail: 'awa.mensah@gmail.com',
    ),
  ),
  ReferenceScreen(
    id: '11',
    title: 'Code reçu par email',
    surface: 'Cliente',
    referenceFile: '11-code.webp',
    builder: (c) => AuthFlowView(
      service: DemoAuthService(country: c),
      onReady: (_) {},
      initialStep: AuthStep.code,
      initialEmail: 'awa.mensah@gmail.com',
    ),
  ),
  ReferenceScreen(
    id: '12',
    title: 'Prénom et quartier',
    surface: 'Cliente',
    referenceFile: '12-prenom-quartier.webp',
    builder: (c) => AuthFlowView(
      service: DemoAuthService(country: c),
      onReady: (_) {},
      startWithProfile: true,
    ),
  ),
  ReferenceScreen(
    id: '13',
    title: 'Moi et suppression du compte',
    surface: 'Cliente',
    referenceFile: '13-compte-suppression.webp',
    builder: (c) => AccountView(
      service: DemoAuthService(country: c),
      onSignedOut: () {},
    ),
  ),
  ReferenceScreen(
    id: '14',
    title: 'Connexion vendeuse',
    surface: 'Vendeuse',
    referenceFile: '14-vendeuse-connexion.webp',
    builder: (c) => AuthFlowView(
      service: DemoAuthService(country: c, app: AccountApp.vendor),
      onReady: (_) {},
      variant: AuthVariant.vendor,
    ),
  ),
  // Spec 006 : onboarding et réglages de la boutique (maquettes générées
  // dans la direction validée, à valider).
  for (final (id, step, title, file) in const [
    ('16', 1, 'Nom de la boutique', '16-boutique-nom.webp'),
    ('17', 3, 'Adresse de ramassage', '17-boutique-adresse.webp'),
    ('18', 4, 'Rayon principal', '18-boutique-rayon.webp'),
    ('19', 5, 'Livraison et préparation', '19-boutique-livraison.webp'),
    ('20', 6, 'Moyens de paiement', '20-boutique-paiement.webp'),
    ('21', 7, 'Horaires', '21-boutique-horaires.webp'),
  ])
    ReferenceScreen(
      id: id,
      title: title,
      surface: 'Vendeuse',
      referenceFile: file,
      builder: (c) => StoreOnboardingView(
        service: DemoStore.service(c, step: step),
        onOpened: (_, _) {},
      ),
    ),
  ReferenceScreen(
    id: '22',
    title: 'Boutique ouverte',
    surface: 'Vendeuse',
    referenceFile: '22-boutique-ouverte.webp',
    builder: (c) => StoreOpenedView(
      store: DemoStore.store(c),
      config: DemoStore.config(c),
      onSeeStore: () {},
      onAddProduct: () {},
    ),
  ),
  ReferenceScreen(
    id: '23',
    title: 'Ma boutique',
    surface: 'Vendeuse',
    referenceFile: '23-boutique-reglages.webp',
    builder: (c) => HomeView(
      service: DemoAuthService(country: c, app: AccountApp.vendor),
      stores: DemoStore.service(c),
      catalog: DemoVendorCatalog.service(c),
      navigator: DemoVendorNavigator(),
      initialTab: HomeTab.store,
    ),
  ),
  // Spec 007 : catalogue de la vendeuse (maquettes à valider).
  ReferenceScreen(
    id: '24',
    title: 'Mes produits',
    surface: 'Vendeuse',
    referenceFile: '24-produits.webp',
    builder: (c) => HomeView(
      service: DemoAuthService(country: c, app: AccountApp.vendor),
      stores: DemoStore.service(c),
      catalog: DemoVendorCatalog.service(c),
      navigator: DemoVendorNavigator(),
      initialTab: HomeTab.products,
    ),
  ),
  ReferenceScreen(
    id: '25',
    title: 'Nouveau produit · photo',
    surface: 'Vendeuse',
    referenceFile: '25-produit-photo.webp',
    builder: (c) => ProductEditorView(
      service: DemoVendorCatalog.service(c),
      initialSource: PhotoSource.camera,
      onDone: (_) {},
      onCancel: () {},
    ),
  ),
  ReferenceScreen(
    id: '26',
    title: 'Prix et stock',
    surface: 'Vendeuse',
    referenceFile: '26-produit-prix.webp',
    builder: (c) => ProductEditorView(
      service: DemoVendorCatalog.service(c),
      product: DemoVendorCatalog.products(c).first,
      initialStep: 2,
      onDone: (_) {},
      onCancel: () {},
    ),
  ),
  ReferenceScreen(
    id: '27',
    title: 'Mes catégories',
    surface: 'Vendeuse',
    referenceFile: '27-categories.webp',
    builder: (c) => StoreCategoriesView(
      service: DemoVendorCatalog.service(c),
      onBack: () {},
    ),
  ),
  // Spec 008 : découverte côté cliente. 28 à 30 sont à valider ; 31 à 33
  // sont les vrais écrans, comparés aux maquettes validées 02 à 04.
  ReferenceScreen(
    id: '28',
    title: 'Fiche produit',
    surface: 'Cliente',
    referenceFile: '28-fiche-produit.webp',
    builder: (c) => ProductPageView(
      service: DemoDiscovery.service(c),
      productId: 'bissap',
      onBack: () {},
      onOpenStore: (_) {},
    ),
  ),
  ReferenceScreen(
    id: '29',
    title: 'Recherche',
    surface: 'Cliente',
    referenceFile: '29-recherche.webp',
    builder: (c) => SearchView(
      service: DemoDiscovery.service(c),
      initialText: 'jus',
      onBack: () {},
      onOpenProduct: (_) {},
      onOpenStore: (_) {},
    ),
  ),
  ReferenceScreen(
    id: '71',
    title: 'Recherche vocale',
    surface: 'Cliente',
    referenceFile: '71-recherche-vocale.webp',
    builder: (c) => VoiceSearchView(
      service: MemorySearchAiService(
        recorder: MemoryVoiceRecorder(
          script: const [
            0.2, 0.3, 0.5, 0.4, 0.6, 0.7, 0.5, 0.8, 0.9, 1, 0.8, 1, //
            0.9, 1, 0.8, 0.9, 0.7, 0.6, 0.8, 0.5, 0.6, 0.4, 0.3, 0.2,
          ],
        ),
      ),
      listenFor: const Duration(milliseconds: 100),
      onBack: () {},
      onSearch: (_, _) {},
    ),
  ),
  ReferenceScreen(
    id: '72',
    title: 'Recherche par photo',
    surface: 'Cliente',
    referenceFile: '72-recherche-photo.webp',
    builder: (c) => SearchView(
      service: DemoDiscovery.service(c),
      ai: MemorySearchAiService(seen: 'gombo'),
      initialPhoto: PhotoSource.gallery,
      onBack: () {},
      onOpenProduct: (_) {},
      onOpenStore: (_) {},
    ),
  ),
  ReferenceScreen(
    id: '73',
    title: 'Copilote d’intention',
    surface: 'Cliente',
    referenceFile: '73-copilote-intention.webp',
    builder: (c) => CopilotView(
      service: MemoryCopilotService(
        discovery: DemoDiscovery.service(c),
        proposal: _copilotProposal(c),
      ),
      ai: MemorySearchAiService(),
      initialText: 'Une sauce gombo pour 4 personnes ce soir',
      onBack: () {},
      onSearchMyself: (_) {},
      onAdded: () {},
    ),
  ),
  ReferenceScreen(
    id: '30',
    title: 'Filtres',
    surface: 'Cliente',
    referenceFile: '30-filtres.webp',
    builder: (c) => Builder(
      builder: (context) => ColoredBox(
        color: const Color(0x66000000),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: SearchFiltersSheet(
                config: DemoStore.config(c),
                initial: const SearchFilters(origin: 'maison'),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
  ReferenceScreen(
    id: '31',
    title: 'Accueil (app)',
    surface: 'Cliente',
    referenceFile: '02-accueil.webp',
    builder: (c) => client.HomeView(
      service: DemoAuthService(country: c),
      discovery: DemoDiscovery.service(c),
      navigator: DemoClientNavigator(),
    ),
  ),
  ReferenceScreen(
    id: '32',
    title: 'Rayon Légumes (app)',
    surface: 'Cliente',
    referenceFile: '03-rayon-legumes.webp',
    builder: (c) => AisleView(
      service: DemoDiscovery.service(c),
      categoryId: 'legumes',
      onBack: () {},
      onSearch: () {},
      onOpenProduct: (_) {},
    ),
  ),
  ReferenceScreen(
    id: '33',
    title: "Page boutique (app) · Les jus d'Esi",
    surface: 'Cliente',
    referenceFile: '04-page-boutique.webp',
    builder: (c) => StorePageView(
      service: DemoDiscovery.service(c),
      storeId: 'esi',
      onBack: () {},
      onOpenProduct: (_) {},
    ),
  ),
  ReferenceScreen(
    id: '34',
    title: 'Livraison',
    surface: 'Cliente',
    referenceFile: '34-livraison.webp',
    builder: (c) => DeliveryView(
      service: DemoCheckout.service(c),
      onBack: () {},
      onAddAddress: () async => false,
    ),
  ),
  ReferenceScreen(
    id: '35',
    title: 'Mes adresses',
    surface: 'Cliente',
    referenceFile: '35-mes-adresses.webp',
    builder: (c) => AddressesView(
      service: DemoCheckout.service(c),
      onBack: () {},
      onEdit: (_) async => false,
    ),
  ),
  ReferenceScreen(
    id: '36',
    title: 'Nouvelle adresse',
    surface: 'Cliente',
    referenceFile: '36-nouvelle-adresse.webp',
    builder: (c) => AddressFormView(
      service: DemoCheckout.service(c, addresses: const []),
      onDone: (_) {},
    ),
  ),
  ReferenceScreen(
    id: '37',
    title: 'Commande envoyée',
    surface: 'Cliente',
    referenceFile: '37-commande-envoyee.webp',
    builder: (c) => FutureBuilder(
      future: DemoCheckout.purchase(c),
      builder: (context, snapshot) => snapshot.data == null
          ? const SizedBox.shrink()
          : OrderSentView(
              service: DemoCheckout.service(c),
              purchase: snapshot.data!,
              onHome: () {},
            ),
    ),
  ),
  ReferenceScreen(
    id: '38',
    title: 'Panier (app)',
    surface: 'Cliente',
    referenceFile: '05-panier.webp',
    builder: (c) => CartPageView(
      service: DemoCheckout.service(c),
      onBack: () {},
      onDelivery: () {},
      onOrdered: (_) {},
      onBrowse: () {},
    ),
  ),
  for (final (id, title, file, failed) in const [
    ('39', 'Paiement en cours', '39-paiement-en-cours.webp', false),
    ('40', 'Paiement échoué', '40-paiement-echoue.webp', true),
  ])
    ReferenceScreen(
      id: id,
      title: title,
      surface: 'Cliente',
      referenceFile: file,
      builder: (c) => FutureBuilder(
        future: DemoCheckout.online(c, failed: failed),
        builder: (context, snapshot) => snapshot.data == null
            ? const SizedBox.shrink()
            : PaymentView(
                service: snapshot.data!.$1,
                purchase: snapshot.data!.$2,
                onSettled: (_) {},
                onBack: () {},
                openAtStart: false,
              ),
      ),
    ),
  ReferenceScreen(
    id: '41',
    title: 'Commandes (vendeuse)',
    surface: 'Vendeuse',
    referenceFile: '41-vendeuse-commandes.webp',
    builder: (c) => Scaffold(
      body: OrdersView(service: DemoVendorOrders.service(c), onOpen: (_) {}),
    ),
  ),
  ReferenceScreen(
    id: '42',
    title: 'Détail du paiement (vendeuse)',
    surface: 'Vendeuse',
    referenceFile: '42-vendeuse-detail-paiement.webp',
    builder: (c) => OrderDetailView(
      service: DemoVendorOrders.service(c),
      orderId: 'o3',
      onBack: () {},
    ),
  ),
  ReferenceScreen(
    id: '43',
    title: 'Mes commandes',
    surface: 'Cliente',
    referenceFile: '43-mes-commandes.webp',
    builder: (c) => Scaffold(
      body: client_orders.MyOrdersView(
        service: DemoClientOrders.service(c),
        onOpen: (_) {},
        onNotifications: () {},
      ),
    ),
  ),
  ReferenceScreen(
    id: '44',
    title: 'Notifications',
    surface: 'Cliente',
    referenceFile: '44-notifications.webp',
    builder: (c) => client_orders.NotificationsView(
      service: DemoClientOrders.service(c),
      onBack: () {},
      onOpenOrder: (_) {},
      clock: () => DemoClientOrders.now,
    ),
  ),
  ReferenceScreen(
    id: '45',
    title: 'Refus de commande (vendeuse)',
    surface: 'Vendeuse',
    referenceFile: '45-vendeuse-refus.webp',
    builder: (c) => Builder(
      builder: (context) => ColoredBox(
        color: const Color(0x66000000),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: const Padding(
              padding: EdgeInsets.only(top: 24),
              child: RefusalSheet(),
            ),
          ),
        ),
      ),
    ),
  ),
  ReferenceScreen(
    id: '46',
    title: 'Réglages des notifications',
    surface: 'Cliente',
    referenceFile: '46-parametres-notifications.webp',
    builder: (c) => client_orders.NotificationSettingsView(
      service: DemoClientOrders.service(c),
      onBack: () {},
    ),
  ),
  ReferenceScreen(
    id: '47',
    title: 'Suivi (app)',
    surface: 'Cliente',
    referenceFile: '06-suivi.webp',
    builder: (c) => client_orders.TrackingView(
      service: DemoClientOrders.service(c),
      orderId: 'o2',
      onBack: () {},
    ),
  ),
  ReferenceScreen(
    id: '48',
    title: 'Nouvelle commande (app vendeuse)',
    surface: 'Vendeuse',
    referenceFile: '08-vendeuse-commande-recue.webp',
    builder: (c) => OrderDetailView(
      service: DemoVendorOrders.service(c),
      orderId: 'o1',
      onBack: () {},
    ),
  ),
  ReferenceScreen(
    id: '49',
    title: 'Signaler un problème',
    surface: 'Cliente',
    referenceFile: '49-signaler-probleme.webp',
    builder: (c) => ReportProblemView(
      service: DemoClientOrders.service(c),
      orderId: 'o3',
      storeName: "Étal d'Akossiwa",
      onBack: () {},
      onSent: (_) {},
    ),
  ),
  ReferenceScreen(
    id: '50',
    title: 'Mon signalement',
    surface: 'Cliente',
    referenceFile: '50-litige-cliente.webp',
    builder: (c) => DisputeView(
      service: DemoClientOrders.disputed(c),
      orderId: 'o3',
      onBack: () {},
      clock: () => DemoClientOrders.now,
    ),
  ),
  ReferenceScreen(
    id: '51',
    title: 'Problème signalé (vendeuse)',
    surface: 'Vendeuse',
    referenceFile: '51-vendeuse-litige.webp',
    builder: (c) => OrderDetailView(
      service: DemoVendorOrders.disputed(c),
      orderId: 'o5',
      onBack: () {},
    ),
  ),
  ReferenceScreen(
    id: '52',
    title: 'Commandes (admin)',
    surface: 'Admin',
    referenceFile: '52-admin-commandes.webp',
    builder: (c) => Scaffold(
      body: admin.AdminOrdersView(
        service: _admin(c),
        onOpen: (_) {},
        clock: _adminNow,
      ),
    ),
  ),
  ReferenceScreen(
    id: '53',
    title: 'Détail d’une commande (admin)',
    surface: 'Admin',
    referenceFile: '53-admin-commande.webp',
    builder: (c) => Scaffold(
      body: admin.AdminOrderView(
        service: _admin(c),
        orderId: 'o1',
        onBack: () {},
        clock: _adminNow,
      ),
    ),
  ),
  ReferenceScreen(
    id: '54',
    title: 'Litiges (admin)',
    surface: 'Admin',
    referenceFile: '54-admin-litige.webp',
    builder: (c) => Scaffold(
      body: admin.AdminDisputesView(
        service: _admin(c),
        initialId: 'd1',
        clock: _adminNow,
      ),
    ),
  ),
  ReferenceScreen(
    id: '55',
    title: 'Boutiques (admin)',
    surface: 'Admin',
    referenceFile: '55-admin-boutiques.webp',
    builder: (c) => Scaffold(body: AdminStoresView(service: _admin(c))),
  ),
  ReferenceScreen(
    id: '56',
    title: 'Réglages (admin)',
    surface: 'Admin',
    referenceFile: '56-admin-reglages.webp',
    builder: (c) => Scaffold(body: AdminSettingsView(service: _admin(c))),
  ),
  ReferenceScreen(
    id: '57',
    title: 'Finances (admin)',
    surface: 'Admin',
    referenceFile: '57-admin-finances.webp',
    builder: (c) => Scaffold(
      body: AdminFinanceView(
        service: _admin(c),
        clock: _adminNow,
        initialSection: FinanceSection.refunds,
      ),
    ),
  ),
  ReferenceScreen(
    id: '58',
    title: 'Journal d’audit (admin)',
    surface: 'Admin',
    referenceFile: '58-admin-journal.webp',
    builder: (c) => Scaffold(body: AdminAuditView(service: _admin(c))),
  ),
  ReferenceScreen(
    id: '59',
    title: 'Ma journée (vendeuse)',
    surface: 'Vendeuse',
    referenceFile: '59-vendeuse-tableau-de-bord.webp',
    builder: (c) => Scaffold(
      body: DashboardView(
        service: DemoDashboardService(c),
        onOrders: () {},
        onProducts: () {},
        onMessages: () {},
      ),
    ),
  ),
  ReferenceScreen(
    id: '60',
    title: 'Conversation (cliente)',
    surface: 'Cliente',
    referenceFile: '60-cliente-conversation.webp',
    builder: (c) => ChatView(
      service: _chat(c, ChatRole.client),
      conversationId: 'c1',
      onBack: () {},
      onAddToCart: (_) async {},
      clock: _chatNow,
      refreshEvery: null,
    ),
  ),
  ReferenceScreen(
    id: '61',
    title: 'Messages (vendeuse)',
    surface: 'Vendeuse',
    referenceFile: '61-vendeuse-messages.webp',
    builder: (c) => Scaffold(
      body: ConversationsView(
        service: _chat(c, ChatRole.vendor),
        onOpen: (_) {},
        clock: _chatNow,
        refreshEvery: null,
      ),
    ),
  ),
  ReferenceScreen(
    id: '62',
    title: 'Conversation et partage (vendeuse)',
    surface: 'Vendeuse',
    referenceFile: '62-vendeuse-conversation.webp',
    builder: (c) => ChatView(
      service: _chat(c, ChatRole.vendor),
      conversationId: 'c1',
      onBack: () {},
      pickProduct: (_) async => null,
      clock: _chatNow,
      refreshEvery: null,
    ),
  ),
  ReferenceScreen(
    id: '63',
    title: 'Laisser un avis',
    surface: 'Cliente',
    referenceFile: '63-cliente-laisser-avis.webp',
    builder: (c) => ReviewFormView(
      service: DemoClientOrders.service(c),
      orderId: 'o3',
      storeName: "Étal d'Akossiwa",
      onBack: () {},
      onSent: (_) {},
    ),
  ),
  ReferenceScreen(
    id: '64',
    title: 'Avis d’une boutique',
    surface: 'Cliente',
    referenceFile: '64-cliente-avis-boutique.webp',
    builder: (c) => StoreReviewsView(
      service: DemoDiscovery.service(c),
      storeId: 'esi',
      storeName: "Les jus d'Esi",
      onBack: () {},
      onMessage: () {},
      clock: _chatNow,
    ),
  ),
  ReferenceScreen(
    id: '65',
    title: 'Mes avis (vendeuse)',
    surface: 'Vendeuse',
    referenceFile: '65-vendeuse-avis.webp',
    builder: (c) => VendorReviewsView(
      service: MemoryVendorReviewsService(DemoDiscovery.reviews()),
      onBack: () {},
      clock: _chatNow,
    ),
  ),
  ReferenceScreen(
    id: '66',
    title: 'Aide',
    surface: 'Cliente',
    referenceFile: '66-aide-support.webp',
    builder: (c) => SupportView(
      service: MemorySupportService(
        orders: const [(id: 'o3', label: "7K2Q4F1A · Étal d'Akossiwa")],
        tickets: [
          SupportTicket(
            id: 't1',
            app: 'client',
            subject: TicketSubject.order,
            status: TicketStatus.open,
            createdAt: DateTime.utc(2026, 10, 5, 10, 40),
            lastActivityAt: DateTime.utc(2026, 10, 5, 10, 40),
            messages: [
              TicketMessage(
                id: 'm0',
                authorRole: 'user',
                body: 'Je n’ai pas reçu ma monnaie',
                createdAt: DateTime.utc(2026, 10, 5, 10, 40),
              ),
            ],
          ),
          SupportTicket(
            id: 't0',
            app: 'client',
            subject: TicketSubject.account,
            status: TicketStatus.closed,
            createdAt: DateTime.utc(2026, 10, 3),
            lastActivityAt: DateTime.utc(2026, 10, 3),
            messages: [
              TicketMessage(
                id: 'm1',
                authorRole: 'user',
                body: 'Changer mon adresse',
                createdAt: DateTime.utc(2026, 10, 3),
              ),
            ],
          ),
        ],
      ),
      onBack: () {},
      clock: _chatNow,
    ),
  ),
  ReferenceScreen(
    id: '67',
    title: 'Tableau de bord (admin)',
    surface: 'Admin',
    referenceFile: '67-admin-tableau-de-bord.webp',
    builder: (c) => Scaffold(
      body: AdminDashboardView(service: _admin(c), onOpen: (_) {}),
    ),
  ),
  ReferenceScreen(
    id: '68',
    title: 'Clientes (admin)',
    surface: 'Admin',
    referenceFile: '68-admin-cliente.webp',
    builder: (c) => Scaffold(
      body: AdminClientsView(
        service: _admin(c),
        clock: _adminNow,
        initialId: 'u1',
      ),
    ),
  ),
  ReferenceScreen(
    id: '69',
    title: 'Support (admin)',
    surface: 'Admin',
    referenceFile: '69-admin-support.webp',
    builder: (c) => Scaffold(
      body: AdminSupportView(
        service: _admin(c),
        clock: _adminNow,
        initialId: 't1',
      ),
    ),
  ),
  ReferenceScreen(
    id: '70',
    title: 'Revenus (admin)',
    surface: 'Admin',
    referenceFile: '70-admin-revenus.webp',
    builder: (c) => Scaffold(
      body: AdminFinanceView(service: _admin(c), clock: _adminNow),
    ),
  ),
];

/// Messagerie de démonstration (photos de produits de la galerie).
MemoryChatService _chat(DemoCountry c, ChatRole role) => MemoryChatService.demo(
  role: role,
  config: DemoStore.config(c),
  photoImage: DemoImages.product('gombo'),
  productImage: DemoImages.product('gombo'),
);

DateTime _chatNow() => DateTime.utc(2026, 10, 5, 11);

/// Admin de démonstration (lieux génériques), dans la devise du pays.
admin.MemoryAdminService _admin(DemoCountry c) =>
    admin.MemoryAdminService(currency: c.currency);

DateTime _adminNow() => DateTime.utc(2026, 10, 5, 11);

/// Panier proposé de démonstration (écran 73), aux prix du pays.
CopilotProposal _copilotProposal(DemoCountry c) {
  CopilotLine line(
    String store,
    String id,
    String name,
    int qty,
    int xof, [
    String unitLabel = 'tas',
  ]) {
    final unit = c.price(xof).amountMinor;
    return CopilotLine(
      variantId: '$id-v',
      productId: id,
      name: name,
      quantity: qty,
      unitLabel: unitLabel,
      unitPriceMinor: unit,
      lineMinor: qty * unit,
      photoKey: 'stores/$store/products/$id.jpg',
    );
  }

  final stores = [
    CopilotStoreLines(
      id: 'akossiwa',
      name: "Étal d'Akossiwa",
      lines: [
        line('akossiwa', 'gombo', 'Gombo frais', 2, 300),
        line('akossiwa', 'tomates', 'Tomates fraîches', 1, 500),
        line('akossiwa', 'piment', 'Piment frais', 1, 400),
      ],
    ),
    CopilotStoreLines(
      id: 'afi',
      name: 'Chez Afi',
      lines: [
        line('afi', 'huile-rouge', 'Huile rouge', 1, 1200, 'bouteille'),
        line('afi', 'poisson-fume', 'Poisson fumé', 1, 1500, 'pièce'),
      ],
    ),
  ];
  return CopilotProposal(
    currencyCode: c.currency.code,
    totalMinor: stores
        .expand((s) => s.lines)
        .fold(0, (sum, l) => sum + l.lineMinor),
    stores: stores,
    missing: const ['Crevettes séchées'],
  );
}
