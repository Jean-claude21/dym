import 'dart:async';

import 'package:dym_account/dym_account.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/app/app.router.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/catalog/categories/store_categories_view.dart';
import 'package:dym_vendor/features/catalog/editor/product_editor_view.dart';
import 'package:dym_vendor/features/content/contents_views.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:dym_vendor/features/orders/orders_views.dart';
import 'package:dym_vendor/features/reviews/reviews_view.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_view.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_viewmodel.dart';
import 'package:dym_vendor/features/store/opened/store_opened_view.dart';
import 'package:dym_vendor/features/store/store_service.dart';
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

  /// Détail d'une commande (écran 42).
  void toOrder(String orderId);

  /// Conversation avec une cliente (écran 62).
  void toChat(String conversationId);

  /// Mes avis (écran 65).
  void toReviews();

  /// Aide (écran 66).
  void toHelp();

  /// Mes contenus et publication (écran 75, spec 020).
  void toContents();
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
  ]) : _contents =
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
        pickProduct: _pickProduct,
      ),
    ),
  );

  /// Mes produits publiés, proposés au partage (écran 62).
  Future<String?> _pickProduct(BuildContext context) async {
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
      ),
    ),
  );
}
