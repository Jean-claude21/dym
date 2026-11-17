import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/features/catalog/categories/store_categories_viewmodel.dart';
import 'package:dym_vendor/features/catalog/editor/product_editor_viewmodel.dart';
import 'package:dym_vendor/features/catalog/products/products_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/catalog_fixtures.dart';

void main() {
  group('éditeur', () {
    test('photo → proposition → publication en 2 étapes', () async {
      final catalog = memoryCatalog(products: const []);
      Product? done;
      final vm = ProductEditorViewModel(
        service: catalog,
        onDone: (p) => done = p,
      );
      await vm.load();
      expect(vm.canContinue, isFalse);

      await vm.addPhoto(PhotoSource.camera);
      expect(vm.photoKeys, hasLength(1));
      expect(vm.suggestion, SuggestionState.received);
      expect(vm.name, 'Jus de bissap 50 cl');
      expect(vm.categoryId, 'boissons');
      expect(catalog.suggestionsShown, 1);
      expect(vm.canContinue, isTrue);

      await vm.next();
      expect(vm.step, 2);
      expect(catalog.current.single.status, ProductStatus.draft);
      expect(vm.canPublish, isFalse, reason: 'prix manquant');

      vm
        ..setPrice('500')
        ..selectUnit('unit-piece');
      vm.setStock(vm.variants.single.id, 12);
      expect(vm.canPublish, isTrue);
      await vm.publish();
      expect(done?.status, ProductStatus.published);
      expect(done?.suggestionId, 's1');
      expect(done?.priceMinor, 500);
      expect(done?.currencyCode, 'XOF');
      expect(done?.variants.single.stockQuantity, 12);
    });

    test(
      "proposition indisponible : saisie manuelle, rien d'inventé",
      () async {
        final catalog = memoryCatalog(products: const [], suggestion: null);
        final vm = ProductEditorViewModel(service: catalog, onDone: (_) {});
        await vm.load();
        await vm.addPhoto(PhotoSource.gallery);
        expect(vm.suggestion, SuggestionState.unavailable);
        expect(vm.name, isEmpty);
        expect(vm.categoryId, isNull);
        expect(catalog.suggestionsShown, 0);
      },
    );

    test("la proposition n'écrase pas ce que la vendeuse a saisi", () async {
      final vm = ProductEditorViewModel(
        service: memoryCatalog(products: const []),
        onDone: (_) {},
      );
      await vm.load();
      vm
        ..setName('Bissap maison')
        ..selectCategory('fait-maison');
      await vm.addPhoto(PhotoSource.camera);
      expect(vm.name, 'Bissap maison');
      expect(vm.categoryId, 'fait-maison');
      expect(vm.description, startsWith('Jus de bissap frais'));
    });

    test('envoi de photo en échec : message, aucune clé', () async {
      final catalog = memoryCatalog(products: const []);
      final vm = ProductEditorViewModel(service: catalog, onDone: (_) {});
      await vm.load();
      catalog.failNext = const NetworkFailure('hors ligne');
      await vm.addPhoto(PhotoSource.camera);
      expect(vm.uploadFailed, isTrue);
      expect(vm.photoKeys, isEmpty);
    });

    test('publication hors ligne puis réessai : un seul produit', () async {
      final catalog = memoryCatalog(products: const []);
      var done = 0;
      final vm = ProductEditorViewModel(
        service: catalog,
        onDone: (_) => done++,
      );
      await vm.load();
      await vm.addPhoto(PhotoSource.camera);
      await vm.next();
      vm.setPrice('500');
      catalog.failNext = const NetworkFailure('hors ligne');
      await vm.publish();
      expect(vm.offline, isTrue);
      expect(done, 0);
      await vm.publish();
      expect(done, 1);
      expect(catalog.current, hasLength(1));
    });

    test('variantes : libellés requis dès la deuxième, prix propre', () async {
      final catalog = memoryCatalog(products: const []);
      Product? done;
      final vm = ProductEditorViewModel(
        service: catalog,
        onDone: (p) => done = p,
      );
      await vm.load();
      await vm.addPhoto(PhotoSource.camera);
      await vm.next();
      vm
        ..setPrice('500')
        ..addVariant();
      expect(vm.canPublish, isFalse);
      final [first, second] = vm.variants;
      vm
        ..setVariantLabel(first.id, '50 cl')
        ..setVariantLabel(second.id, '1 L')
        ..setVariantPrice(second.id, '900');
      expect(vm.canPublish, isTrue);
      await vm.publish();
      expect(done?.variants.map((v) => v.priceMinor), [null, 900]);
    });

    test('stock non suivi : variantes sans stock', () async {
      final catalog = memoryCatalog(products: const []);
      Product? done;
      final vm = ProductEditorViewModel(
        service: catalog,
        onDone: (p) => done = p,
      );
      await vm.load();
      await vm.addPhoto(PhotoSource.camera);
      await vm.next();
      vm
        ..setPrice('500')
        ..setTrackStock(value: false);
      await vm.publish();
      expect(done?.variants.single.stockQuantity, isNull);
    });

    test('prix invalide refusé', () async {
      final vm = ProductEditorViewModel(
        service: memoryCatalog(products: const []),
        onDone: (_) {},
      );
      await vm.load();
      vm.setPrice('12,5');
      expect(vm.priceValid, isFalse, reason: 'F CFA sans décimales');
      vm.setPrice('0');
      expect(vm.priceValid, isFalse);
      vm.setPrice('1 000');
      expect(vm.priceMinor, 1000);
    });

    test('modification : valeurs reprises, pas de proposition', () async {
      final catalog = memoryCatalog();
      final product = esiProducts().first;
      final vm = ProductEditorViewModel(
        service: catalog,
        onDone: (_) {},
        product: product,
      );
      await vm.load();
      expect(vm.id, 'p1');
      expect(vm.priceText, '500');
      expect(vm.variants.map((v) => v.label), ['50 cl', '1 L']);
      expect(vm.storeCategoryIds, {'c-jus'});
      await vm.addPhoto(PhotoSource.camera);
      expect(vm.suggestion, SuggestionState.idle);
    });

    test("appareil photo ouvert d'emblée, puis proposition", () async {
      final catalog = memoryCatalog(products: const []);
      final vm = ProductEditorViewModel(
        service: catalog,
        onDone: (_) {},
        initialSource: PhotoSource.camera,
      );
      await vm.load();
      expect(catalog.calls, containsAllInOrder(['pickPhoto', 'suggest']));
      expect(vm.suggestion, SuggestionState.received);
    });

    test('prix : produit existant ouvert à l’étape 2', () async {
      final vm = ProductEditorViewModel(
        service: memoryCatalog(),
        onDone: (_) {},
        product: esiProducts().first,
        initialStep: 2,
      );
      await vm.load();
      expect(vm.step, 2);
    });

    test('archiver depuis la fiche ; supprimer un brouillon', () async {
      final catalog = memoryCatalog();
      Product? done;
      var closed = false;
      final vm = ProductEditorViewModel(
        service: catalog,
        onDone: (p) => done = p,
        product: esiProducts().first,
      );
      await vm.load();
      await vm.archive();
      expect(done?.isArchived, isTrue);
      final draft = ProductEditorViewModel(
        service: catalog,
        onDone: (_) {},
        onClosed: () => closed = true,
        product: esiProducts()[2],
      );
      await draft.load();
      expect(draft.isDraft, isTrue);
      await draft.deleteDraft();
      expect(closed, isTrue);
      expect(catalog.current.any((p) => p.id == 'p3'), isFalse);
    });

    test('nouvelle catégorie créée et sélectionnée', () async {
      final vm = ProductEditorViewModel(
        service: memoryCatalog(products: const []),
        onDone: (_) {},
      );
      await vm.load();
      expect(await vm.createStoreCategory('Plats du jour'), isTrue);
      expect(vm.storeCategories.map((c) => c.name), contains('Plats du jour'));
      expect(vm.storeCategoryIds, hasLength(1));
      expect(await vm.createStoreCategory('jus'), isFalse, reason: 'doublon');
    });
  });

  group('Mes produits', () {
    Future<ProductsViewModel> loaded({List<Product>? products}) async {
      final vm = ProductsViewModel(
        service: memoryCatalog(products: products),
        onEdit: (_) async {},
        onCategories: () async {},
      );
      await vm.load();
      return vm;
    }

    test('filtres : tout, catégorie, archivés', () async {
      final vm = await loaded();
      expect(vm.visible.map((p) => p.id), ['p1', 'p2', 'p3']);
      vm.selectFilter('c-jus');
      expect(vm.visible.map((p) => p.id), ['p1', 'p2']);
      vm.selectArchived();
      expect(vm.visible.map((p) => p.id), ['p4']);
      expect(vm.categories.map((c) => c.name), ['Jus', 'Sirops']);
    });

    test('arrivage (spec 033) : date posée puis retirée', () async {
      final vm = await loaded();
      final arrival = DateTime(2026, 11, 20);
      await vm.setArrival(vm.visible.first, arrival);
      expect(vm.visible.first.arrivalOn, arrival);
      await vm.setArrival(vm.visible.first, null);
      expect(vm.visible.first.arrivalOn, isNull);
    });

    test('rupture en un geste, état serveur', () async {
      final vm = await loaded();
      await vm.setAvailable(vm.visible.first, available: false);
      expect(vm.visible.first.isAvailable, isFalse);
    });

    test('rupture optimiste (spec 062) : bascule avant la réponse', () async {
      final vm = await loaded();
      final product = vm.visible.first;
      final pending = vm.setAvailable(product, available: false);
      expect(vm.available(product), isFalse);
      await pending;
      expect(vm.available(vm.visible.first), isFalse);
    });

    test('hors ligne : interrupteur inchangé, échec signalé', () async {
      final catalog = memoryCatalog();
      final vm = ProductsViewModel(
        service: catalog,
        onEdit: (_) async {},
        onCategories: () async {},
      );
      await vm.load();
      catalog.failNext = const NetworkFailure('hors ligne');
      await vm.setAvailable(vm.visible.first, available: false);
      expect(vm.visible.first.isAvailable, isTrue);
      // Refus : l'interrupteur revient à l'état de la base.
      expect(vm.available(vm.visible.first), isTrue);
      expect(vm.actionFailure, isA<NetworkFailure>());
    });

    test('hors ligne avec file (spec 107) : gardé, envoyé au retour', () async {
      final catalog = memoryCatalog();
      final queue = OfflineQueue(MemoryJsonStore());
      final vm = ProductsViewModel(
        service: catalog,
        onEdit: (_) async {},
        onCategories: () async {},
        offline: queue,
      );
      await vm.load();
      final product = vm.visible.first;
      catalog.failNext = const NetworkFailure('hors ligne');
      await vm.setAvailable(product, available: false);
      // L'interrupteur garde le geste, rien n'est signalé comme raté.
      expect(vm.available(product), isFalse);
      expect(vm.actionFailure, isNull);
      expect(vm.offlineCount, 1);
      // Retour du réseau : le geste part, la base suit.
      await vm.replayOffline();
      expect(vm.offlineCount, 0);
      expect(vm.visible.first.isAvailable, isFalse);
      vm.dispose();
    });

    test('archiver, restaurer, supprimer un brouillon', () async {
      final vm = await loaded();
      await vm.archive(vm.visible.first, archived: true);
      expect(vm.visible.map((p) => p.id), ['p2', 'p3']);
      vm.selectArchived();
      await vm.archive(
        vm.visible.firstWhere((p) => p.id == 'p1'),
        archived: false,
      );
      vm.selectFilter(null);
      await vm.deleteDraft(vm.visible.firstWhere((p) => p.id == 'p3'));
      expect(vm.visible.map((p) => p.id), ['p1', 'p2']);
    });

    test('catalogue vide', () async {
      final vm = await loaded(products: const []);
      expect(vm.isEmpty, isTrue);
    });
  });

  group('Mes catégories', () {
    test('ajout, doublon, renommage, archivage, ordre', () async {
      final vm = StoreCategoriesViewModel(service: memoryCatalog());
      await vm.load();
      expect(vm.active.map((c) => c.name), ['Jus', 'Sirops']);
      expect(vm.archived.single.name, 'Pâtisseries');

      vm.setNewName('Plats du jour');
      expect(await vm.add(), isTrue);
      expect(vm.newName, isEmpty);
      vm.setNewName('JUS');
      expect(await vm.add(), isFalse);
      expect(vm.duplicate, isTrue);

      await vm.rename(vm.active.first, 'Jus frais');
      expect(vm.active.first.name, 'Jus frais');
      await vm.reorder(2, 0);
      expect(vm.active.first.name, 'Plats du jour');
      await vm.archive(vm.archived.single, archived: false);
      expect(vm.archived, isEmpty);
      expect(vm.active.first.productCount, 0);
      expect(
        vm.active.firstWhere((c) => c.name == 'Jus frais').productCount,
        2,
      );
    });
  });
}
