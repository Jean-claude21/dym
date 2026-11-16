import 'package:dio/dio.dart';
import 'package:dym_core/dym_core.dart';
import 'package:neon_kit/src/auth/neon_auth_client.dart';
import 'package:neon_kit/src/errors.dart';

/// Appels des Neon Functions sous l'identité de l'utilisateur connecté.
///
/// Toute création porte une clé d'idempotence ([post] `idempotencyKey`) :
/// c'est elle qui autorise une nouvelle tentative sur erreur réseau ou 5xx.
class NeonFunctionsClient {
  new({required this._dio});

  final Dio _dio;

  /// `POST <slug/chemin>`.
  Future<Result<T>> post<T>(
    String path, {
    required T Function(Object? json) decode,
    Object? body,
    String? idempotencyKey,
  }) => _call(
    () => _dio.post<Object?>(
      path,
      data: body,
      options: Options(headers: {'Idempotency-Key': ?idempotencyKey}),
    ),
    decode,
    'functions:POST $path',
  );

  /// `POST` sans session (connexion) : aucun jeton n'est joint.
  Future<Result<T>> postPublic<T>(
    String path, {
    required T Function(Object? json) decode,
    Object? body,
  }) => _call(
    () => _dio.post<Object?>(
      path,
      data: body,
      options: Options(extra: {NeonAuthInterceptor.publicKey: true}),
    ),
    decode,
    'functions:POST $path',
  );

  /// `GET <slug/chemin>`.
  Future<Result<T>> get<T>(
    String path, {
    required T Function(Object? json) decode,
    Map<String, Object?>? query,
  }) => _call(
    () => _dio.get<Object?>(path, queryParameters: query),
    decode,
    'functions:GET $path',
  );

  Future<Result<T>> _call<T>(
    Future<Response<Object?>> Function() request,
    T Function(Object? json) decode,
    String where,
  ) async {
    try {
      final response = await request();
      return Ok(decode(response.data));
    } on Object catch (error, stack) {
      final failure = failureFrom(error);
      FailureReports.report(failure, where, stack);
      return Err(failure);
    }
  }
}

/// Intercepteur dio : ajoute le JWT courant, renouvelle et rejoue une fois
/// après un 401.
class NeonAuthInterceptor extends Interceptor {
  new({required this.dio, required this.auth});

  final Dio dio;
  final NeonAuthClient auth;

  static const _retriedKey = 'neon_kit.auth_retried';

  /// Requête sans session (pont de connexion) : ni jeton, ni renouvellement.
  static const publicKey = 'neon_kit.public';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[publicKey] == true) return handler.next(options);
    switch (await auth.validAccessToken()) {
      case Ok(:final value):
        options.headers['Authorization'] = 'Bearer $value';
        handler.next(options);
      case Err(:final failure):
        handler.reject(
          DioException(requestOptions: options, error: NeonAuthAbort(failure)),
        );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra[_retriedKey] == true ||
        options.extra[publicKey] == true) {
      return handler.next(err);
    }
    switch (await auth.refresh()) {
      case Ok():
        options.extra[_retriedKey] = true;
        try {
          handler.resolve(await dio.fetch<Object?>(options));
        } on DioException catch (e) {
          handler.next(e);
        }
      case Err(:final failure):
        handler.next(
          DioException(
            requestOptions: options,
            response: err.response,
            error: NeonAuthAbort(failure),
          ),
        );
    }
  }
}
