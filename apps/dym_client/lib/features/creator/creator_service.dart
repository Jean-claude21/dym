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

  /// Produits en vente à taguer (recherche dans le quartier).
  Future<Result<List<CatalogItem>>> searchProducts(String text);

  Future<Result<ContentItem>> publish({
    required CreatorMedia media,
    String? caption,
    String? categoryId,
    String categorySource = 'chosen',
    List<String> productIds = const [],
  });

  Future<Result<List<ContentItem>>> mine();

  Future<Result<void>> archive(String contentId);

  ImageProvider photo(String objectKey);

  ImageProvider preview(CreatorMedia media);
}

class NeonCreatorService implements CreatorService {
  new({
    required this._repository,
    required this._discovery,
    required this._photos,
    required this._videos,
  });

  final ContentRepository _repository;
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
  }) async {
    final upload = await _repository.uploadCreator(
      media.bytes,
      contentType: media.contentType,
    );
    switch (upload) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final u):
        return await _repository.publishCreator(
          upload: u,
          video: media.isVideo,
          caption: caption,
          categoryId: categoryId,
          categorySource: categorySource,
          productIds: productIds,
        );
    }
  }

  @override
  Future<Result<List<ContentItem>>> mine() => _repository.myCreatorContents();

  @override
  Future<Result<void>> archive(String contentId) =>
      _repository.archive(contentId);

  @override
  ImageProvider photo(String objectKey) => _discovery.photo(objectKey);

  @override
  ImageProvider preview(CreatorMedia media) => MemoryImage(media.bytes);
}
