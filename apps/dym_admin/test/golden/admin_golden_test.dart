@Tags(['golden'])
library;

import 'package:dym_admin/ui/admin_theme.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_view.dart';
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_viewmodel.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth implements AuthService {
  @override
  bool get googleAvailable => true;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Navigator implements AdminNavigator {
  @override
  void toHome() {}

  @override
  void toSignIn({AdminNotice? notice}) {}
}

/// Capture 1 440 × 900 de la connexion admin, à comparer à la maquette 15.
void main() {
  testWidgets('15 · connexion admin', (tester) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: adminTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: DymLocalizations.localizationsDelegates,
        supportedLocales: DymLocalizations.supportedLocales,
        home: AdminSignInView(
          viewModelFactory: () =>
              AdminSignInViewModel(auth: _Auth(), navigator: _Navigator()),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/admin_hero.webp', package: 'dym_auth'),
        tester.element(find.byType(MaterialApp)),
      );
    });
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/15-admin-connexion.png'),
    );
  });
}
