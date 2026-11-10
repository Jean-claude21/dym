import 'dart:typed_data';

import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/widgets.dart';

/// Média choisi avant publication.
typedef CreatorMedia = ({Uint8List bytes, String contentType, bool isVideo});

/// Studio créatrice (spec 036) : profil, posts (photo, vidéo), catégorie,
/// produits tagués, statistiques.
abstract interface class CreatorService {
  Future<Result<CreatorProfile?>> profile();

  Future<Result<CreatorProfile>> become(String name, {String? bio});

  Future<Result<List<ContentCategory>>> categories();

  Future<Result<CreatorMedia?>> pick({
    required bool video,
    required PhotoSource source,
  });

  /// Catégorie proposée par l'IA pour la légende ; `null` : aucune.
  Future<String?> suggestCategory(String caption);

  /// Ingrédients repérés par l'IA dans la légende (spec 038) ; vide : rien.
  Future<List<ShoppingItem>> suggestIngredients(String caption);

  /// Produits en vente à taguer (recherche dans le quartier).
  Future<Result<List<CatalogItem>>> searchProducts(String text);

  Future<Result<ContentItem>> publish({
    required CreatorMedia media,
    String? caption,
    String? categoryId,
    String categorySource = 'chosen',
    List<String> productIds = const [],
    List<ShoppingItem> ingredients = const [],
  });

  Future<Result<List<ContentItem>>> mine();

  Future<Result<void>> archive(String contentId);

  /// Gains d'affiliation (spec 039).
  Future<Result<CreatorCommissions>> commissions();

  /// Devise et décimales du pays, pour afficher les gains.
  Future<Result<CountryConfig>> countryConfig();

  ImageProvider photo(String objectKey);

  ImageProvider preview(CreatorMedia media);
}

class NeonCreatorService implements CreatorService {
  new({
    required this._repository,
    required this._discovery,
    required this._photos,
    required this._videos,
    this._lists,
    this._installs,
  });

  final ContentRepository _repository;

  /// Identifiant d'installation (antifraude de l'affiliation, spec 039).
  final InstallIdProvider? _installs;

  /// IA des listes (spec 029), réutilisée pour les ingrédients.
  final ShoppingListRepository? _lists;
  final DiscoveryService _discovery;
  final PhotoPicker _photos;
  final VideoPicker _videos;

  @override
  Future<Result<CreatorProfile?>> profile() => _repository.creatorProfile();

  @override
  Future<Result<CreatorProfile>> become(String name, {String? bio}) =>
      _repository.becomeCreator(name, bio: bio);

  @override
  Future<Result<List<ContentCategory>>> categories() =>
      _repository.categories();

  @override
  Future<Result<CreatorMedia?>> pick({
    required bool video,
    required PhotoSource source,
  }) async {
    if (video) {
      return (await _videos.pick(source)).map(
        (v) => v == null
            ? null
            : (bytes: v.bytes, contentType: v.contentType, isVideo: true),
      );
    }
    return (await _photos.pick(source)).map(
      (p) => p == null
          ? null
          : (bytes: p.bytes, contentType: p.contentType, isVideo: false),
    );
  }

  @override
  Future<String?> suggestCategory(String caption) async =>
      caption.trim().length < 3
      ? null
      : (await _repository.classify(caption.trim())).valueOrNull;

  @override
  Future<List<ShoppingItem>> suggestIngredients(String caption) async {
    final lists = _lists;
    if (lists == null || caption.trim().length < 3) return const [];
    return (await lists.suggest(caption.trim())).valueOrNull ?? const [];
  }

  @override
  Future<Result<List<CatalogItem>>> searchProducts(String text) async =>
      (await _discovery.search(
        SearchQuery(
          text: text,
          zoneId: _discovery.zone.value,
          availableOnly: true,
          limit: 10,
        ),
      )).map((r) => r.products);

  @override
  Future<Result<ContentItem>> publish({
    required CreatorMedia media,
    String? caption,
    String? categoryId,
    String categorySource = 'chosen',
    List<String> productIds = const [],
    List<ShoppingItem> ingredients = const [],
  }) async {
    final upload = await _repository.uploadCreator(
      media.bytes,
      contentType: media.contentType,
    );
    switch (upload) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final u):
        final published = await _repository.publishCreator(
          upload: u,
          video: media.isVideo,
          caption: caption,
          categoryId: categoryId,
          categorySource: categorySource,
          productIds: productIds,
        );
        if (published case Ok(:final value) when ingredients.isNotEmpty) {
          // Les ingrédients suivent le post ; un échec ne retire pas le post.
          await _repository.setIngredients(value.id, ingredients);
        }
        return published;
    }
  }

  @override
  Future<Result<List<ContentItem>>> mine() => _repository.myCreatorContents();

  @override
  Future<Result<void>> archive(String contentId) =>
      _repository.archive(contentId);

  @override
  Future<Result<CreatorCommissions>> commissions() async {
    // Appareil de la créatrice déclaré : ses autres comptes ne lui
    // rapportent rien.
    if (await _installs?.installId() case final id?) {
      await _repository.registerInstall(id);
    }
    return await _repository.myCommissions();
  }

  @override
  Future<Result<CountryConfig>> countryConfig() => _discovery.countryConfig();

  @override
  ImageProvider photo(String objectKey) => _discovery.photo(objectKey);

  @override
  ImageProvider preview(CreatorMedia media) => MemoryImage(media.bytes);
}
