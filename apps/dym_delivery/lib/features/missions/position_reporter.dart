import 'dart:async';

import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/foundation.dart';

/// Envoie la position du livreur pendant une course en route (spec 044).
/// Sans GPS, une position simulée approche de la cliente ; l'écran et la
/// cliente en sont prévenus (décision 0015).
class PositionReporter {
  new({
    required this._service,
    required this._location,
    this.every = const Duration(seconds: 20),
  });

  final MissionsService _service;
  final LocationProvider _location;
  final Duration every;

  /// Vrai quand la dernière position envoyée était simulée.
  final simulated = ValueNotifier<bool>(false);

  Timer? _timer;
  String? _orderId;
  double _offset = _startOffset;

  /// Écart de départ en degrés de latitude (environ 1,5 km).
  static const _startOffset = 0.015;

  void start() {
    _timer ??= Timer.periodic(every, (_) => unawaited(tick()));
    unawaited(tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> tick() async {
    final runs = (await _service.mine()).valueOrNull ?? const [];
    final run = runs.where((m) => m.status == 'out_for_delivery').firstOrNull;
    if (run == null) {
      _orderId = null;
      simulated.value = false;
      return;
    }
    final real = (await _location.current()).valueOrNull;
    if (real != null) {
      simulated.value = false;
      await _service.reportPosition(
        real.latitude,
        real.longitude,
        simulated: false,
      );
      return;
    }
    final latitude = run.customer.latitude;
    final longitude = run.customer.longitude;
    if (latitude == null || longitude == null) return;
    if (_orderId != run.orderId) {
      _orderId = run.orderId;
      _offset = _startOffset;
    } else {
      _offset *= 0.8;
    }
    simulated.value = true;
    await _service.reportPosition(
      latitude + _offset,
      longitude,
      simulated: true,
    );
  }
}
