import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/reviews/reviews_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
];

MemoryVendorReviewsService _service() => MemoryVendorReviewsService(
  StoreReviews(
    rating: 4.5,
    reviewCount: 2,
    reviews: [
      Review(
        id: 'r1',
        orderId: 'o1',
        storeId: 's1',
        rating: 5,
        comment: 'Les tomates étaient très fraîches, merci !',
        authorFirstName: 'Awa',
        createdAt: DateTime.utc(2026, 10, 3, 10),
      ),
      Review(
        id: 'r2',
        orderId: 'o2',
        storeId: 's1',
        rating: 4,
        comment: 'Bon gombo, livraison un peu longue.',
        reply: 'Merci Kossi, on s’améliore !',
        authorFirstName: 'Kossi',
        createdAt: DateTime.utc(2026, 9, 30, 10),
      ),
    ],
  ),
);

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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  test('répondre : texte exigé, liste relue', () async {
    final service = _service();
    final vm = VendorReviewsViewModel(service: service);
    await vm.load();
    expect(await vm.reply('r1', '  '), isFalse);
    expect(await vm.reply('r1', 'Merci Awa !'), isTrue);
    expect(vm.reviews!.reviews.first.reply, 'Merci Awa !');
    expect(service.replies, ['r1:Merci Awa !']);
  });

  group('écran 65 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        testWidgets('65 · ${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}', (tester) async {
          await _pump(
            tester,
            VendorReviewsView(
              service: _service(),
              onBack: () {},
              clock: () => DateTime.utc(2026, 10, 5, 11),
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

  testWidgets('65 : répondre depuis la feuille', (tester) async {
    final service = _service();
    await _pump(
      tester,
      VendorReviewsView(
        service: service,
        onBack: () {},
        clock: () => DateTime.utc(2026, 10, 5, 11),
      ),
    );
    await tester.tap(find.text('Répondre').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Merci Awa !');
    await tester.pump();
    await tester.tap(find.text('Publier la réponse'));
    await tester.pumpAndSettle();
    expect(service.replies, ['r1:Merci Awa !']);
    expect(find.textContaining('Merci Awa !'), findsOneWidget);
  });
}
