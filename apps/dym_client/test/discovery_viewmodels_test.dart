import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

const _tokoin = ZoneMatch(
  zoneId: 'tokoin',
  zoneName: 'Tokoin',
  cityId: 'lome',
  cityName: 'Lomé',
  countryCode: 'TG',
  distanceM: 180,
);

void main() {
  group('accueil', () {
    test('boutiques ouvertes d’abord, celles du quartier en tête', () async {
      final vm = DiscoveryHomeViewModel(service: memoryDiscovery());
      await vm.load();
      expect(vm.result.openStores.map((s) => s.id), ['kodjo', 'esi']);
      expect(vm.result.stores.last.id, 'afi');
      expect(vm.result.estimateMinutes, 35, reason: '15 min + 20 min');
      expect(vm.zone?.name, 'Bè');
      expect(vm.cityName, 'Lomé');
      expect(vm.aisles.map((a) => a.id), [
        'legumes',
        'boissons',
        'fait-maison',
        'epices',
      ]);
    });

    test('position : quartier proposé puis confirmé', () async {
      final service = memoryDiscovery(zoneMatch: _tokoin);
      final vm = DiscoveryHomeViewModel(service: service);
      await vm.load();
      await vm.locate();
      expect(vm.suggestion?.zoneName, 'Tokoin');
      expect(service.zone.value, 'be', reason: 'rien sans confirmation');
      await vm.confirmSuggestion();
      expect(service.zone.value, 'tokoin');
      expect(vm.suggestion, isNull);
    });

    test('position refusée : la liste reste proposée', () async {
      final vm = DiscoveryHomeViewModel(service: memoryDiscovery());
      await vm.load();
      await vm.locate();
      expect(vm.locationUnavailable, isTrue);
      expect(vm.suggestion, isNull);
    });

    test('hors ligne : reprise', () async {
      final service = memoryDiscovery()
        ..failNext = const NetworkFailure('hors ligne');
      final vm = DiscoveryHomeViewModel(service: service);
      await vm.load();
      expect(vm.offline, isTrue);
      await vm.load();
      expect(vm.ready, isTrue);
    });
  });

  group('rayon', () {
    test('sous-rayons compris, disponibles seulement', () async {
      final service = memoryDiscovery();
      final vm = AisleViewModel(service: service, categoryId: 'legumes');
      await vm.load();
      expect(vm.products.map((p) => p.id), ['tomates']);
      expect(vm.subCategories.single.id, 'tomates');
      await vm.selectOrigin('maison');
      expect(vm.products, isEmpty);
    });
  });

  group('recherche', () {
    test('accents ignorés, préfixe, événement sans texte', () async {
      final service = memoryDiscovery();
      final vm = SearchViewModel(service: service);
      await vm.init();
      vm.setText('e');
      expect(vm.tooShort, isTrue);
      vm.text = 'epices';
      await vm.submit();
      expect(vm.results?.products.single.name, 'Épices du marché');
      vm.text = 'BISS';
      await vm.submit();
      expect(vm.results?.total, 2);
      final (query, total) = service.searches.last;
      expect(total, 2);
      expect(query.activeFilters, 0);
    });

    test('filtres : origine, disponibilité, tri, prix incohérent', () async {
      final vm = SearchViewModel(service: memoryDiscovery());
      await vm.init();
      vm.text = 'bissap';
      await vm.applyFilters(const SearchFilters(availableOnly: true));
      expect(vm.results?.products.map((p) => p.id), ['bissap']);
      vm.text = 'bissap';
      await vm.applyFilters(const SearchFilters(sort: SearchSort.priceDesc));
      expect(vm.results?.products.map((p) => p.id), ['sirop', 'bissap']);
      vm.text = 'marche';
      await vm.applyFilters(
        const SearchFilters(sort: SearchSort.priceAsc, origin: 'marche'),
      );
      expect(vm.results?.products.map((p) => p.id), ['epices']);
      expect(vm.activeFilters, 2);
      await vm.applyFilters(
        const SearchFilters(minPriceMinor: 900, maxPriceMinor: 100),
      );
      expect(vm.filters.origin, 'marche', reason: 'filtre invalide ignoré');
    });

    test('boutiques trouvées', () async {
      final vm = SearchViewModel(service: memoryDiscovery())..text = 'esi';
      await vm.submit();
      expect(vm.results?.stores.single.id, 'esi');
    });
  });

  group('fiche', () {
    test(
      'première variante disponible, prix de la variante, événement',
      () async {
        final service = memoryDiscovery();
        final vm = ProductPageViewModel(service: service, productId: 'bissap');
        await vm.load();
        expect(vm.variant?.id, 'v50');
        expect(vm.priceMinor, 400);
        expect(vm.available, isTrue);
        vm.selectVariant('v1l');
        expect(vm.priceMinor, 700);
        expect(vm.available, isFalse);
        expect(service.viewed, ['bissap']);
        expect(vm.page?.zoneName, 'Bè');
      },
    );

    test('produit retiré', () async {
      final vm = ProductPageViewModel(
        service: memoryDiscovery(),
        productId: 'x',
      );
      await vm.load();
      expect(vm.gone, isTrue);
    });
  });

  group('boutique', () {
    test('produits de la boutique', () async {
      final vm = StorePageViewModel(service: memoryDiscovery(), storeId: 'esi');
      await vm.load();
      expect(vm.products.map((p) => p.id), ['bissap', 'sirop']);
    });
  });
}
