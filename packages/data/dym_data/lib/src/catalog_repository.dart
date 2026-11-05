import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Catalogue de la vendeuse connectée. Les écritures passent par les
/// fonctions SQL (propriété, devise, complétude et événements en base).
class CatalogRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<List<Product>>> myProducts() =>
      _list('my_products', Product.fromJson);

  /// Crée ou met à jour une fiche. [id] et les identifiants des variantes
  /// sont générés par l'app : une nouvelle tentative ne crée pas de doublon.
  Future<Result<Product>> saveProduct({
    required String id,
    required String name,
    required List<ProductVariant> variants,
    String? description,
    String? categoryId,
    String? unitId,
    int? priceMinor,
    String? suggestionId,
    List<String> photoKeys = const [],
    List<String> storeCategoryIds = const [],
  }) => _product('save_product', {
    'p_product': {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'unit_id': unitId,
      'price_minor': priceMinor,
      'suggestion_id': suggestionId,
      'photo_keys': photoKeys,
      'store_category_ids': storeCategoryIds,
      'variants': [for (final v in variants) v.toJson()],
    },
  });

  /// Publie (refusé si incomplet : `ValidationFailure`).
  Future<Result<Product>> publish(String id) =>
      _product('publish_product', {'p_id': id});

  /// Rupture ou réactivation en un geste.
  Future<Result<Product>> setAvailable(String id, {required bool available}) =>
      _product('set_product_available', {'p_id': id, 'p_available': available});

  /// Stock d'une variante (nul : non suivi).
  Future<Result<Product>> setVariantStock(String variantId, int? quantity) =>
      _product('set_variant_stock', {
        'p_variant_id': variantId,
        'p_quantity': quantity,
      });

  Future<Result<Product>> archive(String id, {required bool archived}) =>
      _product('archive_product', {'p_id': id, 'p_archived': archived});

  /// Supprime un brouillon jamais publié.
  Future<Result<void>> deleteDraft(String id) async {
    final result = await _data.rpc<Object?>(
      'delete_product_draft',
      params: {'p_id': id},
    );
    return switch (result) {
      Ok() => const Ok(null),
      Err(:final failure) => Err(failure),
    };
  }

  Future<Result<List<StoreCategory>>> storeCategories() =>
      _list('my_store_categories', StoreCategory.fromJson);

  /// Crée (identifiant fourni par l'app) ou renomme une catégorie.
  Future<Result<List<StoreCategory>>> saveStoreCategory(
    String id,
    String name,
  ) => _list('save_store_category', StoreCategory.fromJson, {
    'p_id': id,
    'p_name': name,
  });

  Future<Result<List<StoreCategory>>> archiveStoreCategory(
    String id, {
    required bool archived,
  }) => _list('archive_store_category', StoreCategory.fromJson, {
    'p_id': id,
    'p_archived': archived,
  });

  Future<Result<List<StoreCategory>>> reorderStoreCategories(
    List<String> ids,
  ) =>
      _list('reorder_store_categories', StoreCategory.fromJson, {'p_ids': ids});

  Future<Result<Product>> _product(
    String fn,
    Map<String, Object?> params,
  ) async {
    final result = await _data.rpc<Object?>(fn, params: params);
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value is! Map<String, dynamic>) {
          return const Err(ServerFailure('produit illisible'));
        }
        try {
          return Ok(Product.fromJson(value));
        } on Object catch (error) {
          return Err(ServerFailure('produit illisible : ${error.runtimeType}'));
        }
    }
  }

  Future<Result<List<T>>> _list<T>(
    String fn,
    T Function(Map<String, dynamic>) decode, [
    Map<String, Object?>? params,
  ]) async {
    final result = await _data.rpc<Object?>(fn, params: params);
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value is! List) return const Err(ServerFailure('liste illisible'));
        try {
          return Ok([
            for (final item in value.cast<Map<String, dynamic>>()) decode(item),
          ]);
        } on Object catch (error) {
          return Err(ServerFailure('liste illisible : ${error.runtimeType}'));
        }
    }
  }
}

/// Photos et propositions (Functions) : envoi par URL présignée, puis
/// proposition « photo → fiche ».
class CatalogMediaRepository {
  new({required this._functions, required this._uploads});

  final NeonFunctionsClient _functions;
  final NeonObjectUploader _uploads;

  /// Envoie une photo compressée ; renvoie sa clé et son URL publique.
  Future<Result<PhotoUpload>> uploadPhoto(
    List<int> bytes, {
    required String contentType,
  }) async {
    final grant = await _functions.post<PhotoUpload>(
      '/v1/catalog/photo-uploads',
      body: {'content_type': contentType},
      // Présigner n'a pas d'effet : une nouvelle tentative est sans risque.
      idempotencyKey: Uuid.v4(),
      decode: (json) => PhotoUpload.fromJson(json! as Map<String, dynamic>),
    );
    switch (grant) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final upload):
        final sent = await _uploads.put(
          Uri.parse(upload.uploadUrl),
          bytes,
          contentType: contentType,
        );
        return switch (sent) {
          Ok() => Ok(upload),
          Err(:final failure) => Err(failure),
        };
    }
  }

  /// Proposition de fiche. Échec (service indisponible, réseau) : l'app
  /// passe à la saisie manuelle. Pas de nouvelle tentative automatique.
  Future<Result<ProductSuggestion>> suggest(String objectKey) =>
      _functions.post<ProductSuggestion>(
        '/v1/catalog/suggestions',
        body: {'object_key': objectKey},
        decode: (json) =>
            ProductSuggestion.fromJson(json! as Map<String, dynamic>),
      );
}
