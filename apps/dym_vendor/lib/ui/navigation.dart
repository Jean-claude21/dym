import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/app/app.router.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/catalog/categories/store_categories_view.dart';
import 'package:dym_vendor/features/catalog/editor/product_editor_view.dart';
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
}

/// Navigation Stacked (pile vidée : on ne revient pas en arrière après la
/// connexion, la déconnexion ou l'ouverture de la boutique).
class StackedAppNavigator implements AppNavigator {
  new([
    NavigationService? navigation,
    StoreService? stores,
    CatalogService? catalog,
  ]) : _navigation = navigation ?? locator<NavigationService>(),
       _stores = stores ?? locator<StoreService>(),
       _catalog = catalog ?? locator<CatalogService>();

  final NavigationService _navigation;
  final StoreService _stores;
  final CatalogService _catalog;

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
}
