import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Commandes de la cliente connectée (suivi, annulation).
class OrderTrackingRepository {
  new({required this._data, required this._functions});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;

  Future<Result<List<CustomerOrder>>> orders({int limit = 50}) async => _decode(
    await _data.rpc<Object?>('my_orders', params: {'p_limit': limit}),
    (json) {
      if (json is! List) throw const FormatException();
      return [
        for (final o in json) CustomerOrder.fromJson(o as Map<String, dynamic>),
      ];
    },
  );

  /// Code de remise à donner au livreur (spec 042) ; nul : aucun.
  Future<Result<String?>> handoverCode(String orderId) async =>
      (await _data.rpc<Object?>(
        'my_handover_code',
        params: {'p_order': orderId},
      )).map((json) => json as String?);

  Future<Result<CustomerOrder>> order(String id) async => _decode(
    await _data.rpc<Object?>('my_order', params: {'p_id': id}),
    (json) {
      if (json is! Map<String, dynamic>) throw const FormatException();
      return CustomerOrder.fromJson(json);
    },
  );

  /// Annulation avant la préparation. Refus : `status_changed`,
  /// `transition_not_allowed`.
  Future<Result<CustomerOrder>> cancel(
    String id, {
    required OrderStatus expected,
  }) async {
    final result = await _functions.post<Object?>(
      '/v1/orders/$id/transitions',
      body: {'to': OrderStatus.cancelled.code, 'expected': expected.code},
      decode: (json) => json,
    );
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok():
        return await order(id);
    }
  }
}

/// Centre de notifications et préférences de la personne connectée.
class NotificationRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<List<AppNotification>>> notifications({int limit = 50}) async =>
      _decode(
        await _data.rpc<Object?>(
          'my_notifications',
          params: {'p_limit': limit},
        ),
        (json) {
          if (json is! List) throw const FormatException();
          return [
            for (final n in json)
              AppNotification.fromJson(n as Map<String, dynamic>),
          ];
        },
      );

  Future<Result<int>> unreadCount() async => _decode(
    await _data.rpc<Object?>('unread_notifications_count'),
    (json) => (json! as num).toInt(),
  );

  /// Marque lues [ids] (nul : toutes) ; renvoie les non-lues restantes.
  Future<Result<int>> markRead([List<String>? ids]) async => _decode(
    await _data.rpc<Object?>('mark_notifications_read', params: {'p_ids': ids}),
    (json) => (json! as num).toInt(),
  );

  Future<Result<List<NotificationPreference>>> preferences() async =>
      _decode(await _data.rpc<Object?>('my_notification_preferences'), _prefs);

  Future<Result<List<NotificationPreference>>> setPreference(
    NotificationCategory category, {
    required bool enabled,
  }) async => _decode(
    await _data.rpc<Object?>(
      'set_notification_preference',
      params: {'p_category': category.name, 'p_enabled': enabled},
    ),
    _prefs,
  );

  /// Téléphone enregistré pour le push (jeton FCM).
  Future<Result<void>> registerDevice({
    required String token,
    required String platform,
    required String app,
  }) => _data.rpc<void>(
    'register_push_token',
    params: {'p_token': token, 'p_platform': platform, 'p_app': app},
  );

  static List<NotificationPreference> _prefs(Object? json) {
    if (json is! List) throw const FormatException();
    return [
      for (final p in json)
        NotificationPreference.fromJson(p as Map<String, dynamic>),
    ];
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
