import 'dart:async';

import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/feed_view.dart';
import 'package:dym_client/features/content/stories.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/home/discovery_home_view.dart';
import 'package:dym_client/features/discovery/market/market_view.dart';
import 'package:dym_client/features/orders/active_order_banner.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_client/ui/navigation.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Onglets de la cliente (design « Épuré », PARCOURS §3).
enum ClientTab { home, market, cuisine, cart, me }

/// Coquille de la cliente : Accueil · Marché · Cuisine · Panier · Moi.
/// « Cuisine » n'apparaît que si les contenus sont activés.
class HomeView extends StatefulWidget {
  const new({
    super.key,
    this.service,
    this.discovery,
    this.navigator,
    this.orders,
    this.content,
    this.initialTab = ClientTab.home,
  });

  /// Contenus shoppables (tests) ; onglet « Cuisine » si le flag est actif.
  final ContentService? content;

  /// Service d'authentification (tests).
  final AuthService? service;

  /// Découverte (tests).
  final DiscoveryService? discovery;

  /// Navigation (tests).
  final AppNavigator? navigator;

  /// Commandes et notifications (tests).
  final OrdersService? orders;

  final ClientTab initialTab;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late ClientTab _tab = widget.initialTab;

  late final AuthService _service = widget.service ?? locator<AuthService>();
  late final DiscoveryService _discovery =
      widget.discovery ?? locator<DiscoveryService>();
  late final AppNavigator _navigator =
      widget.navigator ?? StackedAppNavigator();
  late final OrdersService? _orders =
      widget.orders ??
      (locator.isRegistered<OrdersService>() ? locator<OrdersService>() : null);
  late final ContentService? _content =
      widget.content ??
      (locator.isRegistered<ContentService>()
          ? locator<ContentService>()
          : null);
  bool _cartLoaded = false;
  bool _cuisine = false;

  @override
  void initState() {
    super.initState();
    final content = _content;
    if (content != null) {
      unawaited(
        content.enabled().then((on) {
          if (mounted && on) setState(() => _cuisine = true);
        }),
      );
    }
  }

  List<ClientTab> get _tabs => [
    for (final t in ClientTab.values)
      if (t != ClientTab.cuisine || _cuisine) t,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Panier conservé côté serveur : le mini-panier le montre dès l'accueil.
    final cart = CartScope.maybeOf(context);
    if (cart != null && !_cartLoaded) {
      _cartLoaded = true;
      cart.service.refresh().ignore();
    }
  }

  /// Recommander (spec 027) : articles encore disponibles au panier, puis
  /// ouverture du panier ; message si rien n'a pu être ajouté.
  Future<void> _reorder(String orderId) async {
    final l10n = DymLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final orders = _orders;
    if (orders == null) return;
    final result = await orders.reorder(orderId);
    if (!mounted) return;
    switch (result) {
      case Ok():
        await CartScope.maybeOf(context)?.service.refresh();
        _navigator.toCart();
      case Err():
        messenger?.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  void _select(ClientTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final hasCart = CartScope.maybeOf(context) != null;
    return DymAdaptiveScaffold(
      backgroundColor: c.background,
      currentIndex: _tabs.indexOf(_tab).clamp(0, _tabs.length - 1),
      onDestinationSelected: (i) => _select(_tabs[i]),
      destinations: [
        DymNavItem(icon: Icons.home_outlined, label: l10n.navHome),
        DymNavItem(icon: Icons.storefront_outlined, label: l10n.navMarket),
        if (_cuisine)
          DymNavItem(icon: Icons.soup_kitchen_outlined, label: l10n.navCuisine),
        DymNavItem(icon: Icons.shopping_basket_outlined, label: l10n.navCart),
        DymNavItem(
          icon: Icons.person_outline_rounded,
          label: l10n.accountTitle,
        ),
      ],
      body: switch (_tab) {
        ClientTab.home => WithMiniCart(
          child: DiscoveryHomeView(
            service: _discovery,
            onSearch: _navigator.toSearch,
            onCopilot: _navigator.toCopilot,
            onOpenStore: _navigator.toStore,
            onOpenAisle: _navigator.toAisle,
            onOpenProduct: _navigator.toProduct,
            onReorder: _reorder,
            onShoppingLists: _navigator.toShoppingLists,
            onNotifications: _navigator.toNotifications,
            activeOrder: switch (_orders) {
              final orders? => ActiveOrderBanner(
                service: orders,
                onOpen: _navigator.toOrder,
              ),
              null => null,
            },
            stories: switch (_content) {
              final content? => StoriesRow(
                service: content,
                onOpen: _navigator.toStories,
              ),
              null => null,
            },
          ),
        ),
        ClientTab.market => WithMiniCart(
          child: MarketView(
            service: _discovery,
            onSearch: _navigator.toSearch,
            onOpenAisle: _navigator.toAisle,
            onOpenStore: _navigator.toStore,
            onGroupBuys: _navigator.toGroupBuys,
          ),
        ),
        ClientTab.cuisine => switch (_content) {
          final content? => FeedView(
            service: content,
            onOpenStore: _navigator.toStore,
            onRecipe: _navigator.toRecipe,
          ),
          null => const SizedBox.shrink(),
        },
        ClientTab.cart =>
          hasCart
              ? _navigator.cartPage(onBrowse: () => _select(ClientTab.market))
              : const SizedBox.shrink(),
        ClientTab.me => AccountView(
          service: _service,
          onSignedOut: _navigator.toSignIn,
          banner: switch (_orders) {
            final orders? => ActiveOrderBanner(
              service: orders,
              onOpen: _navigator.toOrder,
            ),
            null => null,
          },
          onOrders: _navigator.toMyOrders,
          onAddresses: hasCart ? _navigator.toAddresses : null,
          onNotifications: _navigator.toNotificationSettings,
          onMessages: _navigator.toMessages,
          onHelp: _navigator.toHelp,
          onWallet: _navigator.toWallet,
          onFavorites: _navigator.toFavorites,
          onBaskets: _navigator.toBaskets,
          onSpaces: _navigator.toSpaces,
          onGroupBuys: _navigator.toGroupBuys,
          onMembership: _navigator.toMembership,
          onCreator: _navigator.toCreatorStudio,
        ),
      },
    );
  }
}
