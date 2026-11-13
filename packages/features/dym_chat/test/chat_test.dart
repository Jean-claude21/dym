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

    test(
      'envoi en échec : reste dans le fil, même clé au nouvel essai',
      () async {
        final service = _service(ChatRole.client);
        final vm = ChatViewModel(
          service: service,
          conversationId: 'c1',
          refreshEvery: null,
        );
        await vm.load();
        service.failNext = const NetworkFailure('3G');
        expect(await vm.sendText('Allô'), isFalse);
        expect(vm.outbox.single.state, OutgoingState.failed);
        expect(vm.entries.last, isA<ChatOutgoingEntry>());
        final key = vm.outbox.single.key;
        expect(await vm.retry(vm.outbox.single), isTrue);
        expect(vm.outbox, isEmpty);
        expect(vm.messages.last.id, key);
        expect(vm.messages.where((m) => m.body == 'Allô'), hasLength(1));
        vm.dispose();
      },
    );

    test('réseau revenu : les messages en échec repartent seuls', () async {
      final service = _service(ChatRole.client);
      final vm = ChatViewModel(
        service: service,
        conversationId: 'c1',
        refreshEvery: null,
      );
      await vm.load();
      service.failNext = const NetworkFailure('3G');
      await vm.sendText('Je passe à 18 h');
      expect(vm.outbox, hasLength(1));
      await vm.load();
      await Future<void>.delayed(Duration.zero);
      expect(vm.outbox, isEmpty);
      expect(service.sent, ['text:Je passe à 18 h']);
      vm.dispose();
    });

    test('abandon : le message en échec disparaît', () async {
      final service = _service(ChatRole.client);
      final vm = ChatViewModel(
        service: service,
        conversationId: 'c1',
        refreshEvery: null,
      );
      await vm.load();
      service.failNext = const ServerFailure('500');
      await vm.sendText('Oups');
      vm.discard(vm.outbox.single);
      expect(vm.outbox, isEmpty);
      vm.dispose();
    });

    test('fil : un séparateur par jour, « vu », groupes, commande', () async {
      final vm = ChatViewModel(
        service: _service(ChatRole.client),
        conversationId: 'c1',
        refreshEvery: null,
      );
      await vm.load();
      final entries = vm.entries;
      expect(entries.first, isA<ChatDayEntry>());
      expect(entries.whereType<ChatDayEntry>(), hasLength(1));
      final m0 = entries.whereType<ChatMessageEntry>().first;
      expect(m0.seen, isTrue, reason: 'lu par la boutique');
      final m3 = entries.whereType<ChatMessageEntry>().last;
      expect(m3.seen, isFalse, reason: 'photo envoyée après la lecture');
      final m2 = entries.whereType<ChatMessageEntry>().elementAt(2);
      expect(m2.continued, isTrue, reason: 'suite de la boutique');
      expect(vm.activeOrder?.status, OrderStatus.preparing);
      expect(vm.activeOrderTotal, isNotNull);
      vm.dispose();
    });

    test(
      'réponses rapides : selon le rôle, cachées pendant la saisie',
      () async {
        final client = ChatViewModel(
          service: _service(ChatRole.client),
          conversationId: 'c1',
          refreshEvery: null,
        );
        final vendor = ChatViewModel(
          service: _service(ChatRole.vendor),
          conversationId: 'c1',
          refreshEvery: null,
        );
        expect(client.quickReplies, QuickReply.client);
        expect(vendor.quickReplies, QuickReply.vendor);
        client.textChanged('Bonj');
        expect(client.quickReplies, isEmpty);
        client.textChanged();
        expect(client.quickReplies, isNotEmpty);
        client.dispose();
        vendor.dispose();
      },
    );

    test('conversations : recherche par prénom', () async {
      final vm = ConversationsViewModel(
        service: _service(ChatRole.vendor),
        refreshEvery: null,
      );
      await vm.load();
      vm.setQuery('mar');
      expect(vm.shown.single.clientFirstName, 'Mariam');
      vm.dispose();
    });

    test('panier proposé : plusieurs produits envoyés', () async {
      final service = _service(ChatRole.vendor);
      final vm = ChatViewModel(
        service: service,
        conversationId: 'c1',
        refreshEvery: null,
      );
      await vm.load();
      expect(await vm.sendProducts(['p-gombo', 'p-gombo']), isTrue);
      expect(service.sent, ['product:p-gombo', 'product:p-gombo']);
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
              pickProducts: (_, _) async => null,
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

  testWidgets('62 : la vendeuse partage des produits (panier proposé)', (
    tester,
  ) async {
    final service = _service(ChatRole.vendor);
    await _pump(
      tester,
      ChatView(
        service: service,
        conversationId: 'c1',
        onBack: () {},
        pickProducts: (context, _) => showProductShareSheet(context, const [
          ShareableProduct(id: 'p-gombo', name: 'Gombo frais'),
          ShareableProduct(id: 'p-tomate', name: 'Tomates'),
        ]),
        clock: _clock,
        refreshEvery: null,
      ),
    );
    await tester.tap(find.byTooltip('Joindre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partager un produit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gombo frais').last);
    await tester.pump();
    await tester.tap(find.text('Envoyer 1 produit'));
    await tester.pumpAndSettle();
    expect(service.sent, ['product:p-gombo']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('60 : réponse rapide, bandeau de commande, boutique', (
    tester,
  ) async {
    final service = _service(ChatRole.client);
    final orders = <String>[];
    final stores = <String>[];
    await _pump(
      tester,
      ChatView(
        service: service,
        conversationId: 'c1',
        onBack: () {},
        onOpenOrder: orders.add,
        onOpenStore: stores.add,
        clock: _clock,
        refreshEvery: null,
      ),
    );
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Commande en cours'), findsOneWidget);
    await tester.tap(find.text('Commande en cours'));
    expect(orders, ['o1']);
    await tester.tap(find.text('Voir la boutique'));
    expect(stores, ['s1']);
    await tester.tap(find.text("C'est disponible ?"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(service.sent, ["text:C'est disponible ?"]);
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
