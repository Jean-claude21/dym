import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Livreur (spec 041) : profil, missions, gestes. Toutes les décisions sont
/// prises en SQL.
class CourierRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<CourierProfile?>> myProfile() async =>
      (await _data.rpc<Object?>('my_courier_profile')).map(
        (json) => json == null
            ? null
            : CourierProfile.fromJson((json as Map).cast<String, dynamic>()),
      );

  Future<Result<CourierProfile>> become({
    required String name,
    required String phone,
    required CourierVehicle vehicle,
    required List<String> zoneIds,
  }) async => (await _data.rpc<Object?>(
    'become_courier',
    params: {
      'p_name': name,
      'p_phone': phone,
      'p_vehicle': vehicle.name,
      'p_zones': zoneIds,
    },
  )).map(_profile);

  Future<Result<CourierProfile>> setOnline({required bool online}) async =>
      (await _data.rpc<Object?>(
        'set_courier_online',
        params: {'p_online': online},
      )).map(_profile);

  Future<Result<List<Mission>>> available() async =>
      (await _data.rpc<Object?>('available_missions')).map(_missions);

  Future<Result<List<Mission>>> mine() async =>
      (await _data.rpc<Object?>('my_missions')).map(_missions);

  Future<Result<Mission>> accept(String orderId) async =>
      (await _data.rpc<Object?>(
        'accept_mission',
        params: {'p_order': orderId},
      )).map(_mission);

  Future<Result<void>> release(String orderId) =>
      _data.rpc<void>('release_mission', params: {'p_order': orderId});

  /// Récupérée (`out_for_delivery`) ou livrée (`delivered`).
  Future<Result<Mission>> transition(
    String orderId, {
    required String to,
    required String expected,
  }) async => (await _data.rpc<Object?>(
    'courier_transition',
    params: {'p_order': orderId, 'p_to': to, 'p_expected': expected},
  )).map(_mission);

  static CourierProfile _profile(Object? json) =>
      CourierProfile.fromJson((json! as Map).cast<String, dynamic>());

  static Mission _mission(Object? json) =>
      Mission.fromJson((json! as Map).cast<String, dynamic>());

  static List<Mission> _missions(Object? json) => [
    for (final m in json as List? ?? const [])
      Mission.fromJson((m as Map).cast<String, dynamic>()),
  ];
}
