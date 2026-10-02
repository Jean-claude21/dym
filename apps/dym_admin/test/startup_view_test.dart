import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dym_admin/app/config_error_app.dart';
import 'package:dym_admin/ui/views/startup/startup_view.dart';
import 'package:dym_admin/ui/views/startup/startup_viewmodel.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_kit/neon_kit.dart';

/// Aucun accès réseau en test : toute requête échoue.
class _Offline implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => throw DioException.connectionError(
    requestOptions: options,
    reason: 'hors ligne',
  );

  @override
  void close({bool force = false}) {}
}

StartupViewModel _viewModel(String env) {
  final environment = DymEnvironment.resolve(
    env: env,
    authUrl: 'https://auth.example.com',
    dataApiUrl: 'https://data.example.com',
    functionsUrl: 'https://fn.example.com',
  );
  return StartupViewModel(
    environment: environment,
    neon: NeonClient(
      config: NeonConfig(
        authUrl: environment.authUrl,
        dataApiUrl: environment.dataApiUrl,
        functionsUrl: environment.functionsUrl,
      ),
      sessionStore: InMemorySessionStore(),
      adapter: _Offline(),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
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
        child: home,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  const sizes = [
    Size(360, 640),
    Size(412, 915),
    Size(915, 412),
    Size(640, 360),
    Size(800, 1280),
    Size(1280, 800),
    Size(1440, 900),
  ];

  for (final locale in const [Locale('fr'), Locale('en')]) {
    for (final size in sizes) {
      final label =
          '${locale.languageCode} · '
          '${size.width.toInt()}×${size.height.toInt()} · texte 130 %';
      testWidgets('démarrage · $label', (tester) async {
        await _pump(
          tester,
          StartupView(viewModelFactory: () => _viewModel('dev')),
          size: size,
          locale: locale,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        expect(find.textContaining('dev'), findsOneWidget);
      });
    }
  }

  testWidgets("production : pas d'environnement affiché", (tester) async {
    await _pump(
      tester,
      StartupView(viewModelFactory: () => _viewModel('production')),
    );
    expect(find.textContaining('Environnement'), findsNothing);
  });

  testWidgets('anglais : textes traduits', (tester) async {
    await _pump(
      tester,
      StartupView(viewModelFactory: () => _viewModel('dev')),
      locale: const Locale('en'),
    );
    expect(find.text('Environment: dev'), findsOneWidget);
  });

  testWidgets('configuration manquante : écran dédié', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ConfigErrorApp());
    await tester.pump();
    expect(find.text('Configuration manquante'), findsOneWidget);
  });
}
