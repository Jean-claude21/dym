import 'package:dym_client/features/discovery/map/store_map_view.dart';
import 'package:dym_client/features/discovery/map/store_map_viewmodel.dart';
import 'package:dym_client/features/discovery/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_map/dym_map.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

PublicStore _at(
  String id,
  String name,
  double lat,
  double lng, {
  bool open = true,
  String origin = 'marche',
}) => PublicStore(
  id: id,
  name: name,
  origin: origin,
  zoneId: 'z-$id',
  zoneName: 'Centre',
  currencyCode: 'EUR',
  prepTimeMinutes: 20,
  deliveryMinutes: 40,
  openNow: open,
  latitude: lat,
  longitude: lng,
  deliveryRadiusM: 3000,
);

// Rouen (deux boutiques, dont une fermée) et Paris.
final _rouen = _at('rouen', 'Primeur du Vieux-Marché', 49.443, 1.088);
final _rouenClosed = _at(
  'rouen2',
  'Épicerie Saint-Marc',
  49.437,
  1.104,
  open: false,
  origin: 'magasin',
);
final _paris = _at('paris', 'Fromagerie des Martyrs', 48.879, 2.340);

const _rouenView = DymMapView(
  center: DymLatLng(49.44, 1.09),
  zoom: 13,
  bounds: DymBounds(
    southWest: DymLatLng(49.40, 1.00),
    northEast: DymLatLng(49.48, 1.20),
  ),
);

MemoryDiscoveryService _service() => MemoryDiscoveryService(
  config: togoConfig(),
  stores: [_rouen, _rouenClosed, _paris],
);

void main() {
  group('viewmodel', () {
    test('le cadre commande les boutiques, ouvertes d’abord', () async {
      final service = _service();
      final vm = StoreMapViewModel(service: service, config: togoConfig());
      await vm.onCameraIdle(_rouenView);
      expect(vm.stores.map((s) => s.id), ['rouen', 'rouen2']);
      final pins = vm.pins((o) => o ?? 'magasin');
      expect(pins.firstWhere((p) => p.id == 'rouen2').dimmed, isTrue);
      expect(service.mapViews.single.stores, 2);
    });

    test('filtre « ouvertes » et sélection avec zone de livraison', () async {
      final vm = StoreMapViewModel(service: _service(), config: togoConfig());
      await vm.onCameraIdle(_rouenView);
      vm.select('rouen');
      expect(vm.areas.single.radiusM, 3000);
      await vm.toggleOpen();
      expect(vm.stores.map((s) => s.id), ['rouen']);
      expect(vm.selected?.id, 'rouen');
    });

    test('cadre vide : état vide ; échec : message', () async {
      final service = _service();
      final vm = StoreMapViewModel(service: service, config: togoConfig());
      await vm.onCameraIdle(
        const DymMapView(
          center: DymLatLng(0, 0),
          zoom: 12,
          bounds: DymBounds(
            southWest: DymLatLng(-1, -1),
            northEast: DymLatLng(1, 1),
          ),
        ),
      );
      expect(vm.empty, isTrue);
      service.failNext = const NetworkFailure('hors ligne');
      await vm.reload();
      expect(vm.offline, isTrue);
    });

    test('ma position recentre la carte ; refusée : message', () async {
      final service = _service()..position = const GeoPoint(48.88, 2.34);
      final engine = FakeMapEngine();
      final vm = StoreMapViewModel(service: service, config: togoConfig())
        ..controls = engine.controls;
      await vm.locateMe();
      expect(engine.moves.single, const DymLatLng(48.88, 2.34));
      service.position = null;
      await vm.locateMe();
      expect(vm.positionUnavailable, isTrue);
    });
  });

  testWidgets('épingle touchée : fiche, rayon et « Voir la boutique »', (
    tester,
  ) async {
    final engine = FakeMapEngine();
    final previous = DymMap.engine;
    DymMap.engine = engine;
    addTearDown(() => DymMap.engine = previous);
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: DymTheme.light(),
        locale: const Locale('fr'),
        localizationsDelegates: DymLocalizations.localizationsDelegates,
        supportedLocales: DymLocalizations.supportedLocales,
        home: Scaffold(
          body: StoreMapView(
            service: _service(),
            config: togoConfig(),
            onOpenStore: (id) => opened = id,
          ),
        ),
      ),
    );
    engine.last!.onCameraIdle!(_rouenView);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pin-rouen')));
    await tester.pumpAndSettle();
    expect(find.text("Livre jusqu'à 3 km"), findsOneWidget);
    await tester.tap(find.text('Voir la boutique'));
    expect(opened, 'rouen');
    expect(tester.takeException(), isNull);
  });
}
