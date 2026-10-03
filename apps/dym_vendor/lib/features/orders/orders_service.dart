import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/store_service.dart';

/// Commandes de la boutique (payées ou en cash) et leurs gestes. Remplaçable
/// en test.
abstract interface class OrdersService {
  /// Référentiel du pays de la boutique (devise).
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<List<VendorOrder>>> orders({VendorOrderScope? scope});

  Future<Result<VendorOrder>> order(String id);

  /// Étape suivante (la base décide). Refus : `status_changed`,
  /// `transition_not_allowed`, `reason_required`.
  Future<Result<VendorOrder>> advance(
    VendorOrder order,
    OrderStatus to, {
    RefusalReason? reason,
    String? note,
  });

  Future<Result<VendorOrder>> confirmCash(VendorOrder order);

  /// Dernier litige de la commande (`Ok(null)` : aucun).
  Future<Result<Dispute?>> dispute(String orderId);

  /// Réponse à la cliente. Refus : `dispute_closed`.
  Future<Result<Dispute>> replyDispute(String disputeId, String body);
}

/// Implémentation Neon.
class NeonOrdersService implements OrdersService {
  new({required this._orders, required this._disputes, required this._stores});

  final VendorOrderRepository _orders;
  final DisputeRepository _disputes;
  final StoreService _stores;

  @override
  Future<Result<CountryConfig>> countryConfig() => _stores.countryConfig();

  @override
  Future<Result<List<VendorOrder>>> orders({VendorOrderScope? scope}) =>
      _orders.orders(scope: scope);

  @override
  Future<Result<VendorOrder>> order(String id) => _orders.order(id);

  @override
  Future<Result<VendorOrder>> advance(
    VendorOrder order,
    OrderStatus to, {
    RefusalReason? reason,
    String? note,
  }) => _orders.transition(
    order.id,
    to: to,
    expected: order.status,
    reason: reason,
    note: note,
  );

  @override
  Future<Result<VendorOrder>> confirmCash(VendorOrder order) =>
      _orders.confirmCash(order.id);

  @override
  Future<Result<Dispute?>> dispute(String orderId) =>
      _disputes.forOrder(orderId);

  @override
  Future<Result<Dispute>> replyDispute(String disputeId, String body) =>
      _disputes.reply(disputeId, body);
}
