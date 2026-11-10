import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Centre d'opérations (spec 053) : vue en direct et réglages d'un pays du
/// périmètre de l'admin. Toute écriture est auditée en base.
class OpsRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<List<String>>> countries() async =>
      (await _data.rpc<Object?>('ops_countries'))
          .map((json) => [for (final c in json! as List) c as String]);

  Future<Result<OpsLive>> live(String country) async =>
      (await _data.rpc<Object?>(
        'ops_live',
        params: {'p_country': country},
      )).map(
        (json) => OpsLive.fromJson((json! as Map).cast<String, dynamic>()),
      );

  Future<Result<OpsSettings>> settings(String country) =>
      _settings('admin_ops_settings', {'p_country': country});

  Future<Result<OpsSettings>> setThresholds(
    String country,
    Map<String, int> values,
  ) => _settings('admin_set_ops_thresholds', {
    'p_country': country,
    'p_values': values,
  });

  Future<Result<OpsSettings>> setFeedWeights(
    String country,
    Map<String, int> weights,
  ) => _settings('admin_set_feed_weights', {
    'p_country': country,
    'p_weights': weights,
  });

  Future<Result<OpsSettings>> savePlan(Map<String, Object?> plan) =>
      _settings('admin_save_membership_plan', {'p_plan': plan});

  Future<Result<OpsSettings>> setScope(
    String email,
    String country, {
    required bool on,
  }) => _settings('admin_set_scope', {
    'p_email': email,
    'p_country': country,
    'p_on': on,
  });

  /// Cash remis par un livreur à l'équipe (spec 043).
  Future<Result<int>> confirmCourierCash(String courierId, String key) async =>
      (await _data.rpc<Object?>(
        'admin_confirm_courier_cash',
        params: {'p_courier': courierId, 'p_key': key},
      )).map((json) => ((json! as Map)['amount_minor'] as num).toInt());

  Future<Result<OpsSettings>> _settings(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(fn, params: params)).map(
    (json) => OpsSettings.fromJson((json! as Map).cast<String, dynamic>()),
  );
}
