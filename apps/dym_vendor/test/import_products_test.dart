import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/catalog/import/import_products_view.dart';
import 'package:dym_vendor/features/catalog/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/store_fixtures.dart';

void main() {
  test('lignes collées : tabulation, point-virgule, en-tête ignorée', () {
    final rows = parseImportText(
      'nom;prix;unité;rayon;stock\n'
      'Tomates ; 500 ; tas ; Légumes ; 40\n'
      '\n'
      'Huile rouge\t1 200\t\tHuiles et condiments\t',
    );
    expect(rows, hasLength(2));
    expect(rows.first.name, 'Tomates');
    expect(rows.first.stock, '40');
    expect(rows.last.price, '1 200');
    expect(rows.last.category, 'Huiles et condiments');
  });

  test(
    'vérifier puis importer : brouillons créés, erreurs par ligne',
    () async {
      final service = MemoryCatalogService(config: togoConfig());
      final vm = ImportProductsViewModel(service: service)
        ..setText(
          'Tomates;500;tas;Légumes;40\nX;100;;Légumes;\nMangues;300;;Inconnu;',
        );
      await vm.verify();
      expect(vm.check?.valid, 1);
      expect(vm.check?.errors.map((e) => e.line), [2, 3]);
      expect(service.imported, isEmpty, reason: 'aperçu : rien créé');
      await vm.import();
      expect(vm.done?.valid, 1);
      expect(service.imported.single.name, 'Tomates');
    },
  );

  testWidgets('écran : coller, vérifier, importer', (tester) async {
    final service = MemoryCatalogService(config: togoConfig());
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: DymTheme.light(),
        locale: const Locale('fr'),
        localizationsDelegates: DymLocalizations.localizationsDelegates,
        supportedLocales: DymLocalizations.supportedLocales,
        home: ImportProductsView(service: service, onBack: () {}),
      ),
    );
    await tester.enterText(
      find.byType(TextField),
      'Tomates;500;tas;Légumes;40',
    );
    await tester.pump();
    await tester.tap(find.text('Vérifier'));
    await tester.pumpAndSettle();
    expect(find.text('1 ligne prête · aucune erreur'), findsOneWidget);
    await tester.ensureVisible(find.text('Importer 1 produit'));
    await tester.tap(find.text('Importer 1 produit'));
    await tester.pumpAndSettle();
    expect(find.text('1 brouillon créé'), findsOneWidget);
  });
}
