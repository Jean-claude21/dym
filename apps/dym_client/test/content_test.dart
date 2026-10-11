import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/feed_view.dart';
import 'package:dym_client/features/content/stories.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
];

const _tomatoes = CatalogItem(
  id: 'p-tomates',
  name: 'Tomates fraîches',
  currencyCode: 'XOF',
  minPriceMinor: 500,
  defaultVariantId: 'v-tomates',
  store: CatalogItemStore(id: 's1', name: "Étal d'Akossiwa", zoneName: 'Bè'),
);

ContentItem _content(String id, {ContentKind kind = ContentKind.video}) =>
    ContentItem(
      id: id,
      kind: kind,
      mediaKey: 'stores/s1/contents/$id.mp4',
      isVideo: true,
      caption: 'Tomates du jour, arrivées ce matin !',
      createdAt: DateTime.utc(2026, 10, 5, 8),
      store: const ContentStore(
        id: 's1',
        name: "Étal d'Akossiwa",
        origin: 'marche',
      ),
      likeCount: 128,
      products: const [_tomatoes],
    );

Widget _video(BuildContext context, Uri url, {required bool active}) =>
    const ColoredBox(color: Color(0xFF225533));

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(412, 915),
  Locale locale = const Locale('fr'),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: locale,
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('viewmodel', () {
    test("fil : vue comptée, j'aime, ajout au panier, signalement", () async {
      final service = MemoryContentService(
        discovery: memoryDiscovery(),
        contents: [_content('c1'), _content('c2')],
      );
      final vm = FeedViewModel(service: service);
      await vm.load();
      expect(vm.items, hasLength(2));
      await vm.onPage(1);
      await vm.toggleLike(vm.items!.first);
      expect(vm.items!.first.liked, isTrue);
      expect(vm.items!.first.likeCount, 129);
      expect(await vm.add(vm.items!.first, _tomatoes), isTrue);
      expect(vm.added, 'Tomates fraîches');
      await vm.report(vm.items!.first, ReportReason.misleading);
      expect(service.gestures, [
        'c1:view',
        'c2:view',
        'c1:like',
        'c1:add:p-tomates',
        'c1:report:misleading',
      ]);
    });

    test("suivies : vide ; vidéos d'un produit", () async {
      final service = MemoryContentService(
        discovery: memoryDiscovery(),
        contents: [_content('c1')],
      );
      final vm = FeedViewModel(service: service);
      await vm.load();
      await vm.selectTab(following: true);
      expect(vm.items, isEmpty);
      final product = FeedViewModel(service: service, productId: 'p-tomates');
      await product.load();
      expect(product.items, hasLength(1));
      expect((await service.productVideoCount('p-tomates')).valueOrNull, 1);
    });
  });

  group('écran 74 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        testWidgets('74 · $name', (tester) async {
          await _pump(
            tester,
            FeedView(
              service: MemoryContentService(
                discovery: memoryDiscovery(),
                contents: [_content('c1')],
              ),
              videoBuilder: _video,
            ),
            size: size,
            locale: locale,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Tomates fraîches'), findsOneWidget);
        });
        testWidgets('stories · $name', (tester) async {
          await _pump(
            tester,
            StoryViewer(
              service: MemoryContentService(discovery: memoryDiscovery()),
              groups: [
                StoryGroup(
                  store: const ContentStore(id: 's1', name: "Étal d'Akossiwa"),
                  stories: [_content('st1', kind: ContentKind.story)],
                ),
              ],
              onClose: () {},
              videoBuilder: _video,
            ),
            size: size,
            locale: locale,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('74 : ajouter, signaler', (tester) async {
    final l10n = await DymLocalizations.delegate.load(const Locale('fr'));
    final service = MemoryContentService(
      discovery: memoryDiscovery(),
      contents: [_content('c1')],
    );
    await _pump(tester, FeedView(service: service, videoBuilder: _video));
    await tester.tap(find.text(l10n.feedAdd));
    await tester.pumpAndSettle();
    expect(find.text(l10n.feedAdded('Tomates fraîches')), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.reportAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.reportSpam));
    await tester.pumpAndSettle();
    expect(service.gestures.last, 'c1:report:spam');
  });

  testWidgets('74 vide : message', (tester) async {
    final l10n = await DymLocalizations.delegate.load(const Locale('fr'));
    await _pump(
      tester,
      FeedView(
        service: MemoryContentService(discovery: memoryDiscovery()),
        videoBuilder: _video,
      ),
    );
    expect(find.text(l10n.feedEmpty), findsOneWidget);
  });

  testWidgets('stories : rangée masquée sans flag', (tester) async {
    await _pump(
      tester,
      Scaffold(
        body: StoriesRow(
          service: MemoryContentService(
            discovery: memoryDiscovery(),
            isEnabled: false,
            groups: [
              StoryGroup(
                store: const ContentStore(id: 's1', name: 'Boutique'),
                stories: [_content('st1', kind: ContentKind.story)],
              ),
            ],
          ),
          onOpen: (_, _) {},
        ),
      ),
    );
    expect(find.text('Boutique'), findsNothing);
  });
}
