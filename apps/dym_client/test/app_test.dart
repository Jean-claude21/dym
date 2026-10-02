import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/app/config_error_app.dart';
import 'package:dym_client/ui/navigation.dart';
import 'package:dym_client/ui/views/home/home_view.dart';
import 'package:dym_client/ui/views/startup/startup_view.dart';
import 'package:dym_client/ui/views/startup/startup_viewmodel.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

class _Auth implements AuthService {
  new(this.bootstrapResult);

  final Result<AuthState> bootstrapResult;
  final calls = <String>[];

  @override
  AccountApp get app => AccountApp.client;

  @override
  bool get googleAvailable => false;

  @override
  String? get email => 'awa.mensah@gmail.com';

  @override
  Me? me = const Me(
    userId: 'u1',
    roles: {UserRole.client},
    profile: Profile(
      userId: 'u1',
      firstName: 'Awa',
      countryCode: 'TG',
      locale: 'fr',
      zoneId: 'z',
    ),
  );

  @override
  Future<Result<AuthState>> bootstrap() async => bootstrapResult;

  @override
  Future<Result<void>> signOut() async {
    calls.add('signOut');
    return const Ok(null);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Navigator implements AppNavigator {
  final routes = <String>[];

  @override
  void toHome() => routes.add('home');

  @override
  void toSignIn({bool startWithProfile = false}) =>
      routes.add(startWithProfile ? 'signIn:profile' : 'signIn');

  @override
  void toAisle(String categoryId) => routes.add('aisle:$categoryId');

  @override
  void toStore(String storeId) => routes.add('store:$storeId');

  @override
  void toProduct(String productId) => routes.add('product:$productId');

  @override
  void toSearch() => routes.add('search');
}

DymEnvironment _env(String name) => DymEnvironment.resolve(
  env: name,
  authUrl: 'https://auth.example.com',
  dataApiUrl: 'https://data.example.com',
  functionsUrl: 'https://fn.example.com',
  mediaUrl: 'https://media.example.com/product-photos',
);

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

  group('démarrage', () {
    Future<_Navigator> start(
      WidgetTester tester,
      Result<AuthState> result, {
      String env = 'dev',
    }) async {
      final navigator = _Navigator();
      await _pump(
        tester,
        StartupView(
          viewModelFactory: () => StartupViewModel(
            auth: _Auth(result),
            environment: _env(env),
            navigator: navigator,
          ),
        ),
      );
      return navigator;
    }

    testWidgets('sans session : connexion', (tester) async {
      final nav = await start(tester, const Ok(AuthState.signedOut()));
      expect(nav.routes, ['signIn']);
    });

    testWidgets("profil à compléter : connexion à l'étape profil", (
      tester,
    ) async {
      final nav = await start(
        tester,
        const Ok(
          AuthState(AuthStatus.needsProfile, Me(userId: 'u', roles: {})),
        ),
      );
      expect(nav.routes, ['signIn:profile']);
    });

    testWidgets('prête : accueil', (tester) async {
      final nav = await start(
        tester,
        const Ok(AuthState(AuthStatus.ready, Me(userId: 'u', roles: {}))),
      );
      expect(nav.routes, ['home']);
    });

    testWidgets('hors ligne : reprise proposée, rien de perdu', (tester) async {
      final nav = await start(tester, const Err(NetworkFailure('hors ligne')));
      expect(nav.routes, isEmpty);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('session révoquée : connexion', (tester) async {
      final nav = await start(
        tester,
        const Err(UnauthenticatedFailure('révoquée')),
      );
      expect(nav.routes, ['signIn']);
    });

    testWidgets("production : pas d'environnement affiché", (tester) async {
      await start(tester, const Err(ServerFailure('x')), env: 'production');
      expect(find.textContaining('Environnement'), findsNothing);
    });

    testWidgets('configuration manquante : écran dédié', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('fr')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(const ConfigErrorApp());
      await tester.pump();
      expect(find.text('Configuration manquante'), findsOneWidget);
    });
  });

  group('accueil, rayons et « Moi »', () {
    for (final size in sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        for (final tab in [0, 1, 2]) {
          testWidgets(
            'onglet $tab · ${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode} · texte 130 %',
            (tester) async {
              await _pump(
                tester,
                HomeView(
                  service: _Auth(const Ok(AuthState.signedOut())),
                  discovery: memoryDiscovery(),
                  navigator: _Navigator(),
                ),
                size: size,
                locale: locale,
                textScale: 1.3,
              );
              final fr = locale.languageCode == 'fr';
              final label = switch (tab) {
                1 => fr ? 'Rayons' : 'Aisles',
                2 => fr ? 'Moi' : 'Me',
                _ => null,
              };
              if (label != null) {
                await tester.tap(find.text(label).last);
                await tester.pump();
              }
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }

    testWidgets('déconnexion depuis « Moi » : retour à la connexion', (
      tester,
    ) async {
      final auth = _Auth(const Ok(AuthState.signedOut()));
      final nav = _Navigator();
      await _pump(
        tester,
        HomeView(service: auth, discovery: memoryDiscovery(), navigator: nav),
      );
      await tester.pump();
      expect(find.text('Boutiques ouvertes près de toi'), findsOneWidget);
      await tester.tap(find.text('Moi').first);
      await tester.pump();
      await tester.tap(find.text('Se déconnecter'));
      await tester.pump();
      expect(auth.calls, ['signOut']);
      expect(nav.routes, ['signIn']);
    });
  });
}
