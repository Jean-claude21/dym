import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/recipe_sheets.dart';
import 'package:dym_client/features/content/report_sheet.dart';
import 'package:dym_client/features/content/share_content.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';

/// Lecteur d'un média vidéo ; remplaçable (tests, galerie).
typedef VideoBuilder = Widget Function(
  BuildContext context,
  Uri url, {
  required bool active,
});

/// Fil de vidéos shoppables (écran 74) : « Pour toi » (quartier) ou
/// « Boutiques suivies » ; produits tagués ajoutés au panier en un tap.
class FeedViewModel extends BaseViewModel {
  new({required this.service, this.productId});

  final ContentService service;

  /// Vidéos d'un produit (depuis sa fiche, C-CAT-12).
  final String? productId;

  bool following = false;

  /// « Près de moi » : boutiques qui livrent ici (spec 101).
  bool near = false;

  /// Catégorie filtrée (spec 037) ; nulle : toutes.
  String? category;
  List<ContentCategory> categories = const [];

  /// Vue en grille (spec 037) ; sinon plein écran.
  bool grid = false;

  /// Change à chaque retour au plein écran (page initiale).
  int pageEpoch = 0;
  List<ContentItem>? items;
  Failure? failure;
  CountryConfig? config;
  int index = 0;

  /// Produit tout juste ajouté, ou nombre d'articles de la recette
  /// (message « ajouté au panier · Voir », effacé après quelques secondes).
  String? added;
  int addedCount = 0;
  Timer? _addedTimer;
  bool _loadingMore = false;
  bool _ended = false;

  Future<void> load() async {
    failure = null;
    items = null;
    _ended = false;
    notifyListeners();
    config ??= (await service.countryConfig()).valueOrNull;
    if (categories.isEmpty && productId == null) {
      categories = (await service.categories()).valueOrNull ?? const [];
    }
    switch (await service.feed(
      following: following,
      near: near,
      productId: productId,
      category: category,
    )) {
      case Ok(:final value):
        items = value;
        index = 0;
        if (value.isNotEmpty) service.viewed(value.first);
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  Future<void> selectTab({required bool following, bool near = false}) async {
    if (this.following == following && this.near == near) return;
    this.following = following;
    this.near = near;
    await load();
  }

  /// « Mes recettes » (spec 101) : ajout ou retrait, compte relu en base.
  Future<void> toggleSave(ContentItem content) async {
    final on = !content.saved;
    _replace(content.copyWith(saved: on));
    if (await service.toggleSave(content, on: on) case Ok(:final value)) {
      // Seuls les champs du geste : le reste (commentaires…) vient du fil.
      _replace(
        content.copyWith(saved: value.saved, saveCount: value.saveCount),
      );
    }
  }

  /// « J'ai fait la recette » (spec 101).
  Future<void> markCooked(ContentItem content, {String? note}) async {
    if (await service.cooked(content, note: note) case Ok(:final value)) {
      _replace(
        content.copyWith(cooked: value.cooked, cookCount: value.cookCount),
      );
    }
  }

  Future<void> selectCategory(String? slug) async {
    if (category == slug) return;
    category = slug;
    await load();
  }

  void toggleGrid() {
    grid = !grid;
    if (!grid) pageEpoch++;
    notifyListeners();
  }

  /// Vignette touchée : retour au plein écran sur ce contenu.
  void openFromGrid(int i) {
    index = i;
    grid = false;
    pageEpoch++;
    notifyListeners();
  }

  /// S'abonner à l'autrice ou à la boutique ; tous ses contenus suivent.
  /// Lien de partage ; null : partage impossible (l'écran le dit).
  Future<Uri?> share(ContentItem content) async =>
      (await service.shareLink(content)).valueOrNull;

  Future<void> toggleFollow(ContentItem content) async {
    final on = !content.followed;
    final owner = content.author?.id ?? content.store?.id;
    if (await service.follow(content, on: on) case Ok(:final value)) {
      items = [
        for (final c in items ?? const <ContentItem>[])
          if ((c.author?.id ?? c.store?.id) == owner)
            c.copyWith(followed: value)
          else
            c,
      ];
      notifyListeners();
    }
  }

  void commentsChanged(ContentItem content, int count) =>
      _replace(content.copyWith(commentCount: count));

  Future<void> onPage(int i) async {
    final list = items;
    if (list == null || i >= list.length) return;
    index = i;
    service.viewed(list[i]);
    notifyListeners();
    if (i >= list.length - 2 && !_loadingMore && !_ended) {
      _loadingMore = true;
      final more = await service.feed(
        following: following,
        near: near,
        before: productId == null ? null : list.last.createdAt,
        productId: productId,
        category: category,
        offset: list.length,
      );
      if (more case Ok(:final value)) {
        if (value.isEmpty) _ended = true;
        items = [...list, ...value];
      }
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(ContentItem content) async {
    final liked = !content.liked;
    _replace(
      content.copyWith(
        liked: liked,
        likeCount: content.likeCount + (liked ? 1 : -1),
      ),
    );
    if (await service.like(content, like: liked) case Ok(:final value)) {
      _replace(content.copyWith(liked: liked, likeCount: value));
    }
  }

  Future<bool> add(ContentItem content, CatalogItem product) async {
    final result = await service.addToCart(content, product);
    if (result.isOk) _showAdded(name: product.name);
    return result.isOk;
  }

  /// Articles de la recette ajoutés (feuille « pour N »).
  void recipeAdded(int count) {
    if (count > 0) _showAdded(count: count);
  }

  void _showAdded({String? name, int count = 0}) {
    added = name;
    addedCount = count;
    _addedTimer?.cancel();
    _addedTimer = Timer(const Duration(seconds: 4), () {
      added = null;
      addedCount = 0;
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _addedTimer?.cancel();
    super.dispose();
  }

  Future<void> report(ContentItem content, ReportReason reason) =>
      service.report(ReportTarget.content, content.id, reason);

  void _replace(ContentItem content) {
    items = [
      for (final c in items ?? const <ContentItem>[])
        if (c.id == content.id) content else c,
    ];
    notifyListeners();
  }
}

/// Écran 74.
class FeedView extends StackedView<FeedViewModel> {
  const new({
    required this.service,
    super.key,
    this.productId,
    this.onBack,
    this.onOpenStore,
    this.videoBuilder = networkVideo,
  });

  final ContentService service;
  final String? productId;

  /// Présent quand le fil est ouvert depuis une fiche produit.
  final VoidCallback? onBack;
  final ValueChanged<String>? onOpenStore;
  final VideoBuilder videoBuilder;

  @override
  FeedViewModel viewModelBuilder(BuildContext context) =>
      FeedViewModel(service: service, productId: productId);

  @override
  void onViewModelReady(FeedViewModel viewModel) => unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, FeedViewModel viewModel, Widget? child) {
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final items = vm.items;
    final Widget body;
    if (items == null) {
      body = DiscoveryState(failure: vm.failure, onRetry: vm.load);
    } else if (items.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s5),
          child: Text(
            vm.following ? l10n.feedEmptyFollowing : l10n.feedEmpty,
            textAlign: TextAlign.center,
            style: context.dym.text.body.copyWith(color: Colors.white),
          ),
        ),
      );
    } else if (vm.grid) {
      body = SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 104),
          child: GridView.builder(
            padding: const EdgeInsets.all(DymTokenSpace.s1),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 9 / 14,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _GridTile(
              content: items[i],
              service: service,
              onTap: () => vm.openFromGrid(i),
            ),
          ),
        ),
      );
    } else {
      body = PageView.builder(
        key: ValueKey('feed-${vm.pageEpoch}'),
        controller: PageController(initialPage: vm.index),
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        onPageChanged: vm.onPage,
        itemBuilder: (context, i) => _ContentPage(
          vm: vm,
          content: items[i],
          active: i == vm.index,
          videoBuilder: videoBuilder,
          onOpenStore: onOpenStore,
        ),
      );
    }
    final c = context.dym.colors;
    final t = context.dym.text;
    final locale = Localizations.localeOf(context).languageCode;
    final cart = CartScope.maybeOf(context);
    final addedText = switch ((vm.added, vm.addedCount)) {
      (final String name, _) => l10n.feedAdded(name),
      (_, final int n) when n > 0 => l10n.recipeAddedLines(n),
      _ => null,
    };
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: body),
          // Haut : Pour toi · Abonnements, grille ; catégories en puces.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (onBack case final back?)
                          IconButton(
                            tooltip: l10n.authBack,
                            onPressed: back,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              shadows: _shadow,
                            ),
                          )
                        else
                          const SizedBox(width: DymTokenSpace.s2),
                        if (productId == null) ...[
                          // Onglets défilables : trois onglets tiennent sur
                          // un petit téléphone, texte agrandi compris.
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final (i, (following, near, label)) in [
                                    (false, false, l10n.feedForYou),
                                    (true, false, l10n.feedFollowing),
                                    (false, true, l10n.feedNear),
                                  ].indexed) ...[
                                    if (i > 0)
                                      const Text(
                                        '·',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          shadows: _shadow,
                                        ),
                                      ),
                                    _Tab(
                                      label: label,
                                      selected:
                                          vm.following == following &&
                                          vm.near == near,
                                      onTap: () => vm.selectTab(
                                        following: following,
                                        near: near,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // « Mes recettes » (spec 101).
                          IconButton(
                            tooltip: l10n.savedRecipesTitle,
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SavedRecipesView(service: vm.service),
                              ),
                            ),
                            icon: const Icon(
                              Icons.bookmarks_outlined,
                              color: Colors.white,
                              shadows: _shadow,
                            ),
                          ),
                          IconButton(
                            tooltip: vm.grid
                                ? l10n.feedFullScreen
                                : l10n.feedGrid,
                            onPressed: vm.toggleGrid,
                            icon: Icon(
                              vm.grid
                                  ? Icons.view_day_outlined
                                  : Icons.grid_view_outlined,
                              color: Colors.white,
                              shadows: _shadow,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (productId == null && vm.categories.isNotEmpty)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: DymTokenSpace.s2,
                          ),
                          children: [
                            for (final (slug, label) in [
                              (null, l10n.feedAllCategories),
                              for (final cat in vm.categories)
                                (cat.slug, cat.label.resolve(locale)),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _DarkChip(
                                  label: label,
                                  selected: vm.category == slug,
                                  onTap: () => vm.selectCategory(slug),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // « 5 articles ajoutés au panier · Voir » (planche 02, étape 4).
          if (addedText != null)
            Positioned(
              left: DymTokenSpace.s3,
              right: DymTokenSpace.s3,
              top: MediaQuery.paddingOf(context).top + 104,
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: c.card,
                  elevation: 2,
                  shadowColor: DymTokenShadows.floating.color,
                  borderRadius: BorderRadius.circular(DymTokenRadius.card),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: c.brand),
                        const SizedBox(width: DymTokenSpace.s2),
                        Expanded(
                          child: Text(
                            addedText,
                            style: t.label.copyWith(color: c.textPrimary),
                          ),
                        ),
                        if (cart != null)
                          TextButton(
                            onPressed: cart.onOpenCart,
                            child: Text(l10n.feedSeeCart),
                          )
                        else
                          const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ombre des textes et icônes posés sur la vidéo (pas de voile ni dégradé).
const _shadow = [Shadow(blurRadius: 8, color: Colors.black54)];

class _Tab extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.button),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s2),
            child: Align(
              widthFactor: 1,
              child: Text(
                label,
                style: t.body.copyWith(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.white70,
                  shadows: _shadow,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puce de catégorie posée sur la vidéo.
class _DarkChip extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? Colors.white : Colors.black38,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DymTokenRadius.chip),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: context.dym.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? c.textPrimary : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentPage extends StatelessWidget {
  const new({
    required this.vm,
    required this.content,
    required this.active,
    required this.videoBuilder,
    this.onOpenStore,
  });

  final FeedViewModel vm;
  final ContentItem content;
  final bool active;
  final VideoBuilder videoBuilder;
  final ValueChanged<String>? onOpenStore;

  Future<void> _openProducts(BuildContext context) async {
    final recipe = await showVideoProducts(
      context,
      service: vm.service,
      content: content,
      config: vm.config,
      onAdd: (p) => vm.add(content, p),
    );
    if (recipe && context.mounted) await _openRecipe(context);
  }

  Future<void> _openRecipe(BuildContext context) async {
    final count = await showRecipeSheet(
      context,
      service: vm.service,
      content: content,
      config: vm.config,
    );
    vm.recipeAdded(count);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final service = vm.service;
    final products = content.products;
    final store = content.store;
    final author = content.author;
    final name = store?.name ?? author?.displayName;
    final storeOrigin = store == null
        ? null
        : originLabel(vm.config, store.origin, locale);
    final white = t.body.copyWith(color: Colors.white, shadows: _shadow);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (content.isVideo)
          videoBuilder(
            context,
            // Lecture adaptative HLS quand la vidéo est convertie (spec 101).
            switch (content.streamUrl) {
              final hls? => Uri.parse(hls),
              _ => service.mediaUrl(content.mediaKey!),
            },
            active: active,
          )
        else
          Image(
            image: service.photo(content.mediaKey!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(color: c.brandDeep),
          ),
        Positioned(
          left: DymTokenSpace.s3,
          right: DymTokenSpace.s2,
          bottom: DymTokenSpace.s3,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Autrice, mention, légende.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (name != null)
                            InkWell(
                              // Créatrice : son profil public (spec 101).
                              onTap: store == null
                                  ? (author == null
                                        ? null
                                        : () => openContentProfile(
                                            context,
                                            service,
                                            'creator',
                                            author.id,
                                          ))
                                  : onOpenStore == null
                                  ? null
                                  : () => onOpenStore!(store.id),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: name,
                                      style: white.copyWith(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (store == null)
                                      TextSpan(
                                        text: ' · ${l10n.feedCreator}',
                                        style: white,
                                      )
                                    else if (originOf(store.origin) != null)
                                      TextSpan(
                                        text: ' · $storeOrigin',
                                        style: white,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          if (content.hasRecipe && author != null) ...[
                            const SizedBox(height: 4),
                            // Transparence (spec 039) : l'autrice touche une
                            // commission sur ces achats.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.paidContent,
                                style: t.label.copyWith(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (content.caption case final caption?) ...[
                            const SizedBox(height: 4),
                            Text(
                              caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: white,
                            ),
                          ],
                          if (content.category case final cat?)
                            Text(
                              '# ${cat.label.resolve(locale)}',
                              style: white.copyWith(fontSize: 14),
                            ),
                          if (content.sourceUrl != null)
                            TextButton.icon(
                              onPressed: () => service.openSource(content),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(48, 40),
                              ),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: Text(l10n.tiktokSeeOriginal),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: DymTokenSpace.s2),
                    // Actions : abonnement, j'aime, commentaires, partage,
                    // signalement.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (name != null)
                          _FollowAvatar(
                            initial: name.characters.first,
                            followed: content.followed,
                            label: content.followed
                                ? l10n.feedFollowingOne
                                : l10n.feedFollow,
                            onTap: () => vm.toggleFollow(content),
                          ),
                        _SideAction(
                          icon: content.liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: content.liked ? c.piment : Colors.white,
                          label: compactCount(content.likeCount, locale),
                          tooltip: l10n.feedLike,
                          onTap: () => vm.toggleLike(content),
                        ),
                        _SideAction(
                          icon: content.saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: content.saved ? c.plantain : Colors.white,
                          label: compactCount(content.saveCount, locale),
                          tooltip: l10n.feedSave,
                          onTap: () => vm.toggleSave(content),
                        ),
                        if (content.hasRecipe)
                          _SideAction(
                            icon: content.cooked
                                ? Icons.restaurant_rounded
                                : Icons.restaurant_menu_rounded,
                            color: content.cooked ? c.plantain : Colors.white,
                            label: compactCount(content.cookCount, locale),
                            tooltip: l10n.feedCooked,
                            onTap: () => _cooked(context, vm, content),
                          ),
                        _SideAction(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: compactCount(content.commentCount, locale),
                          tooltip: l10n.feedComments,
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) => CommentsSheet(
                              service: service,
                              content: content,
                              onCount: (n) => vm.commentsChanged(content, n),
                            ),
                          ),
                        ),
                        _SideAction(
                          icon: Icons.reply_rounded,
                          mirror: true,
                          label: l10n.shareAction,
                          tooltip: l10n.shareAction,
                          onTap: () => shareContent(context, vm.share, content),
                        ),
                        _SideAction(
                          icon: Icons.flag_outlined,
                          tooltip: l10n.reportAction,
                          onTap: () async {
                            final reason = await showReportSheet(context);
                            if (reason != null) {
                              await vm.report(content, reason);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                // Produits de la vidéo : deux vignettes, « +N », recette.
                if (products.isNotEmpty || content.hasRecipe) ...[
                  const SizedBox(height: DymTokenSpace.s3),
                  SizedBox(
                    // Deux lignes de texte : la hauteur suit le texte agrandi.
                    height:
                        56 *
                        MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.5),
                    child: Row(
                      children: [
                        for (final p in products.take(2))
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _ProductPill(
                                product: p,
                                image: switch (p.photoKey) {
                                  final key? => service.photo(key),
                                  null => null,
                                },
                                price: moneyOf(
                                  vm.config,
                                  p.minPriceMinor ?? p.priceMinor,
                                ),
                                onTap: () => _openProducts(context),
                              ),
                            ),
                          ),
                        if (products.length > 2)
                          _MorePill(
                            label: '+${products.length - 2}',
                            tooltip: l10n.feedInThisVideo,
                            onTap: () => _openProducts(context),
                          )
                        else if (products.isEmpty)
                          Expanded(
                            child: DymButton(
                              label: l10n.recipeAllForIt,
                              icon: Icons.shopping_basket_outlined,
                              compact: true,
                              onPressed: () => _openRecipe(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Avatar de l'autrice ou de la boutique, « + » vert pour s'abonner.
class _FollowAvatar extends StatelessWidget {
  const new({
    required this.initial,
    required this.followed,
    required this.label,
    required this.onTap,
  });

  final String initial;
  final bool followed;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 64,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.tintVertTendre,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  initial.toUpperCase(),
                  style: context.dym.text.title.copyWith(color: c.brandDeep),
                ),
              ),
              Positioned(
                bottom: 4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: followed ? Colors.white : c.brand,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    followed ? Icons.check_rounded : Icons.add_rounded,
                    size: 16,
                    color: followed ? c.brand : c.onBrand,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action de la colonne de droite : icône blanche ombrée, libellé dessous.
class _SideAction extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.label,
    this.color = Colors.white,
    this.mirror = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final String? label;
  final Color color;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, color: color, size: 32, shadows: _shadow);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mirror)
                  Transform.flip(flipX: true, child: glyph)
                else
                  glyph,
                if (label case final l?)
                  Text(
                    l,
                    style: context.dym.text.label.copyWith(
                      fontSize: 13,
                      color: Colors.white,
                      shadows: _shadow,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vignette d'un produit de la vidéo (photo, nom, prix) ; ouvre la feuille.
class _ProductPill extends StatelessWidget {
  const new({
    required this.product,
    required this.image,
    required this.price,
    required this.onTap,
  });

  final CatalogItem product;
  final ImageProvider? image;
  final Money? price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.field),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.field),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              ProductThumb(image: image, size: 44),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    if (price != null)
                      Text(
                        price!.format(),
                        maxLines: 1,
                        style: t.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MorePill extends StatelessWidget {
  const new({required this.label, required this.tooltip, required this.onTap});

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.field),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DymTokenRadius.field),
          child: SizedBox(
            width: 56,
            child: Center(
              child: Text(
                label,
                style: context.dym.text.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lecteur réseau (`video_player`) : en boucle, lecture quand la page est
/// visible, pause d'un tap.
Widget networkVideo(BuildContext context, Uri url, {required bool active}) =>
    _NetworkVideo(url: url, active: active);

class _NetworkVideo extends StatefulWidget {
  const new({required this.url, required this.active});

  final Uri url;
  final bool active;

  @override
  State<_NetworkVideo> createState() => _NetworkVideoState();
}

class _NetworkVideoState extends State<_NetworkVideo> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(widget.url);
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      _controller.initialize().then((_) async {
        if (!mounted) return;
        await _controller.setLooping(true);
        setState(() => _ready = true);
        if (widget.active) await _controller.play();
      }),
    );
  }

  @override
  void didUpdateWidget(_NetworkVideo old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    unawaited(widget.active ? _controller.play() : _controller.pause());
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () => unawaited(
        _controller.value.isPlaying ? _controller.pause() : _controller.play(),
      ),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

/// Vignette de la grille (spec 037).
class _GridTile extends StatelessWidget {
  const new({
    required this.content,
    required this.service,
    required this.onTap,
  });

  final ContentItem content;
  final ContentService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (contentPoster(content, service) case final poster?)
            Image(
              image: poster,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(color: c.brandDeep),
            )
          else
            ColoredBox(color: c.brandDeep),
          if (content.isVideo)
            const Center(
              child: Icon(
                Icons.play_circle_rounded,
                color: Colors.white,
                size: 40,
                shadows: [Shadow(blurRadius: 6)],
              ),
            ),
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: Text(
              content.caption ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.label.copyWith(
                color: Colors.white,
                shadows: const [Shadow(blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Commentaires d'un contenu (spec 037).
class CommentsSheet extends StatefulWidget {
  const new({
    required this.service,
    required this.content,
    required this.onCount,
    super.key,
  });

  final ContentService service;
  final ContentItem content;
  final ValueChanged<int> onCount;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _text = TextEditingController();
  List<ContentComment>? _comments;
  bool _sending = false;
  String? _key;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await widget.service.comments(widget.content);
    if (!mounted) return;
    setState(() => _comments = result.valueOrNull ?? const []);
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final key = _key ??= Uuid.v4();
    final result = await widget.service.addComment(
      widget.content,
      body,
      idempotencyKey: key,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (result case Ok(:final value)) {
        _comments = value;
        _text.clear();
        _key = null;
        widget.onCount(value.length);
      }
    });
  }

  Future<void> _delete(ContentComment comment) async {
    if (await widget.service.deleteComment(comment.id) case Ok()) {
      final list = [
        for (final c in _comments ?? const <ContentComment>[])
          if (c.id != comment.id) c,
      ];
      if (!mounted) return;
      setState(() => _comments = list);
      widget.onCount(list.length);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    final c = context.dym.colors;
    final comments = _comments;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Column(
            children: [
              Text(l10n.feedComments, style: t.title),
              Expanded(
                child: comments == null
                    ? const Center(child: CircularProgressIndicator())
                    : comments.isEmpty
                    ? Center(
                        child: Text(
                          l10n.feedNoComment,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      )
                    : ListView(
                        children: [
                          for (final k in comments)
                            ListTile(
                              title: Text(k.authorName, style: t.label),
                              subtitle: Text(k.body, style: t.body),
                              trailing: k.mine
                                  ? IconButton(
                                      tooltip: l10n.feedDeleteComment,
                                      onPressed: () => _delete(k),
                                      icon: const Icon(Icons.delete_rounded),
                                    )
                                  : null,
                            ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(DymTokenSpace.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        maxLength: 300,
                        onChanged: (_) => _key = null,
                        decoration: InputDecoration(
                          hintText: l10n.feedCommentHint,
                          counterText: '',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.chatSend,
                      onPressed: _sending ? null : _send,
                      icon: Icon(Icons.send_rounded, color: c.brand),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « J'ai fait la recette » : un petit mot facultatif (spec 101).
Future<void> _cooked(
  BuildContext context,
  FeedViewModel vm,
  ContentItem content,
) async {
  final l10n = DymLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final note = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(l10n.feedCookedTitle),
      content: TextField(
        controller: note,
        maxLength: 280,
        decoration: InputDecoration(labelText: l10n.feedCookedNote),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(d, true),
          child: Text(l10n.feedCooked),
        ),
      ],
    ),
  );
  final text = note.text.trim();
  note.dispose();
  if (ok != true) return;
  await vm.markCooked(content, note: text.isEmpty ? null : text);
  messenger?.showSnackBar(SnackBar(content: Text(l10n.feedCookedThanks)));
}

/// Profil public d'une créatrice ou d'une boutique (spec 101).
Future<void> openContentProfile(
  BuildContext context,
  ContentService service,
  String kind,
  String id,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => ContentProfileView(service: service, kind: kind, id: id),
  ),
);

class ContentProfileView extends StatefulWidget {
  const new({
    required this.service,
    required this.kind,
    required this.id,
    super.key,
  });

  final ContentService service;
  final String kind;
  final String id;

  @override
  State<ContentProfileView> createState() => _ContentProfileViewState();
}

class _ContentProfileViewState extends State<ContentProfileView> {
  ContentProfile? _profile;
  Failure? _failure;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    switch (await widget.service.profile(widget.kind, widget.id)) {
      case Ok(:final value):
        if (mounted) {
          setState(() {
            _profile = value;
            _following = value?.following ?? false;
          });
        }
      case Err(:final failure):
        if (mounted) setState(() => _failure = failure);
    }
  }

  Future<void> _toggleFollow() async {
    final p = _profile;
    final first = p?.contents.firstOrNull;
    if (p == null || first == null) return;
    final on = !_following;
    setState(() => _following = on);
    await widget.service.follow(first, on: on);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    final c = context.dym.colors;
    final p = _profile;
    return Scaffold(
      appBar: AppBar(title: Text(p?.name ?? '')),
      body: p == null
          ? (_failure == null
                ? const Center(child: CircularProgressIndicator())
                : DymStateView(
                    kind: DymStateKind.error,
                    title: l10n.errorLoadMessage,
                    message: '',
                    actionLabel: l10n.retry,
                    onAction: _load,
                  ))
          : ListView(
              padding: const EdgeInsets.all(DymTokenSpace.s4),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: c.tintVertTendre,
                      child: Text(
                        p.name.characters.firstOrNull ?? '',
                        style: t.display.copyWith(color: c.brandDeep),
                      ),
                    ),
                    const SizedBox(width: DymTokenSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: t.title),
                          Text(
                            l10n.profileFollowers(p.followers),
                            style: t.label.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (p.contents.isNotEmpty)
                      DymButton(
                        label: _following
                            ? l10n.feedFollowingOne
                            : l10n.feedFollow,
                        variant: _following
                            ? DymButtonVariant.secondary
                            : DymButtonVariant.primary,
                        onPressed: _toggleFollow,
                      ),
                  ],
                ),
                if (p.bio case final bio? when bio.isNotEmpty) ...[
                  const SizedBox(height: DymTokenSpace.s3),
                  Text(bio, style: t.body),
                ],
                const SizedBox(height: DymTokenSpace.s4),
                ContentGrid(service: widget.service, items: p.contents),
              ],
            ),
    );
  }
}

/// Grille de vignettes (profil, « Mes recettes »).
class ContentGrid extends StatelessWidget {
  const new({required this.service, required this.items, super.key});

  final ContentService service;
  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    if (items.isEmpty) {
      return DymStateView(
        kind: DymStateKind.empty,
        title: l10n.profileNoContent,
        message: '',
      );
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 9 / 16,
      children: [
        for (final item in items)
          ClipRRect(
            borderRadius: BorderRadius.circular(DymTokenRadius.tile),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (contentPoster(item, service) case final poster?)
                  Image(
                    image: poster,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(color: c.brandDeep),
                  )
                else
                  ColoredBox(color: c.brandDeep),
                if (item.isVideo)
                  const Center(
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                  ),
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: Text(
                    item.caption ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// « Mes recettes » : contenus enregistrés (spec 101).
class SavedRecipesView extends StatefulWidget {
  const new({required this.service, super.key});

  final ContentService service;

  @override
  State<SavedRecipesView> createState() => _SavedRecipesViewState();
}

class _SavedRecipesViewState extends State<SavedRecipesView> {
  List<ContentItem>? _items;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.service.saved().then((r) {
        if (mounted) setState(() => _items = r.valueOrNull ?? const []);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedRecipesTitle)),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(DymTokenSpace.s3),
              children: [ContentGrid(service: widget.service, items: items)],
            ),
    );
  }
}

/// Image d'un contenu dans une grille : la photo ; pour une vidéo, la vignette
/// de la vidéo adaptative (Bunny), sinon la photo du premier produit tagué.
ImageProvider? contentPoster(ContentItem item, ContentService service) {
  if (!item.isVideo) {
    return item.mediaKey == null ? null : service.photo(item.mediaKey!);
  }
  final stream = item.streamUrl;
  if (stream != null && stream.endsWith('/playlist.m3u8')) {
    return NetworkImage(
      stream.replaceFirst(RegExp(r'playlist\.m3u8$'), 'thumbnail.jpg'),
    );
  }
  for (final p in item.products) {
    if (p.photoKey != null) return service.photo(p.photoKey!);
  }
  return null;
}
