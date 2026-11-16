import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:stacked/stacked.dart';

/// Base : chargement, échec, hors ligne ; devise du pays.
abstract class _OrdersLoadingViewModel extends BaseViewModel {
  new(this.service);

  final OrdersService service;

  /// Heure courante (compte à rebours de réponse, spec 075) ; fixée en test.
  DateTime Function() clock = DateTime.now;
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

/// Commandes (écran 41) : onglets nouvelles, en cours, terminées ; relues
/// toutes les [refreshEvery] ; une nouvelle commande déclenche [onArrival]
/// (son et vibration dans la vue).
class OrdersViewModel extends _OrdersLoadingViewModel {
  new({
    required OrdersService service,
    this.refreshEvery = const Duration(seconds: 60),
  }) : super(service);

  /// Relecture en filet ; le temps réel (spec 067) prévient d'abord.
  final Duration refreshEvery;
  StreamSubscription<LiveSignal>? _live;
  VendorOrderScope _scope = VendorOrderScope.newOrders;
  List<VendorOrder> _all = const [];
  Set<String>? _seenNew;
  Timer? _timer;
  bool _offline = false;

  /// Appelé à l'arrivée d'une nouvelle commande en attente.
  void Function()? onArrival;

  VendorOrderScope get scope => _scope;
  bool get ready => _config != null && !failed;
  bool get offline => _offline;

  int get newCount => _all.where((o) => o.status == OrderStatus.pending).length;

  List<VendorOrder> get orders => _all.where(_inScope).toList();

  bool _inScope(VendorOrder o) => switch (_scope) {
    VendorOrderScope.newOrders => o.status == OrderStatus.pending,
    VendorOrderScope.active =>
      o.status.isActive && o.status != OrderStatus.pending,
    VendorOrderScope.done => !o.status.isActive,
  };

  @override
  Future<void> load() async {
    await run(() async {
      final result = await service.orders();
      if (result case Ok(:final value)) _apply(value);
      return result.failureOrNull;
    });
    _timer ??= Timer.periodic(refreshEvery, (_) => unawaited(refresh()));
    _live ??= watchLive(
      service.live,
      when: (s) => s.kind == 'order_status' || s.kind == 'notification',
      reload: () => unawaited(refresh()),
    );
  }

  void _apply(List<VendorOrder> value) {
    _all = value;
    final pending = {
      for (final o in value)
        if (o.status == OrderStatus.pending) o.id,
    };
    final seen = _seenNew;
    if (seen != null && pending.difference(seen).isNotEmpty) onArrival?.call();
    _seenNew = {...?seen, ...pending};
  }

  void selectScope(VendorOrderScope scope) {
    _scope = scope;
    notifyListeners();
  }

  /// Relecture silencieuse (sans état de chargement).
  Future<void> refresh() async {
    final result = await service.orders();
    switch (result) {
      case Ok(:final value):
        _apply(value);
        _offline = false;
      case Err(:final failure):
        _offline = failure is NetworkFailure;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_live?.cancel());
    super.dispose();
  }
}

/// Détail d'une commande (écrans 08 et 42) : accepter, refuser (45), étapes,
/// encaissement.
class OrderDetailViewModel extends _OrdersLoadingViewModel {
  new({
    required OrdersService service,
    required this.orderId,
    this.refreshEvery = const Duration(seconds: 60),
  }) : super(service);

  final String orderId;
  StreamSubscription<LiveSignal>? _live;

  /// Relecture silencieuse : le livreur ou la cliente font avancer la
  /// commande pendant que la fiche est ouverte.
  final Duration refreshEvery;
  Timer? _timer;
  VendorOrder? _order;
  Dispute? _dispute;
  bool _acting = false;
  Failure? _actionFailure;

  VendorOrder? get order => _order;

  /// Litige de la commande (bandeau 51), s'il y en a un.
  Dispute? get dispute => _dispute;
  bool get ready => _order != null && _config != null && !failed;
  bool get acting => _acting;
  Failure? get actionFailure => _actionFailure;

  bool get statusChanged => switch (_actionFailure) {
    ValidationFailure(message: 'status_changed') => true,
    _ => false,
  };

  /// Prochaine étape « en avant » (hors refus).
  OrderStatus? get nextStep =>
      _order?.nextStatuses.where((s) => s != OrderStatus.refused).firstOrNull;

  bool get canRefuse =>
      _order?.nextStatuses.contains(OrderStatus.refused) ?? false;

  @override
  Future<void> load() async {
    await run(() async {
      final result = await service.order(orderId);
      _order = result.valueOrNull;
      if (await service.dispute(orderId) case Ok(:final value)) {
        _dispute = value;
      }
      return result.failureOrNull;
    });
    _timer ??= Timer.periodic(refreshEvery, (_) => unawaited(refresh()));
    _live ??= watchLive(
      service.live,
      when: (s) => s.entityId == orderId,
      reload: () => unawaited(refresh()),
    );
  }

  /// Relecture sans état de chargement ; jamais pendant un geste.
  Future<void> refresh() async {
    if (_acting) return;
    if (await service.order(orderId) case Ok(:final value) when !_acting) {
      _order = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_live?.cancel());
    super.dispose();
  }

  /// Réponse à la cliente (51) ; `true` si envoyée.
  Future<bool> replyDispute(String body) async {
    final d = _dispute;
    if (d == null || body.trim().isEmpty || _acting) return false;
    _acting = true;
    _actionFailure = null;
    notifyListeners();
    final result = await service.replyDispute(d.id, body.trim());
    _acting = false;
    switch (result) {
      case Ok(:final value):
        _dispute = value;
        notifyListeners();
        return true;
      case Err(:final failure):
        _actionFailure = failure;
        notifyListeners();
        return false;
    }
  }

  Future<void> advance(OrderStatus to) => _act((o) => service.advance(o, to));

  /// Récupération par le livreur DYM : la vendeuse scanne son code (spec 096).
  bool get awaitsPickupScan {
    final o = _order;
    return o != null &&
        o.status == OrderStatus.ready &&
        o.fulfillment == Fulfillment.delivery &&
        (o.courier?.isDym ?? false);
  }

  /// Livraison sans livreur : la vendeuse peut la confier à un des siens.
  bool get canAssignCourier {
    final o = _order;
    return o != null &&
        o.fulfillment == Fulfillment.delivery &&
        o.courier == null &&
        (o.status == OrderStatus.accepted ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.ready);
  }

  /// Vrai si le code est bon (la commande est partie) ; sinon essais restants.
  Future<CodeCheck?> confirmPickup(String code) async {
    if (_acting) return null;
    _acting = true;
    _actionFailure = null;
    notifyListeners();
    final result = await service.confirmPickup(orderId, code);
    _acting = false;
    if (result case Err(:final failure)) _actionFailure = failure;
    await refresh();
    notifyListeners();
    return result.valueOrNull;
  }

  Future<List<StoreCourierInfo>> couriers() async =>
      (await service.storeCouriers()).valueOrNull ?? const [];

  Future<bool> assignCourier(String courierId) async {
    if (_acting) return false;
    _acting = true;
    _actionFailure = null;
    notifyListeners();
    final result = await service.assignCourier(orderId, courierId);
    _acting = false;
    if (result case Err(:final failure)) _actionFailure = failure;
    await refresh();
    notifyListeners();
    return result.isOk;
  }

  Future<void> refuse(RefusalReason reason, String? note) => _act(
    (o) => service.advance(o, OrderStatus.refused, reason: reason, note: note),
  );

  Future<void> confirmCash() => _act(service.confirmCash);

  Future<void> _act(
    Future<Result<VendorOrder>> Function(VendorOrder order) gesture,
  ) async {
    final current = _order;
    if (current == null || _acting) return;
    _acting = true;
    _actionFailure = null;
    notifyListeners();
    final result = await gesture(current);
    switch (result) {
      case Ok(:final value):
        _order = value;
      case Err(:final failure):
        _actionFailure = failure;
        final fresh = await service.order(orderId);
        if (fresh case Ok(:final value)) _order = value;
    }
    _acting = false;
    notifyListeners();
  }
}
