import 'dart:async';

import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:stacked/stacked.dart';

/// Base : chargement, échec, hors ligne ; devise du pays ; relecture
/// périodique silencieuse (les gestes de la vendeuse arrivent sans geste).
abstract class _OrdersLoadingViewModel extends BaseViewModel {
  new(this.service, {this.refreshEvery});

  final OrdersService service;

  /// Nul : pas de relecture automatique.
  final Duration? refreshEvery;
  Failure? _failure;
  CountryConfig? _config;
  Timer? _timer;
  bool _offline = false;

  Failure? get failure => _failure;
  bool get failed => _failure != null;
  CountryConfig? get config => _config;

  /// Dernière relecture hors ligne (l'écran reste affiché).
  bool get offline => _offline;

  Money? money(int minor) => _config?.money(minor);

  /// Lecture des données ; renvoie l'échec éventuel.
  Future<Failure?> read();

  Future<void> load() async {
    _failure = null;
    setBusy(true);
    final config = await service.countryConfig();
    switch (config) {
      case Err(:final failure):
        _failure = failure;
      case Ok(:final value):
        _config = value;
        _failure = await read();
    }
    setBusy(false);
    final every = refreshEvery;
    if (every != null) {
      _timer ??= Timer.periodic(every, (_) => unawaited(refresh()));
    }
  }

  /// Relecture silencieuse.
  Future<void> refresh() async {
    final failure = await read();
    _offline = failure is NetworkFailure;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Mes commandes (écran 43) : en cours puis terminées.
class MyOrdersViewModel extends _OrdersLoadingViewModel {
  new({
    required OrdersService service,
    super.refreshEvery = const Duration(seconds: 20),
  }) : super(service);

  List<CustomerOrder> _orders = const [];

  bool get ready => _config != null && !failed;
  List<CustomerOrder> get active =>
      _orders.where((o) => o.status.isActive).toList();
  List<CustomerOrder> get done =>
      _orders.where((o) => !o.status.isActive).toList();
  bool get isEmpty => _orders.isEmpty;

  @override
  Future<Failure?> read() async {
    final result = await service.orders();
    if (result case Ok(:final value)) _orders = value;
    return result.failureOrNull;
  }
}

/// Suivi d'une commande (écran 06, sans carte) : étapes, heure estimée,
/// cash à payer, annulation avant préparation.
class TrackingViewModel extends _OrdersLoadingViewModel {
  new({
    required OrdersService service,
    required this.orderId,
    super.refreshEvery = const Duration(seconds: 20),
  }) : super(service);

  final String orderId;
  CustomerOrder? _order;
  Dispute? _dispute;
  Review? _review;
  bool _reordering = false;
  ReorderResult? _reordered;
  Failure? _reorderFailure;
  bool _cancelling = false;
  Failure? _cancelFailure;
  String? _handoverCode;

  CustomerOrder? get order => _order;

  /// Code à donner au livreur DYM à la remise (spec 042).
  String? get handoverCode => _handoverCode;
  Dispute? get dispute => _dispute;

  /// Mon avis sur la commande (nul : pas encore donné).
  Review? get review => _review;
  bool get canReview =>
      _order?.status == OrderStatus.delivered && _review == null;
  bool get reordering => _reordering;
  ReorderResult? get reordered => _reordered;
  Failure? get reorderFailure => _reorderFailure;

  /// Réachat : livrée, refusée ou annulée.
  bool get canReorder => switch (_order?.status) {
    OrderStatus.delivered ||
    OrderStatus.refused ||
    OrderStatus.cancelled => true,
    _ => false,
  };

  /// Remet les articles au panier ; `true` si au moins un a été ajouté.
  Future<bool> reorder() async {
    final o = _order;
    if (o == null || _reordering) return false;
    _reordering = true;
    _reorderFailure = null;
    notifyListeners();
    final result = await service.reorder(o.id);
    _reordering = false;
    switch (result) {
      case Ok(:final value):
        _reordered = value;
      case Err(:final failure):
        _reorderFailure = failure;
    }
    notifyListeners();
    return (_reordered?.added ?? 0) > 0 && result.isOk;
  }

  bool get ready => _order != null && _config != null && !failed;
  bool get cancelling => _cancelling;

  /// Signalement possible : acceptée, en cours, ou livrée depuis 7 jours au
  /// plus, sans litige ouvert (la base décide en dernier).
  bool get canReport {
    final o = _order;
    if (o == null || (_dispute?.isOpen ?? false)) return false;
    if (o.status == OrderStatus.delivered) {
      final at = o.deliveredAt ?? o.reachedAt(OrderStatus.delivered);
      return at == null || clock().difference(at) <= const Duration(days: 7);
    }
    return o.status.isActive && o.status != OrderStatus.pending;
  }

  /// Horloge (tests).
  DateTime Function() clock = DateTime.now;
  Failure? get cancelFailure => _cancelFailure;

  /// La commande a changé entre la lecture et le geste.
  bool get statusChanged => switch (_cancelFailure) {
    ValidationFailure(message: 'status_changed') => true,
    _ => false,
  };

  @override
  Future<Failure?> read() async {
    final result = await service.order(orderId);
    if (result case Ok(:final value)) _order = value;
    if (await service.dispute(orderId) case Ok(:final value)) _dispute = value;
    _handoverCode =
        _order?.fulfillment == Fulfillment.delivery &&
            (_order?.status.isActive ?? false)
        ? (await service.handoverCode(orderId)).valueOrNull
        : null;
    if (_order?.status == OrderStatus.delivered) {
      if (await service.orderReview(orderId) case Ok(:final value)) {
        _review = value;
      }
    }
    return result.failureOrNull;
  }

  Future<void> cancel() async {
    final current = _order;
    if (current == null || _cancelling) return;
    _cancelling = true;
    _cancelFailure = null;
    notifyListeners();
    final result = await service.cancel(current);
    _cancelling = false;
    switch (result) {
      case Ok(:final value):
        _order = value;
      case Err(:final failure):
        _cancelFailure = failure;
        await read();
    }
    notifyListeners();
  }
}

/// Centre de notifications (écran 44).
class NotificationsViewModel extends _OrdersLoadingViewModel {
  new({required OrdersService service, this.clock = DateTime.now})
    : super(service);

  final DateTime Function() clock;
  List<AppNotification> _items = const [];

  List<AppNotification> get items => _items;
  bool get ready => _config != null && !failed;
  bool get hasUnread => _items.any((n) => n.unread);

  @override
  Future<Failure?> read() async {
    final result = await service.notifications();
    if (result case Ok(:final value)) _items = value;
    return result.failureOrNull;
  }

  Future<void> readAll() async {
    await service.markRead();
    await refresh();
  }

  /// Ouvre une notification : elle est lue.
  Future<void> open(AppNotification n) async {
    if (!n.unread) return;
    await service.markRead([n.id]);
    await refresh();
  }
}

/// Réglages des notifications (écran 46).
class NotificationSettingsViewModel extends _OrdersLoadingViewModel {
  new({required OrdersService service}) : super(service);

  List<NotificationPreference> _prefs = const [];
  Failure? _saveFailure;

  List<NotificationPreference> get preferences => _prefs;
  bool get ready => _config != null && !failed;
  Failure? get saveFailure => _saveFailure;

  @override
  Future<Failure?> read() async {
    final result = await service.preferences();
    if (result case Ok(:final value)) _prefs = value;
    return result.failureOrNull;
  }

  Future<void> toggle(NotificationCategory category, {required bool on}) async {
    _saveFailure = null;
    final result = await service.setPreference(category, enabled: on);
    switch (result) {
      case Ok(:final value):
        _prefs = value;
      case Err(:final failure):
        _saveFailure = failure;
    }
    notifyListeners();
  }
}

/// Signaler un problème (écran 49).
class ReportProblemViewModel extends BaseViewModel {
  new({required this.service, required this.orderId, required this.onSent});

  final OrdersService service;
  final String orderId;
  final void Function(Dispute dispute) onSent;

  DisputeReason _reason = DisputeReason.missingItem;
  String description = '';
  bool _submitted = false;
  Failure? _failure;

  DisputeReason get reason => _reason;
  bool get descriptionValid {
    final n = description.trim().length;
    return n >= 3 && n <= 500;
  }

  bool get showErrors => _submitted;
  Failure? get failure => _failure;

  void selectReason(DisputeReason value) {
    _reason = value;
    notifyListeners();
  }

  void setDescription(String value) {
    description = value;
    notifyListeners();
  }

  Future<void> send() async {
    _submitted = true;
    _failure = null;
    notifyListeners();
    if (!descriptionValid) return;
    final result = await runBusyFuture(
      service.openDispute(
        orderId,
        reason: _reason,
        description: description.trim(),
      ),
    );
    switch (result) {
      case Ok(:final value):
        onSent(value);
      case Err(:final failure):
        _failure = failure;
        notifyListeners();
    }
  }
}

/// Mon signalement (écran 50) : fil et réponse ; relu toutes les 20 s.
class DisputeViewModel extends _OrdersLoadingViewModel {
  new({
    required OrdersService service,
    required this.orderId,
    super.refreshEvery = const Duration(seconds: 20),
  }) : super(service);

  final String orderId;
  Dispute? _dispute;
  bool _sending = false;
  Failure? _sendFailure;

  Dispute? get dispute => _dispute;
  bool get ready => _dispute != null && _config != null && !failed;
  bool get sending => _sending;
  Failure? get sendFailure => _sendFailure;

  @override
  Future<Failure?> read() async {
    final result = await service.dispute(orderId);
    switch (result) {
      case Ok(value: final d?):
        _dispute = d;
        return null;
      case Ok():
        return const NotFoundFailure('litige');
      case Err(:final failure):
        return failure;
    }
  }

  /// Envoie [body] ; `true` si envoyé (le champ peut être vidé).
  Future<bool> send(String body) async {
    final d = _dispute;
    if (d == null || body.trim().isEmpty || _sending) return false;
    _sending = true;
    _sendFailure = null;
    notifyListeners();
    final result = await service.replyDispute(d.id, body.trim());
    _sending = false;
    switch (result) {
      case Ok(:final value):
        _dispute = value;
        notifyListeners();
        return true;
      case Err(:final failure):
        _sendFailure = failure;
        notifyListeners();
        return false;
    }
  }
}
