import 'dart:typed_data';

import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/search/search_view.dart';
import 'package:dym_client/features/discovery/search/voice_search_view.dart';
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
  await tester.pumpAndSettle();
}

void _noop([Object? _]) {}

SearchView _search(SearchAiService ai) => SearchView(
  service: memoryDiscovery(),
  onBack: _noop,
  onOpenProduct: _noop,
  onOpenStore: _noop,
  debounce: Duration.zero,
  ai: ai,
);

class _FailingAi extends MemorySearchAiService {
  new() : super(recorder: MemoryVoiceRecorder(fail: true));

  @override
  Future<Result<String?>> describePhoto(PickedPhoto photo) async =>
      const Err(NetworkFailure('hors ligne'));
}

void main() {
  group('viewmodels', () {
    test('voix : écoute, transcription, texte entendu', () async {
      final ai = MemorySearchAiService();
      final vm = VoiceSearchViewModel(service: ai);
      await vm.init();
      expect(vm.step, VoiceStep.listening);
      expect(vm.history, hasLength(3));
      (ai.recorder as MemoryVoiceRecorder).speak(0.9);
      await Future<void>.delayed(Duration.zero);
      expect(vm.levels.last, 0.9);
      await vm.finish();
      expect(vm.step, VoiceStep.heard);
      expect(vm.heard, 'des tomates et du gombo pour ce soir');
      vm.dispose();
    });

    test('voix : micro refusé, rien compris', () async {
      final denied = VoiceSearchViewModel(service: _FailingAi());
      await denied.init();
      expect(denied.step, VoiceStep.failed);
      expect(denied.failure, isA<ForbiddenFailure>());
      final silent = VoiceSearchViewModel(
        service: MemorySearchAiService(heard: null),
      );
      await silent.init();
      await silent.finish();
      expect(silent.step, VoiceStep.nothing);
    });

    test('recherche : seules les recherches validées sont retenues', () async {
      final ai = MemorySearchAiService();
      final vm = SearchViewModel(
        service: memoryDiscovery(),
        debounce: Duration.zero,
        ai: ai,
      );
      await vm.init();
      expect(vm.aiEnabled, isTrue);
      vm.setText('bis');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(ai.remembered, isEmpty, reason: 'frappe intermédiaire');
      expect(vm.suggestions.map((s) => s.label.resolve('fr')), [
        'Jus de bissap',
      ]);
      await vm.submitTyped();
      expect(ai.remembered.single, ('bis', SearchSource.text));
      expect(vm.history.first.query, 'bis');
      await vm.searchPhoto(PhotoSource.gallery);
      expect(vm.photo?.query, 'gombo frais');
      expect(ai.remembered.last, ('gombo frais', SearchSource.photo));
      vm.editPhotoQuery();
      expect(vm.photo, isNull);
      await vm.forgetHistory();
      expect(vm.history, isEmpty);
    });

    test('photo : non reconnue, puis échec réseau', () async {
      final vm = SearchViewModel(
        service: memoryDiscovery(),
        ai: MemorySearchAiService(seen: null),
      );
      await vm.init();
      await vm.searchPhoto(PhotoSource.camera);
      expect(vm.photoOutcome, const Ok<void>(null));
      final failing = SearchViewModel(
        service: memoryDiscovery(),
        ai: _FailingAi(),
      );
      await failing.init();
      await failing.searchPhoto(PhotoSource.camera);
      expect(failing.photoOutcome?.failureOrNull, isA<NetworkFailure>());
    });

    test('flag coupé : ni voix ni photo', () async {
      final vm = SearchViewModel(
        service: memoryDiscovery(),
        ai: MemorySearchAiService(enabled: false),
      );
      await vm.init();
      expect(vm.aiEnabled, isFalse);
    });
  });

  group('écrans 71 et 72 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        Future<void> show(WidgetTester tester, Widget view) async {
          await _pump(tester, view, size: size, locale: locale, textScale: 1.3);
          expect(tester.takeException(), isNull);
        }

        testWidgets('71 · $name', (tester) async {
          final ai = MemorySearchAiService();
          await show(
            tester,
            VoiceSearchView(service: ai, onBack: _noop, onSearch: (_, _) {}),
          );
          final l10n = await DymLocalizations.delegate.load(locale);
          await tester.tap(find.byTooltip(l10n.voiceStop));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.textContaining('tomates et du gombo', findRichText: true),
            findsWidgets,
          );
        });
        testWidgets('72 · $name', (tester) async {
          final ai = MemorySearchAiService(
            photo: PickedPhoto(bytes: Uint8List(0), contentType: 'image/jpeg'),
            seen: 'bissap',
          );
          await show(tester, _search(ai));
          final l10n = await DymLocalizations.delegate.load(locale);
          await tester.tap(find.byTooltip(l10n.photoSearchAction));
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.photoFromGallery));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text(l10n.photoSearchFrom), findsOneWidget);
          expect(find.text('bissap'), findsWidgets);
        });
        testWidgets('historique et suggestions · $name', (tester) async {
          await show(tester, _search(MemorySearchAiService()));
          expect(find.text('jus de bissap'), findsOneWidget);
          await tester.enterText(find.byType(TextField), 'tom');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('71 → recherche du texte entendu', (tester) async {
    final ai = MemorySearchAiService(heard: 'bissap');
    final l10n = await DymLocalizations.delegate.load(const Locale('fr'));
    await _pump(tester, _search(ai));
    await tester.tap(find.byTooltip(l10n.voiceSearchAction));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.voiceStop));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.voiceSearch));
    await tester.pumpAndSettle();
    expect(find.text('Jus de bissap'), findsWidgets);
    expect(ai.remembered.single, ('bissap', SearchSource.voice));
  });

  testWidgets('historique : une puce relance la recherche, Effacer', (
    tester,
  ) async {
    final ai = MemorySearchAiService();
    final l10n = await DymLocalizations.delegate.load(const Locale('fr'));
    await _pump(tester, _search(ai));
    await tester.tap(find.text('jus de bissap'));
    await tester.pumpAndSettle();
    expect(find.text('Jus de bissap'), findsWidgets);
    await tester.tap(find.byTooltip(l10n.searchClear));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.searchHistoryClear));
    await tester.pumpAndSettle();
    expect(find.text(l10n.searchHistory), findsNothing);
  });

  testWidgets('flag coupé : pas de micro', (tester) async {
    final l10n = await DymLocalizations.delegate.load(const Locale('fr'));
    await _pump(tester, _search(MemorySearchAiService(enabled: false)));
    expect(find.byTooltip(l10n.voiceSearchAction), findsNothing);
  });
}
