import 'package:dym_models/src/json.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'catalog_models.g.dart';

/// Statut d'un produit.
enum ProductStatus { draft, published, archived }

/// Catégorie de la boutique (« Jus », « Sirops »), propre à la vendeuse.
@immutable
@JsonSerializable()
class StoreCategory {
  const new({
    required this.id,
    required this.name,
    this.sort = 0,
    this.isArchived = false,
    this.productCount = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$StoreCategoryFromJson(json);

  final String id;
  final String name;
  final int sort;
  final bool isArchived;
  final int productCount;
}

/// Variante d'un produit. Prix nul : prix de base ; stock nul : non suivi.
@immutable
@JsonSerializable()
class ProductVariant {
  const new({
    required this.id,
    this.label,
    this.priceMinor,
    this.stockQuantity,
    this.sort = 0,
  });

  factory fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);

  final String id;
  final String? label;
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? priceMinor;
  final int? stockQuantity;
  final int sort;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'price_minor': priceMinor,
    'stock_quantity': stockQuantity,
  };
}

/// Produit de la vendeuse (`my_products()`), avec ce qui manque pour publier.
@immutable
@JsonSerializable()
class Product {
  const new({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.status,
    this.description,
    this.categoryId,
    this.unitId,
    this.priceMinor,
    this.isAvailable = true,
    this.suggestionId,
    this.variants = const [],
    this.photoKeys = const [],
    this.storeCategoryIds = const [],
    this.missing = const [],
    this.arrivalOn,
  });

  factory fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

  final String id;
  final String name;
  final String? description;
  final String? categoryId;
  final String? unitId;
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? priceMinor;
  final String currencyCode;
  final ProductStatus status;
  final bool isAvailable;
  final String? suggestionId;

  /// Date d'arrivage (spec 033) ; nulle : produit normal.
  final DateTime? arrivalOn;
  final List<ProductVariant> variants;
  final List<String> photoKeys;
  final List<String> storeCategoryIds;

  /// Éléments manquants pour publier (`category`, `price`, `photo`,
  /// `variant`).
  final List<String> missing;

  bool get isPublished => status == ProductStatus.published;
  bool get isArchived => status == ProductStatus.archived;

  /// Stock total suivi (nul si aucune variante n'est suivie).
  int? get trackedStock {
    final tracked = variants.where((v) => v.stockQuantity != null);
    if (tracked.isEmpty) return null;
    return tracked.fold<int>(0, (sum, v) => sum + v.stockQuantity!);
  }
}

/// Fiche proposée à partir d'une photo (Function `suggestions`).
@immutable
@JsonSerializable()
class ProductSuggestion {
  const new({
    required this.suggestionId,
    required this.name,
    this.categoryId,
    this.description,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$ProductSuggestionFromJson(json);

  final String suggestionId;
  final String name;
  final String? categoryId;
  final String? description;
}

/// Envoi de photo autorisé (Function `photo-uploads`).
@immutable
@JsonSerializable()
class PhotoUpload {
  const new({
    required this.objectKey,
    required this.uploadUrl,
    required this.publicUrl,
  });

  factory fromJson(Map<String, dynamic> json) => _$PhotoUploadFromJson(json);

  final String objectKey;
  final String uploadUrl;
  final String publicUrl;
}

/// Ligne d'import du catalogue (spec 081), telle que saisie dans le tableur :
/// le serveur lit le prix, cherche le rayon et l'unité.
@immutable
class ImportRow {
  const new({
    required this.name,
    required this.price,
    this.unit = '',
    this.category = '',
    this.stock = '',
  });

  final String name;
  final String price;
  final String unit;
  final String category;
  final String stock;

  Map<String, String> toJson() => {
    'name': name,
    'price': price,
    'unit': unit,
    'category': category,
    'stock': stock,
  };
}

/// Ligne refusée : numéro (à partir de 1) et raison (`name_invalid`,
/// `price_invalid`, `category_unknown`, `unit_unknown`, `stock_invalid`,
/// `error`).
@immutable
class ImportError {
  const new({required this.line, required this.reason});

  final int line;
  final String reason;
}

/// Résultat d'un import (aperçu ou création).
@immutable
class ImportReport {
  const new({required this.valid, this.errors = const [], this.dry = true});

  factory fromJson(Map<String, dynamic> json) => ImportReport(
    valid: (json['valid'] as num?)?.toInt() ?? 0,
    dry: json['dry'] as bool? ?? true,
    errors: [
      for (final e in (json['errors'] as List? ?? const []))
        ImportError(
          line: ((e as Map)['line'] as num).toInt(),
          reason: e['reason'] as String? ?? 'error',
        ),
    ],
  );

  final int valid;
  final List<ImportError> errors;
  final bool dry;
}
