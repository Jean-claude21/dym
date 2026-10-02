import 'package:meta/meta.dart';

/// Texte multilingue venu du référentiel
/// (`{"fr": "Légumes", "en": "Vegetables"}`).
///
/// Le français est toujours présent (contrainte en base) et sert de repli.
@immutable
class LocalizedText {
  const new(this.values);

  /// Lit un objet JSON de chaînes ; les valeurs non textuelles sont ignorées.
  factory fromJson(Object? json) {
    if (json is! Map) return const LocalizedText({});
    return LocalizedText({
      for (final e in json.entries)
        if (e.value is String) '${e.key}': e.value as String,
    });
  }

  /// Langue → texte.
  final Map<String, String> values;

  /// Texte dans la langue demandée (`en`, `en_GH`…), sinon en français,
  /// sinon la première valeur disponible, sinon une chaîne vide.
  String resolve(String locale) {
    final language = locale.split(RegExp('[-_]')).first.toLowerCase();
    return values[locale] ??
        values[language] ??
        values['fr'] ??
        (values.isEmpty ? '' : values.values.first);
  }

  Map<String, String> toJson() => values;

  @override
  bool operator ==(Object other) =>
      other is LocalizedText &&
      other.values.length == values.length &&
      other.values.entries.every((e) => values[e.key] == e.value);

  @override
  int get hashCode => Object.hashAllUnordered(
    values.entries.map((e) => Object.hash(e.key, e.value)),
  );

  @override
  String toString() => 'LocalizedText(${values['fr'] ?? ''})';
}
