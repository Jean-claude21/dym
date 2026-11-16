import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/foundation.dart';

/// Commandes de la cliente, centre de notifications et réglages. Le nombre
/// de non-lues est partagé (pastille de l'onglet). Remplaçable en test.
abstract interface class OrdersService {
  /// Changements en direct (statut, notification…, spec 067).
  Stream<LiveSignal> get live;

  /// Non-lues (relu à chaque lecture du centre ou de la liste).
  ValueListenable<int> get unread;

  Future<Result<CountryConfig>> countryConfig();

  Future<Result<List<CustomerOrder>>> orders();

  Future<Result<CustomerOrder>> order(String id);

  /// Code de remise à donner au livreur DYM (spec 042) ; nul : aucun.
  Future<Result<String?>> handoverCode(String orderId);

  /// Suivi en direct : boutique, porte, livreur, minutes restantes (spec 096).
  Future<Result<LiveTracking>> liveTracking(String orderId);

  /// Lien de suivi à partager (n'importe quelle messagerie), 24 h au plus.
  Future<Result<Uri>> shareTracking(String orderId);

  Future<Result<CustomerOrder>> cancel(CustomerOrder order);

  Future<Result<List<AppNotification>>> notifications();

  Future<void> refreshUnread();

  /// Marque lues [ids] (nul : toutes).
  Future<Result<int>> markRead([List<String>? ids]);

  Future<Result<List<NotificationPreference>>> preferences();

  /// Dernier litige d'une commande (`Ok(null)` : aucun).
  Future<Result<Dispute?>> dispute(String orderId);

  Future<Result<Dispute>> openDispute(
    String orderId, {
    required DisputeReason reason,
    required String description,
  });

  Future<Result<Dispute>> replyDispute(String disputeId, String body);

  /// Mon avis sur une commande (`Ok(null)` : pas encore donné).
  Future<Result<Review?>> orderReview(String orderId);

  /// Refus : `review_not_allowed`, `review_exists`.
  Future<Result<Review>> leaveReview(
    String orderId, {
    required int rating,
    List<ReviewTag> tags = const [],
    String? comment,
  });

  /// Réachat en un tap : articles encore en vente remis au panier.
  Future<Result<ReorderResult>> reorder(String orderId);

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
    required this._disputes,
    required this._reviews,
    required this._reorders,
    required this._reference,
    required this._auth,
    this._live = LiveFeed.none,
    this._delivery,
    this._trackingBase,
  });

  /// Suivi en direct (spec 096) ; absent : pas de carte.
  final DeliveryRepository? _delivery;

  /// Adresse publique des liens de suivi (`<Functions>/t/`).
  final Uri? _trackingBase;

  @override
  Future<Result<LiveTracking>> liveTracking(String orderId) async =>
      await _delivery?.tracking(orderId) ?? const Err(NotFoundFailure('suivi'));

  @override
  Future<Result<Uri>> shareTracking(String orderId) async {
    final delivery = _delivery;
    final base = _trackingBase;
    if (delivery == null || base == null) {
      return const Err(NotFoundFailure('suivi'));
    }
    return (await delivery.share(orderId))
        .map((share) => base.replace(path: '${base.path}/t/${share.token}'));
  }

  final LiveFeed _live;

  @override
  Stream<LiveSignal> get live => _live.signals;

  final OrderTrackingRepository _orders;
  final NotificationRepository _notifications;
  final DisputeRepository _disputes;
  final ReviewRepository _reviews;
  final ReorderRepository _reorders;
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
  Future<Result<String?>> handoverCode(String orderId) =>
      _orders.handoverCode(orderId);

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
  Future<Result<Dispute?>> dispute(String orderId) =>
      _disputes.forOrder(orderId);

  @override
  Future<Result<Dispute>> openDispute(
    String orderId, {
    required DisputeReason reason,
    required String description,
  }) => _disputes.open(orderId, reason: reason, description: description);

  @override
  Future<Result<Dispute>> replyDispute(String disputeId, String body) =>
      _disputes.reply(disputeId, body);

  @override
  Future<Result<Review?>> orderReview(String orderId) =>
      _reviews.orderReview(orderId);

  @override
  Future<Result<Review>> leaveReview(
    String orderId, {
    required int rating,
    List<ReviewTag> tags = const [],
    String? comment,
  }) => _reviews.leave(orderId, rating: rating, tags: tags, comment: comment);

  @override
  Future<Result<ReorderResult>> reorder(String orderId) =>
      _reorders.reorder(orderId);

  @override
  Future<Result<List<NotificationPreference>>> setPreference(
    NotificationCategory category, {
    required bool enabled,
  }) => _notifications.setPreference(category, enabled: enabled);
}
