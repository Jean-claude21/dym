import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

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

Map<String, dynamic> _map(Object? json) => json! as Map<String, dynamic>;

/// Avis (spec 016) : lectures par la Data API, gestes par la Function
/// (notifications).
class ReviewRepository {
  new({required this._data, required this._functions});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;

  /// Avis publics d'une boutique (visiteuse comprise).
  Future<Result<StoreReviews>> storeReviews(String storeId) async => _decode(
    await _data.rpc<Object?>('store_reviews', params: {'p_store': storeId}),
    (json) => StoreReviews.fromJson(_map(json)),
  );

  /// Avis de ma boutique (vendeuse).
  Future<Result<StoreReviews>> myStoreReviews() async => _decode(
    await _data.rpc<Object?>('my_store_reviews'),
    (json) => StoreReviews.fromJson(_map(json)),
  );

  /// Mon avis sur une commande (`Ok(null)` : pas encore donné).
  Future<Result<Review?>> orderReview(String orderId) async => _decode(
    await _data.rpc<Object?>('order_review', params: {'p_order': orderId}),
    (json) => json == null ? null : Review.fromJson(_map(json)),
  );

  /// Refus : `review_not_allowed`, `review_exists`.
  Future<Result<Review>> leave(
    String orderId, {
    required int rating,
    List<ReviewTag> tags = const [],
    String? comment,
  }) => _functions.post(
    '/v1/orders/$orderId/review',
    body: {
      'rating': rating,
      'tags': [for (final t in tags) t.code],
      'comment': comment,
    },
    decode: (json) => Review.fromJson(_map(json)),
  );

  Future<Result<Review>> reply(String reviewId, String reply) =>
      _functions.post(
        '/v1/reviews/$reviewId/reply',
        body: {'reply': reply},
        decode: (json) => Review.fromJson(_map(json)),
      );
}

/// Demandes d'aide de l'utilisatrice (spec 016), par la Data API.
class SupportRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<List<SupportTicket>>> myTickets(String app) async => _decode(
    await _data.rpc<Object?>('my_tickets', params: {'p_app': app}),
    (json) => [for (final t in json! as List) SupportTicket.fromJson(_map(t))],
  );

  /// Refus : `ticket_invalid` ; commande d'autrui : `NotFoundFailure`.
  Future<Result<SupportTicket>> open({
    required String app,
    required TicketSubject subject,
    required String body,
    String? orderId,
  }) async => _decode(
    await _data.rpc<Object?>(
      'open_ticket',
      params: {
        'p_app': app,
        'p_subject': subject.code,
        'p_body': body,
        'p_order': orderId,
      },
    ),
    (json) => SupportTicket.fromJson(_map(json)),
  );

  Future<Result<SupportTicket>> reply(String ticketId, String body) async =>
      _decode(
        await _data.rpc<Object?>(
          'reply_ticket',
          params: {'p_ticket': ticketId, 'p_body': body},
        ),
        (json) => SupportTicket.fromJson(_map(json)),
      );
}

/// Réachat en un tap (C-ORD-09).
class ReorderRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<ReorderResult>> reorder(String orderId) async => _decode(
    await _data.rpc<Object?>('reorder', params: {'p_order': orderId}),
    (json) => ReorderResult.fromJson(_map(json)),
  );
}
