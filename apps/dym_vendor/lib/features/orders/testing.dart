import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';

/// Gestes permis à la vendeuse (miroir des règles SQL, tests et galerie).
List<OrderStatus> vendorNextStatuses(OrderStatus from, Fulfillment mode) =>
    switch (from) {
      OrderStatus.pending => const [OrderStatus.accepted, OrderStatus.refused],
      OrderStatus.accepted => const [OrderStatus.preparing, OrderStatus.ready],
      OrderStatus.preparing => const [OrderStatus.ready],
      OrderStatus.ready =>
        mode == Fulfillment.delivery
            ? const [OrderStatus.outForDelivery]
            : const [OrderStatus.delivered],
      OrderStatus.outForDelivery => const [OrderStatus.delivered],
      _ => const [],
    };

/// Commandes en mémoire (tests, galerie). Jamais en production.
class MemoryOrdersService implements OrdersService {
  new({required this.config, List<VendorOrder> orders = const []})
    : _orders = [for (final o in orders) _withNext(o)];

  final CountryConfig config;
  final List<VendorOrder> _orders;
  final _disputes = <String, Dispute>{};

  /// Signaux en direct simulés (tests).
  final liveSignals = StreamController<LiveSignal>.broadcast();

  @override
  Stream<LiveSignal> get live => liveSignals.stream;

  /// Prochain appel en échec (une fois).
  Failure? failNext;
  int reads = 0;
  final gestures = <String>[];

  Result<T>? _fail<T>() {
    final failure = failNext;
    if (failure == null) return null;
    failNext = null;
    return Err(failure);
  }

  /// Une commande devient visible (paiement confirmé, cash).
  void arrive(VendorOrder order) => _orders.insert(0, _withNext(order));

  @override
  Future<Result<CountryConfig>> countryConfig() async =>
      _fail<CountryConfig>() ?? Ok(config);

  @override
  Future<Result<List<VendorOrder>>> orders({VendorOrderScope? scope}) async {
    reads++;
    final failed = _fail<List<VendorOrder>>();
    if (failed != null) return failed;
    bool keep(VendorOrder o) => switch (scope) {
      VendorOrderScope.newOrders => o.status == OrderStatus.pending,
      VendorOrderScope.active =>
        o.status.isActive && o.status != OrderStatus.pending,
      VendorOrderScope.done => !o.status.isActive,
      null => true,
    };
    return Ok(_orders.where(keep).toList());
  }

  @override
  Future<Result<VendorOrder>> order(String id) async =>
      _fail<VendorOrder>() ??
      (_orders.where((o) => o.id == id).firstOrNull == null
          ? const Err(NotFoundFailure('commande'))
          : Ok(_orders.firstWhere((o) => o.id == id)));

  @override
  Future<Result<VendorOrder>> advance(
    VendorOrder order,
    OrderStatus to, {
    RefusalReason? reason,
    String? note,
  }) async {
    final failed = _fail<VendorOrder>();
    if (failed != null) return failed;
    final i = _orders.indexWhere((o) => o.id == order.id);
    final current = _orders[i];
    if (current.status != order.status) {
      return const Err(ValidationFailure('status_changed'));
    }
    if (!vendorNextStatuses(current.status, current.fulfillment).contains(to)) {
      return const Err(ValidationFailure('transition_not_allowed'));
    }
    if (to == OrderStatus.refused && reason == null) {
      return const Err(ValidationFailure('reason_required'));
    }
    gestures.add('${order.id}:${to.code}');
    return Ok(
      _orders[i] = _copy(
        current,
        status: to,
        reason: reason,
        acceptedAt: to == OrderStatus.accepted
            ? DateTime.utc(2026, 10, 5, 10, 44)
            : current.acceptedAt,
      ),
    );
  }

  @override
  Future<Result<VendorOrder>> confirmCash(VendorOrder order) async {
    final i = _orders.indexWhere((o) => o.id == order.id);
    final current = _orders[i];
    if (!current.isCash) return const Err(ValidationFailure('not_cash'));
    if (current.status != OrderStatus.delivered) {
      return const Err(ValidationFailure('not_delivered'));
    }
    gestures.add('${order.id}:cash');
    return Ok(
      _orders[i] = _copy(
        current,
        status: current.status,
        cashCollectedAt: DateTime.utc(2026, 10, 5, 11, 30),
      ),
    );
  }

  /// Litige sur une commande (tests, galerie).
  void seedDispute(Dispute d) => _disputes[d.orderId] = d;

  @override
  Future<Result<Dispute?>> dispute(String orderId) async =>
      _fail<Dispute?>() ?? Ok(_disputes[orderId]);

  @override
  Future<Result<Dispute>> replyDispute(String disputeId, String body) async {
    final failed = _fail<Dispute>();
    if (failed != null) return failed;
    final d = _disputes.values.firstWhere((d) => d.id == disputeId);
    if (!d.isOpen) return const Err(ValidationFailure('dispute_closed'));
    gestures.add('${d.orderId}:reply');
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
        customerFirstName: d.customerFirstName,
        messages: [
          ...d.messages,
          DisputeMessage(
            id: 'm${d.messages.length}',
            authorRole: 'vendor',
            body: body,
            createdAt: DateTime.utc(2026, 10, 5, 11, 10),
          ),
        ],
      ),
    );
  }

  static VendorOrder _withNext(VendorOrder o) => _copy(o, status: o.status);

  static VendorOrder _copy(
    VendorOrder o, {
    required OrderStatus status,
    RefusalReason? reason,
    DateTime? acceptedAt,
    DateTime? cashCollectedAt,
  }) => VendorOrder(
    id: o.id,
    createdAt: o.createdAt,
    status: status,
    fulfillment: o.fulfillment,
    currencyCode: o.currencyCode,
    subtotalMinor: o.subtotalMinor,
    deliveryFeeMinor: o.deliveryFeeMinor,
    totalMinor: o.totalMinor,
    paymentStatus: o.paymentStatus,
    paymentMethod: o.paymentMethod,
    itemCount: o.itemCount,
    customerFirstName: o.customerFirstName,
    zoneName: o.zoneName,
    substitutionAllowed: o.substitutionAllowed,
    items: o.items,
    delivery: o.delivery,
    payment: o.payment,
    etaAt: o.etaAt,
    acceptedAt: acceptedAt ?? o.acceptedAt,
    deliveredAt: status == OrderStatus.delivered
        ? (o.deliveredAt ?? DateTime.utc(2026, 10, 5, 11, 20))
        : o.deliveredAt,
    cashCollectedAt: cashCollectedAt ?? o.cashCollectedAt,
    statusReason: reason ?? o.statusReason,
    statusNote: o.statusNote,
    refundDue: o.refundDue,
    history: [
      ...o.history,
      if (status != o.status)
        OrderStatusEvent(
          toStatus: status,
          actorRole: 'vendor',
          occurredAt: DateTime.utc(2026, 10, 5, 10, 45),
        ),
    ],
    nextStatuses: vendorNextStatuses(status, o.fulfillment),
  );
}
