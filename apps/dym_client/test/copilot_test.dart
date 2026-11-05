import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/discovery/copilot/copilot_view.dart';
import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
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

CopilotLine _line(String id, String name, int qty, int price, String need) =>
    CopilotLine(
      variantId: id,
      productId: 'p-$id',
      name: name,
      quantity: qty,
      unitLabel: 'tas',
      unitPriceMinor: price,
      lineMinor: qty * price,
      need: need,
    );

final _proposal = CopilotProposal(
  currencyCode: 'XOF',
  totalMinor: 2 * 300 + 500 + 1200,
  stores: [
    CopilotStoreLines(
      id: 's1',
      name: "Étal d'Akossiwa",
      lines: [
        _line('v1', 'Gombo frais', 2, 300, 'Gombo'),
        _line('v2', 'Tomates fraîches', 1, 500, 'Tomates'),
      ],
    ),
    CopilotStoreLines(
      id: 's2',
      name: 'Chez Afi',
      lines: [_line('v3', 'Huile rouge', 1, 1200, 'Huile rouge')],
    ),
  ],
  missing: const ['Crevettes séchées'],
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
  await tester.pumpAndSettle();
}

void main() {
  group('viewmodel', () {
    test('intention → proposition, retrait rechiffré, tout ajouter', () async {
      final service = MemoryCopilotService(
        discovery: memoryDiscovery(),
        proposal: _proposal,
      );
      final vm = CopilotViewModel(service: service);
      await vm.init(initialText: 'Une sauce gombo pour 4');
      expect(vm.proposal!.lines, hasLength(3));
      await vm.remove(vm.proposal!.lines.first);
      expect(vm.proposal!.lines, hasLength(2));
      expect(vm.proposal!.totalMinor, 1700, reason: 'total du serveur');
      expect(vm.proposal!.missing, ['Crevettes séchées']);
      expect(await vm.addAll(), isTrue);
      expect(service.added, ['v2', 'v3']);
    });

    test('IA indisponible : échec, aucune proposition inventée', () async {
      final vm = CopilotViewModel(
        service: MemoryCopilotService(
          discovery: memoryDiscovery(),
          failure: const ServerFailure('503'),
        ),
      );
      await vm.init(initialText: 'anniversaire');
      expect(vm.proposal, isNull);
      expect(vm.failure, isA<ServerFailure>());
    });

    test('photo : décrite puis demandée', () async {
      final vm = CopilotViewModel(
        service: MemoryCopilotService(
          discovery: memoryDiscovery(),
          proposal: _proposal,
        ),
        ai: MemorySearchAiService(seen: 'sauce gombo'),
      );
      await vm.init();
      expect(vm.aiEnabled, isTrue);
      await vm.askPhoto(PhotoSource.gallery);
      expect(vm.asked, 'sauce gombo');
    });
  });

  group('écran 73 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        testWidgets('73 · $name', (tester) async {
          await _pump(
            tester,
            CopilotView(
              service: MemoryCopilotService(
                discovery: memoryDiscovery(),
                proposal: _proposal,
              ),
              ai: MemorySearchAiService(),
              initialText: 'Une sauce gombo pour 4 personnes ce soir',
              onBack: () {},
              onSearchMyself: (_) {},
              onAdded: () {},
            ),
            size: size,
            locale: locale,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
          expect(find.text("Étal d'Akossiwa"), findsOneWidget);
        });
        testWidgets('73 rien trouvé · $name', (tester) async {
          await _pump(
            tester,
            CopilotView(
              service: MemoryCopilotService(discovery: memoryDiscovery()),
              initialText: 'un vélo',
              onBack: () {},
              onSearchMyself: (_) {},
              onAdded: () {},
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

  testWidgets('retirer, tout ajouter, chercher moi-même', (tester) async {
    final l10n = await DymLocalizations.delegate.load(const Locale('fr'));
    final service = MemoryCopilotService(
      discovery: memoryDiscovery(),
      proposal: _proposal,
    );
    var added = false;
    String? myself;
    await _pump(
      tester,
      CopilotView(
        service: service,
        initialText: 'Une sauce gombo',
        onBack: () {},
        onSearchMyself: (t) => myself = t,
        onAdded: () => added = true,
      ),
    );
    expect(find.text(l10n.copilotMissing('Crevettes séchées')), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.copilotRemove('Huile rouge')));
    await tester.pumpAndSettle();
    expect(find.text('Huile rouge'), findsNothing);
    expect(find.text('Chez Afi'), findsNothing, reason: 'boutique vidée');
    await tester.tap(find.text(l10n.copilotAddAll));
    await tester.pumpAndSettle();
    expect(added, isTrue);
    expect(service.added, ['v1', 'v2']);
    await tester.tap(find.text(l10n.copilotSearchMyself));
    expect(myself, 'Une sauce gombo');
  });

  testWidgets('saisie : envoyer une intention', (tester) async {
    final l10n = await DymLocalizations.delegate.load(const Locale('fr'));
    await _pump(
      tester,
      CopilotView(
        service: MemoryCopilotService(
          discovery: memoryDiscovery(),
          proposal: _proposal,
        ),
        onBack: () {},
        onSearchMyself: (_) {},
        onAdded: () {},
      ),
    );
    expect(find.text(l10n.copilotExample), findsOneWidget);
    expect(find.byTooltip(l10n.voiceSearchAction), findsNothing);
    await tester.enterText(find.byType(TextField), 'Une sauce gombo');
    await tester.tap(find.byTooltip(l10n.copilotSend));
    await tester.pumpAndSettle();
    expect(find.text(l10n.copilotProposal), findsOneWidget);
  });
}
