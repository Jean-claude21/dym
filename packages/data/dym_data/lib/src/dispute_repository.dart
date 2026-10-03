import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Litiges : lecture par la Data API, gestes par la Function (notifications).
class DisputeRepository {
  new({required this._data, required this._functions});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;

  /// Dernier litige d'une commande (`Ok(null)` : aucun).
  Future<Result<Dispute?>> forOrder(String orderId) async {
    final result = await _data.rpc<Object?>(
      'order_dispute',
      params: {'p_order': orderId},
    );
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value == null) return const Ok(null);
        try {
          return Ok(Dispute.fromJson(value as Map<String, dynamic>));
        } on Object {
          return const Err(ServerFailure('réponse illisible'));
        }
    }
  }

  /// Signalement. Refus : `dispute_not_allowed`, `dispute_already_open`.
  Future<Result<Dispute>> open(
    String orderId, {
    required DisputeReason reason,
    required String description,
  }) => _functions.post<Dispute>(
    '/v1/orders/$orderId/disputes',
    body: {'reason': reason.code, 'description': description},
    decode: (json) => Dispute.fromJson(json! as Map<String, dynamic>),
  );

  /// Message. Refus : `dispute_closed`.
  Future<Result<Dispute>> reply(String disputeId, String body) =>
      _functions.post<Dispute>(
        '/v1/disputes/$disputeId/messages',
        body: {'body': body},
        decode: (json) => Dispute.fromJson(json! as Map<String, dynamic>),
      );
}
