import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/feed_view.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

const _recettes = ContentCategory(
  id: 'cat-r',
  slug: 'recettes',
  label: LocalizedText({'fr': 'Recettes', 'en': 'Recipes'}),
);

ContentItem _post(String id, {bool followed = false, ContentCategory? cat}) =>
    ContentItem(
      id: id,
      kind: ContentKind.post,
      mediaKey: 'creators/u1/contents/$id.jpg',
      isVideo: false,
      caption: 'Post $id',
      createdAt: DateTime.utc(2026, 11, 10),
      author: const ContentAuthor(id: 'u1', displayName: 'Awa cuisine'),
      category: cat,
      followed: followed,
    );

void main() {
  MemoryContentService service() => MemoryContentService(
    discovery: memoryDiscovery(),
    contents: [
      _post('a', cat: _recettes),
      _post('b'),
    ],
  )..contentCategories = const [_recettes];

  group('fil classé (spec 037)', () {
    test('catégorie filtrée ; grille puis retour au plein écran', () async {
      final vm = FeedViewModel(service: service());
      await vm.load();
      expect(vm.categories.single.slug, 'recettes');
      expect(vm.items, hasLength(2));
      await vm.selectCategory('recettes');
      expect(vm.items!.single.id, 'a');
      vm.toggleGrid();
      expect(vm.grid, isTrue);
      vm.openFromGrid(0);
      expect(vm.grid, isFalse);
      expect(vm.index, 0);
    });

    test("s'abonner : tous les contenus de l'autrice suivent", () async {
      final s = service();
      final vm = FeedViewModel(service: s);
      await vm.load();
      await vm.toggleFollow(vm.items!.first);
      expect(vm.items!.every((c) => c.followed), isTrue);
      expect(s.followed, ['u1']);
    });

    testWidgets('commentaires : ajout et suppression du sien', (tester) async {
      final s = service();
      var count = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: Scaffold(
            body: CommentsSheet(
              service: s,
              content: _post('a'),
              onCount: (n) => count = n,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Pas encore de commentaire'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Merci pour la recette !');
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();
      expect(find.text('Merci pour la recette !'), findsOneWidget);
      expect(count, 1);
      await tester.tap(find.byTooltip('Supprimer mon commentaire'));
      await tester.pumpAndSettle();
      expect(count, 0);
    });
  });
}
