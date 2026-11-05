import 'package:dym_core/dym_core.dart';
import 'package:json_annotation/json_annotation.dart';

/// Libellé multilingue (`jsonb` en base).
class LocalizedTextConverter implements JsonConverter<LocalizedText, Object?> {
  const new();

  @override
  LocalizedText fromJson(Object? json) => LocalizedText.fromJson(json);

  @override
  Object? toJson(LocalizedText object) => object.toJson();
}

/// Libellé multilingue facultatif.
class NullableLocalizedTextConverter
    implements JsonConverter<LocalizedText?, Object?> {
  const new();

  @override
  LocalizedText? fromJson(Object? json) =>
      json == null ? null : LocalizedText.fromJson(json);

  @override
  Object? toJson(LocalizedText? object) => object?.toJson();
}

/// Montant en unités mineures : PostgREST renvoie un `bigint` en nombre (ou en
/// chaîne au-delà de 2^53, impossible ici).
int minorFromJson(Object? json) => switch (json) {
  final int value => value,
  final String value => int.parse(value),
  _ => throw FormatException('montant invalide : $json'),
};

int? nullableMinorFromJson(Object? json) =>
    json == null ? null : minorFromJson(json);
