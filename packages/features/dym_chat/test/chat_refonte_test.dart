import 'dart:async';
import 'dart:typed_data';

import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chat refait (spec 111) : réponse, réactions, suppression, transfert,
/// document, « écrit… », « reçu », nouveaux messages, recherche, filtres,
/// vocal chronométré.

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

class _Docs implements DocumentPicker {
  new(this.result);

  final Result<PickedDocument?> result;

  @override
  Future<Result<PickedDocument?>> pick() async => result;
}

class _Recorder implements VoiceRecorder {
  final _levels = StreamController<double>.broadcast();

  @override
  Stream<double> get level => _levels.stream;

  @override
  Future<Result<void>> start() async => const Ok(null);

  @override
  Future<Result<RecordedAudio?>> stop() async => Ok(
    RecordedAudio(
      bytes: Uint8List(10),
      contentType: 'audio/wav',
      duration: const Duration(seconds: 3),
    ),
  );

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async => await _levels.close();
}

Future<ChatViewModel> _vm(
  MemoryChatService service, {
  DateTime Function()? clock,
  Duration? refreshEvery,
}) async {
  final vm = ChatViewModel(
    service: service,
    conversationId: 'c1',
    refreshEvery: refreshEvery,
    clock: clock ?? () => DateTime.utc(2026, 10, 5, 10, 20),
  );
  await vm.load();
  return vm;
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view
    ..physicalSize = const Size(412, 915)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(412, 915),
          disableAnimations: true,
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('viewmodel', () {
    test('répondre : le message part avec sa citation', () async {
      final vm = await _vm(_service(ChatRole.client));
      vm.startReply(vm.messageById('m1')!);
      expect(vm.replyingTo?.id, 'm1');
      expect(await vm.sendText('Super, 3 tas'), isTrue);
      expect(vm.replyingTo, isNull);
      final sent = vm.messages.last;
      expect(sent.replyTo?.id, 'm1');
      expect(sent.replyTo?.body, "Oui ! Je viens d'en recevoir ce matin.");
    });

    test('réagir : une réaction par personne, la même la retire', () async {
      final vm = await _vm(_service(ChatRole.client));
      await vm.react(vm.messageById('m1')!, '👍');
      expect(vm.messageById('m1')!.reactions.single.emoji, '👍');
      expect(vm.messageById('m1')!.reactionOf(ChatRole.client), '👍');
      await vm.react(vm.messageById('m1')!, '❤️');
      expect(vm.messageById('m1')!.reactions.single.emoji, '❤️');
      await vm.react(vm.messageById('m1')!, '❤️');
      expect(vm.messageById('m1')!.reactions, isEmpty);
    });

    test("supprimer : pour tous dans l'heure, pour moi ensuite", () async {
      final service = _service(ChatRole.client);
      final early = await _vm(service);
      final m0 = early.messageById('m0')!;
      expect(early.canDeleteForAll(m0), isTrue);
      // Pas le message d'un autre.
      expect(early.canDeleteForAll(early.messageById('m1')!), isFalse);
      final late = await _vm(
        service,
        clock: () => DateTime.utc(2026, 10, 5, 12),
      );
      expect(late.canDeleteForAll(m0), isFalse);

      expect(await early.deleteMessage(m0, forAll: true), isTrue);
      expect(early.messageById('m0')!.deleted, isTrue);
      expect(early.messageById('m0')!.body, isNull);
      expect(
        await early.deleteMessage(early.messageById('m3')!, forAll: false),
        isTrue,
      );
      expect(early.messageById('m3'), isNull);
      expect(service.actions.where((a) => a.startsWith('delete')), [
        'delete:m0:all',
        'delete:m3:me',
      ]);
    });

    test('transférer : texte vers une autre conversation', () async {
      final service = _service(ChatRole.vendor);
      final vm = await _vm(service);
      final targets = await vm.forwardTargets();
      expect(targets.map((c) => c.id), isNot(contains('c1')));
      expect(targets, isNotEmpty);
      expect(vm.messageById('m1')!.forwardable, isTrue);
      expect(vm.messageById('m3')!.forwardable, isFalse);
      expect(await vm.forward(vm.messageById('m1')!, 'c2'), isTrue);
      expect(service.actions, contains('forward:m1:c2'));
    });

    test(
      'document : envoyé avec nom et taille ; trop lourd : refusé',
      () async {
        final service = _service(ChatRole.client)
          ..documents = _Docs(
            Ok(
              PickedDocument(
                bytes: Uint8List(52000),
                name: 'facture.pdf',
                contentType: 'application/pdf',
              ),
            ),
          );
        final vm = await _vm(service);
        expect(vm.canSendDocuments, isTrue);
        expect(await vm.sendDocument(), isTrue);
        final sent = vm.messages.last;
        expect(sent.kind, MessageKind.file);
        expect(sent.fileName, 'facture.pdf');
        expect(sent.fileSize, 52000);

        service.documents = _Docs(const Err(ValidationFailure('too_large')));
        expect(await vm.sendDocument(), isFalse);
        expect(vm.sendFailure, isA<ValidationFailure>());
        expect(
          documentFrom('virus.exe', Uint8List(3)),
          isA<Err<PickedDocument?>>(),
        );
      },
    );

    test('« écrit… » : envoyé une fois par 3 s, reçu en direct', () async {
      final service = _service(ChatRole.client);
      final vm = await _vm(service, refreshEvery: const Duration(hours: 1));
      vm
        ..textChanged('B')
        ..textChanged('Bo')
        ..textChanged('Bon');
      expect(service.actions.where((a) => a.startsWith('typing')).length, 1);

      service.liveSignals.add(
        const LiveSignal.event(
          kind: 'typing',
          entityId: 'c1',
          payload: {'role': 'vendor'},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(vm.typingRole, 'vendor');
      expect(vm.typingName, "Étal d'Akossiwa");
      vm.dispose();
    });

    test('« Nouveaux messages » et ✓✓ reçus', () async {
      final base = _service(ChatRole.client);
      final thread = (await base.thread('c1')).valueOrNull!;
      final at = DateTime.utc(2026, 10, 5, 10);
      final service = MemoryChatService(
        role: ChatRole.client,
        config: _config,
        threads: [
          ConversationThread(
            conversation: thread.conversation,
            role: 'client',
            messages: thread.messages,
            myReadAt: at.add(const Duration(minutes: 3)),
            peerDeliveredAt: at.add(const Duration(minutes: 7)),
          ),
        ],
      );
      final vm = await _vm(service);
      final entries = vm.entries;
      final i = entries.indexWhere((e) => e is ChatNewEntry);
      expect((entries[i] as ChatNewEntry).count, 2);
      expect((entries[i + 1] as ChatMessageEntry).message.id, 'm1');
      final photo = entries.whereType<ChatMessageEntry>().last;
      expect(photo.message.id, 'm3');
      expect(photo.delivered, isTrue);
      expect(photo.seen, isFalse);
    });

    test('recherche et galerie de la conversation', () async {
      final vm = await _vm(_service(ChatRole.client));
      vm
        ..openSearch()
        ..setSearch('g');
      expect(vm.searchResults, isEmpty);
      vm.setSearch('gombo');
      expect(vm.searchResults.map((m) => m.id), ['m2', 'm0']);
      vm.closeSearch();
      expect(vm.searching, isFalse);
      expect(vm.mediaMessages.map((m) => m.id), ['m3']);
    });

    test("liste : filtres, « reçu » signalé à l'ouverture", () async {
      final service = _service(ChatRole.vendor);
      final vm = ConversationsViewModel(service: service, refreshEvery: null);
      await vm.load();
      expect(service.actions, contains('delivered'));
      final all = vm.shown.length;
      vm.setFilter(ConversationFilter.unread);
      expect(vm.shown.every((c) => c.unread > 0), isTrue);
      expect(vm.shown.length, lessThan(all));
      vm.setFilter(ConversationFilter.orders);
      expect(vm.shown, isEmpty);
    });
  });

  group('écran', () {
    testWidgets('appui long : réagir puis répondre avec citation', (
      tester,
    ) async {
      final service = _service(ChatRole.client);
      await _pump(
        tester,
        ChatView(
          service: service,
          conversationId: 'c1',
          onBack: () {},
          clock: () => DateTime.utc(2026, 10, 5, 10, 20),
          refreshEvery: null,
        ),
      );
      await tester.longPress(
        find.text("Oui ! Je viens d'en recevoir ce matin."),
      );
      await tester.pumpAndSettle();
      expect(find.text('Répondre'), findsOneWidget);
      expect(find.text('Transférer'), findsOneWidget);
      await tester.tap(find.text('👍'));
      await tester.pumpAndSettle();
      expect(service.actions, contains('react:m1:👍'));

      await tester.longPress(
        find.text("Oui ! Je viens d'en recevoir ce matin."),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Répondre'));
      await tester.pumpAndSettle();
      expect(find.text("Réponse à Étal d'Akossiwa"), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Parfait');
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Parfait'), findsOneWidget);
      // Citation dans la bulle envoyée.
      expect(
        find.text("Oui ! Je viens d'en recevoir ce matin."),
        findsNWidgets(2),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('supprimé pour tous, document, filtres', (tester) async {
      final service = _service(ChatRole.client)
        ..documents = _Docs(
          Ok(
            PickedDocument(
              bytes: Uint8List(2048),
              name: 'liste-courses.pdf',
              contentType: 'application/pdf',
            ),
          ),
        );
      await service.deleteMessage('m0', forAll: true);
      await _pump(
        tester,
        ChatView(
          service: service,
          conversationId: 'c1',
          onBack: () {},
          clock: () => DateTime.utc(2026, 10, 5, 10, 20),
          refreshEvery: null,
        ),
      );
      expect(find.text('Ce message a été supprimé'), findsOneWidget);
      await tester.tap(find.byTooltip('Joindre'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Document'));
      await tester.pumpAndSettle();
      expect(find.text('liste-courses.pdf'), findsOneWidget);
      expect(find.text('2 Ko · PDF'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());

      await _pump(
        tester,
        ConversationsView(
          service: _service(ChatRole.vendor),
          onOpen: (_) {},
          refreshEvery: null,
        ),
      );
      expect(find.text('Toutes'), findsOneWidget);
      await tester.tap(find.text('Non lues'));
      await tester.pump();
      expect(find.text('Kossi'), findsNothing);
      expect(find.text('Mariam'), findsOneWidget);
    });

    testWidgets('vocal : les secondes défilent, envoi verrouillé', (
      tester,
    ) async {
      var now = DateTime.utc(2026, 10, 5, 10, 20);
      final service = _service(ChatRole.client)..recorder = _Recorder();
      await _pump(
        tester,
        ChatView(
          service: service,
          conversationId: 'c1',
          onBack: () {},
          clock: () => now,
          refreshEvery: null,
        ),
      );
      await tester.tap(find.byTooltip('Enregistrer un vocal'));
      await tester.pump();
      expect(find.text('0:00'), findsOneWidget);
      now = now.add(const Duration(seconds: 7));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('0:07'), findsOneWidget);
      await tester.tap(find.byTooltip('Envoyer le vocal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(service.sent.last, startsWith('audio:'));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
