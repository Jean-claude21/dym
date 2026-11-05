import 'package:dym_core/dym_core.dart';
import 'package:http/http.dart' as http;
import 'package:neon_kit/src/auth/neon_auth_client.dart';
import 'package:neon_kit/src/config.dart';
import 'package:neon_kit/src/errors.dart';
import 'package:postgrest/postgrest.dart';

/// Data API (PostgREST) sous l'identité de l'utilisateur connecté (RLS).
///
/// Les nouvelles tentatives des lectures (GET, HEAD) sur erreur réseau ou 5xx
/// sont faites par `postgrest` ; ce client ajoute le jeton et rejoue une fois
/// après un 401.
class NeonDataClient {
  new({
    required NeonConfig config,
    required NeonAuthClient auth,
    http.Client? httpClient,
  }) : _client = PostgrestClient(
         config.dataApiUrl.toString(),
         httpClient: _AuthenticatedClient(auth, httpClient ?? http.Client()),
         retryCount: config.maxRetries,
         retryableStatusCodes: const {500, 502, 503, 504, 520},
       );

  final PostgrestClient _client;

  /// Requête sur une table ou une vue.
  PostgrestQueryBuilder<void> from(String table) => _client.from(table);

  /// Exécute une requête et convertit toute erreur en [Failure].
  Future<Result<T>> run<T>(Future<T> Function(PostgrestClient db) query) async {
    try {
      return Ok(await query(_client));
    } on Object catch (error) {
      return Err(failureFrom(error));
    }
  }

  /// Appelle une fonction SQL exposée (`/rpc/<fn>`).
  Future<Result<T>> rpc<T>(String fn, {Map<String, Object?>? params}) =>
      run((db) => db.rpc<T>(fn, params: params));
}

/// Client HTTP qui porte le JWT courant et rejoue une fois après un 401.
class _AuthenticatedClient extends http.BaseClient {
  new(this._auth, this._inner);

  final NeonAuthClient _auth;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.bodyBytes : null;
    final first = await _sendWithToken(request, body, refreshed: false);
    if (first.statusCode != 401 || body == null) return first;
    await first.stream.drain<void>();
    final refreshed = await _auth.refresh();
    if (refreshed case Err(:final failure)) throw NeonAuthAbort(failure);
    return await _sendWithToken(request, body, refreshed: true);
  }

  Future<http.StreamedResponse> _sendWithToken(
    http.BaseRequest original,
    List<int>? body, {
    required bool refreshed,
  }) async {
    final token = await _auth.validAccessToken();
    final value = switch (token) {
      Ok(:final value) => value,
      Err(:final failure) => throw NeonAuthAbort(failure),
    };
    final request = refreshed && body != null
        ? (http.Request(original.method, original.url)
            ..headers.addAll(original.headers)
            ..bodyBytes = body)
        : original;
    request.headers['Authorization'] = 'Bearer $value';
    return await _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
