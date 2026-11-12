import 'package:dym_admin/app/config_error_app.dart';
import 'package:dym_admin/features/ops/testing.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_admin/ui/views/home/admin_home_view.dart';
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_view.dart';
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_viewmodel.dart';
import 'package:dym_admin/ui/views/startup/startup_view.dart';
import 'package:dym_admin/ui/views/startup/startup_viewmodel.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth implements AuthService {
  new({
    this.bootstrapResult = const Ok(AuthState.signedOut()),
    this.googleResult = const Ok(null),
    this.googleAvailable = true,
  });

  final Result<AuthState> bootstrapResult;
  final Result<AuthState?> googleResult;
  final calls = <String>[];

  @override
  final bool googleAvailable;

  @override
  AccountApp get app => AccountApp.admin;

  @override
  String? get email => 'ops@dym.example';

  @override
  Me? me = const Me(
    userId: 'u1',
    roles: {UserRole.admin},
    profile: Profile(
      userId: 'u1',
      firstName: 'Kossi',
      countryCode: 'TG',
      locale: 'fr',
      zoneId: 'z',
    ),
  );

  @override
  Future<Result<AuthState>> bootstrap() async => bootstrapResult;

  @override
  Future<Result<AuthState?>> signInWithGoogle() async {
    calls.add('google');
    return googleResult;
  }

  @override
  Future<Result<void>> sendEmailCode(String email) async {
    calls.add('code:$email');
    return const Ok(null);
  }

  @override
  Future<Result<AuthState>> verifyEmailCode(String email, String code) async {
    calls.add('verify:$code');
    return _ready;
  }

  @override
  Future<Result<void>> signOut() async {
    calls.add('signOut');
    return const Ok(null);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Navigator implements AdminNavigator {
  final routes = <String>[];

  @override
  void toHome() => routes.add('home');

  @override
  void toSignIn({AdminNotice? notice}) =>
      routes.add(notice == null ? 'signIn' : 'signIn:${notice.name}');
}

const Ok<AuthState> _ready = Ok(
  AuthState(AuthStatus.ready, Me(userId: 'u1', roles: {UserRole.admin})),
);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(1440, 900),
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
  final env = DymEnvironment.resolve(env: 'dev');

  group('démarrage', () {
    Future<_Navigator> start(WidgetTester tester, Result<AuthState> r) async {
      final nav = _Navigator();
      await _pump(
        tester,
        StartupView(
          viewModelFactory: () => StartupViewModel(
            auth: _Auth(bootstrapResult: r),
            environment: env,
            navigator: nav,
          ),
        ),
      );
      return nav;
    }

    testWidgets('admin connecté : tableau de bord', (tester) async {
      expect((await start(tester, _ready)).routes, ['home']);
    });

    testWidgets('compte non admin : accès réservé (SC-005)', (tester) async {
      final nav = await start(tester, const Err(ForbiddenFailure('non')));
      expect(nav.routes, ['signIn:accessDenied']);
    });

    testWidgets('sans session : connexion', (tester) async {
      final nav = await start(tester, const Ok(AuthState.signedOut()));
      expect(nav.routes, ['signIn']);
    });
  });

  group('connexion', () {
    testWidgets('Google : admin → tableau de bord', (tester) async {
      final nav = _Navigator();
      final auth = _Auth(googleResult: _ready);
      await _pump(
        tester,
        AdminSignInView(
          viewModelFactory: () =>
              AdminSignInViewModel(auth: auth, navigator: nav),
        ),
      );
      await tester.tap(find.text('Continuer avec Google'));
      await tester.pump();
      expect(nav.routes, ['home']);
    });

    testWidgets('Google : compte non admin refusé, message', (tester) async {
      final nav = _Navigator();
      final auth = _Auth(googleResult: const Err(ForbiddenFailure('non')));
      await _pump(
        tester,
        AdminSignInView(
          viewModelFactory: () =>
              AdminSignInViewModel(auth: auth, navigator: nav),
        ),
      );
      await tester.tap(find.text('Continuer avec Google'));
      await tester.pump();
      expect(nav.routes, isEmpty);
      expect(find.textContaining("l'équipe DYM. Ce compte"), findsOneWidget);
    });

    testWidgets('Google non configuré : message, aucun bouton', (tester) async {
      await _pump(
        tester,
        AdminSignInView(
          viewModelFactory: () => AdminSignInViewModel(
            auth: _Auth(googleAvailable: false),
            navigator: _Navigator(),
          ),
        ),
      );
      expect(find.text('Continuer avec Google'), findsNothing);
      expect(find.text('Recevoir mon code'), findsOneWidget);
    });

    testWidgets('code email : admin par défaut → tableau de bord', (
      tester,
    ) async {
      final nav = _Navigator();
      final auth = _Auth(googleAvailable: false);
      await _pump(
        tester,
        AdminSignInView(
          viewModelFactory: () =>
              AdminSignInViewModel(auth: auth, navigator: nav),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'ops@dym.example');
      await tester.tap(find.text('Recevoir mon code'));
      await tester.pump();
      expect(auth.calls, ['code:ops@dym.example']);
      expect(find.textContaining('Envoyé à'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump();
      expect(auth.calls.last, 'verify:123456');
      expect(nav.routes, ['home']);
    });

    for (final size in const [
      Size(412, 915),
      Size(800, 1280),
      Size(1280, 800),
      Size(1440, 900),
    ]) {
      testWidgets(
        'mise en page ${size.width.toInt()}×${size.height.toInt()} · 130 %',
        (tester) async {
          await _pump(
            tester,
            AdminSignInView(
              notice: AdminNotice.inactive,
              viewModelFactory: () => AdminSignInViewModel(
                notice: AdminNotice.inactive,
                auth: _Auth(),
                navigator: _Navigator(),
              ),
            ),
            size: size,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
          expect(find.textContaining('30 minutes'), findsOneWidget);
        },
      );
    }
  });

  group('tableau de bord', () {
    testWidgets('inactivité : déconnexion et message', (tester) async {
      final nav = _Navigator();
      final auth = _Auth();
      await _pump(
        tester,
        AdminHomeView(
          service: auth,
          admin: MemoryAdminService(),
          navigator: nav,
          inactivity: const Duration(minutes: 1),
        ),
      );
      await tester.pump(const Duration(seconds: 50));
      await tester.tapAt(const Offset(700, 450));
      await tester.pump(const Duration(seconds: 50));
      expect(nav.routes, isEmpty, reason: 'interaction : délai remis à zéro');
      await tester.pump(const Duration(seconds: 15));
      expect(auth.calls, ['signOut']);
      expect(nav.routes, ['signIn:inactive']);
    });

    testWidgets('déconnexion depuis Configuration', (tester) async {
      final nav = _Navigator();
      final auth = _Auth();
      await _pump(
        tester,
        AdminHomeView(
          service: auth,
          admin: MemoryAdminService(),
          navigator: nav,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Commandes bloquées'), findsOneWidget);
      await tester.tap(find.text('Configuration').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Se déconnecter'));
      await tester.pump();
      expect(nav.routes, ['signIn']);
    });

    for (final size in const [
      Size(800, 1280),
      Size(1280, 800),
      Size(1440, 900),
    ]) {
      testWidgets('mise en page ${size.width.toInt()}×${size.height.toInt()}', (
        tester,
      ) async {
        await _pump(
          tester,
          AdminHomeView(
            service: _Auth(),
            admin: MemoryAdminService(),
            navigator: _Navigator(),
          ),
          size: size,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('configuration manquante : écran dédié', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ConfigErrorApp());
    await tester.pump();
    expect(find.text('Configuration manquante'), findsOneWidget);
  });
}
