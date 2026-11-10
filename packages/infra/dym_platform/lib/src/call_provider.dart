import 'dart:async';

import 'package:dym_core/dym_core.dart';

/// Fournisseur média d'un appel (spec 035). La base tient l'état de l'appel ;
/// le fournisseur transporte la voix et l'image. Le vrai (WebRTC, serveur
/// TURN) remplace la simulation avant la production finale (décision 0015).
abstract interface class CallProvider {
  /// `true` : aucun média réel ne circule (affiché à l'écran).
  bool get simulated;

  /// Rejoint le canal média de l'appel décroché.
  Future<Result<void>> join(String callId, {required bool video});

  Future<void> leave();
}

/// Simulation : l'appel « se connecte » sans média réel.
class SimulatedCallProvider implements CallProvider {
  const new();

  @override
  bool get simulated => true;

  @override
  Future<Result<void>> join(String callId, {required bool video}) async =>
      const Ok(null);

  @override
  Future<void> leave() async {}
}
