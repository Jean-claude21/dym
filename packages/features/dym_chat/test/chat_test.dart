import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

final _config = CountryConfig(
  country: Country.fromJson(const {
    'code': 'TG',
    'name': {'fr': 'Pays test', 'en': 'Test country'},
    'currency_code': 'XOF',
    'dial_code': '+228',
    'default_locale': 'fr',
    'timezone': 'UTC',
  }),
  currency: Currency.xof,
  cities: const [],
  zones: const [],
  categories: const [],
  storeOrigins: const [],
  units: const [],
  paymentMethods: const [],
  deliveryFees: const [],
  featureFlags: const [],
);

MemoryChatService _service(ChatRole role) =>
    MemoryChatService.demo(role: role, config: _config);

DateTime _clock() => DateTime.utc(2026, 10, 5, 11);

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
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('viewmodels', () {
    test("conversations : non-lus, la plus récente d'abord", () async {
      final vm = ConversationsViewModel(
        service: _service(ChatRole.vendor),
        refreshEvery: null,
      );
      await vm.load();
      expect(vm.conversations.first.clientFirstName, 'Awa');
      expect(vm.unread, 2);
    });

    test("fil : lu à l'ouverture, images signées, envois", () async {
      final service = _service(ChatRole.client);
      final vm = ChatViewModel(
        service: service,
        conversationId: 'c1',
        refreshEvery: null,
        initialProductId: 'p-gombo',
      );
      await vm.load();
      expect(vm.messages, hasLength(4));
      expect(vm.mediaUrl('m3'), 'memory://m3');
      expect(await service.unreadCount(), const Ok(0));
      expect(await vm.sendText('   '), isFalse);
      expect(await vm.sendText(' Merci ! '), isTrue);
      expect(vm.messages.last.body, 'Merci !');
      expect(await vm.sendPendingProduct(), isTrue);
      expect(vm.pendingProductId, isNull);
      service.photo = PickedPhoto(
        bytes: Uint8List(4),
        contentType: 'image/jpeg',
      );
      expect(await vm.sendPhoto(PhotoSource.gallery), isTrue);
      expect(service.sent, ['text:Merci !', 'product:p-gombo', 'image:photo']);
      vm.dispose();
    });

    test('envoi en échec : même clé au nouvel essai (aucun doublon)', () async {
      final service = _service(ChatRole.client);
      final vm = ChatViewModel(
        service: service,
        conversationId: 'c1',
        refreshEvery: null,
      );
      await vm.load();
      service.failNext = const NetworkFailure('3G');
      expect(await vm.sendText('Allô'), isFalse);
      expect(vm.sendFailure, isA<NetworkFailure>());
      expect(await vm.sendText('Allô'), isTrue);
      expect(await vm.sendText('Allô'), isTrue);
      expect(vm.messages.where((m) => m.body == 'Allô'), hasLength(2));
      vm.dispose();
    });
  });

  group('écrans 60 à 62 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        Future<void> show(WidgetTester tester, Widget view) async {
          await _pump(tester, view, size: size, locale: locale, textScale: 1.3);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }

        testWidgets('60 · $name', (tester) async {
          await show(
            tester,
            ChatView(
              service: _service(ChatRole.client),
              conversationId: 'c1',
              onBack: () {},
              onAddToCart: (_) async {},
              clock: _clock,
              refreshEvery: null,
            ),
          );
        });
        testWidgets('61 · $name', (tester) async {
          await show(
            tester,
            ConversationsView(
              service: _service(ChatRole.vendor),
              onOpen: (_) {},
              clock: _clock,
              refreshEvery: null,
            ),
          );
        });
        testWidgets('62 · $name', (tester) async {
          await show(
            tester,
            ChatView(
              service: _service(ChatRole.vendor),
              conversationId: 'c1',
              onBack: () {},
              pickProduct: (_) async => null,
              clock: _clock,
              refreshEvery: null,
            ),
          );
        });
        testWidgets('62 partage · $name', (tester) async {
          await show(
            tester,
            const ProductShareSheet(
              products: [
                ShareableProduct(
                  id: 'p1',
                  name: 'Gombo frais',
                  detail: 'le tas · 300 F CFA',
                ),
                ShareableProduct(id: 'p2', name: 'Tomates fraîches'),
              ],
            ),
          );
        });
      }
    }
  });

  testWidgets('60 : ajouter au panier un produit partagé, écrire', (
    tester,
  ) async {
    final added = <String>[];
    final service = _service(ChatRole.client);
    await _pump(
      tester,
      ChatView(
        service: service,
        conversationId: 'c1',
        onBack: () {},
        onAddToCart: (item) async => added.add(item.id),
        clock: _clock,
        refreshEvery: null,
      ),
    );
    expect(find.text('Gombo frais'), findsOneWidget);
    await tester.tap(find.text('Ajouter au panier'));
    await tester.pump();
    expect(added, ['p-gombo']);
    await tester.enterText(find.byType(TextField), 'Merci');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Merci'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('62 : la vendeuse partage un produit', (tester) async {
    final service = _service(ChatRole.vendor);
    await _pump(
      tester,
      ChatView(
        service: service,
        conversationId: 'c1',
        onBack: () {},
        pickProduct: (context) => showProductShareSheet(context, const [
          ShareableProduct(id: 'p-gombo', name: 'Gombo frais'),
        ]),
        clock: _clock,
        refreshEvery: null,
      ),
    );
    await tester.tap(find.byTooltip('Partager un produit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partager'));
    await tester.pumpAndSettle();
    expect(service.sent, ['product:p-gombo']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('61 : ouvrir une conversation', (tester) async {
    final opened = <String>[];
    await _pump(
      tester,
      ConversationsView(
        service: _service(ChatRole.vendor),
        onOpen: opened.add,
        clock: _clock,
        refreshEvery: null,
      ),
    );
    expect(find.text('2 non lus'), findsOneWidget);
    await tester.tap(find.text('Awa'));
    expect(opened, ['c1']);
    await tester.pumpWidget(const SizedBox());
  });
}
