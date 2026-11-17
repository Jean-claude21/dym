import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

void main() {
  test(
    'Rouen détecté : passer en France, panier de Lomé signalé (spec 110)',
    () async {
      final service =
          memoryDiscovery(
              zoneMatch: const ZoneMatch(
                zoneId: 'rouen-centre',
                zoneName: 'Centre',
                cityId: 'rouen',
                cityName: 'Rouen',
                countryCode: 'FR',
                distanceM: 300,
              ),
            )
            ..cartCountry = 'TG'
            ..cartItems = 2;
      final vm = DiscoveryHomeViewModel(service: service);
      await vm.load();
      await vm.locateOnStart();
      expect(vm.suggestsElsewhere, isTrue);
      expect(vm.suggestion?.cityName, 'Rouen');

      await vm.moveToSuggestion();
      expect(service.moves, ['FR:rouen-centre']);
      expect(vm.cartElsewhere, 'TG');
      expect(vm.suggestion, isNull);

      await vm.clearCartElsewhere();
      expect(service.cartCleared, isTrue);
      expect(vm.cartElsewhere, isNull);

      // Une seule détection par session.
      service.moves.clear();
      await vm.locateOnStart();
      expect(vm.suggestion, isNull);
    },
  );

  test('position dans le quartier affiché : rien à proposer', () async {
    final service = memoryDiscovery();
    final vm = DiscoveryHomeViewModel(service: service);
    await vm.load();
    await vm.locateOnStart();
    expect(vm.suggestsElsewhere, isFalse);
  });
}
