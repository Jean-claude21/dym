import 'dart:async';

import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/widgets.dart';

/// Contenus shoppables côté cliente (spec 020) : fil de vidéos (74),
/// stories de l'accueil, vidéos d'un produit, signalements.
abstract interface class ContentService {
  /// Onglet « Vidéos » et stories proposés (flag `shoppable_content`).
  Future<bool> enabled();

  Future<Result<List<ContentItem>>> feed({
    bool following = false,
    DateTime? before,
    String? productId,
  });

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
  });

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
  Future<Result<List<ContentItem>>> feed({
    bool following = false,
    DateTime? before,
    String? productId,
  }) => _repository.feed(
    zoneId: _discovery.zone.value,
    following: following,
    before: before,
    productId: productId,
  );

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
    return (await _cart.add(variant)).map((_) {});
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
  });

  final DiscoveryService discovery;
  final List<ContentItem> contents;
  final List<StoryGroup> groups;
  final bool isEnabled;
  final Failure? failure;
  final gestures = <String>[];

  @override
  Future<bool> enabled() async => isEnabled;

  @override
  Future<Result<List<ContentItem>>> feed({
    bool following = false,
    DateTime? before,
    String? productId,
  }) async {
    if (failure case final f?) return Err(f);
    return Ok([
      for (final c in contents)
        if (!following &&
            (productId == null || c.products.any((p) => p.id == productId)))
          c,
    ]);
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
}
