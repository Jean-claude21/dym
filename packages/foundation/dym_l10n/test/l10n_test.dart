import 'package:dym_l10n/dym_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<DymLocalizations> _load(WidgetTester tester, Locale locale) async {
  late DymLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: DymLocalizations.supportedLocales,
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) {
          l10n = DymLocalizations.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return l10n;
}

void main() {
  testWidgets('français par défaut', (tester) async {
    expect(DymLocalizations.supportedLocales.first, const Locale('fr'));
    final l10n = await _load(tester, const Locale('fr'));
    expect(l10n.appNameVendor, 'DYM Vendeuse');
    expect(l10n.environmentLabel('dev'), 'Environnement : dev');
  });

  testWidgets('anglais', (tester) async {
    final l10n = await _load(tester, const Locale('en'));
    expect(l10n.appNameVendor, 'DYM Seller');
  });

  testWidgets('langue non prise en charge : français', (tester) async {
    final l10n = await _load(tester, const Locale('ee'));
    expect(l10n.navHome, 'Accueil');
  });
}
