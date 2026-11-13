import 'dart:async';

/// Signal temps réel (spec 067) : un changement qui concerne la personne
/// connectée, ou une (re)connexion après laquelle tout écran se recharge.
class LiveSignal {
  /// Événement adressé à la personne.
  const new event({required this.kind, this.entityId, this.payload = const {}})
    : resync = false;

  /// Connexion (re)établie : des événements ont pu manquer.
  const new resync()
    : kind = '',
      entityId = null,
      payload = const {},
      resync = true;

  /// `message`, `order_status` ou `notification`.
  final String kind;

  /// Conversation, commande ou achat concerné.
  final String? entityId;

  /// Détails courts (statut, type de notification…).
  final Map<String, Object?> payload;

  /// Vrai pour un signal de reconnexion.
  final bool resync;

  /// Type de notification (`new_order`, `mission_available`…), si c'en est une.
  String? get notificationKind =>
      kind == 'notification' ? payload['kind'] as String? : null;
}

/// Source de signaux temps réel ; une app sans connexion en direct passe
/// [LiveFeed.none].
abstract interface class LiveFeed {
  /// Aucun signal (tests, apps sans temps réel).
  static const LiveFeed none = _NoLive();

  Stream<LiveSignal> get signals;
}

class _NoLive implements LiveFeed {
  const new();

  @override
  Stream<LiveSignal> get signals => const Stream.empty();
}

/// Recharge [reload] quand un signal correspond à [when] (et à chaque
/// reconnexion), au plus une fois par [debounce] : plusieurs événements
/// d'une même transaction déclenchent un seul rechargement.
StreamSubscription<LiveSignal> watchLive(
  Stream<LiveSignal> signals, {
  required bool Function(LiveSignal signal) when,
  required void Function() reload,
  Duration debounce = const Duration(milliseconds: 300),
}) {
  Timer? pending;
  return signals.listen((signal) {
    if (!signal.resync && !when(signal)) return;
    pending?.cancel();
    pending = Timer(debounce, reload);
  })..onDone(() => pending?.cancel());
}
