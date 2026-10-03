import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Onglet de la liste des commandes.
enum VendorOrderScope { newOrders, active, done }

/// Commandes de la boutique de la vendeuse connectée (payées ou en cash).
/// Les gestes passent par la Function (notifications et push).
class VendorOrderRepository {
  new({required this._data, required this._functions});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;

  Future<Result<List<VendorOrder>>> orders({
    VendorOrderScope? scope,
    int limit = 50,
  }) async {
    final result = await _data.rpc<Object?>(
      'my_store_orders',
      params: {
        'p_scope': switch (scope) {
          VendorOrderScope.newOrders => 'new',
          VendorOrderScope.active => 'active',
          VendorOrderScope.done => 'done',
          null => null,
        },
        'p_limit': limit,
      },
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

  /// Étape suivante. Refus (`ValidationFailure.message`) : `status_changed`,
  /// `transition_not_allowed`, `reason_required`.
  Future<Result<VendorOrder>> transition(
    String id, {
    required OrderStatus to,
    required OrderStatus expected,
    RefusalReason? reason,
    String? note,
  }) => _thenReload(
    id,
    _functions.post<Object?>(
      '/v1/orders/$id/transitions',
      body: {
        'to': to.code,
        'expected': expected.code,
        'reason': reason?.code,
        'note': note,
      },
      decode: (json) => json,
    ),
  );

  /// Encaissement du cash (commande livrée). Refus : `not_cash`,
  /// `not_delivered`.
  Future<Result<VendorOrder>> confirmCash(String id) => _thenReload(
    id,
    _functions.post<Object?>(
      '/v1/orders/$id/cash-collected',
      body: const <String, Object?>{},
      decode: (json) => json,
    ),
  );

  /// Geste réussi : détail relu (format de la vendeuse).
  Future<Result<VendorOrder>> _thenReload(
    String id,
    Future<Result<Object?>> gesture,
  ) async {
    switch (await gesture) {
      case Err(:final failure):
        return Err(failure);
      case Ok():
        return await order(id);
    }
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
