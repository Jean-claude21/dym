import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Commandes de la boutique de la vendeuse connectée (payées ou en cash).
class VendorOrderRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<List<VendorOrder>>> orders({int limit = 50}) async {
    final result = await _data.rpc<Object?>(
      'my_store_orders',
      params: {'p_limit': limit},
    );
    return _decode(result, (json) {
      if (json is! List) throw const FormatException();
      return [
        for (final o in json) VendorOrder.fromJson(o as Map<String, dynamic>),
      ];
    });
  }

  /// Détail ; `NotFoundFailure` si la commande n'est pas (encore) visible.
  Future<Result<VendorOrder>> order(String id) async {
    final result = await _data.rpc<Object?>(
      'my_store_order',
      params: {'p_id': id},
    );
    return _decode(result, (json) {
      if (json is! Map<String, dynamic>) throw const FormatException();
      return VendorOrder.fromJson(json);
    });
  }

  Result<T> _decode<T>(Result<Object?> result, T Function(Object? json) f) {
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        try {
          return Ok(f(value));
        } on Object {
          return const Err(ServerFailure('réponse illisible'));
        }
    }
  }
}
