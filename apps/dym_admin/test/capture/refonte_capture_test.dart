@Tags(['golden'])
library;

import 'package:dym_admin/features/ops/testing.dart';
import 'package:dym_admin/ui/admin_theme.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_admin/ui/views/home/admin_home_view.dart';
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_view.dart';
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_viewmodel.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures de la refonte de l'admin (spec 091) : coque, tableau de bord,
/// boutiques, sur bureau et téléphone.
final _now = DateTime.utc(2026, 10, 5, 11);

class _Auth implements AuthService {
  @override
  AccountApp get app => AccountApp.admin;
  @override
  String? get email => 'jc.messan@dym.test';
  @override
  bool get googleAvailable => true;
  @override
  Future<Result<void>> signOut() async => const Ok(null);
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Navigator implements AdminNavigator {
  @override
  void toHome() {}
  @override
  void toSignIn({AdminNotice? notice}) {}
}

Future<void> _capture(
  WidgetTester tester,
  String name,
  AdminTab tab, {
  Size size = const Size(1440, 1000),
  String? tap,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: adminTheme(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: AdminHomeView(
        service: _Auth(),
        admin: MemoryAdminService(),
        navigator: _Navigator(),
        initialTab: tab,
        clock: () => _now,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 600));
  if (tap != null) {
    await tester.tap(find.text(tap).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/refonte_$name.png'),
  );
}

Future<void> _signIn(WidgetTester tester, String name, Size size) async {
  tester.view
    ..physicalSize = size
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
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump(const Duration(milliseconds: 300));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/refonte_$name.png'),
  );
}

void main() {
  testWidgets(
    'connexion',
    (t) => _signIn(t, 'connexion', const Size(1440, 900)),
  );
  testWidgets(
    'connexion téléphone',
    (t) => _signIn(t, 'connexion_telephone', const Size(412, 915)),
  );
  testWidgets(
    'tableau de bord',
    (t) => _capture(t, 'tableau', AdminTab.dashboard),
  );
  testWidgets('boutiques', (t) => _capture(t, 'boutiques', AdminTab.stores));
  testWidgets(
    'boutique ouverte',
    (t) => _capture(t, 'boutique', AdminTab.stores, tap: "Étal d'Akossiwa"),
  );
  testWidgets('commandes', (t) => _capture(t, 'commandes', AdminTab.orders));
  testWidgets('litiges', (t) => _capture(t, 'litiges', AdminTab.disputes));
  testWidgets('finances', (t) => _capture(t, 'finances', AdminTab.finance));
  testWidgets('configuration', (t) => _capture(t, 'config', AdminTab.settings));
  testWidgets(
    'téléphone',
    (t) => _capture(
      t,
      'telephone',
      AdminTab.dashboard,
      size: const Size(412, 915),
    ),
  );
}
