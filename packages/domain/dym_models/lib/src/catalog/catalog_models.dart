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
