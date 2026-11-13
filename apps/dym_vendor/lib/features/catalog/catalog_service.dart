import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:flutter/widgets.dart';

/// Fiche à enregistrer (identifiants générés par l'app : idempotence).
@immutable
class ProductInput {
  const new({
    required this.id,
    required this.name,
    required this.variants,
    this.description,
    this.categoryId,
    this.unitId,
    this.priceMinor,
    this.suggestionId,
    this.photoKeys = const [],
    this.storeCategoryIds = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? categoryId;
  final String? unitId;
  final int? priceMinor;
  final String? suggestionId;
  final List<String> photoKeys;
  final List<String> storeCategoryIds;
  final List<ProductVariant> variants;
}

/// Accès de l'app vendeuse à son catalogue. Remplaçable en test.
abstract interface class CatalogService {
  /// Référentiel du pays (rayons, unités, devise).
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<List<Product>>> products();

  Future<Result<List<StoreCategory>>> storeCategories();

  Future<Result<Product>> saveProduct(ProductInput input);

  Future<Result<Product>> publish(String id);

  /// Import en masse (spec 081) : aperçu ou création en brouillon.
  Future<Result<ImportReport>> importProducts(
    List<ImportRow> rows, {
    required bool dry,
  });

  Future<Result<Product>> setAvailable(String id, {required bool available});

  /// Date d'arrivage (spec 033) ; nulle : produit normal.
  Future<Result<Product>> setArrival(String id, DateTime? arrivalOn);

  Future<Result<Product>> archive(String id, {required bool archived});

  Future<Result<void>> deleteDraft(String id);

  Future<Result<List<StoreCategory>>> saveStoreCategory(String id, String name);

  Future<Result<List<StoreCategory>>> archiveStoreCategory(
    String id, {
    required bool archived,
  });

  Future<Result<List<StoreCategory>>> reorderStoreCategories(List<String> ids);

  /// Prise ou choix d'une photo ; `null` si annulé.
  Future<Result<PickedPhoto?>> pickPhoto(PhotoSource source);

  /// Envoie la photo ; renvoie sa clé d'objet.
  Future<Result<String>> uploadPhoto(PickedPhoto photo);

  Future<Result<ProductSuggestion>> suggest(String objectKey);

  /// Image d'une photo du catalogue.
  ImageProvider photo(String objectKey);

  /// Événement `ai_product_suggestion_shown` (sans effet sur le parcours).
  void suggestionShown();

  /// Nouvel identifiant (produit, variante, catégorie).
  String newId();
}

/// Implémentation Neon.
class NeonCatalogService implements CatalogService {
  new({
    required this._catalog,
    required this._media,
    required this._events,
    required this._stores,
    required this._picker,
    required this._environment,
  });

  final CatalogRepository _catalog;
  final CatalogMediaRepository _media;
  final EventsRepository _events;
  final StoreService _stores;
  final PhotoPicker _picker;
  final DymEnvironment _environment;

  @override
  Future<Result<CountryConfig>> countryConfig() => _stores.countryConfig();

  @override
  Future<Result<List<Product>>> products() => _catalog.myProducts();

  @override
  Future<Result<List<StoreCategory>>> storeCategories() =>
      _catalog.storeCategories();

  @override
  Future<Result<Product>> saveProduct(ProductInput input) =>
      _catalog.saveProduct(
        id: input.id,
        name: input.name,
        description: input.description,
        categoryId: input.categoryId,
        unitId: input.unitId,
        priceMinor: input.priceMinor,
        suggestionId: input.suggestionId,
        photoKeys: input.photoKeys,
        storeCategoryIds: input.storeCategoryIds,
        variants: input.variants,
      );

  @override
  Future<Result<Product>> publish(String id) => _catalog.publish(id);

  @override
  Future<Result<ImportReport>> importProducts(
    List<ImportRow> rows, {
    required bool dry,
  }) => _catalog.importProducts(rows, dry: dry);

  @override
  Future<Result<Product>> setAvailable(String id, {required bool available}) =>
      _catalog.setAvailable(id, available: available);

  @override
  Future<Result<Product>> setArrival(String id, DateTime? arrivalOn) =>
      _catalog.setArrival(id, arrivalOn);

  @override
  Future<Result<Product>> archive(String id, {required bool archived}) =>
      _catalog.archive(id, archived: archived);

  @override
  Future<Result<void>> deleteDraft(String id) => _catalog.deleteDraft(id);

  @override
  Future<Result<List<StoreCategory>>> saveStoreCategory(
    String id,
    String name,
  ) => _catalog.saveStoreCategory(id, name);

  @override
  Future<Result<List<StoreCategory>>> archiveStoreCategory(
    String id, {
    required bool archived,
  }) => _catalog.archiveStoreCategory(id, archived: archived);

  @override
  Future<Result<List<StoreCategory>>> reorderStoreCategories(
    List<String> ids,
  ) => _catalog.reorderStoreCategories(ids);

  @override
  Future<Result<PickedPhoto?>> pickPhoto(PhotoSource source) =>
      _picker.pick(source);

  @override
  Future<Result<String>> uploadPhoto(PickedPhoto photo) async {
    final result = await _media.uploadPhoto(
      photo.bytes,
      contentType: photo.contentType,
    );
    return switch (result) {
      Ok(:final value) => Ok(value.objectKey),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<ProductSuggestion>> suggest(String objectKey) =>
      _media.suggest(objectKey);

  @override
  ImageProvider photo(String objectKey) =>
      dymNetworkImage(_environment.media(objectKey).toString());

  @override
  void suggestionShown() =>
      unawaited(_events.track('ai_product_suggestion_shown'));

  @override
  String newId() => Uuid.v4();
}
