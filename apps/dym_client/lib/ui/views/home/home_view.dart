import 'dart:async';

import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/feed_view.dart';
import 'package:dym_client/features/content/stories.dart';
import 'package:dym_client/features/discovery/aisle/aisles_view.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/home/discovery_home_view.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_client/features/orders/orders_views.dart';
import 'package:dym_client/ui/navigation.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Onglets de la cliente.
enum ClientTab { home, aisles, videos, orders, me }

/// Accueil de la cliente : découverte (écran 02), rayons et « Moi ».
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

  /// Contenus shoppables (tests) ; onglet « Vidéos » si le flag est actif.
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
  late final OrdersService _orders = widget.orders ?? locator<OrdersService>();
  late final ContentService? _content =
      widget.content ??
      (locator.isRegistered<ContentService>()
          ? locator<ContentService>()
          : null);
  bool _cartLoaded = false;
  bool _videos = false;

  @override
  void initState() {
    super.initState();
    final content = _content;
    if (content != null) {
      unawaited(
        content.enabled().then((on) {
          if (mounted && on) setState(() => _videos = true);
        }),
      );
    }
  }

  List<ClientTab> get _tabs => [
    for (final t in ClientTab.values)
      if (t != ClientTab.videos || _videos) t,
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
    final result = await _orders.reorder(orderId);
    if (!mounted) return;
    switch (result) {
      case Ok():
        await CartScope.maybeOf(context)?.service.refresh();
        _navigator.toCart();
      case Err():
        messenger?.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return DymAdaptiveScaffold(
      backgroundColor: c.background,
      currentIndex: _tabs.indexOf(_tab).clamp(0, _tabs.length - 1),
      onDestinationSelected: (i) => setState(() => _tab = _tabs[i]),
      destinations: [
        DymNavItem(icon: Icons.home_rounded, label: l10n.navHome),
        DymNavItem(icon: Icons.grid_view_rounded, label: l10n.navAisles),
        if (_videos)
          DymNavItem(icon: Icons.play_circle_rounded, label: l10n.navVideos),
        DymNavItem(icon: Icons.receipt_long_rounded, label: l10n.navOrders),
        DymNavItem(icon: Icons.person_rounded, label: l10n.accountTitle),
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
            stories: switch (_content) {
              final content? => StoriesRow(
                service: content,
                onOpen: _navigator.toStories,
              ),
              null => null,
            },
          ),
        ),
        ClientTab.videos => switch (_content) {
          final content? => FeedView(
            service: content,
            onOpenStore: _navigator.toStore,
          ),
          null => const SizedBox.shrink(),
        },
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
          onHelp: _navigator.toHelp,
          onWallet: _navigator.toWallet,
        ),
      },
    );
  }
}
