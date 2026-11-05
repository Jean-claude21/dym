import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dym_core/dym_core.dart';
import 'package:neon_kit/src/errors.dart';

/// Envoi direct d'un objet vers une URL présignée (stockage d'objets), sans
/// jeton : la signature de l'URL fait foi. `PUT` est idempotent : nouvelle
/// tentative sur erreur réseau ou 5xx.
class NeonObjectUploader {
  new({required this._dio});

  final Dio _dio;

  Future<Result<void>> put(
    Uri url,
    List<int> bytes, {
    required String contentType,
  }) async {
    try {
      await _dio.putUri<void>(
        url,
        // Octets bruts (rejouables, contrairement à un flux).
        data: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        options: Options(headers: {Headers.contentTypeHeader: contentType}),
      );
      return const Ok(null);
    } on Object catch (error) {
      return Err(failureFrom(error));
    }
  }
}
