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

  /// Remise : le code donné par la cliente.
  Future<Result<HandoverResult>> deliver(String orderId, String code) async =>
      (await _data.rpc<Object?>(
        'courier_deliver',
        params: {'p_order': orderId, 'p_code': code},
      )).map(
        (json) =>
            HandoverResult.fromJson((json! as Map).cast<String, dynamic>()),
      );

  /// Gains du jour, wallet, cash à remettre (spec 043).
  Future<Result<CourierEarnings>> earnings() async =>
      (await _data.rpc<Object?>('courier_earnings')).map(_earnings);

  /// Point de recharge : cash de la cliente vers son wallet.
  Future<Result<CourierEarnings>> cashTopup({
    required String code,
    required int amountMinor,
    required String key,
  }) async => (await _data.rpc<Object?>(
    'courier_cash_topup',
    params: {'p_code': code, 'p_amount_minor': amountMinor, 'p_key': key},
  )).map(_earnings);

  /// Boutique : cash que lui doivent les livreurs.
  Future<Result<List<StoreCourierCash>>> storeCash() async =>
      (await _data.rpc<Object?>('store_courier_cash')).map(_storeCash);

  /// Boutique : tout le cash du livreur est reçu.
  Future<Result<List<StoreCourierCash>>> confirmStoreCash(
    String courierId, {
    required String key,
  }) async => (await _data.rpc<Object?>(
    'confirm_courier_cash',
    params: {'p_courier': courierId, 'p_key': key},
  )).map(_storeCash);

  static CourierEarnings _earnings(Object? json) =>
      CourierEarnings.fromJson((json! as Map).cast<String, dynamic>());

  static List<StoreCourierCash> _storeCash(Object? json) => [
    for (final c in json as List? ?? const [])
      StoreCourierCash.fromJson((c as Map).cast<String, dynamic>()),
  ];

  static CourierProfile _profile(Object? json) =>
      CourierProfile.fromJson((json! as Map).cast<String, dynamic>());

  static Mission _mission(Object? json) =>
      Mission.fromJson((json! as Map).cast<String, dynamic>());

  static List<Mission> _missions(Object? json) => [
    for (final m in json as List? ?? const [])
      Mission.fromJson((m as Map).cast<String, dynamic>()),
  ];
}
