import 'dart:async';

import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/widgets.dart';

/// Contenus shoppables côté cliente (spec 020) : fil de vidéos (74),
/// stories de l'accueil, vidéos d'un produit, signalements.
abstract interface class ContentService {
  /// Onglet « Vidéos » et stories proposés (flag `shoppable_content`).
  Future<bool> enabled();

  /// Fil : vidéos d'un produit (par date), sinon fil classé (spec 037).
  Future<Result<List<ContentItem>>> feed({
    bool following = false,
    bool near = false,
    DateTime? before,
    String? productId,
    String? category,
    int offset = 0,
  });

  /// Profil public d'une créatrice ou d'une boutique (spec 101).
  Future<Result<ContentProfile?>> profile(String kind, String id);

  /// « Mes recettes » : enregistrer ou retirer.
  Future<Result<ContentItem>> toggleSave(
    ContentItem content, {
    required bool on,
  });

  Future<Result<List<ContentItem>>> saved();

  /// « J'ai fait la recette ».
  Future<Result<ContentItem>> cooked(ContentItem content, {String? note});

  /// Catégories des contenus (puces du fil).
  Future<Result<List<ContentCategory>>> categories();

  /// S'abonner à l'autrice ou à la boutique du contenu ; état final.
  Future<Result<bool>> follow(ContentItem content, {required bool on});

  Future<Result<List<ContentComment>>> comments(ContentItem content);

  Future<Result<List<ContentComment>>> addComment(
    ContentItem content,
    String body, {
    required String idempotencyKey,
  });

  Future<Result<void>> deleteComment(String commentId);

  /// « Tout pour la faire » (spec 038) : panier composé en base.
  Future<Result<CopilotProposal>> recipeBasket(
    ContentItem content, {
    int? servings,
  });

  /// Article de la recette ajouté au panier : attribué au contenu (spec 039).
  void recipeAdded(ContentItem content, String variantId);

  /// Lien court du contenu, à coller sur TikTok ou ailleurs (spec 040).
  Future<Result<Uri>> shareLink(ContentItem content);

  /// Contenu d'un lien de partage ouvert.
  Future<Result<ContentItem>> openShare(String code);

  /// Ouvre la vidéo d'origine (TikTok) hors de l'app.
  Future<void> openSource(ContentItem content);

  Future<Result<List<StoryGroup>>> stories();

  Future<Result<int>> productVideoCount(String productId);

  void viewed(ContentItem content);

  /// Produit tagué touché : statistique, puis ajout au panier.
  Future<Result<void>> addToCart(ContentItem content, CatalogItem product);

  Future<Result<int>> like(ContentItem content, {required bool like});

  Future<Result<void>> report(
    ReportTarget target,
    String targetId,
    ReportReason reason,
  );

  /// Référentiel du pays (devise d'affichage).
  Future<Result<CountryConfig>> countryConfig();

  /// URL d'un média (lecture publique).
  Uri mediaUrl(String objectKey);

  ImageProvider photo(String objectKey);
}

/// Implémentation Neon.
class NeonContentService implements ContentService {
  new({
    required this._repository,
    required this._discovery,
    required this._cart,
    required this._media,
    this._installs,
    this._shareBase,
    this._pages = const PluginExternalPageOpener(),
  });

  /// Adresse publique des liens de partage (Functions) ; absente : aucun
  /// partage.
  final Uri? _shareBase;
  final ExternalPageOpener _pages;

  /// Identifiant d'installation (antifraude de l'affiliation, spec 039).
  final InstallIdProvider? _installs;
  bool _installSent = false;

  /// Contenu à l'origine d'un ajout au panier : appareil déclaré une fois,
  /// puis attribution des variantes.
  Future<void> _touch(ContentItem content, List<String> variantIds) async {
    if (!_installSent) {
      if (await _installs?.installId() case final id?) {
        _installSent = (await _repository.registerInstall(id)).isOk;
      }
    }
    await _repository.touch(content.id, variantIds);
  }

  final ContentRepository _repository;
  final DiscoveryService _discovery;
  final CartService _cart;
  final Uri Function(String key) _media;

  @override
  Future<bool> enabled() async =>
      (await _discovery.countryConfig()).valueOrNull?.isEnabled(
        'shoppable_content',
      ) ??
      false;

  @override
  Future<Result<ContentProfile?>> profile(String kind, String id) =>
      _repository.profile(kind, id);

  @override
  Future<Result<ContentItem>> toggleSave(
    ContentItem content, {
    required bool on,
  }) => _repository.toggleSave(content.id, on: on);

  @override
  Future<Result<List<ContentItem>>> saved() => _repository.savedContents();

  @override
  Future<Result<ContentItem>> cooked(ContentItem content, {String? note}) =>
      _repository.cooked(content.id, note: note);

  @override
  Future<Result<List<ContentItem>>> feed({
    bool following = false,
    bool near = false,
    DateTime? before,
    String? productId,
    String? category,
    int offset = 0,
  }) => productId != null
      ? _repository.feed(
          zoneId: _discovery.zone.value,
          before: before,
          productId: productId,
        )
      : _repository.rankedFeed(
          zoneId: _discovery.zone.value,
          following: following,
          near: near,
          category: category,
          offset: offset,
        );

  @override
  Future<Result<List<ContentCategory>>> categories() =>
      _repository.categories();

  @override
  Future<Result<bool>> follow(ContentItem content, {required bool on}) =>
      _repository.follow(
        on: on,
        creatorId: content.author?.id,
        storeId: content.author == null ? content.store?.id : null,
      );

  @override
  Future<Result<List<ContentComment>>> comments(ContentItem content) =>
      _repository.comments(content.id);

  @override
  Future<Result<List<ContentComment>>> addComment(
    ContentItem content,
    String body, {
    required String idempotencyKey,
  }) =>
      _repository.addComment(content.id, body, idempotencyKey: idempotencyKey);

  @override
  Future<Result<void>> deleteComment(String commentId) =>
      _repository.deleteComment(commentId);

  @override
  Future<Result<CopilotProposal>> recipeBasket(
    ContentItem content, {
    int? servings,
  }) => _repository.recipeBasket(
    content.id,
    zoneId: _discovery.zone.value,
    servings: servings,
  );

  @override
  void recipeAdded(ContentItem content, String variantId) =>
      unawaited(_touch(content, [variantId]));

  @override
  Future<Result<Uri>> shareLink(ContentItem content) async {
    final base = _shareBase;
    if (base == null) return const Err(UnknownFailure('partage non configuré'));
    return (await _repository.createShareLink(content.id))
        .map((code) => base.resolve('/s/$code'));
  }

  @override
  Future<Result<ContentItem>> openShare(String code) =>
      _repository.openShareLink(code);

  @override
  Future<void> openSource(ContentItem content) async {
    if (content.sourceUrl case final url?) await _pages.open(Uri.parse(url));
  }

  @override
  Future<Result<List<StoryGroup>>> stories() =>
      _repository.stories(zoneId: _discovery.zone.value);

  @override
  Future<Result<int>> productVideoCount(String productId) =>
      _repository.productVideoCount(productId);

  @override
  void viewed(ContentItem content) => unawaited(_repository.viewed(content.id));

  @override
  Future<Result<void>> addToCart(
    ContentItem content,
    CatalogItem product,
  ) async {
    unawaited(_repository.clicked(content.id, product.id));
    final variant = product.defaultVariantId;
    if (variant == null) return const Err(NotFoundFailure('variante'));
    final added = await _cart.add(variant);
    // Ajout réussi : la créatrice du contenu touche sa commission (spec 039).
    if (added.isOk) unawaited(_touch(content, [variant]));
    return added.map((_) {});
  }

  @override
  Future<Result<int>> like(ContentItem content, {required bool like}) =>
      _repository.like(content.id, like: like);

  @override
  Future<Result<void>> report(
    ReportTarget target,
    String targetId,
    ReportReason reason,
  ) => _repository.report(target, targetId, reason);

  @override
  Future<Result<CountryConfig>> countryConfig() => _discovery.countryConfig();

  @override
  Uri mediaUrl(String objectKey) => _media(objectKey);

  @override
  ImageProvider photo(String objectKey) => _discovery.photo(objectKey);
}

/// Contenus en mémoire (tests, galerie).
class MemoryContentService implements ContentService {
  new({
    required this.discovery,
    this.contents = const [],
    this.groups = const [],
    this.isEnabled = true,
    this.failure,
    this.recipe,
  });

  final DiscoveryService discovery;
  final List<ContentItem> contents;
  final List<StoryGroup> groups;
  final bool isEnabled;
  final Failure? failure;

  /// Panier de recette selon les portions (tests, galerie).
  final CopilotProposal Function(int? servings)? recipe;
  final gestures = <String>[];

  @override
  Future<bool> enabled() async => isEnabled;

  @override
  Future<Result<List<ContentItem>>> feed({
    bool following = false,
    bool near = false,
    DateTime? before,
    String? productId,
    String? category,
    int offset = 0,
  }) async {
    if (failure case final f?) return Err(f);
    return Ok(
      [
        for (final c in contents)
          if ((!following || c.followed) &&
              (category == null || c.category?.slug == category) &&
              (productId == null || c.products.any((p) => p.id == productId)))
            c,
      ].skip(before == null ? offset : contents.length).toList(),
    );
  }

  /// Catégories de démonstration.
  List<ContentCategory> contentCategories = const [];
  final followed = <String>[];
  final commentsById = <String, List<ContentComment>>{};

  @override
  Future<Result<List<ContentCategory>>> categories() async =>
      Ok(contentCategories);

  @override
  Future<Result<bool>> follow(ContentItem content, {required bool on}) async {
    final id = content.author?.id ?? content.store?.id ?? '';
    on ? followed.add(id) : followed.remove(id);
    return Ok(on);
  }

  @override
  Future<Result<List<ContentComment>>> comments(ContentItem content) async =>
      Ok(commentsById[content.id] ?? const []);

  @override
  Future<Result<List<ContentComment>>> addComment(
    ContentItem content,
    String body, {
    required String idempotencyKey,
  }) async {
    final list = commentsById.putIfAbsent(content.id, () => []);
    if (!list.any((c) => c.id == idempotencyKey)) {
      list.insert(
        0,
        ContentComment(
          id: idempotencyKey,
          body: body.trim(),
          authorName: 'Awa',
          createdAt: DateTime.utc(2026, 11, 10),
          mine: true,
        ),
      );
    }
    return Ok(List.of(list));
  }

  @override
  Future<Result<CopilotProposal>> recipeBasket(
    ContentItem content, {
    int? servings,
  }) async {
    gestures.add('${content.id}:basket:${servings ?? '-'}');
    return Ok(recipe?.call(servings) ?? const CopilotProposal());
  }

  @override
  Future<Result<void>> deleteComment(String commentId) async {
    for (final list in commentsById.values) {
      list.removeWhere((c) => c.id == commentId);
    }
    return const Ok(null);
  }

  @override
  Future<Result<List<StoryGroup>>> stories() async => Ok(groups);

  @override
  Future<Result<int>> productVideoCount(String productId) async => Ok(
    contents.where((c) => c.products.any((p) => p.id == productId)).length,
  );

  @override
  void viewed(ContentItem content) => gestures.add('${content.id}:view');

  @override
  Future<Result<void>> addToCart(
    ContentItem content,
    CatalogItem product,
  ) async {
    gestures.add('${content.id}:add:${product.id}');
    return const Ok(null);
  }

  @override
  void recipeAdded(ContentItem content, String variantId) =>
      gestures.add('${content.id}:recipe:$variantId');

  @override
  Future<Result<Uri>> shareLink(ContentItem content) async {
    gestures.add('${content.id}:share');
    return Ok(Uri.parse('https://dym.test/s/${content.id}'));
  }

  @override
  Future<Result<ContentItem>> openShare(String code) async {
    final found = contents.where((c) => c.id == code).firstOrNull;
    return found == null ? const Err(NotFoundFailure('lien')) : Ok(found);
  }

  @override
  Future<void> openSource(ContentItem content) async =>
      gestures.add('${content.id}:source');

  @override
  Future<Result<int>> like(ContentItem content, {required bool like}) async {
    gestures.add('${content.id}:${like ? 'like' : 'unlike'}');
    return Ok(content.likeCount + (like ? 1 : -1));
  }

  @override
  Future<Result<void>> report(
    ReportTarget target,
    String targetId,
    ReportReason reason,
  ) async {
    gestures.add('$targetId:report:${reason.name}');
    return const Ok(null);
  }

  @override
  Future<Result<CountryConfig>> countryConfig() => discovery.countryConfig();

  @override
  Uri mediaUrl(String objectKey) => Uri.parse('https://media.test/$objectKey');

  @override
  ImageProvider photo(String objectKey) => discovery.photo(objectKey);

  /// Recettes enregistrées et faites (spec 101).
  final savedIds = <String>{};
  final cookedIds = <String>{};

  @override
  Future<Result<ContentProfile?>> profile(String kind, String id) async => Ok(
    ContentProfile(
      kind: kind,
      id: id,
      name: kind == 'creator' ? 'Awa cuisine' : 'Étal',
      followers: 3,
      contents: [
        for (final c in contents)
          if (c.author?.id == id || c.store?.id == id) c,
      ],
    ),
  );

  @override
  Future<Result<ContentItem>> toggleSave(
    ContentItem content, {
    required bool on,
  }) async {
    on ? savedIds.add(content.id) : savedIds.remove(content.id);
    return Ok(
      content.copyWith(saved: on, saveCount: content.saveCount + (on ? 1 : -1)),
    );
  }

  @override
  Future<Result<List<ContentItem>>> saved() async => Ok([
    for (final c in contents)
      if (savedIds.contains(c.id)) c.copyWith(saved: true),
  ]);

  @override
  Future<Result<ContentItem>> cooked(
    ContentItem content, {
    String? note,
  }) async {
    cookedIds.add(content.id);
    return Ok(content.copyWith(cooked: true, cookCount: content.cookCount + 1));
  }
}
