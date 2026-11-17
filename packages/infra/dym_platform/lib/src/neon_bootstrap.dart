import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_platform/src/local_store.dart';
import 'package:dym_platform/src/secure_session_store.dart';
import 'package:neon_kit/neon_kit.dart';

/// Client Neon de l'app pour l'environnement compilé, avec la session dans le
/// stockage sécurisé de l'appareil et les lectures du premier écran gardées
/// sur l'appareil (spec 107), effacées à la déconnexion.
NeonClient createNeonClient(
  DymEnvironment environment, {
  SessionStore? sessionStore,
  ResponseCacheStore? offlineCache,
}) {
  final cache = offlineCache ?? FileResponseCache();
  final client = NeonClient(
    config: NeonConfig(
      authUrl: environment.authUrl,
      dataApiUrl: environment.dataApiUrl,
      functionsUrl: environment.functionsUrl,
    ),
    sessionStore: sessionStore ?? SecureSessionStore(),
    offlineCache: cache,
  );
  // Déconnexion : rien de la personne précédente ne reste sur l'appareil.
  client.auth.sessionChanges.listen((session) {
    if (session == null) unawaited(cache.clear());
  });
  return client;
}

/// Réponses gardées dans des fichiers de l'app (une par lecture).
class FileResponseCache implements ResponseCacheStore {
  new({LocalJsonStore? store}) : _store = store ?? FileJsonStore();

  final LocalJsonStore _store;
  final _keys = <String>{};

  @override
  Future<String?> read(String key) async => switch (await _store.read(key)) {
    final String body => body,
    _ => null,
  };

  bool _indexed = false;

  @override
  Future<void> write(String key, String body) async {
    // Index relu une fois : les lectures des sessions précédentes restent
    // connues, donc effaçables.
    if (!_indexed) {
      _indexed = true;
      final index = await _store.read('data_index');
      if (index is List) _keys.addAll(index.whereType<String>());
    }
    _keys.add(key);
    await _store.write(key, body);
    await _store.write('data_index', _keys.toList());
  }

  @override
  Future<void> clear() async {
    final index = await _store.read('data_index');
    for (final key in {
      ..._keys,
      if (index is List) ...index.whereType<String>(),
    }) {
      await _store.delete(key);
    }
    _keys.clear();
    await _store.delete('data_index');
  }
}
