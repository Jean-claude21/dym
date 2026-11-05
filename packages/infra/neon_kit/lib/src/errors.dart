import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dym_core/dym_core.dart';
import 'package:http/http.dart' as http;
import 'package:postgrest/postgrest.dart';

/// Interruption d'une requête faute de session valide. Volontairement une
/// [Error] (et non une `Exception`) : le client Data API ne la retente pas.
final class NeonAuthAbort extends Error {
  new(this.failure);

  final Failure failure;
}

/// Échec correspondant à un statut HTTP et au corps d'erreur normalisé des
/// Functions (`{error: {code, message, fields}}`).
Failure failureFromStatus(int status, Object? body) {
  final error = _errorBody(body);
  final message = error.$1 ?? 'HTTP $status';
  return switch (status) {
    400 || 422 => ValidationFailure(message, fields: error.$2),
    401 => UnauthenticatedFailure(message),
    403 => ForbiddenFailure(message),
    404 => NotFoundFailure(message),
    409 => ConflictFailure(message),
    429 => RateLimitedFailure(message),
    >= 500 => ServerFailure(message, statusCode: status),
    _ => UnknownFailure(message),
  };
}

(String?, Map<String, String>) _errorBody(Object? body) {
  var json = body;
  if (json is String) {
    try {
      json = jsonDecode(json);
    } on FormatException {
      return (null, const {});
    }
  }
  if (json is! Map) return (null, const {});
  final error = json['error'];
  if (error is! Map) {
    final message = json['message'];
    return (message is String ? message : null, const {});
  }
  final message = error['message'];
  final fields = error['fields'];
  return (
    message is String ? message : null,
    fields is Map
        ? {for (final e in fields.entries) '${e.key}': '${e.value}'}
        : const {},
  );
}

/// Échec correspondant à une erreur dio.
Failure failureFromDio(DioException error) {
  final inner = error.error;
  if (inner is NeonAuthAbort) return inner.failure;
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure('réseau indisponible ou trop lent');
    case DioExceptionType.badResponse:
      final response = error.response!;
      return failureFromStatus(response.statusCode ?? 0, response.data);
    case DioExceptionType.cancel:
      return const UnknownFailure('requête annulée');
    case DioExceptionType.badCertificate:
      return const NetworkFailure('certificat refusé');
    case DioExceptionType.unknown:
      if (inner is http.ClientException) {
        return const NetworkFailure('réseau indisponible');
      }
      if (inner is FormatException) {
        return const ServerFailure('réponse illisible');
      }
      return UnknownFailure(inner?.runtimeType.toString() ?? 'erreur inconnue');
  }
}

/// Échec correspondant à une erreur PostgREST (Data API).
Failure failureFromPostgrest(PostgrestException error) {
  final code = error.code ?? '';
  final message = error.message.length > 300
      ? '${error.message.substring(0, 300)}…'
      : error.message;
  return switch (code) {
    '23505' || '409' => ConflictFailure(message),
    '42501' || '403' => ForbiddenFailure(message),
    'PGRST116' || '404' || '406' => NotFoundFailure(message),
    'PGRST301' ||
    'PGRST302' ||
    'PGRST303' ||
    '401' => UnauthenticatedFailure(message),
    'P0001' ||
    '22023' ||
    '23514' ||
    '23502' ||
    '22P02' ||
    '400' ||
    '422' => ValidationFailure(message),
    '429' => RateLimitedFailure(message),
    _ when code.startsWith('5') && code.length == 3 => ServerFailure(
      message,
      statusCode: int.tryParse(code),
    ),
    _ when code.length == 3 && int.tryParse(code) != null =>
      int.parse(code) >= 200 && int.parse(code) < 300
          ? const ServerFailure('réponse illisible')
          : UnknownFailure(message),
    _ => UnknownFailure(message),
  };
}

/// Convertit toute erreur levée pendant une opération en [Failure].
Failure failureFrom(Object error) => switch (error) {
  NeonAuthAbort(:final failure) => failure,
  DioException() => failureFromDio(error),
  PostgrestException() => failureFromPostgrest(error),
  TimeoutException() ||
  http.ClientException() => const NetworkFailure('réseau indisponible'),
  FormatException() => const ServerFailure('réponse illisible'),
  _ => UnknownFailure(error.runtimeType.toString()),
};
