import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:neon_kit/neon_kit.dart';
import 'package:test/test.dart';

class _Store implements ResponseCacheStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String body) async => values[key] = body;

  @override
  Future<void> clear() async => values.clear();
}

class _Net extends http.BaseClient {
  bool online = true;
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    if (!online) throw const SocketException('hors ligne');
    return http.StreamedResponse(
      http.ByteStream.fromBytes('{"popular":[1]}'.codeUnits),
      200,
    );
  }
}

void main() {
  test('premier écran sans réseau : dernière réponse (spec 107)', () async {
    final net = _Net();
    final store = _Store();
    final client = OfflineReadCache(net, store);
    final url = Uri.parse('https://data.test/rest/v1/rpc/home_feed');
    final first = await client.post(url, body: '{"p_zone":"be"}');
    expect(first.body, '{"popular":[1]}');
    net.online = false;
    final offline = await client.post(url, body: '{"p_zone":"be"}');
    expect(offline.body, '{"popular":[1]}');
    expect(offline.headers['x-dym-cache'], '1');
    // Autre quartier, jamais lu : l'échec remonte.
    expect(
      () => client.post(url, body: '{"p_zone":"agoe"}'),
      throwsA(isA<SocketException>()),
    );
  });

  test('écritures et fonctions hors liste : jamais gardées', () async {
    final net = _Net();
    final store = _Store();
    final client = OfflineReadCache(net, store);
    await client.post(Uri.parse('https://data.test/rest/v1/rpc/place_order'));
    await client.get(Uri.parse('https://data.test/rest/v1/orders'));
    expect(store.values, isEmpty);
    await client.get(
      Uri.parse('https://data.test/rest/v1/countries?code=eq.TG'),
    );
    expect(store.values, hasLength(1));
  });
}
