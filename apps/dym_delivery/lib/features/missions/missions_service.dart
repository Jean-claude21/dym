import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';

/// Livreur (spec 041) : profil, missions proposées et en cours, gestes.
abstract interface class MissionsService {
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<CourierProfile?>> profile();

  Future<Result<CourierProfile>> become({
    required String name,
    required String phone,
    required CourierVehicle vehicle,
    required List<String> zoneIds,
  });

  Future<Result<CourierProfile>> setOnline({required bool online});

  Future<Result<List<Mission>>> available();

  Future<Result<List<Mission>>> mine();

  Future<Result<Mission>> accept(Mission mission);

  Future<Result<void>> release(Mission mission);

  /// Geste suivant (`out_for_delivery` : récupérée, `delivered` : livrée).
  Future<Result<Mission>> advance(Mission mission, String to);
}

/// Implémentation Neon.
class NeonMissionsService implements MissionsService {
  new({required this._couriers, required this._reference, required this._auth});

  final CourierRepository _couriers;
  final ReferenceRepository _reference;
  final AuthService _auth;
  CountryConfig? _config;

  @override
  Future<Result<CountryConfig>> countryConfig() async {
    final cached = _config;
    if (cached != null) return Ok(cached);
    final code = _auth.me?.profile?.countryCode;
    if (code == null) {
      return const Err(UnauthenticatedFailure('profil incomplet'));
    }
    final result = await _reference.countryConfig(code);
    if (result case Ok(:final value)) _config = value;
    return result;
  }

  @override
  Future<Result<CourierProfile?>> profile() => _couriers.myProfile();

  @override
  Future<Result<CourierProfile>> become({
    required String name,
    required String phone,
    required CourierVehicle vehicle,
    required List<String> zoneIds,
  }) => _couriers.become(
    name: name,
    phone: phone,
    vehicle: vehicle,
    zoneIds: zoneIds,
  );

  @override
  Future<Result<CourierProfile>> setOnline({required bool online}) =>
      _couriers.setOnline(online: online);

  @override
  Future<Result<List<Mission>>> available() => _couriers.available();

  @override
  Future<Result<List<Mission>>> mine() => _couriers.mine();

  @override
  Future<Result<Mission>> accept(Mission mission) =>
      _couriers.accept(mission.orderId);

  @override
  Future<Result<void>> release(Mission mission) =>
      _couriers.release(mission.orderId);

  @override
  Future<Result<Mission>> advance(Mission mission, String to) =>
      _couriers.transition(mission.orderId, to: to, expected: mission.status);
}

/// Implémentation en mémoire (tests, galerie).
class MemoryMissionsService implements MissionsService {
  new({
    required this.config,
    this.current,
    List<Mission>? open,
    List<Mission>? accepted,
  }) : open = open ?? [],
       accepted = accepted ?? [];

  final CountryConfig config;
  CourierProfile? current;
  final List<Mission> open;
  final List<Mission> accepted;
  final gestures = <String>[];

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(config);

  @override
  Future<Result<CourierProfile?>> profile() async => Ok(current);

  @override
  Future<Result<CourierProfile>> become({
    required String name,
    required String phone,
    required CourierVehicle vehicle,
    required List<String> zoneIds,
  }) async {
    if (zoneIds.isEmpty) return const Err(ValidationFailure('invalid_zones'));
    if (!RegExp(r'^\+?[0-9 ]{8,20}$').hasMatch(phone)) {
      return const Err(ValidationFailure('invalid_phone'));
    }
    return Ok(
      current = CourierProfile(
        displayName: name,
        phone: phone,
        vehicle: vehicle,
        zoneIds: zoneIds,
      ),
    );
  }

  @override
  Future<Result<CourierProfile>> setOnline({required bool online}) async {
    final c = current!;
    return Ok(
      current = CourierProfile(
        displayName: c.displayName,
        phone: c.phone,
        vehicle: c.vehicle,
        zoneIds: c.zoneIds,
        isOnline: online,
      ),
    );
  }

  @override
  Future<Result<List<Mission>>> available() async =>
      Ok(current?.isOnline ?? false ? List.of(open) : const []);

  @override
  Future<Result<List<Mission>>> mine() async => Ok(List.of(accepted));

  @override
  Future<Result<Mission>> accept(Mission mission) async {
    gestures.add('accept:${mission.orderId}');
    if (!open.any((m) => m.orderId == mission.orderId)) {
      return const Err(ValidationFailure('mission_taken'));
    }
    open.removeWhere((m) => m.orderId == mission.orderId);
    final taken = _with(mission, mission.status, accepted: true);
    accepted.add(taken);
    return Ok(taken);
  }

  @override
  Future<Result<void>> release(Mission mission) async {
    gestures.add('release:${mission.orderId}');
    accepted.removeWhere((m) => m.orderId == mission.orderId);
    return const Ok(null);
  }

  @override
  Future<Result<Mission>> advance(Mission mission, String to) async {
    gestures.add('$to:${mission.orderId}');
    final next = _with(mission, to, accepted: true);
    final i = accepted.indexWhere((m) => m.orderId == mission.orderId);
    if (i >= 0) accepted[i] = next;
    return Ok(next);
  }

  static Mission _with(Mission m, String status, {required bool accepted}) =>
      Mission(
        orderId: m.orderId,
        status: status,
        createdAt: m.createdAt,
        deliveryFeeMinor: m.deliveryFeeMinor,
        currencyCode: m.currencyCode,
        itemCount: m.itemCount,
        store: m.store,
        customer: m.customer,
        acceptedAt: accepted ? DateTime(2026, 11, 10, 10) : null,
        next: switch (status) {
          'ready' => const ['out_for_delivery'],
          'out_for_delivery' => const ['delivered'],
          _ => const [],
        },
      );
}
