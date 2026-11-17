import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Groupes (spec 112) : espace famille et achat groupé.

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
  test('dans un groupe, « mien » vient de la base, pas du rôle', () {
    final theirs = ChatMessage(
      id: 'x',
      conversationId: 'g',
      authorRole: 'client',
      kind: MessageKind.text,
      createdAt: DateTime.utc(2026),
      authorName: 'Mia',
      mine: false,
      reactions: const [
        MessageReaction(emoji: '👍', count: 1, roles: ['client'], mine: false),
      ],
    );
    expect(theirs.fromMe(ChatRole.client), isFalse);
    expect(theirs.reactionOf(ChatRole.client), isNull);
  });

  test('liste : créer un groupe famille, filtre Groupes', () async {
    final service = _service(ChatRole.client);
    final vm = ConversationsViewModel(service: service, refreshEvery: null);
    await vm.load();
    expect(vm.canCreateGroups, isTrue);
    expect(vm.hasGroups, isFalse);
    final id = await vm.createFamilyGroup('La famille');
    expect(id, isNotNull);
    expect(vm.hasGroups, isTrue);
    vm.setFilter(ConversationFilter.groups);
    expect(vm.shown.single.title(ChatRole.client), 'La famille');
    final vendor = ConversationsViewModel(
      service: _service(ChatRole.vendor),
      refreshEvery: null,
    );
    expect(vendor.canCreateGroups, isFalse);
  });

  test(
    'groupe : membres par code, retrait, nom ; ni réponses rapides',
    () async {
      final service = _service(ChatRole.client);
      final conv = (await service.createFamilyGroup('La famille')).valueOrNull!;
      final vm = ChatViewModel(
        service: service,
        conversationId: conv.id,
        refreshEvery: null,
      );
      await vm.load();
      expect(vm.isGroup, isTrue);
      expect(vm.quickReplies, isEmpty);
      await vm.loadGroup();
      expect(vm.group!.meAdmin, isTrue);
      expect(await vm.addMember('mia12345'), isNull);
      expect(vm.group!.members.map((m) => m.firstName), ['Awa', 'Mia']);
      expect(await vm.addMember('INCONNU'), 'recipient_unknown');
      await vm.removeMember('u-Mia');
      expect(vm.group!.members.length, 1);
      await vm.renameGroup('Famille et voisins');
      expect(vm.group!.title, 'Famille et voisins');
    },
  );

  testWidgets('créer un groupe depuis la liste, puis ses infos', (
    tester,
  ) async {
    final service = _service(ChatRole.client);
    String? opened;
    await _pump(
      tester,
      ConversationsView(
        service: service,
        onOpen: (id) => opened = id,
        refreshEvery: null,
      ),
    );
    await tester.tap(find.byTooltip('Nouveau groupe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'La famille');
    await tester.pump();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    expect(opened, isNotNull);
    expect(find.text('La famille'), findsOneWidget);
    expect(find.text('Groupes'), findsOneWidget);

    await _pump(
      tester,
      ChatView(
        service: service,
        conversationId: opened!,
        onBack: () {},
        refreshEvery: null,
      ),
    );
    expect(find.text('1 membre'), findsOneWidget);
    expect(find.byTooltip('Appeler'), findsNothing);
    expect(find.text('Écris le premier message du groupe.'), findsOneWidget);
    await tester.tap(find.text('La famille'));
    await tester.pumpAndSettle();
    expect(find.text('Infos du groupe'), findsOneWidget);
    await tester.tap(find.text('Ajouter un proche'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'YAO12345');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter un proche'));
    await tester.pumpAndSettle();
    expect(find.text('Yao'), findsOneWidget);
    expect(find.text('Administratrice'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("fil d'achat groupé : le prénom au-dessus des messages", (
    tester,
  ) async {
    final service = _service(ChatRole.client);
    final conv = (await service.groupOfferThread('o1')).valueOrNull!;
    final base = (await service.thread(conv.id)).valueOrNull!;
    final threaded = MemoryChatService(
      role: ChatRole.client,
      config: _config,
      threads: [
        base.copyWith(
          messages: [
            ChatMessage(
              id: 'm1',
              conversationId: conv.id,
              authorRole: 'client',
              kind: MessageKind.text,
              body: 'Je prends 3 tas, qui partage la livraison ?',
              createdAt: DateTime.utc(2026, 10, 5, 10),
              authorName: 'Efua',
              mine: false,
            ),
          ],
        ),
      ],
    );
    await _pump(
      tester,
      ChatView(
        service: threaded,
        conversationId: conv.id,
        onBack: () {},
        refreshEvery: null,
      ),
    );
    expect(find.text('Igname'), findsOneWidget);
    expect(find.text('Efua'), findsOneWidget);
    expect(find.text('3 membres'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
