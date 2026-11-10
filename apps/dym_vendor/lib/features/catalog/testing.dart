import 'dart:typed_data';

import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:flutter/widgets.dart';

/// Catalogue en mémoire pour les tests et la galerie : reproduit les règles
/// des fonctions SQL (devise de la boutique, complétude de la publication,
/// suppression des seuls brouillons, noms de catégorie uniques). N'est
/// jamais branché en production.
class MemoryCatalogService implements CatalogService {
  new({
    required this.config,
    this.storeId = '00000000-0000-4000-8000-000000000001',
    List<Product> products = const [],
    List<StoreCategory> categories = const [],
    this.pickedPhoto,
    this.suggestion,
    this.photoResolver,
    List<String> uploadKeys = const [],
  }) {
    _uploadKeys.addAll(uploadKeys);
    _products.addAll(products);
    _categories.addAll(categories);
  }

  final CountryConfig config;
  final String storeId;

  /// Photo renvoyée par [pickPhoto] (`null` : annulé).
  PickedPhoto? pickedPhoto;

  /// Proposition renvoyée par [suggest] (`null` : service indisponible).
  ProductSuggestion? suggestion;

  /// Image d'une clé connue d'avance (galerie : photos de démonstration).
  final ImageProvider Function(String key)? photoResolver;

  /// Prochain appel en échec (une fois).
  Failure? failNext;

  final calls = <String>[];
  int suggestionsShown = 0;

  final _products = <Product>[];
  final _categories = <StoreCategory>[];
  final _photos = <String, Uint8List>{};
  final _uploadKeys = <String>[];
  int _ids = 0;

  List<Product> get current => List.unmodifiable(_products);

  Result<T>? _fail<T>(String name) {
    calls.add(name);
    final failure = failNext;
    if (failure == null) return null;
    failNext = null;
    return Err(failure);
  }

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(config);

  @override
  Future<Result<List<Product>>> products() async =>
      _fail('products') ?? Ok(current);

  @override
  Future<Result<List<StoreCategory>>> storeCategories() async =>
      _fail('storeCategories') ?? Ok(_sortedCategories());

  List<StoreCategory> _sortedCategories() => [
    for (final c
        in [..._categories]..sort((a, b) {
          if (a.isArchived != b.isArchived) return a.isArchived ? 1 : -1;
          return a.sort.compareTo(b.sort);
        }))
      StoreCategory(
        id: c.id,
        name: c.name,
        sort: c.sort,
        isArchived: c.isArchived,
        productCount: _products
            .where((p) => !p.isArchived && p.storeCategoryIds.contains(c.id))
            .length,
      ),
  ];

  Product? _find(String id) => _products.where((p) => p.id == id).firstOrNull;

  void _put(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    index < 0 ? _products.insert(0, product) : _products[index] = product;
  }

  static List<String> _missing(Product p) => [
    if (p.categoryId == null) 'category',
    if (p.priceMinor == null) 'price',
    if (p.photoKeys.isEmpty) 'photo',
    if (p.variants.isEmpty) 'variant',
  ];

  Product _copy(
    Product p, {
    ProductStatus? status,
    bool? isAvailable,
    DateTime? arrivalOn,
    bool clearArrival = false,
  }) => Product(
    id: p.id,
    name: p.name,
    description: p.description,
    categoryId: p.categoryId,
    unitId: p.unitId,
    priceMinor: p.priceMinor,
    currencyCode: p.currencyCode,
    status: status ?? p.status,
    isAvailable: isAvailable ?? p.isAvailable,
    suggestionId: p.suggestionId,
    variants: p.variants,
    photoKeys: p.photoKeys,
    storeCategoryIds: p.storeCategoryIds,
    missing: p.missing,
    arrivalOn: clearArrival ? null : (arrivalOn ?? p.arrivalOn),
  );

  @override
  Future<Result<Product>> setArrival(String id, DateTime? arrivalOn) async {
    final failed = _fail<Product>('setArrival');
    if (failed != null) return failed;
    final product = _find(id);
    if (product == null) return const Err(ForbiddenFailure('inaccessible'));
    final updated = _copy(
      product,
      arrivalOn: arrivalOn,
      clearArrival: arrivalOn == null,
    );
    _put(updated);
    return Ok(updated);
  }

  @override
  Future<Result<Product>> saveProduct(ProductInput input) async {
    final failed = _fail<Product>('saveProduct');
    if (failed != null) return failed;
    if (input.name.trim().length < 2 || input.name.trim().length > 80) {
      return const Err(ValidationFailure('nom invalide'));
    }
    if (input.photoKeys.length > 5 || input.variants.length > 10) {
      return const Err(ValidationFailure('trop de photos ou de variantes'));
    }
    final existing = _find(input.id);
    final draft = Product(
      id: input.id,
      name: input.name.trim(),
      description: input.description,
      categoryId: input.categoryId,
      unitId: input.unitId,
      priceMinor: input.priceMinor,
      currencyCode: config.currency.code,
      status: existing?.status ?? ProductStatus.draft,
      isAvailable: existing?.isAvailable ?? true,
      suggestionId: input.suggestionId ?? existing?.suggestionId,
      variants: input.variants.isEmpty
          ? [ProductVariant(id: newId())]
          : input.variants,
      photoKeys: input.photoKeys,
      storeCategoryIds: input.storeCategoryIds,
    );
    final saved = Product(
      id: draft.id,
      name: draft.name,
      description: draft.description,
      categoryId: draft.categoryId,
      unitId: draft.unitId,
      priceMinor: draft.priceMinor,
      currencyCode: draft.currencyCode,
      status: draft.status,
      isAvailable: draft.isAvailable,
      suggestionId: draft.suggestionId,
      variants: draft.variants,
      photoKeys: draft.photoKeys,
      storeCategoryIds: draft.storeCategoryIds,
      missing: _missing(draft),
    );
    _put(saved);
    return Ok(saved);
  }

  @override
  Future<Result<Product>> publish(String id) async {
    final failed = _fail<Product>('publish');
    if (failed != null) return failed;
    final product = _find(id);
    if (product == null) return const Err(ForbiddenFailure('inaccessible'));
    if (_missing(product).isNotEmpty) {
      return const Err(ValidationFailure('produit incomplet'));
    }
    final published = _copy(product, status: ProductStatus.published);
    _put(published);
    return Ok(published);
  }

  @override
  Future<Result<Product>> setAvailable(
    String id, {
    required bool available,
  }) async {
    final failed = _fail<Product>('setAvailable');
    if (failed != null) return failed;
    final product = _find(id);
    if (product == null) return const Err(ForbiddenFailure('inaccessible'));
    final updated = _copy(product, isAvailable: available);
    _put(updated);
    return Ok(updated);
  }

  @override
  Future<Result<Product>> archive(String id, {required bool archived}) async {
    final failed = _fail<Product>('archive');
    if (failed != null) return failed;
    final product = _find(id);
    if (product == null) return const Err(ForbiddenFailure('inaccessible'));
    final updated = _copy(
      product,
      status: archived
          ? ProductStatus.archived
          : (_missing(product).isEmpty
                ? ProductStatus.published
                : ProductStatus.draft),
    );
    _put(updated);
    return Ok(updated);
  }

  @override
  Future<Result<void>> deleteDraft(String id) async {
    final failed = _fail<void>('deleteDraft');
    if (failed != null) return failed;
    final product = _find(id);
    if (product == null || product.status != ProductStatus.draft) {
      return const Err(ValidationFailure('seul un brouillon se supprime'));
    }
    _products.remove(product);
    return const Ok(null);
  }

  @override
  Future<Result<List<StoreCategory>>> saveStoreCategory(
    String id,
    String name,
  ) async {
    final failed = _fail<List<StoreCategory>>('saveStoreCategory');
    if (failed != null) return failed;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 40) {
      return const Err(ValidationFailure('nom invalide'));
    }
    if (_categories.any(
      (c) => c.id != id && c.name.toLowerCase() == trimmed.toLowerCase(),
    )) {
      return const Err(ConflictFailure('doublon'));
    }
    final index = _categories.indexWhere((c) => c.id == id);
    if (index < 0) {
      _categories.add(
        StoreCategory(id: id, name: trimmed, sort: _categories.length),
      );
    } else {
      final c = _categories[index];
      _categories[index] = StoreCategory(
        id: id,
        name: trimmed,
        sort: c.sort,
        isArchived: c.isArchived,
      );
    }
    return Ok(_sortedCategories());
  }

  @override
  Future<Result<List<StoreCategory>>> archiveStoreCategory(
    String id, {
    required bool archived,
  }) async {
    final failed = _fail<List<StoreCategory>>('archiveStoreCategory');
    if (failed != null) return failed;
    final index = _categories.indexWhere((c) => c.id == id);
    if (index < 0) return const Err(ForbiddenFailure('inaccessible'));
    final c = _categories[index];
    _categories[index] = StoreCategory(
      id: c.id,
      name: c.name,
      sort: c.sort,
      isArchived: archived,
    );
    return Ok(_sortedCategories());
  }

  @override
  Future<Result<List<StoreCategory>>> reorderStoreCategories(
    List<String> ids,
  ) async {
    final failed = _fail<List<StoreCategory>>('reorderStoreCategories');
    if (failed != null) return failed;
    for (final (i, id) in ids.indexed) {
      final index = _categories.indexWhere((c) => c.id == id);
      if (index < 0) continue;
      final c = _categories[index];
      _categories[index] = StoreCategory(
        id: c.id,
        name: c.name,
        sort: i,
        isArchived: c.isArchived,
      );
    }
    return Ok(_sortedCategories());
  }

  @override
  Future<Result<PickedPhoto?>> pickPhoto(PhotoSource source) async =>
      _fail('pickPhoto') ?? Ok(pickedPhoto);

  @override
  Future<Result<String>> uploadPhoto(PickedPhoto photo) async {
    final failed = _fail<String>('uploadPhoto');
    if (failed != null) return failed;
    // Clés prévues d'avance (galerie : photos de démonstration).
    final key = _uploadKeys.isNotEmpty
        ? _uploadKeys.removeAt(0)
        : 'stores/$storeId/products/${newId()}.jpg';
    if (photo.bytes.isNotEmpty) _photos[key] = photo.bytes;
    return Ok(key);
  }

  @override
  Future<Result<ProductSuggestion>> suggest(String objectKey) async {
    final failed = _fail<ProductSuggestion>('suggest');
    if (failed != null) return failed;
    final value = suggestion;
    return value == null
        ? const Err(ServerFailure('proposition désactivée', statusCode: 503))
        : Ok(value);
  }

  @override
  ImageProvider photo(String objectKey) {
    final bytes = _photos[objectKey];
    if (bytes != null) return MemoryImage(bytes);
    return photoResolver?.call(objectKey) ?? MemoryImage(_transparentPng);
  }

  @override
  void suggestionShown() => suggestionsShown++;

  @override
  String newId() {
    _ids++;
    return '00000000-0000-4000-8000-${_ids.toString().padLeft(12, '0')}';
  }

  /// PNG 1 × 1 transparent (photo inconnue).
  static final _transparentPng = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);
}
