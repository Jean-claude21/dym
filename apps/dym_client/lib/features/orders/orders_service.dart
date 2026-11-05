import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/foundation.dart';

/// Commandes de la cliente, centre de notifications et réglages. Le nombre
/// de non-lues est partagé (pastille de l'onglet). Remplaçable en test.
abstract interface class OrdersService {
  /// Non-lues (relu à chaque lecture du centre ou de la liste).
  ValueListenable<int> get unread;

  Future<Result<CountryConfig>> countryConfig();

  Future<Result<List<CustomerOrder>>> orders();

  Future<Result<CustomerOrder>> order(String id);

  Future<Result<CustomerOrder>> cancel(CustomerOrder order);

  Future<Result<List<AppNotification>>> notifications();

  Future<void> refreshUnread();

  /// Marque lues [ids] (nul : toutes).
  Future<Result<int>> markRead([List<String>? ids]);

  Future<Result<List<NotificationPreference>>> preferences();

  Future<Result<List<NotificationPreference>>> setPreference(
    NotificationCategory category, {
    required bool enabled,
  });
}

/// Implémentation Neon.
class NeonOrdersService implements OrdersService {
  new({
    required this._orders,
    required this._notifications,
    required this._reference,
    required this._auth,
  });

  final OrderTrackingRepository _orders;
  final NotificationRepository _notifications;
  final ReferenceRepository _reference;
  final AuthService _auth;
  final ValueNotifier<int> _unread = ValueNotifier(0);
  CountryConfig? _config;

  @override
  ValueListenable<int> get unread => _unread;

  @override
  Future<Result<CountryConfig>> countryConfig() async {
    final cached = _config;
    if (cached != null) return Ok(cached);
    final code = _auth.me?.profile?.countryCode;
    if (code == null) return const Err(UnauthenticatedFailure('profil'));
    final result = await _reference.countryConfig(code);
    if (result case Ok(:final value)) _config = value;
    return result;
  }

  @override
  Future<Result<List<CustomerOrder>>> orders() async {
    final result = await _orders.orders();
    await refreshUnread();
    return result;
  }

  @override
  Future<Result<CustomerOrder>> order(String id) => _orders.order(id);

  @override
  Future<Result<CustomerOrder>> cancel(CustomerOrder order) =>
      _orders.cancel(order.id, expected: order.status);

  @override
  Future<Result<List<AppNotification>>> notifications() async {
    final result = await _notifications.notifications();
    await refreshUnread();
    return result;
  }

  @override
  Future<void> refreshUnread() async {
    if (await _notifications.unreadCount() case Ok(:final value)) {
      _unread.value = value;
    }
  }

  @override
  Future<Result<int>> markRead([List<String>? ids]) async {
    final result = await _notifications.markRead(ids);
    if (result case Ok(:final value)) _unread.value = value;
    return result;
  }

  @override
  Future<Result<List<NotificationPreference>>> preferences() =>
      _notifications.preferences();

  @override
  Future<Result<List<NotificationPreference>>> setPreference(
    NotificationCategory category, {
    required bool enabled,
  }) => _notifications.setPreference(category, enabled: enabled);
}
