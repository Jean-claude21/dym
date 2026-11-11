// Fakes repris des tests d'écran : certaines aides n'y servent pas.
// ignore_for_file: unused_element
@Tags(['golden'])
library;

import 'package:dym_client/features/discovery/search/search_view.dart';
import 'package:dym_client/features/discovery/search/voice_search_view.dart';
import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/discovery_fixtures.dart';
import 'capture.dart';

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
  testWidgets('vocal', (tester) async {
    await capture(
      tester,
      'vocal',
      VoiceSearchView(
        service: MemorySearchAiService(),
        onBack: () {},
        onSearch: (_, _) {},
      ),
    );
  });
}
