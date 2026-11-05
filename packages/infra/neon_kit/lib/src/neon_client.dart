import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:neon_kit/src/auth/neon_auth_client.dart';
import 'package:neon_kit/src/config.dart';
import 'package:neon_kit/src/data/neon_data_client.dart';
import 'package:neon_kit/src/functions/neon_functions_client.dart';
import 'package:neon_kit/src/retry.dart';
import 'package:neon_kit/src/session.dart';
import 'package:neon_kit/src/storage/object_uploader.dart';

/// Point d'entrée unique vers Neon : [auth], [data] (Data API), [functions].
class NeonClient {
  /// Crée le client. [adapter], [httpClient], [clock] et [sleep] servent aux
  /// tests ; en production, les valeurs par défaut s'appliquent.
  factory({
    required NeonConfig config,
    required SessionStore sessionStore,
    HttpClientAdapter? adapter,
    http.Client? httpClient,
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
  }) {
    final policy = RetryPolicy(
      maxRetries: config.maxRetries,
      baseDelay: config.retryBaseDelay,
    );

    Dio dioFor(Uri base) {
      final dio = Dio(
        BaseOptions(
          baseUrl: base.toString(),
          connectTimeout: config.connectTimeout,
          receiveTimeout: config.receiveTimeout,
          contentType: Headers.jsonContentType,
        ),
      );
      if (adapter != null) dio.httpClientAdapter = adapter;
      return dio;
    }

    final authDio = dioFor(config.authUrl);
    authDio.interceptors.add(
      RetryInterceptor(dio: authDio, policy: policy, sleep: sleep),
    );
    final auth = NeonAuthClient(
      dio: authDio,
      config: config,
      store: sessionStore,
      clock: clock,
    );

    final functionsDio = dioFor(config.functionsUrl);
    functionsDio.interceptors.addAll([
      NeonAuthInterceptor(dio: functionsDio, auth: auth),
      RetryInterceptor(dio: functionsDio, policy: policy, sleep: sleep),
    ]);

    // Stockage d'objets : URL absolues présignées, sans jeton.
    final uploadDio = Dio(
      BaseOptions(
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
      ),
    );
    if (adapter != null) uploadDio.httpClientAdapter = adapter;
    uploadDio.interceptors.add(
      RetryInterceptor(dio: uploadDio, policy: policy, sleep: sleep),
    );

    return NeonClient._(
      auth: auth,
      data: NeonDataClient(config: config, auth: auth, httpClient: httpClient),
      functions: NeonFunctionsClient(dio: functionsDio),
      uploads: NeonObjectUploader(dio: uploadDio),
    );
  }

  new _({
    required this.auth,
    required this.data,
    required this.functions,
    required this.uploads,
  });

  /// Authentification et session.
  final NeonAuthClient auth;

  /// Data API (lectures et CRUD sous RLS).
  final NeonDataClient data;

  /// Functions (effets externes).
  final NeonFunctionsClient functions;

  /// Envoi d'objets vers des URL présignées.
  final NeonObjectUploader uploads;
}
