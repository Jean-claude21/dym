import 'package:dym_admin/features/ops/testing.dart';
import 'package:dym_admin/features/settings/settings_view.dart';
import 'package:dym_admin/features/settings/settings_viewmodel.dart';
import 'package:dym_admin/ui/admin_theme.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('réglages de la recherche (spec 028)', () {
    test('poids du pays réglés et synonymes ajoutés puis retirés', () async {
      final vm = AdminSettingsViewModel(service: MemoryAdminService());
      await vm.load();
      await vm.selectTab(SettingsTab.search);
      expect(vm.search.ruleFor(vm.country).weights['weight_text'], 40);

      expect(await vm.setRanking({'weight_price': 80}), isTrue);
      final rule = vm.search.ruleFor(vm.country);
      expect(rule.countryCode, vm.country);
      expect(rule.weights['weight_price'], 80);
      expect(rule.weights['weight_text'], 40, reason: 'autres poids gardés');

      expect(await vm.setSynonym('Lanman', ['oseille']), isTrue);
      expect(vm.search.synonyms.map((s) => s.term), contains('lanman'));
      expect(await vm.setSynonym('lanman', const []), isTrue);
      expect(vm.search.synonyms.map((s) => s.term), isNot(contains('lanman')));
    });

    testWidgets('onglet : poids et noms locaux affichés', (tester) async {
      tester.view
        ..physicalSize = const Size(1280, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: adminTheme(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: Scaffold(
            body: AdminSettingsView(service: MemoryAdminService()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recherche'));
      await tester.pumpAndSettle();
      expect(find.text('Correspondance au texte'), findsOneWidget);
      expect(find.text('Noms locaux'), findsOneWidget);
    });
  });
}
