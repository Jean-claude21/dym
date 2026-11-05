import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

/// Réponse simulée.
class FakeResponse {
  const new(this.status, [this.body, this.headers = const {}]);

  final int status;
  final Object? body;
  final Map<String, String> headers;
}

/// Coupure réseau simulée.
class NetworkDown {
  const new();
}

typedef Handler = FutureOr<Object> Function(FakeRequest request);

/// Requête reçue par le serveur simulé.
class FakeRequest {
  const new(this.method, this.uri, this.headers, this.body);

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final Object? body;

  String? get bearer {
    final value = headers.entries
        .where((e) => e.key.toLowerCase() == 'authorization')
        .map((e) => e.value)
        .firstOrNull;
    return value?.replaceFirst('Bearer ', '');
  }
}

/// Serveur simulé partagé par dio (Auth, Functions) et http (Data API).
class FakeServer {
  final _routes = <String, Handler>{};
  final requests = <FakeRequest>[];

  /// Enregistre une route `METHODE /chemin` (chemin complet de l'URL).
  void on(String method, String path, Handler handler) =>
      _routes['$method $path'] = handler;

  int count(String method, String path) =>
      requests.where((r) => r.method == method && r.uri.path == path).length;

  Future<FakeResponse> _handle(FakeRequest request) async {
    requests.add(request);
    final handler = _routes['${request.method} ${request.uri.path}'];
    if (handler == null) return const FakeResponse(404, {'message': 'route'});
    final result = await handler(request);
    if (result is NetworkDown) throw const _Down();
    return result as FakeResponse;
  }

  HttpClientAdapter get dioAdapter => _DioAdapter(this);

  http.Client get httpClient => _HttpClient(this);
}

class _Down implements Exception {
  const new();
}

class _DioAdapter implements HttpClientAdapter {
  new(this.server);

  final FakeServer server;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body = options.data;
    if (body is String) body = jsonDecode(body);
    final FakeResponse response;
    try {
      response = await server._handle(
        FakeRequest(
          options.method,
          options.uri,
          options.headers.map((k, v) => MapEntry(k, '$v')),
          body,
        ),
      );
    } on _Down {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'réseau coupé',
      );
    }
    return ResponseBody.fromString(
      response.body is String
          ? response.body! as String
          : jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [
          if (response.body is String) 'text/html' else Headers.jsonContentType,
        ],
        for (final e in response.headers.entries) e.key: [e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _HttpClient extends http.BaseClient {
  new(this.server);

  final FakeServer server;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final raw = request is http.Request ? request.body : '';
    final FakeResponse response;
    try {
      response = await server._handle(
        FakeRequest(
          request.method,
          request.url,
          request.headers,
          raw.isEmpty ? null : jsonDecode(raw),
        ),
      );
    } on _Down {
      throw http.ClientException('réseau coupé', request.url);
    }
    final text = response.body is String
        ? response.body! as String
        : jsonEncode(response.body);
    return http.StreamedResponse(
      Stream.value(utf8.encode(text)),
      response.status,
      request: request,
      headers: {
        'content-type': response.body is String
            ? 'text/html'
            : 'application/json',
        ...response.headers,
      },
    );
  }
}

/// JWT non signé (le client ne vérifie pas la signature).
String fakeJwt({required String sub, required DateTime expiresAt}) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.'
      '${part({'sub': sub, 'exp': expiresAt.millisecondsSinceEpoch ~/ 1000})}.'
      'signature';
}
