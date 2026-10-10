import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/aisle/aisles_view.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/home/discovery_home_view.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_client/features/orders/orders_views.dart';
import 'package:dym_client/ui/navigation.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Onglets de la cliente.
enum ClientTab { home, aisles, orders, me }

/// Accueil de la cliente : découverte (écran 02), rayons et « Moi ».
class HomeView extends StatefulWidget {
  const new({
    super.key,
    this.service,
    this.discovery,
    this.navigator,
    this.orders,
    this.initialTab = ClientTab.home,
  });

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
  late final OrdersService _orders = widget.orders ?? locator<OrdersService>();
  bool _cartLoaded = false;

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

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return DymAdaptiveScaffold(
      backgroundColor: c.background,
      currentIndex: _tab.index,
      onDestinationSelected: (i) => setState(() => _tab = ClientTab.values[i]),
      destinations: [
        DymNavItem(icon: Icons.home_rounded, label: l10n.navHome),
        DymNavItem(icon: Icons.grid_view_rounded, label: l10n.navAisles),
        DymNavItem(icon: Icons.receipt_long_rounded, label: l10n.navOrders),
        DymNavItem(icon: Icons.person_rounded, label: l10n.accountTitle),
      ],
      body: switch (_tab) {
        ClientTab.home => WithMiniCart(
          child: DiscoveryHomeView(
            service: _discovery,
            onSearch: _navigator.toSearch,
            onOpenStore: _navigator.toStore,
            onOpenAisle: _navigator.toAisle,
          ),
        ),
        ClientTab.aisles => WithMiniCart(
          child: AislesView(
            service: _discovery,
            onOpenAisle: _navigator.toAisle,
          ),
        ),
        ClientTab.orders => MyOrdersView(
          service: _orders,
          onOpen: _navigator.toOrder,
          onNotifications: _navigator.toNotifications,
        ),
        ClientTab.me => AccountView(
          service: _service,
          onSignedOut: _navigator.toSignIn,
          onAddresses: CartScope.maybeOf(context) == null
              ? null
              : _navigator.toAddresses,
          onNotifications: _navigator.toNotificationSettings,
          onMessages: _navigator.toMessages,
        ),
      },
    );
  }
}
