import 'package:dym_core/dym_core.dart';
import 'package:meta/meta.dart';

/// Origine d'une recherche retenue (spec 018).
enum SearchSource {
  text,
  voice,
  photo;

  static SearchSource fromCode(String? code) =>
      values.where((s) => s.name == code).firstOrNull ?? text;
}

/// Recherche récente de la personne connectée (C-SEARCH-07).
@immutable
class SearchHistoryEntry {
  const new({
    required this.query,
    required this.source,
    required this.searchedAt,
  });

  factory fromJson(Map<String, dynamic> json) => SearchHistoryEntry(
    query: json['query'] as String,
    source: SearchSource.fromCode(json['source'] as String?),
    searchedAt: DateTime.parse(json['searched_at'] as String),
  );

  final String query;
  final SearchSource source;
  final DateTime searchedAt;
}

/// Complétion pendant la saisie (C-SEARCH-08) : un rayon ou un produit.
@immutable
class SearchSuggestion {
  const new({required this.label, this.categoryId});

  factory fromJson(Map<String, dynamic> json) => SearchSuggestion(
    label: LocalizedText.fromJson(json['label']),
    categoryId: json['category_id'] as String?,
  );

  final LocalizedText label;

  /// Renseigné pour un rayon.
  final String? categoryId;

  bool get isCategory => categoryId != null;

  @override
  bool operator ==(Object other) =>
      other is SearchSuggestion &&
      other.categoryId == categoryId &&
      other.label.resolve('fr') == label.resolve('fr');

  @override
  int get hashCode => Object.hash(categoryId, label.resolve('fr'));
}
