import 'dart:math' as math;

import 'package:dio/dio.dart';

/// Politique de nouvelle tentative (constitution VII) : erreur réseau ou 5xx
/// seulement, jamais sur 4xx, et seulement pour une requête idempotente.
class RetryPolicy {
  new({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 300),
    math.Random? random,
  }) : _random = random ?? math.Random();

  final int maxRetries;
  final Duration baseDelay;
  final math.Random _random;

  static const _idempotentMethods = {'GET', 'HEAD', 'PUT', 'DELETE', 'OPTIONS'};

  /// Vrai si la requête peut être rejouée sans effet de bord en double.
  static bool isIdempotent(RequestOptions options) =>
      _idempotentMethods.contains(options.method.toUpperCase()) ||
      options.headers.keys.any((k) => k.toLowerCase() == 'idempotency-key');

  /// Vrai si l'erreur justifie une nouvelle tentative.
  static bool isRetryable(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    DioExceptionType.badResponse => (error.response?.statusCode ?? 0) >= 500,
    _ => false,
  };

  bool shouldRetry(DioException error, int attempt) =>
      attempt < maxRetries &&
      isIdempotent(error.requestOptions) &&
      isRetryable(error);

  /// Délai avant la tentative n° [attempt] (0 = première nouvelle tentative) :
  /// `base × 2^attempt`, plus un aléa de 0 à 25 %.
  Duration delay(int attempt) {
    final ms = baseDelay.inMilliseconds * math.pow(2, attempt);
    return Duration(
      milliseconds: (ms * (1 + _random.nextDouble() / 4)).round(),
    );
  }
}

/// Intercepteur dio appliquant [RetryPolicy].
class RetryInterceptor extends Interceptor {
  new({
    required this.dio,
    required this.policy,
    Future<void> Function(Duration)? sleep,
  }) : _sleep = sleep ?? Future<void>.delayed;

  final Dio dio;
  final RetryPolicy policy;
  final Future<void> Function(Duration) _sleep;

  static const _attemptKey = 'neon_kit.attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    if (!policy.shouldRetry(err, attempt)) return handler.next(err);
    await _sleep(policy.delay(attempt));
    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await dio.fetch<Object?>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
