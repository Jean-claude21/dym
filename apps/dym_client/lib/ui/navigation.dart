import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/app/app.router.dart';
import 'package:dym_client/features/cart/addresses/address_form_view.dart';
import 'package:dym_client/features/cart/addresses/addresses_view.dart';
import 'package:dym_client/features/cart/cart/cart_view.dart';
import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/delivery/delivery_view.dart';
import 'package:dym_client/features/cart/sent/order_sent_view.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/aisle/aisle_view.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/product/product_page_view.dart';
import 'package:dym_client/features/discovery/search/search_view.dart';
import 'package:dym_client/features/discovery/store/store_page_view.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

/// Navigation de l'app, remplaçable en test.
abstract interface class AppNavigator {
  void toSignIn({bool startWithProfile = false});

  void toHome();

  /// Rayon (écran 03).
  void toAisle(String categoryId);

  /// Page boutique (écran 04).
  void toStore(String storeId);

  /// Fiche produit (écran 28).
  void toProduct(String productId);

  /// Recherche (écran 29).
  void toSearch();

  /// Panier (écran 05).
  void toCart();

  /// Mes adresses (écran 35).
  void toAddresses();
}

/// Navigation Stacked (pile vidée : on ne revient pas en arrière après la
/// connexion ou la déconnexion). Les écrans de découverte s'empilent.
class StackedAppNavigator implements AppNavigator {
  new([
    NavigationService? navigation,
    DiscoveryService? discovery,
    CartService? cart,
  ]) : _navigation = navigation ?? locator<NavigationService>(),
       _discovery = discovery ?? locator<DiscoveryService>(),
       _cart = cart ?? locator<CartService>();

  final NavigationService _navigation;
  final DiscoveryService _discovery;
  final CartService _cart;

  NavigatorState get _navigator => StackedService.navigatorKey!.currentState!;

  void _push(Widget view) =>
      _navigator.push<void>(MaterialPageRoute(builder: (_) => view));

  void _back() => _navigator.pop();

  @override
  void toSignIn({bool startWithProfile = false}) =>
      _navigation.clearStackAndShow<void>(
        Routes.signInView,
        arguments: SignInViewArguments(startWithProfile: startWithProfile),
      );

  @override
  void toHome() => _navigation.clearStackAndShow<void>(Routes.homeView);

  @override
  void toAisle(String categoryId) => _push(
    WithMiniCart(
      child: AisleView(
        service: _discovery,
        categoryId: categoryId,
        onBack: _back,
        onSearch: toSearch,
        onOpenProduct: toProduct,
      ),
    ),
  );

  @override
  void toStore(String storeId) => _push(
    WithMiniCart(
      child: StorePageView(
        service: _discovery,
        storeId: storeId,
        onBack: _back,
        onOpenProduct: toProduct,
      ),
    ),
  );

  @override
  void toProduct(String productId) => _push(
    ProductPageView(
      service: _discovery,
      productId: productId,
      onBack: _back,
      onOpenStore: toStore,
    ),
  );

  @override
  void toSearch() => _push(
    WithMiniCart(
      child: SearchView(
        service: _discovery,
        onBack: _back,
        onOpenProduct: toProduct,
        onOpenStore: toStore,
      ),
    ),
  );

  @override
  void toCart() => _push(
    CartPageView(
      service: _cart,
      onBack: _back,
      onDelivery: _toDelivery,
      onBrowse: _back,
      onOrdered: _toOrderSent,
    ),
  );

  void _toDelivery() => _push(
    DeliveryView(
      service: _cart,
      onBack: _back,
      onAddAddress: () => _toAddressForm(null),
    ),
  );

  @override
  void toAddresses() => _push(
    AddressesView(service: _cart, onBack: _back, onEdit: _toAddressForm),
  );

  Future<bool> _toAddressForm(CustomerAddress? address) async =>
      await _navigator.push<bool>(
        MaterialPageRoute(
          builder: (context) => AddressFormView(
            service: _cart,
            initial: address,
            onDone: (saved) => Navigator.of(context).pop(saved),
          ),
        ),
      ) ??
      false;

  /// Commande envoyée : le panier et la livraison quittent la pile.
  void _toOrderSent(Purchase purchase) => _navigator.pushAndRemoveUntil<void>(
    MaterialPageRoute(
      builder: (_) =>
          OrderSentView(service: _cart, purchase: purchase, onHome: toHome),
    ),
    (route) => route.isFirst,
  );
}
