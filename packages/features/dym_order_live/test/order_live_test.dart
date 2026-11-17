import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_order_live/dym_order_live.dart';
import 'package:flutter_test/flutter_test.dart';

const _store = TrackPoint(6.13, 1.22);
const _door = TrackPoint(6.14, 1.23);

class _Service implements OrderLiveService {
  LiveTracking tracking0 = _tracking(
    'ready',
    courier: const TrackPoint(6.12, 1.21),
  );
  bool routeFails = false;
  final routed = <List<TrackPoint>>[];

  @override
  Future<Result<LiveTracking>> tracking(String orderId) async => Ok(tracking0);

  @override
  Future<Result<DeliveryRoute>> route(List<TrackPoint> points) async {
    routed.add(points);
    if (routeFails) return const Err(NetworkFailure('hors ligne'));
    return Ok(DeliveryRoute(points: points, distanceM: 1200, durationS: 300));
  }
}

LiveTracking _tracking(String status, {TrackPoint? courier}) => LiveTracking(
  orderId: 'o1',
  status: status,
  storeName: 'Étal',
  store: _store,
  destination: _door,
  courier: courier == null
      ? null
      : TrackedCourier(name: 'Kofi', position: courier),
  etaMinutes: 12,
);

void main() {
  test('étapes : vers la boutique, vers la porte, livrée (spec 109)', () async {
    final service = _Service();
    final vm = OrderLiveViewModel(service: service, orderId: 'o1');
    await vm.refresh();
    expect(vm.phase, LivePhase.toStore);
    // Livreur → boutique → porte.
    expect(service.routed.single, hasLength(3));
    expect(vm.etaMinutes, 12);

    service.tracking0 = _tracking(
      'out_for_delivery',
      courier: const TrackPoint(6.13, 1.22),
    );
    await vm.refresh();
    expect(vm.phase, LivePhase.toDoor);
    expect(service.routed.last, [const TrackPoint(6.13, 1.22), _door]);

    service.tracking0 = _tracking('delivered', courier: _door);
    await vm.refresh();
    expect(vm.phase, LivePhase.delivered);
    expect(vm.etaMinutes, isNull);
    expect(vm.route, isNull);
    vm.dispose();
  });

  test('itinéraire indisponible : ligne droite en pointillés', () async {
    final service = _Service()..routeFails = true;
    final vm = OrderLiveViewModel(service: service, orderId: 'o1');
    await vm.refresh();
    expect(vm.route?.approximate, isTrue);
    expect(vm.route?.points, hasLength(3));
    vm.dispose();
  });

  test('pas de livreur : en attente, boutique → porte', () async {
    final service = _Service()..tracking0 = _tracking('accepted');
    final vm = OrderLiveViewModel(service: service, orderId: 'o1');
    await vm.refresh();
    expect(vm.phase, LivePhase.waiting);
    expect(service.routed.single, [_store, _door]);
    vm.dispose();
  });

  test('distance : quelques mètres ne relancent pas l’itinéraire', () async {
    final service = _Service();
    final vm = OrderLiveViewModel(service: service, orderId: 'o1');
    await vm.refresh();
    service.tracking0 = _tracking(
      'ready',
      courier: const TrackPoint(6.12005, 1.21),
    );
    await vm.refresh();
    expect(service.routed, hasLength(1));
    vm.dispose();
  });
}
