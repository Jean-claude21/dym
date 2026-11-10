import 'package:dym_client/features/creator/creator_service.dart';
import 'package:dym_client/features/creator/creator_views.dart';
import 'package:dym_client/features/creator/tiktok_views.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

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

    testWidgets('gains : en attente, versés, dernières commissions', (
      tester,
    ) async {
      final service = _Fake()
        ..current = const CreatorProfile(displayName: 'Awa cuisine')
        ..earnings = CreatorCommissions(
          pendingMinor: 50,
          paidMinor: 120,
          items: [
            CreatorCommission(
              id: 'a1',
              status: CommissionStatus.pending,
              amountMinor: 50,
              rateBps: 500,
              createdAt: DateTime(2026, 11, 10),
              productName: 'Tomates',
            ),
          ],
        );
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: CreatorStudioView(
            service: service,
            onBack: () {},
            onCompose: () async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mes gains'), findsOneWidget);
      expect(find.text('Tomates'), findsOneWidget);
      expect(find.text('En attente de livraison'), findsOneWidget);
    });
  });

  group('pont TikTok (spec 040)', () {
    test(
      'import : vidéo du compte, légende reprise, publiée avec ingrédients',
      () async {
        final service = _Fake();
        final vm = TikTokImportViewModel(service: service)
          ..url = 'https://www.tiktok.com/@awa.cuisine/video/1';
        await vm.import();
        expect(vm.imported, isNotNull);
        expect(vm.caption, 'Sauce gombo');
        await vm.findIngredients();
        expect(await vm.publish(), isTrue);
        expect(service.importedPost!.ingredients, hasLength(2));
        expect(service.importedPost!.caption, 'Sauce gombo');
      },
    );

    test('import sans couverture : la créatrice choisit une photo', () async {
      final service = _Fake();
      final vm = TikTokImportViewModel(service: service)
        ..url = 'https://www.tiktok.com/@awa.cuisine/video/nocover';
      await vm.import();
      expect(vm.needsCover, isTrue);
      expect(await vm.publish(), isFalse);
      await vm.pickCover();
      expect(await vm.publish(), isTrue);
      expect(service.importedPost!.cover, isNotNull);
    });

    test("import : vidéo d'un autre compte refusée", () async {
      final vm = TikTokImportViewModel(service: _Fake())
        ..url = 'https://www.tiktok.com/@autre/video/1';
      await vm.import();
      expect(vm.imported, isNull);
      expect(vm.problem, TikTokImportError.notOwner);
    });

    testWidgets('studio : compte relié, import proposé, partage copié', (
      tester,
    ) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      final service = _Fake()
        ..current = const CreatorProfile(displayName: 'Awa cuisine')
        ..posts = [
          ContentItem(
            id: 'p1',
            kind: ContentKind.post,
            mediaKey: 'creators/u/contents/p1.jpg',
            isVideo: false,
            caption: 'Sauce gombo',
            createdAt: DateTime(2026, 11, 10),
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: CreatorStudioView(
            service: service,
            onBack: () {},
            onCompose: () async => false,
            onImportTikTok: () async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Mon compte TikTok'),
        '@Awa.Cuisine',
      );
      await tester.tap(find.text('Relier mon compte'));
      await tester.pumpAndSettle();
      expect(find.text('@awa.cuisine'), findsOneWidget);
      expect(find.text('Importer une vidéo TikTok'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byTooltip('Partager'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Partager'));
      await tester.pumpAndSettle();
      expect(service.shared, ['p1']);
      expect(copied.single, contains('https://fn.test/s/ab12cd34'));
      expect(find.textContaining('Lien copié'), findsOneWidget);
    });
  });
}
