import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Découverte côté cliente : lecture seule, avec ou sans session (rôle
/// anonyme). Ouverture, disponibilité et estimations sont calculées en base.
class DiscoveryRepository {
  new(this._data);

  final NeonDataClient _data;

  /// Accueil : boutiques qui livrent [zoneId] ou la position donnée (rayon de
  /// la boutique, spec 094), ouvertes d'abord puis les plus proches.
  Future<Result<DiscoverResult>> discover(
    String? zoneId, {
    double? latitude,
    double? longitude,
  }) => _object('discover_stores', {
    'p_zone': zoneId,
    'p_latitude': ?latitude,
    'p_longitude': ?longitude,
  }, DiscoverResult.fromJson);

  /// Carte (spec 095) : boutiques actives dont la position tombe dans le
  /// cadre donné, ouvertes d'abord ; filtres catégorie et « ouvertes ».
  Future<Result<List<PublicStore>>> mapStores({
    required double south,
    required double west,
    required double north,
    required double east,
    String? categoryId,
    bool openOnly = false,
  }) async {
    final result = await _data.rpc<Object?>(
      'map_stores',
      params: {
        'p_south': south,
        'p_west': west,
        'p_north': north,
        'p_east': east,
        'p_category': categoryId,
        'p_open_only': openOnly,
      },
    );
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value is! List) {
          return const Err(ServerFailure('réponse illisible'));
        }
        try {
          return Ok([
            for (final row in value)
              PublicStore.fromJson(row as Map<String, dynamic>),
          ]);
        } on Object catch (error) {
          return Err(ServerFailure('réponse illisible : ${error.runtimeType}'));
        }
    }
  }

  /// Fil personnel de l'accueil (spec 027) pour [zoneId].
  Future<Result<HomeFeed>> homeFeed(String zoneId) =>
      _object('home_feed', {'p_zone': zoneId}, HomeFeed.fromJson);

  /// Quartier le plus proche d'une position (rien si hors des villes ouvertes).
  Future<Result<ZoneMatch?>> nearestZone(
    double latitude,
    double longitude, {
    String? countryCode,
  }) => _nullable('nearest_zone', {
    'p_latitude': latitude,
    'p_longitude': longitude,
    'p_country': countryCode,
  }, ZoneMatch.fromJson);

  Future<Result<SearchResults>> search(SearchQuery query) =>
      _object('search_catalog', query.toParams(), SearchResults.fromJson);

  /// Page boutique ; `NotFoundFailure` si la boutique n'est plus active.
  Future<Result<StorePageData>> storePage(String storeId) =>
      _required('store_page', {'p_store': storeId}, StorePageData.fromJson);

  /// Fiche produit ; `NotFoundFailure` si le produit n'est plus public.
  Future<Result<ProductPageData>> productPage(
    String productId, {
    String? zoneId,
  }) => _required('product_page', {
    'p_product': productId,
    'p_zone': zoneId,
  }, ProductPageData.fromJson);

  Future<Result<T>> _object<T>(
    String fn,
    Map<String, Object?> params,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final result = await _nullable(fn, params, decode);
    switch (result) {
      case Ok(value: final value?):
        return Ok(value);
      case Ok():
        return const Err(ServerFailure('réponse vide'));
      case Err(:final failure):
        return Err(failure);
    }
  }

  Future<Result<T>> _required<T>(
    String fn,
    Map<String, Object?> params,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final result = await _nullable(fn, params, decode);
    switch (result) {
      case Ok(value: final value?):
        return Ok(value);
      case Ok():
        return const Err(NotFoundFailure('introuvable'));
      case Err(:final failure):
        return Err(failure);
    }
  }

  Future<Result<T?>> _nullable<T>(
    String fn,
    Map<String, Object?> params,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final result = await _data.rpc<Object?>(fn, params: params);
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value == null) return const Ok(null);
        if (value is! Map<String, dynamic>) {
          return const Err(ServerFailure('réponse illisible'));
        }
        try {
          return Ok(decode(value));
        } on Object catch (error) {
          return Err(ServerFailure('réponse illisible : ${error.runtimeType}'));
        }
    }
  }
}
