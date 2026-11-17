import 'dart:async';

import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_order_live/dym_order_live.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/app/app.router.dart';
import 'package:dym_vendor/features/broadcast/broadcast_view.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/catalog/categories/store_categories_view.dart';
import 'package:dym_vendor/features/catalog/editor/product_editor_view.dart';
import 'package:dym_vendor/features/catalog/import/import_products_view.dart';
import 'package:dym_vendor/features/content/contents_views.dart';
import 'package:dym_vendor/features/credit/credit_service.dart';
import 'package:dym_vendor/features/credit/credit_views.dart';
import 'package:dym_vendor/features/group_buy/group_offers_view.dart';
import 'package:dym_vendor/features/haggle/haggling_view.dart';
import 'package:dym_vendor/features/orders/adjustments_panel.dart';
import 'package:dym_vendor/features/orders/courier_cash_view.dart';
import 'package:dym_vendor/features/orders/couriers_view.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:dym_vendor/features/orders/orders_views.dart';
import 'package:dym_vendor/features/reviews/reviews_view.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_view.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_viewmodel.dart';
import 'package:dym_vendor/features/store/opened/store_opened_view.dart';
import 'package:dym_vendor/features/store/staff/staff_view.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:dym_vendor/features/till/end_of_market_view.dart';
import 'package:dym_vendor/features/till/qr_charge_view.dart';
import 'package:dym_vendor/features/till/till_service.dart';
import 'package:dym_vendor/features/till/till_view.dart';
import 'package:dym_vendor/features/wholesale/wholesale_view.dart';
import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

/// Navigation de l'app, remplaçable en test.
abstract interface class AppNavigator {
  void toSignIn({bool startWithProfile = false});

  /// Démarrage : session, profil puis boutique décident de la suite.
  void toStartup();

  void toHome();

  /// Onboarding de la boutique (absente ou en brouillon).
  void toStoreOnboarding();

  void toStoreOpened(MyStore store, CountryConfig config);

  /// Réglage d'une étape ; se termine au retour.
  Future<void> toStoreSetting(StoreStep step);

  /// Premier produit, depuis l'écran de réussite : l'éditeur, puis
  /// l'accueil.
  void toAddProduct();

  /// Éditeur d'un produit (`null` : nouveau) ; se termine au retour.
  Future<void> toProductEditor({Product? product});

  /// « Mes catégories » ; se termine au retour.
  Future<void> toStoreCategories();

  /// Import en masse du catalogue (spec 081).
  Future<void> toImportProducts();

  /// Détail d'une commande (écran 42).
  void toOrder(String orderId);

  /// Conversation avec une cliente (écran 62).
  void toChat(String conversationId);

  /// Mes avis (écran 65).
  void toReviews();

  /// Cash encaissé pour la boutique par les livreurs DYM (spec 043).
  void toCourierCash();

  /// « Ma caisse » (spec 045).
  void toTill();

  /// « Encaisser » (planche 04) : QR ou code, sans passer par la caisse.
  void toCharge();

  /// « Mon compte », rangé dans Boutique (design « Épuré »).
  void toAccount();

  /// Équipe de la boutique (spec 087).
  void toStaff();

  /// Livreurs de la boutique (spec 096).
  void toStoreCouriers();

  /// Ardoise (spec 047).
  void toCredit();

  /// Partage de la boutique et fin de marché (spec 048).
  void toStudio();

  /// Achat de gros groupé (spec 049).
  void toWholesale();

  /// Marchandage (spec 050).
  void toHaggling();

  /// Offres groupées entre voisines clientes (spec 051).
  void toGroupOffers();

  /// Vendeuse Pro et visibilité (spec 052).
  void toMembership();

  /// Aide (écran 66).
  void toHelp();

  /// Mes contenus et publication (écran 75, spec 020).
  void toContents();

  /// Publier un statut directement (raccourci de l'accueil, spec 077).
  void toPublishStatus();

  /// Relance des clientes et stock bas (écran 78, spec 021).
  void toBroadcast();
}

/// Navigation Stacked (pile vidée : on ne revient pas en arrière après la
/// connexion, la déconnexion ou l'ouverture de la boutique).
class StackedAppNavigator implements AppNavigator {
  new([
    NavigationService? navigation,
    StoreService? stores,
    CatalogService? catalog,
    ChatService? chat,
    VendorReviewsService? reviews,
    SupportService? support,
    VendorContentService? contents,
    VendorBroadcastService? broadcasts,
  ]) : _broadcasts =
           broadcasts ??
           (locator.isRegistered<VendorBroadcastService>()
               ? locator<VendorBroadcastService>()
               : null),
       _contents =
           contents ??
           (locator.isRegistered<VendorContentService>()
               ? locator<VendorContentService>()
               : null),
       _reviews = reviews ?? locator<VendorReviewsService>(),
       _support = support ?? locator<SupportService>(),
       _navigation = navigation ?? locator<NavigationService>(),
       _stores = stores ?? locator<StoreService>(),
       _catalog = catalog ?? locator<CatalogService>(),
       _chat = chat ?? locator<ChatService>();

  final NavigationService _navigation;
  final StoreService _stores;
  final CatalogService _catalog;
  final ChatService _chat;
  final VendorReviewsService _reviews;
  final SupportService _support;
  final VendorContentService? _contents;
  final VendorBroadcastService? _broadcasts;

  @override
  void toBroadcast() {
    final broadcasts = _broadcasts;
    if (broadcasts == null) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (_) =>
            BroadcastView(service: broadcasts, onBack: () => _navigator.pop()),
      ),
    );
  }

  @override
  void toPublishStatus() {
    final contents = _contents;
    if (contents == null) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (route) => PublishContentView(
          service: contents,
          onBack: () => Navigator.of(route).pop(),
          onPublished: () => Navigator.of(route).pop(),
        ),
      ),
    );
  }

  @override
  void toContents() {
    final contents = _contents;
    if (contents == null) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => MyContentsView(
          service: contents,
          onBack: () => _navigator.pop(),
          onPublish: () => _navigator.push<void>(
            MaterialPageRoute(
              builder: (route) => PublishContentView(
                service: contents,
                onBack: () => Navigator.of(route).pop(),
                onPublished: () => Navigator.of(route).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void toReviews() => _navigator.push<void>(
    MaterialPageRoute(
      builder: (_) =>
          VendorReviewsView(service: _reviews, onBack: () => _navigator.pop()),
    ),
  );

  @override
  void toMembership() {
    if (!locator.isRegistered<MembershipService>()) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (context) => MembershipView(
          service: locator<MembershipService>(),
          title: DymLocalizations.of(context).membershipVendorTitle,
          onBack: () => _navigator.pop(),
        ),
      ),
    );
  }

  @override
  void toGroupOffers() {
    if (!locator.isRegistered<GroupOffersService>()) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => GroupOffersView(
          service: locator<GroupOffersService>(),
          onBack: () => _navigator.pop(),
        ),
      ),
    );
  }

  @override
  void toHaggling() {
    if (!locator.isRegistered<HagglingService>()) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => HagglingView(
          service: locator<HagglingService>(),
          onBack: () => _navigator.pop(),
        ),
      ),
    );
  }

  @override
  void toWholesale() {
    if (!locator.isRegistered<WholesaleService>()) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => WholesaleView(
          service: locator<WholesaleService>(),
          onBack: () => _navigator.pop(),
        ),
      ),
    );
  }

  @override
  void toStudio() {
    if (!locator.isRegistered<TillService>()) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => EndOfMarketView(
          service: locator<TillService>(),
          onBack: () => _navigator.pop(),
        ),
      ),
    );
  }

  @override
  void toCredit() {
    if (!locator.isRegistered<CreditService>()) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => CreditView(
          service: locator<CreditService>(),
          onBack: () => _navigator.pop(),
        ),
      ),
    );
  }

  @override
  void toTill() {
    if (!locator.isRegistered<TillService>()) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => TillView(
          service: locator<TillService>(),
          onBack: () => _navigator.pop(),
          onQr: () async => await _navigator.push<void>(
            MaterialPageRoute(
              builder: (route) => QrChargeView(
                service: locator<TillService>(),
                onDone: () => Navigator.of(route).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void toCharge() {
    if (!locator.isRegistered<TillService>()) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (route) => QrChargeView(
          service: locator<TillService>(),
          onDone: () => Navigator.of(route).pop(),
        ),
      ),
    );
  }

  @override
  void toStoreCouriers() => _navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => StoreCouriersView(service: locator<OrdersService>()),
    ),
  );

  @override
  void toStaff() => _navigator.push<void>(
    MaterialPageRoute(
      builder: (route) => Scaffold(
        appBar: AppBar(),
        body: StaffView(service: locator<StoreService>()),
      ),
    ),
  );

  @override
  void toAccount() => _navigator.push<void>(
    MaterialPageRoute(
      builder: (route) => Scaffold(
        appBar: AppBar(),
        body: AccountView(
          service: locator<AuthService>(),
          onSignedOut: toSignIn,
          onHelp: toHelp,
        ),
      ),
    ),
  );

  @override
  void toCourierCash() {
    if (!locator.isRegistered<CourierCashService>()) return;
    _navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => CourierCashView(
          service: locator<CourierCashService>(),
          onBack: () => _navigator.pop(),
        ),
      ),
    );
  }

  @override
  void toHelp() => _navigator.push<void>(
    MaterialPageRoute(
      builder: (_) =>
          SupportView(service: _support, onBack: () => _navigator.pop()),
    ),
  );

  NavigatorState get _navigator => StackedService.navigatorKey!.currentState!;

  void _replaceAll(Widget view) => _navigator.pushAndRemoveUntil<void>(
    MaterialPageRoute(builder: (_) => view),
    (_) => false,
  );

  @override
  void toSignIn({bool startWithProfile = false}) =>
      _navigation.clearStackAndShow<void>(
        Routes.signInView,
        arguments: SignInViewArguments(startWithProfile: startWithProfile),
      );

  @override
  void toStartup() => _navigation.clearStackAndShow<void>(Routes.startupView);

  @override
  void toHome() => _navigation.clearStackAndShow<void>(Routes.homeView);

  @override
  void toStoreOnboarding() => _replaceAll(
    StoreOnboardingView(service: _stores, onOpened: toStoreOpened),
  );

  @override
  void toStoreOpened(MyStore store, CountryConfig config) => _replaceAll(
    StoreOpenedView(
      store: store,
      config: config,
      onSeeStore: toHome,
      onAddProduct: toAddProduct,
    ),
  );

  @override
  Future<void> toStoreSetting(StoreStep step) => _navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => StoreOnboardingView(
        service: _stores,
        editStep: step,
        onOpened: (_, _) => _navigator.pop(),
        onSaved: (_) => _navigator.pop(),
        onCancel: () => _navigator.pop(),
      ),
    ),
  );

  @override
  void toAddProduct() => _navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => ProductEditorView(
        service: _catalog,
        initialSource: PhotoSource.camera,
        onDone: (_) => toHome(),
        onCancel: toHome,
      ),
    ),
  );

  @override
  Future<void> toProductEditor({Product? product}) => _navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => ProductEditorView(
        service: _catalog,
        product: product,
        initialSource: product == null ? PhotoSource.camera : null,
        onDone: (_) => _navigator.pop(),
        onCancel: () => _navigator.pop(),
      ),
    ),
  );

  @override
  Future<void> toImportProducts() => _navigator.push<void>(
    MaterialPageRoute(
      builder: (_) =>
          ImportProductsView(service: _catalog, onBack: () => _navigator.pop()),
    ),
  );

  @override
  Future<void> toStoreCategories() => _navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => StoreCategoriesView(
        service: _catalog,
        onBack: () => _navigator.pop(),
      ),
    ),
  );

  @override
  void toChat(String conversationId) => _navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => ChatView(
        service: _chat,
        conversationId: conversationId,
        onBack: () => _navigator.pop(),
        pickProducts: _pickProducts,
        onOpenOrder: toOrder,
      ),
    ),
  );

  /// Mes produits publiés, proposés au partage (écran 62), un ou plusieurs.
  Future<List<String>?> _pickProducts(BuildContext context, String _) async {
    final products = await _catalog.products();
    final config = await _stores.countryConfig();
    if (!context.mounted) return null;
    final list = products.valueOrNull ?? const <Product>[];
    final currency = config.valueOrNull?.currency;
    return await showProductShareSheet(context, [
      for (final p in list)
        if (p.isPublished)
          ShareableProduct(
            id: p.id,
            name: p.name,
            detail: switch ((p.priceMinor, currency)) {
              (final int minor, final Currency c) => Money(minor, c).format(),
              _ => null,
            },
            photo: p.photoKeys.isEmpty
                ? null
                : _catalog.photo(p.photoKeys.first),
          ),
    ]);
  }

  @override
  void toOrder(String orderId) => _navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => OrderDetailView(
        service: locator<OrdersService>(),
        orderId: orderId,
        onBack: () => _navigator.pop(),
        adjustments: locator.isRegistered<VendorAdjustmentsService>()
            ? locator<VendorAdjustmentsService>()
            : null,
        // Livraison en direct et fil de commande (spec 109).
        live: locator.isRegistered<OrderLiveService>()
            ? locator<OrderLiveService>()
            : null,
        onOrderChat: (orderId) => unawaited(_toOrderChat(orderId)),
      ),
    ),
  );

  /// Fil de la commande : cliente, boutique et livreur (spec 109).
  Future<void> _toOrderChat(String orderId) async {
    if (!locator.isRegistered<ChatService>()) return;
    final result = await locator<ChatService>().orderThread(orderId);
    if (result case Ok(:final value)) toChat(value.id);
  }
}
