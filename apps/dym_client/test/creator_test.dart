import 'dart:typed_data';

import 'package:dym_client/features/creator/creator_service.dart';
import 'package:dym_client/features/creator/creator_views.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  @override
  Future<Result<List<ContentItem>>> mine() async => const Ok([]);

  @override
  Future<Result<void>> archive(String contentId) async => const Ok(null);

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
  group('studio créatrice (spec 036)', () {
    test('devenir créatrice : nom vérifié', () async {
      final vm = CreatorStudioViewModel(service: _Fake());
      await vm.load();
      expect(vm.profile, isNull);
      expect(await vm.become('A', ''), isFalse);
      expect(vm.problem, CreatorError.name);
      expect(await vm.become('Awa cuisine', ''), isTrue);
      expect(vm.profile!.displayName, 'Awa cuisine');
    });

    test('catégorie : IA proposée et gardée comme provenance', () async {
      final service = _Fake();
      final vm = ComposeViewModel(service: service);
      await vm.load();
      await vm.pick(video: false, source: PhotoSource.gallery);
      vm.caption = 'Ma sauce gombo du dimanche';
      await vm.suggest();
      expect(vm.categoryId, 'cat-r');
      expect(await vm.publish(), isTrue);
      expect(service.published!.source, 'ai');
    });

    test('sans catégorie : « Autre » par défaut côté serveur', () async {
      final service = _Fake()..suggestion = null;
      final vm = ComposeViewModel(service: service);
      await vm.load();
      await vm.pick(video: true, source: PhotoSource.gallery);
      expect(await vm.publish(), isTrue);
      expect(service.published!.categoryId, isNull);
      expect(service.published!.source, 'default');
    });

    test(
      'ingrédients : IA puis saisie, sans doublon, publiés avec le post',
      () async {
        final service = _Fake();
        final vm = ComposeViewModel(service: service);
        await vm.load();
        await vm.pick(video: false, source: PhotoSource.gallery);
        vm
          ..caption = 'Sauce gombo pour 4'
          ..addIngredient('tomates');
        await vm.findIngredients();
        expect(vm.ingredients.map((i) => i.label), ['tomates', 'Gombo']);
        vm.removeIngredient(0);
        expect(await vm.publish(), isTrue);
        expect(service.published!.ingredients.single.label, 'Gombo');
      },
    );

    test('produits tagués : 5 au plus', () {
      final vm = ComposeViewModel(service: _Fake());
      for (var i = 0; i < 7; i++) {
        vm.toggleTag(
          CatalogItem(
            id: 'p$i',
            name: 'Produit $i',
            currencyCode: 'XOF',
            store: const CatalogItemStore(
              id: 's1',
              name: 'Étal',
              zoneName: 'Bè',
            ),
          ),
        );
      }
      expect(vm.tagged, hasLength(ComposeViewModel.maxTags));
    });

    testWidgets('écran : studio fermé, ouverture du profil', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: CreatorStudioView(
            service: _Fake(),
            onBack: () {},
            onCompose: () async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ouvrir mon studio'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Awa cuisine');
      await tester.tap(find.text('Ouvrir mon studio'));
      await tester.pumpAndSettle();
      expect(find.text('Nouveau post'), findsOneWidget);
    });
  });
}
