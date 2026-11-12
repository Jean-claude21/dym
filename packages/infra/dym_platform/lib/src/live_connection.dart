import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:flutter/widgets.dart';
import 'package:neon_kit/neon_kit.dart';

/// Connexion temps réel pilotée par l'écoute et le cycle de vie (spec 067).
///
/// - ouverte tant qu'au moins un écran écoute [signals] ;
/// - fermée en arrière-plan (le push prend le relais), rouverte au retour ;
/// - aucune connexion sans écran qui écoute : rien ne reste ouvert pour rien.
class LiveConnection implements LiveFeed {
  new(this._client) {
    _controller = StreamController<LiveSignal>.broadcast(
      onListen: _sync,
      onCancel: _sync,
    );
  }

  final NeonLiveClient _client;
  late final StreamController<LiveSignal> _controller;
  StreamSubscription<LiveSignal>? _forward;
  AppLifecycleListener? _life;
  bool _foreground = true;

  @override
  Stream<LiveSignal> get signals => _controller.stream;

  /// Suit le premier plan (à appeler une fois l'app lancée).
  void attach() {
    _life ??= AppLifecycleListener(
      onResume: () {
        _foreground = true;
        _sync();
      },
      onHide: () {
        _foreground = false;
        _sync();
      },
    );
  }

  void _sync() {
    final wanted = _foreground && _controller.hasListener;
    if (wanted) {
      _forward ??= _client.signals.listen(_controller.add);
      _client.start();
    } else {
      unawaited(_client.stop());
    }
  }

  Future<void> dispose() async {
    _life?.dispose();
    await _forward?.cancel();
    await _client.stop();
    await _controller.close();
  }
}
