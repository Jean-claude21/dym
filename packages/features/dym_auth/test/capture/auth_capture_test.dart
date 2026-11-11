@Tags(['golden'])
library;

import 'package:dym_auth/dym_auth.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth_service.dart';

/// Captures de contrôle des pages d'entrée (design « Épuré ») : téléphone
/// 412 × 915, densité 2. À regarder à l'œil, pas une non-régression.
void main() {
  Future<void> capture(
    WidgetTester tester,
    String name,
    Widget child, {
    Size size = const Size(412, 915),
  }) async {
    tester.view
      ..physicalSize = size * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: DymTheme.light(),
        locale: const Locale('fr'),
        localizationsDelegates: DymLocalizations.localizationsDelegates,
        supportedLocales: DymLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            devicePixelRatio: 2,
            disableAnimations: true,
            padding: const EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: child,
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = (element.widget as Image).image;
        await precacheImage(image, element);
      }
    });
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  Widget flow(AuthVariant variant, AuthStep step) => AuthFlowView(
    service: FakeAuthService(),
    onReady: (_) {},
    variant: variant,
    initialStep: step,
    initialEmail: step == AuthStep.welcome ? '' : 'awa@exemple.com',
    startWithProfile: step == AuthStep.profile,
  );

  for (final variant in AuthVariant.values) {
    testWidgets('bienvenue ${variant.name}', (tester) async {
      await capture(
        tester,
        'welcome_${variant.name}',
        flow(variant, AuthStep.welcome),
      );
    });
  }
  for (final step in [AuthStep.email, AuthStep.code, AuthStep.profile]) {
    testWidgets('étape ${step.name}', (tester) async {
      await capture(
        tester,
        'step_${step.name}',
        flow(AuthVariant.client, step),
      );
    });
  }
}
