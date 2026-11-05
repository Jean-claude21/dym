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
  bool _cancelling = false;
  Failure? _cancelFailure;

  CustomerOrder? get order => _order;
  bool get ready => _order != null && _config != null && !failed;
  bool get cancelling => _cancelling;
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
