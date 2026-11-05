import 'dart:async';

import 'package:dym_account/dym_account.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/app/app.router.dart';
import 'package:dym_client/features/cart/addresses/address_form_view.dart';
import 'package:dym_client/features/cart/addresses/addresses_view.dart';
import 'package:dym_client/features/cart/cart/cart_view.dart';
import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/delivery/delivery_view.dart';
import 'package:dym_client/features/cart/payment/payment_view.dart';
import 'package:dym_client/features/cart/sent/order_sent_view.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/aisle/aisle_view.dart';
import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/discovery/copilot/copilot_view.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/product/product_page_view.dart';
import 'package:dym_client/features/discovery/search/search_view.dart';
import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_client/features/discovery/store/store_page_view.dart';
import 'package:dym_client/features/orders/disputes_views.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_client/features/orders/orders_views.dart';
import 'package:dym_client/features/reviews/review_views.dart';
import 'package:dym_client/ui/views/home/home_view.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
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

  /// Recherche (écran 29), texte facultatif lancé à l'ouverture.
  void toSearch({String text = ''});

  /// Copilote d'intention (écran 73).
  void toCopilot();

  /// Panier (écran 05).
  void toCart();

  /// Mes adresses (écran 35).
  void toAddresses();

  /// Onglet « Commandes » (écran 43), pile vidée.
  void toOrders();

  /// Suivi d'une commande (écran 06).
  void toOrder(String orderId);

  /// Centre de notifications (écran 44).
  void toNotifications();

  /// Réglages des notifications (écran 46).
  void toNotificationSettings();

  /// Mes messages (spec 015).
  void toMessages();

  /// Conversation avec une boutique (écran 60), produit à joindre facultatif.
  Future<void> toStoreChat(String storeId, {String? productId});

  /// Conversation existante (notification, liste).
  void toChat(String conversationId);

  /// Aide (écran 66).
  void toHelp();
}

/// Navigation Stacked (pile vidée : on ne revient pas en arrière après la
/// connexion ou la déconnexion). Les écrans de découverte s'empilent.
class StackedAppNavigator implements AppNavigator {
  new([
    NavigationService? navigation,
    DiscoveryService? discovery,
    CartService? cart,
    OrdersService? orders,
    ChatService? chat,
    SupportService? support,
    SearchAiService? searchAi,
    CopilotService? copilot,
  ]) : _support = support ?? locator<SupportService>(),
       _copilot =
           copilot ??
           (locator.isRegistered<CopilotService>()
               ? locator<CopilotService>()
               : null),
       _searchAi =
           searchAi ??
           (locator.isRegistered<SearchAiService>()
               ? locator<SearchAiService>()
               : null),
       _navigation = navigation ?? locator<NavigationService>(),
       _discovery = discovery ?? locator<DiscoveryService>(),
       _cart = cart ?? locator<CartService>(),
       _orders = orders ?? locator<OrdersService>(),
       _chat = chat ?? locator<ChatService>();

  final NavigationService _navigation;
  final DiscoveryService _discovery;
  final CartService _cart;
  final OrdersService _orders;
  final ChatService _chat;
  final SupportService _support;

  /// Recherche augmentée (spec 018) ; absente : recherche texte seule.
  final SearchAiService? _searchAi;

  /// Copilote d'intention (spec 019) ; absent : pas de point d'entrée.
  final CopilotService? _copilot;

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
        onMessage: () => unawaited(toStoreChat(storeId)),
        onReviews: () => _discovery.storePage(storeId).then((page) {
          if (page case Ok(:final value)) {
            _toStoreReviews(storeId, value.store.name);
          }
        }),
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
      onAsk: (store, product) =>
          unawaited(toStoreChat(store, productId: product)),
    ),
  );

  @override
  void toSearch({String text = ''}) => _push(
    WithMiniCart(
      child: SearchView(
        service: _discovery,
        initialText: text,
        ai: _searchAi,
        onBack: _back,
        onOpenProduct: toProduct,
        onOpenStore: toStore,
      ),
    ),
  );

  @override
  void toCopilot() {
    final copilot = _copilot;
    if (copilot == null) return;
    _push(
      CopilotView(
        service: copilot,
        ai: _searchAi,
        onBack: _back,
        onSearchMyself: (text) {
          _back();
          toSearch(text: text);
        },
        onAdded: () {
          _back();
          toCart();
        },
      ),
    );
  }

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

  /// Après « Commander » : paiement en ligne à confirmer (39, 40), sinon
  /// commande envoyée (37). Le panier et la livraison quittent la pile.
  void _toOrderSent(Purchase purchase) => _navigator.pushAndRemoveUntil<void>(
    MaterialPageRoute(
      builder: (_) => purchase.awaitingPayment || purchase.paymentFailed
          ? PaymentView(
              service: _cart,
              purchase: purchase,
              onBack: toHome,
              onSettled: _toOrderSent,
            )
          : OrderSentView(
              service: _cart,
              purchase: purchase,
              onHome: toHome,
              onTrack: toOrders,
            ),
    ),
    (route) => route.isFirst,
  );

  @override
  void toOrders() => _navigator.pushAndRemoveUntil<void>(
    MaterialPageRoute(
      builder: (_) => const HomeView(initialTab: ClientTab.orders),
    ),
    (_) => false,
  );

  @override
  void toOrder(String orderId) => _push(
    TrackingView(
      service: _orders,
      orderId: orderId,
      onBack: _back,
      onReport: _toReport,
      onDispute: _toDispute,
      onReview: _toReview,
      onReordered: toCart,
    ),
  );

  Future<bool> _toReview(String orderId, String storeName) async =>
      await _navigator.push<bool>(
        MaterialPageRoute(
          builder: (context) => ReviewFormView(
            service: _orders,
            orderId: orderId,
            storeName: storeName,
            onBack: () => Navigator.of(context).pop(false),
            onSent: (_) => Navigator.of(context).pop(true),
          ),
        ),
      ) ??
      false;

  void _toStoreReviews(String storeId, String storeName) => _push(
    StoreReviewsView(
      service: _discovery,
      storeId: storeId,
      storeName: storeName,
      onBack: _back,
      onMessage: () => unawaited(toStoreChat(storeId)),
    ),
  );

  @override
  void toHelp() => _push(SupportView(service: _support, onBack: _back));

  Future<bool> _toReport(String orderId, String storeName) async =>
      await _navigator.push<bool>(
        MaterialPageRoute(
          builder: (context) => ReportProblemView(
            service: _orders,
            orderId: orderId,
            storeName: storeName,
            onBack: () => Navigator.of(context).pop(false),
            onSent: (_) => Navigator.of(context).pop(true),
          ),
        ),
      ) ??
      false;

  void _toDispute(String orderId) =>
      _push(DisputeView(service: _orders, orderId: orderId, onBack: _back));

  @override
  void toNotifications() => _push(
    NotificationsView(
      service: _orders,
      onBack: _back,
      onOpenOrder: toOrder,
      onOpenConversation: toChat,
    ),
  );

  @override
  void toMessages() => _push(
    Scaffold(
      body: ConversationsView(service: _chat, onOpen: toChat, onBack: _back),
    ),
  );

  @override
  Future<void> toStoreChat(String storeId, {String? productId}) async {
    final context = _navigator.context;
    final l10n = DymLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    switch (await _chat.start(storeId)) {
      case Ok(:final value):
        _push(_chatView(value.id, productId: productId));
      case Err(:final failure):
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              failure is NetworkFailure
                  ? l10n.errorOffline
                  : l10n.chatStoreUnavailable,
            ),
          ),
        );
    }
  }

  @override
  void toChat(String conversationId) => _push(_chatView(conversationId));

  Widget _chatView(String id, {String? productId}) => Builder(
    builder: (context) => ChatView(
      service: _chat,
      conversationId: id,
      onBack: _back,
      initialProductId: productId,
      onOpenProduct: toProduct,
      onAddToCart: (item) async {
        final variant = item.defaultVariantId;
        if (item.variantCount > 1 || variant == null) {
          toProduct(item.id);
        } else {
          await addToCart(context, variant, confirm: true);
        }
      },
    ),
  );

  @override
  void toNotificationSettings() =>
      _push(NotificationSettingsView(service: _orders, onBack: _back));
}
