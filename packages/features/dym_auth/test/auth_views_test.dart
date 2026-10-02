import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth_service.dart';

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
        child: child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

/// Amène le parcours à l'étape voulue avec le service simulé (le profil est
/// ouvert directement par `startWithProfile`). Les boutons sont déclenchés
/// directement : ce test vérifie les mises en page, pas le défilement.
Future<void> _goTo(WidgetTester tester, AuthStep step) async {
  if (step == AuthStep.welcome || step == AuthStep.profile) return;
  Future<void> press(String label) async {
    tester
        .widget<DymButton>(find.widgetWithText(DymButton, label))
        .onPressed!();
    await tester.pump(const Duration(milliseconds: 400));
  }

  await press('Continuer avec mon email');
  if (step == AuthStep.email) return;
  await tester.enterText(find.byType(TextField).first, 'awa@example.com');
  await tester.pump();
  await press('Recevoir mon code');
}

void main() {
  for (final variant in AuthVariant.values) {
    for (final step in [
      AuthStep.welcome,
      AuthStep.email,
      AuthStep.code,
      AuthStep.profile,
    ]) {
      for (final size in _sizes) {
        for (final locale in const [Locale('fr'), Locale('en')]) {
          final name =
              '${variant.name} · ${step.name} · '
              '${size.width.toInt()}×${size.height.toInt()} · '
              '${locale.languageCode} · texte 130 %';
          testWidgets(name, (tester) async {
            final service = FakeAuthService();
            await _pump(
              tester,
              AuthFlowView(
                service: service,
                onReady: (_) {},
                variant: variant,
                startWithProfile: step == AuthStep.profile,
              ),
              size: size,
              locale: locale,
              textScale: 1.3,
            );
            if (locale.languageCode == 'fr') await _goTo(tester, step);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  testWidgets('bienvenue sans Google : seul le bouton email', (tester) async {
    await _pump(
      tester,
      AuthFlowView(
        service: FakeAuthService(googleAvailable: false),
        onReady: (_) {},
      ),
    );
    expect(find.text('Continuer avec Google'), findsNothing);
    expect(find.text('Continuer avec mon email'), findsOneWidget);
  });

  testWidgets("parcours email jusqu'au profil, puis prête", (tester) async {
    final service = FakeAuthService();
    final ready = <String>[];
    await _pump(
      tester,
      AuthFlowView(
        service: service,
        onReady: (me) => ready.add(me.profile!.firstName),
      ),
    );
    await _goTo(tester, AuthStep.code);
    expect(find.text('Entre le code'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '482913');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Bienvenue sur DYM !'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Awa');
    expect(find.textContaining('Tokoin'), findsNothing, reason: 'aucune liste');
    await tester.enterText(find.byType(TextField).at(1), 'tok');
    await tester.pump();
    await tester.tap(find.textContaining('Tokoin'));
    await tester.pump();
    expect(find.text('Tokoin, Lomé'), findsOneWidget);
    await tester.tap(find.text("C'est parti"));
    await tester.pump(const Duration(milliseconds: 400));
    expect(ready, ['Awa']);
    expect(service.calls.last, 'profile:Awa:z-tokoin:fr');
  });

  testWidgets('recherche de quartier : sans accents, cibles ≥ 48 dp', (
    tester,
  ) async {
    await _pump(
      tester,
      AuthFlowView(
        service: FakeAuthService(),
        onReady: (_) {},
        startWithProfile: true,
      ),
    );
    await tester.enterText(find.byType(TextField).at(1), 'be');
    await tester.pump();
    expect(find.textContaining('Bè'), findsNWidgets(2), reason: 'Bè, Bè Kpota');
    final row = tester.getSize(
      find
          .ancestor(
            of: find.textContaining('Bè').first,
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(row.height, greaterThanOrEqualTo(48));
    await tester.enterText(find.byType(TextField).at(1), 'zzz');
    await tester.pump();
    expect(find.textContaining('Aucun quartier trouvé'), findsOneWidget);
  });

  testWidgets('adresse par la position, ou message si indisponible', (
    tester,
  ) async {
    final service = FakeAuthService()
      ..locateResult = const Ok(
        ZoneMatch(
          zoneId: 'z-agoe',
          zoneName: 'Agoè',
          cityId: 'lome',
          cityName: 'Lomé',
          countryCode: 'TG',
          distanceM: 240,
        ),
      );
    await _pump(
      tester,
      AuthFlowView(service: service, onReady: (_) {}, startWithProfile: true),
    );
    await tester.tap(find.text('Utiliser ma position'));
    await tester.pump();
    expect(service.calls, contains('locate'));
    expect(find.text('Agoè, Lomé'), findsOneWidget);

    service.locateResult = const Ok(null);
    await tester.tap(find.text('Utiliser ma position'));
    await tester.pump();
    expect(
      find.text('Position indisponible : cherche ton quartier.'),
      findsOneWidget,
    );
  });
}
