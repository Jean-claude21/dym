import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:stacked/stacked.dart';

/// Base : chargement, échec, hors ligne ; devise du pays.
abstract class _OrdersLoadingViewModel extends BaseViewModel {
  new(this.service);

  final OrdersService service;
  Failure? _failure;
  CountryConfig? _config;

  Failure? get failure => _failure;
  bool get failed => _failure != null;
  CountryConfig? get config => _config;

  Money? money(int minor) => _config?.money(minor);

  Future<void> load();

  Future<void> run(Future<Failure?> Function() work) async {
    _failure = null;
    setBusy(true);
    final config = await service.countryConfig();
    switch (config) {
      case Err(:final failure):
        _failure = failure;
      case Ok(:final value):
        _config = value;
        _failure = await work();
    }
    setBusy(false);
  }
}

/// Commandes (écran 41), rafraîchies toutes les [refreshEvery] : une commande
/// payée apparaît sans geste.
class OrdersViewModel extends _OrdersLoadingViewModel {
  new({
    required OrdersService service,
    this.refreshEvery = const Duration(seconds: 20),
  }) : super(service);

  final Duration refreshEvery;
  List<VendorOrder> _orders = const [];
  Timer? _timer;
  bool _offline = false;

  List<VendorOrder> get orders => _orders;
  bool get ready => _config != null && !failed;

  /// Dernière relecture automatique hors ligne (la liste reste affichée).
  bool get offline => _offline;

  @override
  Future<void> load() async {
    await run(() async {
      final result = await service.orders();
      _orders = result.valueOrNull ?? const [];
      return result.failureOrNull;
    });
    _timer ??= Timer.periodic(refreshEvery, (_) => unawaited(refresh()));
  }

  /// Relecture silencieuse (sans état de chargement).
  Future<void> refresh() async {
    final result = await service.orders();
    switch (result) {
      case Ok(:final value):
        _orders = value;
        _offline = false;
      case Err(:final failure):
        _offline = failure is NetworkFailure;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Détail d'une commande et de son paiement (écran 42).
class OrderDetailViewModel extends _OrdersLoadingViewModel {
  new({required OrdersService service, required this.orderId}) : super(service);

  final String orderId;
  VendorOrder? _order;

  VendorOrder? get order => _order;
  bool get ready => _order != null && _config != null && !failed;

  @override
  Future<void> load() => run(() async {
    final result = await service.order(orderId);
    _order = result.valueOrNull;
    return result.failureOrNull;
  });
}
