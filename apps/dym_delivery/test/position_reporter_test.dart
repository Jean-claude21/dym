import 'package:dym_core/dym_core.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/features/missions/position_reporter.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter_test/flutter_test.dart';

class _Location implements LocationProvider {
  new(this.point);

  final GeoPoint? point;

  @override
  Future<Result<GeoPoint?>> current() async => Ok(point);
}

CountryConfig _togo() => CountryConfig(
  country: Country.fromJson(const {
    'code': 'TG',
    'name': {'fr': 'Togo'},
    'currency_code': 'XOF',
    'dial_code': '+228',
    'default_locale': 'fr',
    'timezone': 'Africa/Lome',
  }),
  currency: Currency.xof,
  cities: const [],
  zones: const [],
  categories: const [],
  storeOrigins: const [],
  units: const [],
  paymentMethods: const [],
  deliveryFees: const [],
  featureFlags: const [],
);

Mission _run(String status) => Mission(
  orderId: 'o1',
  status: status,
  createdAt: DateTime(2026, 11, 10, 9),
  deliveryFeeMinor: 500,
  currencyCode: 'XOF',
  itemCount: 1,
  store: const MissionPlace(name: 'Étal'),
  customer: const MissionPlace(latitude: 6.13, longitude: 1.22),
);

void main() {
  group('position du livreur (spec 044)', () {
    test('pas de course en route : rien envoyé', () async {
      final service = MemoryMissionsService(
        config: _togo(),
        accepted: [_run('ready')],
      );
      await PositionReporter(
        service: service,
        location: _Location(const GeoPoint(6.2, 1.3)),
      ).tick();
      expect(service.positions, isEmpty);
    });

    test('GPS disponible : position réelle', () async {
      final service = MemoryMissionsService(
        config: _togo(),
        accepted: [_run('out_for_delivery')],
      );
      final reporter = PositionReporter(
        service: service,
        location: _Location(const GeoPoint(6.2, 1.3)),
      );
      await reporter.tick();
      expect(service.positions.single.latitude, 6.2);
      expect(service.positions.single.simulated, isFalse);
      expect(reporter.simulated.value, isFalse);
    });

    test('sans GPS : position simulée, signalée, qui se rapproche', () async {
      final service = MemoryMissionsService(
        config: _togo(),
        accepted: [_run('out_for_delivery')],
      );
      final reporter = PositionReporter(
        service: service,
        location: _Location(null),
      );
      await reporter.tick();
      await reporter.tick();
      expect(service.positions.every((p) => p.simulated), isTrue);
      expect(reporter.simulated.value, isTrue);
      expect(
        service.positions.last.latitude,
        lessThan(service.positions.first.latitude),
      );
    });
  });
}
