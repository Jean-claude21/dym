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
import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/feed_view.dart';
import 'package:dym_client/features/content/stories.dart';
import 'package:dym_client/features/creator/creator_service.dart';
import 'package:dym_client/features/creator/creator_views.dart';
import 'package:dym_client/features/creator/tiktok_views.dart';
import 'package:dym_client/features/discovery/aisle/aisle_view.dart';
import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/discovery/copilot/copilot_view.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/product/product_page_view.dart';
import 'package:dym_client/features/discovery/search/search_view.dart';
import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_client/features/discovery/store/store_page_view.dart';
import 'package:dym_client/features/favorites/favorites_service.dart';
import 'package:dym_client/features/favorites/favorites_views.dart';
import 'package:dym_client/features/group_buy/group_buy_view.dart';
import 'package:dym_client/features/haggle/haggle_sheet.dart';
import 'package:dym_client/features/orders/adjustments_view.dart';
import 'package:dym_client/features/orders/disputes_views.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_client/features/orders/orders_views.dart';
import 'package:dym_client/features/reviews/review_views.dart';
import 'package:dym_client/features/shopping/shopping_service.dart';
import 'package:dym_client/features/shopping/shopping_viewmodels.dart';
import 'package:dym_client/features/shopping/shopping_views.dart';
import 'package:dym_client/features/spaces/spaces_service.dart';
import 'package:dym_client/features/spaces/spaces_views.dart';
import 'package:dym_client/features/wallet/wallet_service.dart';
import 'package:dym_client/features/wallet/wallet_view.dart';
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

  /// Fil de vidéos d'un produit (C-CAT-12).
  void toProductVideos(String productId);

  /// Stories du quartier, à partir d'une boutique.
  void toStories(List<StoryGroup> groups, int index);

  /// Panier (écran 05).
  void toCart();

  /// Panier de l'onglet « Panier » (design « Épuré ») : sans retour quand
  /// [onBack] est nul.
  Widget cartPage({required VoidCallback onBrowse, VoidCallback? onBack});

  /// Mes commandes, depuis « Moi » (design « Épuré »).
  void toMyOrders();

  /// Mes adresses (écran 35).
  void toAddresses();

  /// « Moi » puis « Mes commandes » (écran 43), pile vidée.
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

  /// Mon wallet (spec 025).
  void toWallet();

  /// Mes courses (spec 029).
  void toShoppingLists();

  /// Panier proposé pour une liste (notification de rappel).
  Future<void> toShoppingList(String listId);

  /// Mes favoris (spec 030).
  void toFavorites();

  /// Mes paniers enregistrés (spec 030).
  void toBaskets();

  /// Mes espaces (spec 031).
  void toSpaces();

  /// Achats groupés entre voisins (spec 051).
  void toGroupBuys();

  /// DYM+ (spec 052).
  void toMembership();

  /// Studio créatrice (spec 036).
  void toCreatorStudio();

  /// « Tout pour la faire » d'une recette (spec 038).
  void toRecipe(ContentItem content);

  /// Lien de partage ouvert (spec 040) : « Tout pour la faire » du contenu.
  Future<void> toShared(String code);

  /// Un espace (notification, liste).
  Future<void> toSpace(String spaceId);
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
    ContentService? content,
    WalletService? wallet,
    ShoppingService? shopping,
    FavoritesService? favorites,
    SpacesService? spaces,
  ]) : _walletOverride = wallet,
       _spacesOverride = spaces,
       _shoppingOverride = shopping,
       _favoritesOverride = favorites,
       _support = support ?? locator<SupportService>(),
       _content =
           content ??
           (locator.isRegistered<ContentService>()
               ? locator<ContentService>()
               : null),
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
  final WalletService? _walletOverride;

  /// Wallet (spec 025), résolu au premier usage.
  WalletService get _wallet => _walletOverride ?? locator<WalletService>();

  final ShoppingService? _shoppingOverride;

  /// Assistant de courses (spec 029), résolu au premier usage.
  ShoppingService get _shopping =>
      _shoppingOverride ?? locator<ShoppingService>();

  final FavoritesService? _favoritesOverride;

  final SpacesService? _spacesOverride;

  /// Espaces (spec 031) ; absents des tests sans service.
  SpacesService? get _spaces =>
      _spacesOverride ??
      (locator.isRegistered<SpacesService>() ? locator<SpacesService>() : null);

  /// Marchandage (spec 050) ; absent des tests sans service.
  HaggleService? get _haggle =>
      locator.isRegistered<HaggleService>() ? locator<HaggleService>() : null;

  /// Favoris et paniers (spec 030) ; absents des tests sans service.
  FavoritesService? get _favorites =>
      _favoritesOverride ??
      (locator.isRegistered<FavoritesService>()
          ? locator<FavoritesService>()
          : null);

  /// Recherche augmentée (spec 018) ; absente : recherche texte seule.
  final SearchAiService? _searchAi;

  /// Copilote d'intention (spec 019) ; absent : pas de point d'entrée.
  final CopilotService? _copilot;

  /// Contenus shoppables (spec 020).
  final ContentService? _content;

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

  /// Lien de partage reçu à l'ouverture de l'app web (`?share=<code>`), gardé
  /// jusqu'à l'accueil (après connexion ou création du compte).
  static String? pendingShare = Uri.base.queryParameters['share'];

  /// Boutique partagée sur WhatsApp (`?store=<id>`, spec 048).
  static String? pendingStore = Uri.base.queryParameters['store'];

  @override
  void toHome() {
    unawaited(_navigation.clearStackAndShow<void>(Routes.homeView));
    if (pendingShare case final code?) {
      pendingShare = null;
      unawaited(toShared(code));
    }
    if (pendingStore case final store?) {
      pendingStore = null;
      toStore(store);
    }
  }

  @override
  Future<void> toShared(String code) async {
    final contents = _content;
    if (contents == null) return;
    if (await contents.openShare(code) case Ok(:final value)) {
      if (value.hasRecipe) toRecipe(value);
    }
  }

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
        favorites: _favorites,
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
      content: _content,
      onVideos: toProductVideos,
      favorites: _favorites,
      haggle: _haggle,
    ),
  );

  @override
  void toProductVideos(String productId) {
    final content = _content;
    if (content == null) return;
    _push(
      FeedView(
        service: content,
        productId: productId,
        onBack: _back,
        onOpenStore: toStore,
      ),
    );
  }

  @override
  void toStories(List<StoryGroup> groups, int index) {
    final content = _content;
    if (content == null) return;
    _push(
      StoryViewer(
        service: content,
        groups: groups,
        initial: index,
        onClose: _back,
      ),
    );
  }

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
  void toCart() => _push(cartPage(onBack: _back, onBrowse: _back));

  @override
  Widget cartPage({required VoidCallback onBrowse, VoidCallback? onBack}) =>
      CartPageView(
        service: _cart,
        onBack: onBack,
        onDelivery: _toDelivery,
        onBrowse: onBrowse,
        onOrdered: _toOrderSent,
        onSave: switch (_favorites) {
          final f? => (context) => saveCartAsBasket(context, f),
          null => null,
        },
        onSendToSpace: switch (_spaces) {
          final s? => (context) => sendCartToSpace(context, s).then((_) {}),
          null => null,
        },
      );

  @override
  void toMyOrders() => _push(
    MyOrdersView(
      service: _orders,
      onOpen: toOrder,
      onNotifications: toNotifications,
      onBack: _back,
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
  void toOrders() {
    _navigator.pushAndRemoveUntil<void>(
      MaterialPageRoute(
        builder: (_) => const HomeView(initialTab: ClientTab.me),
      ),
      (_) => false,
    );
    toMyOrders();
  }

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
      adjustments: locator.isRegistered<AdjustmentsService>()
          ? locator<AdjustmentsService>()
          : null,
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
      onReport: switch (_content) {
        final content? => (review, reason) => content.report(
          ReportTarget.review,
          review.id,
          reason,
        ),
        null => null,
      },
    ),
  );

  @override
  void toHelp() => _push(SupportView(service: _support, onBack: _back));

  @override
  void toWallet() => _push(WalletView(service: _wallet, onBack: _back));

  @override
  void toShoppingLists() => _push(
    ShoppingListsView(
      service: _shopping,
      onBack: _back,
      onEdit: _toShoppingEdit,
      onOpen: _toShoppingProposal,
    ),
  );

  Future<bool> _toShoppingEdit(ShoppingDraft draft) async =>
      await _navigator.push<bool>(
        MaterialPageRoute(
          builder: (context) => ShoppingEditView(
            service: _shopping,
            draft: draft,
            onBack: () => Navigator.of(context).pop(false),
            onSaved: (_) => Navigator.of(context).pop(true),
          ),
        ),
      ) ??
      false;

  /// Panier composé pour la liste : retrait possible, puis ajout au panier.
  void _toShoppingProposal(ShoppingList list) => _push(
    CopilotView(
      service: _shopping.copilotFor(list),
      title: list.name,
      // Le texte ne sert qu'à lancer la proposition (liste, pas intention).
      initialText: list.id,
      onBack: _back,
      onAdded: () {
        _back();
        toCart();
      },
    ),
  );

  @override
  void toRecipe(ContentItem content) {
    final copilot = _copilot;
    final contents = _content;
    if (copilot == null || contents == null) return;
    _push(
      CopilotView(
        service: ListCopilotService(
          base: copilot,
          proposeList: () => contents.recipeBasket(content),
          addToCart: (variantId, quantity) async {
            final ok = (await _cart.add(variantId, quantity: quantity)).isOk;
            if (ok) contents.recipeAdded(content, variantId);
            return ok;
          },
        ),
        title: content.caption ?? content.author?.displayName ?? '',
        // Le texte ne sert qu'à lancer la composition (recette, pas intention).
        initialText: content.id,
        onBack: _back,
        onAdded: () {
          _back();
          toCart();
        },
      ),
    );
  }

  @override
  void toCreatorStudio() {
    if (!locator.isRegistered<CreatorService>()) return;
    final service = locator<CreatorService>();
    _push(
      CreatorStudioView(
        service: service,
        onBack: _back,
        onCompose: () async =>
            await _navigator.push<bool>(
              MaterialPageRoute(
                builder: (context) => ComposePostView(
                  service: service,
                  onBack: () => Navigator.of(context).pop(false),
                  onPublished: () => Navigator.of(context).pop(true),
                ),
              ),
            ) ??
            false,
        onImportTikTok: () async =>
            await _navigator.push<bool>(
              MaterialPageRoute(
                builder: (context) => TikTokImportView(
                  service: service,
                  onBack: () => Navigator.of(context).pop(false),
                  onPublished: () => Navigator.of(context).pop(true),
                ),
              ),
            ) ??
            false,
      ),
    );
  }

  @override
  void toMembership() {
    if (!locator.isRegistered<MembershipService>()) return;
    _push(
      Builder(
        builder: (context) => MembershipView(
          service: locator<MembershipService>(),
          title: DymLocalizations.of(context).membershipClientTitle,
          onBack: _back,
        ),
      ),
    );
  }

  @override
  void toGroupBuys() {
    if (!locator.isRegistered<GroupBuyService>()) return;
    _push(GroupBuysView(service: locator<GroupBuyService>(), onBack: _back));
  }

  @override
  void toSpaces() {
    final spaces = _spaces;
    if (spaces == null) return;
    _push(SpacesView(service: spaces, onBack: _back, onOpen: toSpace));
  }

  @override
  Future<void> toSpace(String spaceId) async {
    final spaces = _spaces;
    if (spaces == null) return;
    await _navigator.push<void>(
      MaterialPageRoute(
        builder: (context) => SpaceView(
          service: spaces,
          spaceId: spaceId,
          onBack: () => Navigator.of(context).pop(),
          onValidated: () {
            Navigator.of(context).pop();
            toCart();
          },
        ),
      ),
    );
  }

  @override
  void toFavorites() {
    final favorites = _favorites;
    if (favorites == null) return;
    _push(
      FavoritesView(
        service: favorites,
        discovery: _discovery,
        onBack: _back,
        onOpenStore: toStore,
        onOpenProduct: toProduct,
      ),
    );
  }

  @override
  void toBaskets() {
    final favorites = _favorites;
    if (favorites == null) return;
    _push(
      BasketsView(
        service: favorites,
        discovery: _discovery,
        onBack: _back,
        onAdded: () {
          _back();
          _cart.refresh().ignore();
          toCart();
        },
      ),
    );
  }

  @override
  Future<void> toShoppingList(String listId) async {
    final lists = (await _shopping.lists()).valueOrNull ?? const [];
    for (final list in lists) {
      if (list.id == listId) return _toShoppingProposal(list);
    }
    toShoppingLists();
  }

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
      onOpenShoppingList: (id) => unawaited(toShoppingList(id)),
      onOpenSpace: (id) => unawaited(toSpace(id)),
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
      onOpenOrder: toOrder,
      onOpenStore: toStore,
      pickProducts: _pickStoreProducts,
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

  /// Produits de la boutique, à montrer dans la conversation (« c'est
  /// disponible ? »).
  Future<List<String>?> _pickStoreProducts(
    BuildContext context,
    String storeId,
  ) async {
    final page = await _discovery.storePage(storeId);
    if (!context.mounted) return null;
    final locale = Localizations.localeOf(context).languageCode;
    final products = page.valueOrNull?.products ?? const <CatalogItem>[];
    return await showProductShareSheet(context, [
      for (final p in products)
        if (p.available)
          ShareableProduct(
            id: p.id,
            name: p.name,
            detail: p.unitLabel?.resolve(locale),
            photo: p.photoKey == null ? null : _discovery.photo(p.photoKey!),
          ),
    ], searchLabel: DymLocalizations.of(context).chatSearchStoreProducts);
  }

  @override
  void toNotificationSettings() =>
      _push(NotificationSettingsView(service: _orders, onBack: _back));
}
