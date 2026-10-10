import 'dart:convert';
import 'dart:typed_data';

import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Recherche augmentée (spec 018) : historique et suggestions par la Data
/// API ; voix et photo par la Function (flag `ai_search`, modèles en base).
class SearchAiRepository {
  new({required this._data, required this._functions});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;

  /// Dernières recherches de la personne connectée.
  Future<Result<List<SearchHistoryEntry>>> history({int limit = 8}) async {
    final result = await _data.rpc<Object?>(
      'my_searches',
      params: {'p_limit': limit},
    );
    return result.map(
      (json) => [
        for (final e in json! as List)
          SearchHistoryEntry.fromJson(e as Map<String, dynamic>),
      ],
    );
  }

  /// Retient une recherche validée (touche Rechercher, voix, photo, produit
  /// ouvert).
  Future<Result<void>> remember(String query, SearchSource source) async =>
      (await _data.rpc<Object?>(
        'remember_search',
        params: {'p_query': query, 'p_source': source.name},
      )).map((_) {});

  Future<Result<void>> forget() async =>
      (await _data.rpc<Object?>('forget_searches')).map((_) {});

  /// Complétions pendant la saisie (visiteuse comprise).
  Future<Result<List<SearchSuggestion>>> suggestions(
    String prefix, {
    String? zoneId,
  }) async {
    final result = await _data.rpc<Object?>(
      'search_suggestions',
      params: {'p_prefix': prefix, 'p_zone': zoneId},
    );
    return result.map(
      (json) => [
        for (final s in json! as List)
          SearchSuggestion.fromJson(s as Map<String, dynamic>),
      ],
    );
  }

  /// Message vocal → texte de recherche (`Ok(null)` : rien compris).
  /// Refus `feature_disabled` si la fonction est coupée pour le pays.
  Future<Result<String?>> transcribe(Uint8List audio, String mediaType) =>
      _functions.post(
        '/v1/search/voice',
        body: {'audio': base64Encode(audio), 'media_type': mediaType},
        decode: _query,
      );

  /// Photo → texte de recherche (`Ok(null)` : rien de reconnaissable).
  Future<Result<String?>> describePhoto(Uint8List image, String mediaType) =>
      _functions.post(
        '/v1/search/photo',
        body: {'image': base64Encode(image), 'media_type': mediaType},
        decode: _query,
      );

  static String? _query(Object? json) =>
      (json! as Map<String, dynamic>)['query'] as String?;
}
