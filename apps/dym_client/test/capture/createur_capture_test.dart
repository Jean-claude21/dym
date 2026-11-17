// Fakes repris des tests d'écran : certaines aides n'y servent pas.
@Tags(['golden'])
library;

import 'package:dym_client/features/creator/creator_service.dart';
import 'package:dym_client/features/creator/creator_views.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/discovery_fixtures.dart';
import 'capture.dart';

const _recettes = ContentCategory(
  id: 'cat-r',
  slug: 'recettes',
  label: LocalizedText({'fr': 'Recettes', 'en': 'Recipes'}),
);
const _autre = ContentCategory(
  id: 'cat-a',
  slug: 'autre',
  label: LocalizedText({'fr': 'Autre', 'en': 'Other'}),
);

class _Fake implements CreatorService {
  @override
  Future<Result<ContentItem>> setCover(String contentId, int? frame) async =>
      const Err(NotFoundFailure('contenu'));

  CreatorProfile? current;
  String? suggestion = 'recettes';
  ({
    String? categoryId,
    String source,
    List<String> products,
    List<ShoppingItem> ingredients,
  })?
  published;

  @override
  Future<Result<CreatorProfile?>> profile() async => Ok(current);

  @override
  Future<Result<CreatorProfile>> become(String name, {String? bio}) async {
    if (name.trim().length < 2) {
      return const Err(ValidationFailure('invalid_name'));
    }
    return Ok(current = CreatorProfile(displayName: name.trim(), bio: bio));
  }

  @override
  Future<Result<List<ContentCategory>>> categories() async =>
      const Ok([_recettes, _autre]);

  @override
  Future<Result<CreatorMedia?>> pick({
    required bool video,
    required PhotoSource source,
  }) async => Ok((
    bytes: Uint8List(4),
    contentType: video ? 'video/mp4' : 'image/jpeg',
    isVideo: video,
  ));

  @override
  Future<String?> suggestCategory(String caption) async => suggestion;

  @override
  Future<List<ShoppingItem>> suggestIngredients(String caption) async => const [
    ShoppingItem(label: 'Gombo', query: 'gombo', quantity: 2),
    ShoppingItem(label: 'Tomates', query: 'tomate'),
  ];

  @override
  Future<Result<List<CatalogItem>>> searchProducts(String text) async =>
      const Ok([]);

  @override
  Future<Result<ContentItem>> publish({
    required CreatorMedia media,
    String? caption,
    String? categoryId,
    String categorySource = 'chosen',
    List<String> productIds = const [],
    List<ShoppingItem> ingredients = const [],
  }) async {
    published = (
      categoryId: categoryId,
      source: categorySource,
      products: productIds,
      ingredients: ingredients,
    );
    return Ok(
      ContentItem(
        id: 'p1',
        kind: ContentKind.post,
        mediaKey: 'creators/u/contents/p1.jpg',
        isVideo: false,
        createdAt: DateTime(2026, 11, 10),
      ),
    );
  }

  List<ContentItem> posts = const [];

  @override
  Future<Result<List<ContentItem>>> mine() async => Ok(posts);

  @override
  Future<Result<void>> archive(String contentId) async => const Ok(null);

  CreatorCommissions earnings = const CreatorCommissions();

  @override
  Future<Result<CreatorCommissions>> commissions() async => Ok(earnings);

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(togoConfig());

  @override
  Future<Result<CreatorProfile>> setTikTokHandle(String handle) async => Ok(
    current = CreatorProfile(
      displayName: current?.displayName ?? 'Awa',
      tiktokHandle: handle.replaceFirst('@', '').toLowerCase(),
    ),
  );

  @override
  Future<Result<TikTokImport>> importTikTok(String url) async =>
      url.contains('@autre')
      ? const Err(ValidationFailure('not_owner'))
      : Ok((
          upload: url.contains('nocover')
              ? null
              : (contentId: 'c1', objectKey: 'creators/u/contents/c1.jpg'),
          caption: 'Sauce gombo',
          sourceUrl: url,
          verified: false,
        ));

  ({
    TikTokImport video,
    String? caption,
    List<ShoppingItem> ingredients,
    CreatorMedia? cover,
  })?
  importedPost;

  @override
  Future<Result<ContentItem>> publishImport(
    TikTokImport video, {
    String? caption,
    List<ShoppingItem> ingredients = const [],
    CreatorMedia? cover,
  }) async {
    importedPost = (
      video: video,
      caption: caption,
      ingredients: ingredients,
      cover: cover,
    );
    return Ok(
      ContentItem(
        id: video.upload?.contentId ?? 'c2',
        kind: ContentKind.post,
        mediaKey: video.upload?.objectKey,
        isVideo: false,
        createdAt: DateTime(2026, 11, 10),
        sourceUrl: video.sourceUrl,
      ),
    );
  }

  final shared = <String>[];

  @override
  Future<Result<Uri>> shareLink(ContentItem post) async {
    shared.add(post.id);
    return Ok(Uri.parse('https://fn.test/s/ab12cd34'));
  }

  @override
  ImageProvider photo(String objectKey) => MemoryImage(_pixel);

  @override
  ImageProvider preview(CreatorMedia media) => MemoryImage(_pixel);
}

final _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  testWidgets('createur', (tester) async {
    await capture(
      tester,
      'createur',
      CreatorStudioView(
        service: _Fake(),
        onBack: () {},
        onCompose: () async => false,
      ),
    );
  });
}
