import 'dart:typed_data';

import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/content/contents_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Octets vides pour un média de test.
final Uint8List _empty = Uint8List(0);

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
];

const _catalog = [
  Product(
    id: 'p1',
    name: 'Gombo frais',
    currencyCode: 'XOF',
    status: ProductStatus.published,
  ),
  Product(
    id: 'p2',
    name: 'Tomates fraîches',
    currencyCode: 'XOF',
    status: ProductStatus.published,
  ),
];

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
  group('viewmodels', () {
    test('story : média, produits tagués (5 au plus), publication', () async {
      final service = MemoryVendorContentService(catalog: _catalog);
      final vm = PublishContentViewModel(service: service);
      await vm.init();
      expect(vm.canPublish, isFalse, reason: 'sans média');
      await vm.pick(video: false, source: PhotoSource.gallery);
      vm
        ..toggleTag('p1')
        ..caption = 'Gombo frais du jour, venez vite !';
      expect(vm.canPublish, isTrue);
      expect(await vm.publish(), isTrue);
      expect(service.gestures, ['publish:story:p1']);
    });

    test('vidéo : une photo ne suffit pas', () async {
      final vm = PublishContentViewModel(
        service: MemoryVendorContentService(catalog: _catalog),
      );
      await vm.init();
      vm.selectKind(ContentKind.video);
      await vm.pick(video: false, source: PhotoSource.gallery);
      expect(vm.canPublish, isFalse);
      await vm.pick(video: true, source: PhotoSource.gallery);
      expect(vm.canPublish, isTrue);
    });

    test('mes contenus : archiver, supprimer', () async {
      final service = MemoryVendorContentService(catalog: _catalog);
      await service.publish(
        kind: ContentKind.story,
        media: (bytes: _empty, contentType: 'image/jpeg', isVideo: false),
      );
      final vm = MyContentsViewModel(service: service);
      await vm.load();
      await vm.archive(vm.items!.single);
      expect(vm.items!.single.status, 'archived');
      await vm.delete(vm.items!.single);
      expect(vm.items, isEmpty);
    });
  });

  group('écran 75 et mes contenus aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        testWidgets('75 · $name', (tester) async {
          await _pump(
            tester,
            PublishContentView(
              service: MemoryVendorContentService(catalog: _catalog),
              onBack: () {},
              onPublished: () {},
            ),
            size: size,
            locale: locale,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
        });
        testWidgets('mes contenus · $name', (tester) async {
          final service = MemoryVendorContentService(catalog: _catalog);
          await service.publish(
            kind: ContentKind.video,
            media: (bytes: _empty, contentType: 'video/mp4', isVideo: true),
          );
          await _pump(
            tester,
            MyContentsView(
              service: service,
              onBack: () {},
              onPublish: () async {},
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

  testWidgets('75 : galerie, taguer, publier', (tester) async {
    final l10n = await DymLocalizations.delegate.load(const Locale('fr'));
    final service = MemoryVendorContentService(catalog: _catalog);
    var published = false;
    await _pump(
      tester,
      PublishContentView(
        service: service,
        onBack: () {},
        onPublished: () => published = true,
      ),
    );
    await tester.tap(find.text(l10n.contentGallery));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gombo frais'));
    await tester.tap(find.text('Gombo frais'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.contentPublishStory));
    await tester.tap(find.text(l10n.contentPublishStory));
    await tester.pumpAndSettle();
    expect(published, isTrue);
    expect(service.gestures, ['publish:story:p1']);
  });
}
