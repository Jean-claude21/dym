@Tags(['golden'])
library;

import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service implements AuthService {
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
  Future<Result<void>> signOut() async => const Ok(null);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Capture 412 × 915 (×2) de « Moi » avec la confirmation de suppression,
/// à comparer à la maquette 13.
void main() {
  testWidgets('13 · compte et suppression', (tester) async {
    tester.view
      ..physicalSize = const Size(824, 1830)
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
          data: const MediaQueryData(
            size: Size(412, 915),
            devicePixelRatio: 2,
            disableAnimations: true,
            padding: EdgeInsets.only(top: 24),
          ),
          child: AccountView(service: _Service(), onSignedOut: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Supprimer mon compte'));
    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/13-compte-suppression.png'),
    );
  });
}
