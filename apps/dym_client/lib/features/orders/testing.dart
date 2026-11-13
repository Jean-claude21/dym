import 'dart:async';

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

  /// Signaux en direct simulés (tests).
  final liveSignals = StreamController<LiveSignal>.broadcast();

  @override
  Stream<LiveSignal> get live => liveSignals.stream;
  final ValueNotifier<int> _unread = ValueNotifier(0);
  final _disputes = <String, Dispute>{};
  final _reviews = <String, Review>{};

  /// Articles écartés au prochain réachat (tests).
  List<String> reorderSkipped = const [];
  final reorders = <String>[];
  final _prefs = <NotificationCategory, bool>{
    NotificationCategory.orders: true,
    NotificationCategory.payments: true,
    NotificationCategory.messages: true,
    NotificationCategory.promotions: false,
    NotificationCategory.quietNight: false,
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

  /// Codes de remise par commande (spec 042).
  final handoverCodes = <String, String>{};

  @override
  Future<Result<String?>> handoverCode(String orderId) async =>
      Ok(handoverCodes[orderId]);

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

  @override
  Future<Result<Review?>> orderReview(String orderId) async =>
      _fail<Review?>() ?? Ok(_reviews[orderId]);

  @override
  Future<Result<Review>> leaveReview(
    String orderId, {
    required int rating,
    List<ReviewTag> tags = const [],
    String? comment,
  }) async {
    final failed = _fail<Review>();
    if (failed != null) return failed;
    if (_reviews.containsKey(orderId)) {
      return const Err(ValidationFailure('review_exists'));
    }
    return Ok(
      _reviews[orderId] = Review(
        id: 'r-$orderId',
        orderId: orderId,
        storeId: 's',
        rating: rating,
        tags: tags,
        comment: comment,
        createdAt: DateTime.utc(2026, 10, 5, 11),
      ),
    );
  }

  @override
  Future<Result<ReorderResult>> reorder(String orderId) async {
    final failed = _fail<ReorderResult>();
    if (failed != null) return failed;
    reorders.add(orderId);
    return Ok(ReorderResult(added: 1, skipped: reorderSkipped));
  }

  /// Litige déjà ouvert (tests, galerie).
  void seedDispute(Dispute d) => _disputes[d.orderId] = d;

  @override
  Future<Result<Dispute?>> dispute(String orderId) async =>
      _fail<Dispute?>() ?? Ok(_disputes[orderId]);

  @override
  Future<Result<Dispute>> openDispute(
    String orderId, {
    required DisputeReason reason,
    required String description,
  }) async {
    final failed = _fail<Dispute>();
    if (failed != null) return failed;
    if (_disputes[orderId]?.isOpen ?? false) {
      return const Err(ValidationFailure('dispute_already_open'));
    }
    final now = DateTime.utc(2026, 10, 5, 11);
    return Ok(
      _disputes[orderId] = Dispute(
        id: 'd-$orderId',
        orderId: orderId,
        reason: reason,
        description: description,
        status: 'open',
        createdAt: now,
        currencyCode: config.currency.code,
        messages: [
          DisputeMessage(
            id: 'm0',
            authorRole: 'client',
            body: description,
            createdAt: now,
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<Dispute>> replyDispute(String disputeId, String body) async {
    final d = _disputes.values.firstWhere((d) => d.id == disputeId);
    if (!d.isOpen) return const Err(ValidationFailure('dispute_closed'));
    return Ok(
      _disputes[d.orderId] = Dispute(
        id: d.id,
        orderId: d.orderId,
        reason: d.reason,
        description: d.description,
        status: d.status,
        createdAt: d.createdAt,
        currencyCode: d.currencyCode,
        storeName: d.storeName,
        messages: [
          ...d.messages,
          DisputeMessage(
            id: 'm${d.messages.length}',
            authorRole: 'client',
            body: body,
            createdAt: DateTime.utc(2026, 10, 5, 11, 5),
          ),
        ],
      ),
    );
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
      courier: o.courier,
    );
