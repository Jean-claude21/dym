import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/foundation.dart';

/// Commandes et notifications en mémoire (tests, galerie) : reproduit
/// l'annulation avant préparation. Jamais en production.
class MemoryOrdersService implements OrdersService {
  new({
    required this.config,
    List<CustomerOrder> orders = const [],
    List<AppNotification> notifications = const [],
  }) : _orders = [...orders],
       _notifications = [...notifications] {
    _unread.value = _notifications.where((n) => n.unread).length;
  }

  final CountryConfig config;
  final List<CustomerOrder> _orders;
  final List<AppNotification> _notifications;
  final ValueNotifier<int> _unread = ValueNotifier(0);
  final _prefs = <NotificationCategory, bool>{
    NotificationCategory.orders: true,
    NotificationCategory.payments: true,
    NotificationCategory.messages: true,
    NotificationCategory.promotions: false,
  };

  /// Prochain appel en échec (une fois).
  Failure? failNext;
  int reads = 0;

  Result<T>? _fail<T>() {
    final failure = failNext;
    if (failure == null) return null;
    failNext = null;
    return Err(failure);
  }

  /// La vendeuse fait avancer la commande (tests).
  void advance(String id, OrderStatus status) {
    final i = _orders.indexWhere((o) => o.id == id);
    _orders[i] = copyOrder(_orders[i], status: status);
  }

  @override
  ValueListenable<int> get unread => _unread;

  @override
  Future<Result<CountryConfig>> countryConfig() async =>
      _fail<CountryConfig>() ?? Ok(config);

  @override
  Future<Result<List<CustomerOrder>>> orders() async {
    reads++;
    return _fail<List<CustomerOrder>>() ?? Ok(List.of(_orders));
  }

  @override
  Future<Result<CustomerOrder>> order(String id) async {
    reads++;
    final failed = _fail<CustomerOrder>();
    if (failed != null) return failed;
    final o = _orders.where((o) => o.id == id).firstOrNull;
    return o == null ? const Err(NotFoundFailure('commande')) : Ok(o);
  }

  @override
  Future<Result<CustomerOrder>> cancel(CustomerOrder order) async {
    final failed = _fail<CustomerOrder>();
    if (failed != null) return failed;
    final current = _orders.firstWhere((o) => o.id == order.id);
    if (current.status != order.status) {
      return const Err(ValidationFailure('status_changed'));
    }
    if (!current.canCancel) {
      return const Err(ValidationFailure('transition_not_allowed'));
    }
    final cancelled = copyOrder(current, status: OrderStatus.cancelled);
    _orders[_orders.indexOf(current)] = cancelled;
    return Ok(cancelled);
  }

  @override
  Future<Result<List<AppNotification>>> notifications() async =>
      _fail<List<AppNotification>>() ?? Ok(List.of(_notifications));

  @override
  Future<void> refreshUnread() async =>
      _unread.value = _notifications.where((n) => n.unread).length;

  @override
  Future<Result<int>> markRead([List<String>? ids]) async {
    for (final (i, n) in _notifications.indexed) {
      if (n.unread && (ids == null || ids.contains(n.id))) {
        _notifications[i] = AppNotification(
          id: n.id,
          kind: n.kind,
          category: n.category,
          orderId: n.orderId,
          purchaseId: n.purchaseId,
          params: n.params,
          readAt: DateTime.utc(2026, 10, 5, 11),
          createdAt: n.createdAt,
        );
      }
    }
    await refreshUnread();
    return Ok(_unread.value);
  }

  @override
  Future<Result<List<NotificationPreference>>> preferences() async =>
      _fail<List<NotificationPreference>>() ?? Ok(_list());

  @override
  Future<Result<List<NotificationPreference>>> setPreference(
    NotificationCategory category, {
    required bool enabled,
  }) async {
    _prefs[category] = enabled;
    return Ok(_list());
  }

  List<NotificationPreference> _list() => [
    for (final e in _prefs.entries)
      NotificationPreference(category: e.key, pushEnabled: e.value),
  ];
}

/// Copie d'une commande avec un autre statut ; les étapes permises suivent
/// les règles de la cliente (annuler avant la préparation).
CustomerOrder copyOrder(CustomerOrder o, {required OrderStatus status}) =>
    CustomerOrder(
      id: o.id,
      purchaseId: o.purchaseId,
      status: status,
      fulfillment: o.fulfillment,
      createdAt: o.createdAt,
      currencyCode: o.currencyCode,
      totalMinor: o.totalMinor,
      subtotalMinor: o.subtotalMinor,
      deliveryFeeMinor: o.deliveryFeeMinor,
      store: o.store,
      itemCount: o.itemCount,
      etaAt: status.isActive ? o.etaAt : null,
      acceptedAt: o.acceptedAt,
      cancelledBy: status == OrderStatus.cancelled ? 'client' : o.cancelledBy,
      statusReason: o.statusReason,
      paymentStatus: o.paymentStatus,
      paymentMethod: o.paymentMethod,
      items: o.items,
      history: [
        ...o.history,
        if (status != o.status)
          OrderStatusEvent(
            toStatus: status,
            actorRole: 'vendor',
            occurredAt: DateTime.utc(2026, 10, 5, 10, 30),
          ),
      ],
      nextStatuses:
          status == OrderStatus.pending || status == OrderStatus.accepted
          ? const [OrderStatus.cancelled]
          : const [],
      address: o.address,
    );
