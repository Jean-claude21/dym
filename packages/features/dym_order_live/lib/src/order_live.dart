import 'dart:async';
import 'dart:math' as math;

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:stacked/stacked.dart';

/// Données d'une livraison en direct (spec 109) : suivi et itinéraire.
abstract interface class OrderLiveService {
  Future<Result<LiveTracking>> tracking(String orderId);

  /// Itinéraire passant par [points] ; échec : l'écran trace une ligne droite.
  Future<Result<DeliveryRoute>> route(List<TrackPoint> points);
}

class NeonOrderLiveService implements OrderLiveService {
  new(this._delivery, this._routes);

  final DeliveryRepository _delivery;
  final RouteRepository _routes;

  @override
  Future<Result<LiveTracking>> tracking(String orderId) =>
      _delivery.tracking(orderId);

  @override
  Future<Result<DeliveryRoute>> route(List<TrackPoint> points) =>
      _routes.route(points);
}

/// Étape visible de la livraison.
enum LivePhase {
  /// Pas encore de livreur.
  waiting,

  /// Le livreur va chercher la commande à la boutique.
  toStore,

  /// Commande récupérée : en route vers la porte.
  toDoor,

  /// Remise confirmée par le code.
  delivered,
}

/// Distance en mètres (haversine), pour savoir si le livreur a bougé.
double distanceM(TrackPoint a, TrackPoint b) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// Suivi en direct pour la cliente, la vendeuse et le livreur : relu toutes
/// les [every] tant que la livraison n'est pas finie ; itinéraire recalculé
/// quand l'étape change ou que le livreur a bougé de plus de 150 m.
class OrderLiveViewModel extends BaseViewModel {
  new({
    required this.service,
    required this.orderId,
    this.every = const Duration(seconds: 10),
  });

  final OrderLiveService service;
  final String orderId;
  final Duration every;

  LiveTracking? tracking;
  DeliveryRoute? route;
  Failure? failure;
  Timer? _timer;
  LivePhase? _routedPhase;
  TrackPoint? _routedFrom;

  LivePhase get phase {
    final t = tracking;
    if (t == null || t.courier == null) return LivePhase.waiting;
    return switch (t.status) {
      'delivered' => LivePhase.delivered,
      'out_for_delivery' => LivePhase.toDoor,
      _ => LivePhase.toStore,
    };
  }

  /// Minutes restantes, seulement pendant la course.
  int? get etaMinutes => switch (phase) {
    LivePhase.toStore || LivePhase.toDoor => tracking?.etaMinutes,
    _ => null,
  };

  Future<void> start() async {
    await refresh();
    if (phase != LivePhase.delivered) {
      _timer ??= Timer.periodic(every, (_) => unawaited(refresh()));
    }
  }

  Future<void> refresh() async {
    switch (await service.tracking(orderId)) {
      case Ok(:final value):
        tracking = value;
        failure = null;
      case Err(failure: final f):
        failure = f;
        notifyListeners();
        return;
    }
    if (phase == LivePhase.delivered) {
      _timer?.cancel();
      _timer = null;
    }
    notifyListeners();
    await _updateRoute();
  }

  /// Points de l'itinéraire selon l'étape.
  List<TrackPoint> get waypoints {
    final t = tracking;
    if (t == null) return const [];
    final courier = t.courier?.position;
    return switch (phase) {
      LivePhase.toDoor => [?courier, ?t.destination],
      LivePhase.toStore => [?courier, ?t.store, ?t.destination],
      LivePhase.waiting => [?t.store, ?t.destination],
      LivePhase.delivered => const [],
    };
  }

  Future<void> _updateRoute() async {
    final points = waypoints;
    if (points.length < 2) {
      route = null;
      notifyListeners();
      return;
    }
    final from = points.first;
    final moved = _routedFrom == null || distanceM(_routedFrom!, from) > 150;
    if (_routedPhase == phase && !moved && route != null) return;
    _routedPhase = phase;
    _routedFrom = from;
    switch (await service.route(points)) {
      case Ok(:final value) when value.points.length >= 2:
        route = value;
      case Ok() || Err():
        // Itinéraire indisponible : ligne droite, en pointillés.
        route = DeliveryRoute(points: points, approximate: true);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
