import 'dart:async';

import 'package:dym_auth/dym_auth.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/features/broadcast/broadcast_view.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/catalog/products/products_view.dart';
import 'package:dym_vendor/features/content/contents_views.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';
import 'package:dym_vendor/features/dashboard/dashboard_view.dart';
import 'package:dym_vendor/features/orders/new_order_alert.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:dym_vendor/features/orders/orders_views.dart';
import 'package:dym_vendor/features/store/my_store/my_store_view.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:dym_vendor/ui/navigation.dart';
import 'package:flutter/material.dart';

/// Onglets de la vendeuse (design « Épuré », PARCOURS §3).
enum HomeTab { dashboard, orders, products, messages, store }

/// Coquille de la vendeuse : Aujourd'hui · Commandes · Catalogue · Messages ·
/// Boutique. Le compte est rangé dans Boutique.
class HomeView extends StatefulWidget {
  const new({
    this.broadcasts,
    this.contents,
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

  /// Relance (tests) ; « Relancer mes clientes » si le flag est actif.
  final VendorBroadcastService? broadcasts;

  /// Contenus (tests) ; « Mes contenus » si le flag est actif.
  final VendorContentService? contents;

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
  bool _contents = false;
  bool _broadcast = false;

  /// Nouvelles commandes annoncées sur tous les onglets (spec 075).
  late final NewOrderWatcher? _watcher = switch (widget.orders ??
      (locator.isRegistered<OrdersService>()
          ? locator<OrdersService>()
          : null)) {
    final service? => NewOrderWatcher(service: service),
    null => null,
  };
  CountryConfig? _config;

  @override
  void initState() {
    super.initState();
    if (locator.isRegistered<PushNotifications>()) {
      unawaited(locator<PushNotifications>().start());
    }
    if (_watcher case final watcher?) {
      unawaited(
        watcher.service.countryConfig().then((r) {
          if (mounted) setState(() => _config = r.valueOrNull);
        }),
      );
      unawaited(watcher.start());
    }
    final contents =
        widget.contents ??
        (locator.isRegistered<VendorContentService>()
            ? locator<VendorContentService>()
            : null);
    if (contents != null) {
      unawaited(
        contents.enabled().then((on) {
          if (mounted && on) setState(() => _contents = true);
        }),
      );
    }
    final broadcasts =
        widget.broadcasts ??
        (locator.isRegistered<VendorBroadcastService>()
            ? locator<VendorBroadcastService>()
            : null);
    if (broadcasts != null) {
      unawaited(
        broadcasts.enabled().then((on) {
          if (mounted && on) setState(() => _broadcast = true);
        }),
      );
    }
  }

  void _select(HomeTab tab) => setState(() => _tab = tab);

  @override
  void dispose() {
    _watcher?.dispose();
    super.dispose();
  }

  String? _amount(VendorOrder o) {
    final config = _config;
    if (config == null || config.currency.code != o.currencyCode) return null;
    return config.money(o.totalMinor).format();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final name = _service.me?.profile?.firstName;
    final scaffold = DymAdaptiveScaffold(
      backgroundColor: c.background,
      currentIndex: _tab.index,
      onDestinationSelected: (i) => _select(HomeTab.values[i]),
      destinations: [
        DymNavItem(icon: Icons.today_outlined, label: l10n.navToday),
        DymNavItem(icon: Icons.receipt_long_outlined, label: l10n.navOrders),
        DymNavItem(icon: Icons.grid_view_outlined, label: l10n.navCatalog),
        DymNavItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: l10n.chatMessagesTitle,
        ),
        DymNavItem(icon: Icons.storefront_outlined, label: l10n.navStore),
      ],
      body: switch (_tab) {
        HomeTab.dashboard => DashboardView(
          service: _dashboard,
          greeting: name == null || name.isEmpty
              ? null
              : l10n.vendorGreeting(name),
          onOrders: () => _select(HomeTab.orders),
          onProducts: () => _select(HomeTab.products),
          onMessages: () => _select(HomeTab.messages),
          onCharge: _navigator.toCharge,
          onTill: _navigator.toTill,
          onPublish: _contents ? _navigator.toPublishStatus : null,
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
          onReviews: _navigator.toReviews,
          onCourierCash: _navigator.toCourierCash,
          onCredit: _navigator.toCredit,
          onStudio: _navigator.toStudio,
          onWholesale: _navigator.toWholesale,
          onHaggling: _navigator.toHaggling,
          onGroupOffers: _navigator.toGroupOffers,
          onMembership: _navigator.toMembership,
          onTill: _navigator.toTill,
          onContents: _contents ? _navigator.toContents : null,
          onBroadcast: _broadcast ? _navigator.toBroadcast : null,
          onAccount: _navigator.toAccount,
        ),
      },
    );
    return switch (_watcher) {
      final watcher? => NewOrderAlertHost(
        watcher: watcher,
        onOpen: _navigator.toOrder,
        money: _amount,
        child: scaffold,
      ),
      null => scaffold,
    };
  }
}
