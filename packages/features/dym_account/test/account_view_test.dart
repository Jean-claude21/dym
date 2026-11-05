import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Service minimal pour l'écran « Moi ».
class _Service implements AuthService {
  final calls = <String>[];
  Result<void> deleteResult = const Ok(null);

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
  Future<Result<void>> signOut() async {
    calls.add('signOut');
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    calls.add('delete');
    return deleteResult;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  for (final size in sizes) {
    for (final locale in const [Locale('fr'), Locale('en')]) {
      testWidgets('Moi · ${size.width.toInt()}×${size.height.toInt()} · '
          '${locale.languageCode} · texte 130 %', (tester) async {
        await _pump(
          tester,
          AccountView(service: _Service(), onSignedOut: () {}),
          size: size,
          locale: locale,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('profil affiché : prénom, email, initiale', (tester) async {
    await _pump(tester, AccountView(service: _Service(), onSignedOut: () {}));
    expect(find.text('Awa'), findsOneWidget);
    expect(find.text('awa.mensah@gmail.com'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('déconnexion', (tester) async {
    final service = _Service();
    var signedOut = 0;
    await _pump(
      tester,
      AccountView(service: service, onSignedOut: () => signedOut++),
    );
    await tester.tap(find.text('Se déconnecter'));
    await tester.pump();
    expect(service.calls, ['signOut']);
    expect(signedOut, 1);
  });

  testWidgets('suppression : confirmation obligatoire', (tester) async {
    final service = _Service();
    var signedOut = 0;
    await _pump(
      tester,
      AccountView(service: service, onSignedOut: () => signedOut++),
    );
    await tester.ensureVisible(find.text('Supprimer mon compte'));
    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ton compte ?'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(service.calls, isEmpty);

    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer définitivement'));
    await tester.pumpAndSettle();
    expect(service.calls, ['delete']);
    expect(signedOut, 1);
  });

  testWidgets('suppression hors ligne : message, pas de déconnexion', (
    tester,
  ) async {
    final service = _Service()
      ..deleteResult = const Err(NetworkFailure('hors ligne'));
    var signedOut = 0;
    await _pump(
      tester,
      AccountView(service: service, onSignedOut: () => signedOut++),
    );
    await tester.ensureVisible(find.text('Supprimer mon compte'));
    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer définitivement'));
    await tester.pumpAndSettle();
    expect(signedOut, 0);
    expect(find.textContaining('Pas de connexion'), findsOneWidget);
  });
}
