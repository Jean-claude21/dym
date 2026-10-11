import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Relance des clientes et alerte de stock bas (spec 021) : audience et
/// réglage par la Data API, envoi par la Function (push).
class BroadcastRepository {
  new({required this._data, required this._functions});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;

  Future<Result<BroadcastAudience>> audience() async =>
      (await _data.rpc<Object?>('broadcast_audience')).map(
        (json) => BroadcastAudience.fromJson(json! as Map<String, dynamic>),
      );

  /// Refus : `feature_disabled`, `broadcast_daily_limit`,
  /// `broadcast_invalid`. Renvoie le nombre de destinataires.
  Future<Result<int>> send(
    BroadcastSegment segment,
    String message, {
    String? productId,
  }) => _functions.post(
    '/v1/vendor/broadcasts',
    body: {
      'segment': segment.name,
      'message': message,
      'product_id': productId,
    },
    // Une relance par jour : rejouer après une coupure réseau est sans risque.
    idempotencyKey: Uuid.v4(),
    decode: (json) =>
        ((json! as Map<String, dynamic>)['recipients'] as num).toInt(),
  );

  /// Nul : alerte coupée.
  Future<Result<void>> setLowStockThreshold(int? threshold) async =>
      (await _data.rpc<Object?>(
        'set_low_stock_threshold',
        params: {'p_threshold': threshold},
      )).map((_) {});
}
