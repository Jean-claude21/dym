import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/catalog/products/products_view.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';
import 'package:dym_vendor/features/dashboard/dashboard_view.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:dym_vendor/features/orders/orders_views.dart';
import 'package:dym_vendor/features/store/my_store/my_store_view.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:dym_vendor/ui/navigation.dart';
import 'package:flutter/material.dart';

/// Onglets de l'accueil de la vendeuse.
enum HomeTab { dashboard, orders, messages, products, store, me }

/// Accueil de la vendeuse : « Mes produits » (écran 24), « Ma boutique »
/// (écran 23) et « Moi ».
class HomeView extends StatefulWidget {
  const new({
    super.key,
    this.service,
    this.stores,
    this.catalog,
    this.orders,
    this.dashboard,
    this.chat,
    this.navigator,
    this.initialTab = HomeTab.dashboard,
  });

  /// Service d'authentification (tests).
  final AuthService? service;

  /// Boutique (tests).
  final StoreService? stores;

  /// Catalogue (tests).
  final CatalogService? catalog;

  /// Commandes (tests).
  final OrdersService? orders;

  final DashboardService? dashboard;

  /// Messagerie (tests).
  final ChatService? chat;

  /// Navigation (tests).
  final AppNavigator? navigator;

  final HomeTab initialTab;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late HomeTab _tab = widget.initialTab;

  late final AuthService _service = widget.service ?? locator<AuthService>();
  late final StoreService _stores = widget.stores ?? locator<StoreService>();
  late final CatalogService _catalog =
      widget.catalog ?? locator<CatalogService>();
  late final OrdersService _orders = widget.orders ?? locator<OrdersService>();
  late final DashboardService _dashboard =
      widget.dashboard ?? locator<DashboardService>();
  late final ChatService _chat = widget.chat ?? locator<ChatService>();
  late final AppNavigator _navigator =
      widget.navigator ?? StackedAppNavigator();

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return DymAdaptiveScaffold(
      backgroundColor: c.background,
      currentIndex: _tab.index,
      onDestinationSelected: (i) => setState(() => _tab = HomeTab.values[i]),
      destinations: [
        DymNavItem(icon: Icons.home_rounded, label: l10n.navHome),
        DymNavItem(icon: Icons.receipt_long_rounded, label: l10n.navOrders),
        DymNavItem(
          icon: Icons.chat_bubble_rounded,
          label: l10n.chatMessagesTitle,
        ),
        DymNavItem(
          icon: Icons.shopping_basket_rounded,
          label: l10n.navProducts,
        ),
        DymNavItem(icon: Icons.storefront_rounded, label: l10n.navStore),
        DymNavItem(icon: Icons.person_rounded, label: l10n.accountTitle),
      ],
      body: switch (_tab) {
        HomeTab.dashboard => DashboardView(
          service: _dashboard,
          onOrders: () => setState(() => _tab = HomeTab.orders),
          onProducts: () => setState(() => _tab = HomeTab.products),
          onMessages: () => setState(() => _tab = HomeTab.messages),
        ),
        HomeTab.messages => ConversationsView(
          service: _chat,
          onOpen: _navigator.toChat,
        ),
        HomeTab.orders => OrdersView(
          service: _orders,
          onOpen: _navigator.toOrder,
        ),
        HomeTab.products => ProductsView(
          service: _catalog,
          onEdit: (product) => _navigator.toProductEditor(product: product),
          onCategories: _navigator.toStoreCategories,
        ),
        HomeTab.store => MyStoreView(
          service: _stores,
          onEdit: _navigator.toStoreSetting,
        ),
        HomeTab.me => AccountView(
          service: _service,
          onSignedOut: _navigator.toSignIn,
        ),
      },
    );
  }
}
