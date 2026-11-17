import 'dart:convert';

import 'package:http/http.dart' as http;

/// Stockage des réponses gardées (fichiers sur l'appareil en production).
abstract interface class ResponseCacheStore {
  Future<String?> read(String key);
  Future<void> write(String key, String body);
  Future<void> clear();
}

/// Lectures du premier écran gardées sur l'appareil (spec 107) : référentiel
/// du pays, boutiques, accueil, fil. Réseau d'abord ; sans réseau, la
/// dernière réponse est rendue telle quelle. Jamais d'écriture en cache.
class OfflineReadCache extends http.BaseClient {
  new(this._inner, this._store, {bool Function(http.BaseRequest)? cacheable})
    : _cacheable = cacheable ?? defaultCacheable;

  final http.Client _inner;
  final ResponseCacheStore _store;
  final bool Function(http.BaseRequest) _cacheable;

  /// Tables du référentiel (lecture) et fonctions du premier écran.
  static const tables = {
    'countries',
    'cities',
    'zones',
    'categories',
    'units',
    'store_origins',
    'payment_methods',
    'feature_flags',
    'delivery_fee_defaults',
  };
  static const functions = {
    'home_feed',
    'discover_stores',
    'content_feed_ranked',
    'stories_feed',
  };

  static bool defaultCacheable(http.BaseRequest request) {
    final segments = request.url.pathSegments;
    if (segments.isEmpty) return false;
    final last = segments.last;
    final isRpc =
        segments.length >= 2 && segments[segments.length - 2] == 'rpc';
    if (isRpc) return request.method == 'POST' && functions.contains(last);
    return request.method == 'GET' && tables.contains(last);
  }

  /// Clé courte et stable (FNV-1a sur deux graines) : nom de fichier sûr.
  static String _key(http.BaseRequest request, List<int>? body) {
    final bytes = [
      ...utf8.encode('${request.method} ${request.url} '),
      ...?body,
    ];
    String fnv(int seed) {
      var h = seed;
      for (final b in bytes) {
        h = ((h ^ b) * 0x01000193) & 0xffffffff;
      }
      return h.toRadixString(16).padLeft(8, '0');
    }

    return 'data_${fnv(0x811c9dc5)}${fnv(0x01234567)}';
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_cacheable(request)) return await _inner.send(request);
    final body = request is http.Request ? request.bodyBytes : null;
    final key = _key(request, body);
    try {
      final response = await _inner.send(request);
      if (response.statusCode != 200) return response;
      final bytes = await response.stream.toBytes();
      await _store.write(key, utf8.decode(bytes, allowMalformed: true));
      return http.StreamedResponse(
        http.ByteStream.fromBytes(bytes),
        response.statusCode,
        headers: response.headers,
        request: response.request,
        reasonPhrase: response.reasonPhrase,
        contentLength: bytes.length,
      );
    } on Object {
      final cached = await _store.read(key);
      if (cached == null) rethrow;
      final bytes = utf8.encode(cached);
      return http.StreamedResponse(
        http.ByteStream.fromBytes(bytes),
        200,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'x-dym-cache': '1',
        },
        request: request,
        contentLength: bytes.length,
      );
    }
  }
}
