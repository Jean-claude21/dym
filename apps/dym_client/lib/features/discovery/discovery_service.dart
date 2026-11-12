import 'dart:async';

import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Accès de l'app cliente à la découverte. Le quartier choisi est partagé
/// par les écrans (accueil, rayon, recherche, fiche). Remplaçable en test.
abstract interface class DiscoveryService {
  /// Quartier de livraison choisi (au départ : celui du profil).
  ValueListenable<String?> get zone;

  void selectZone(String zoneId);

  /// Référentiel du pays (quartiers, rayons, origines, unités, devise).
  Future<Result<CountryConfig>> countryConfig();

  /// Boutiques qui livrent le quartier choisi, et estimation.
  Future<Result<DiscoverResult>> discover();

  /// Fil personnel de l'accueil (spec 027) pour le quartier choisi.
  Future<Result<HomeFeed>> homeFeed();

  /// Quartier proposé à partir de la position (`null` : position refusée
  /// ou hors des villes ouvertes). La position n'est pas conservée.
  Future<Result<ZoneMatch?>> locateZone();

  /// Recherche ou rayon, dans le quartier choisi.
  Future<Result<SearchResults>> search(SearchQuery query);

  Future<Result<StorePageData>> storePage(String storeId);

  /// Avis publics d'une boutique (écran 64).
  Future<Result<StoreReviews>> storeReviews(String storeId);

  Future<Result<ProductPageData>> productPage(String productId);

  /// Image d'une photo du catalogue.
  ImageProvider photo(String objectKey);

  /// `search_performed` : nombres seulement, jamais le texte saisi.
  void searchPerformed(SearchQuery query, int total);

  /// `product_viewed`.
  void productViewed(String productId);
}

/// Implémentation Neon.
class NeonDiscoveryService implements DiscoveryService {
  new({
    required this._discovery,
    required this._reference,
    required this._events,
    required this._auth,
    required this._location,
    required this._environment,
    required this._reviews,
  }) : _zone = ValueNotifier(_auth.me?.profile?.zoneId);

  final ReviewRepository _reviews;

  @override
  Future<Result<StoreReviews>> storeReviews(String storeId) =>
      _reviews.storeReviews(storeId);

  final DiscoveryRepository _discovery;
  final ReferenceRepository _reference;
  final EventsRepository _events;
  final AuthService _auth;
  final LocationProvider _location;
  final DymEnvironment _environment;
  final ValueNotifier<String?> _zone;
  CountryConfig? _config;

  String? get _countryCode => _auth.me?.profile?.countryCode;

  @override
  ValueListenable<String?> get zone => _zone;

  @override
  void selectZone(String zoneId) => _zone.value = zoneId;

  @override
  Future<Result<CountryConfig>> countryConfig() async {
    final cached = _config;
    if (cached != null) return Ok(cached);
    final code = _countryCode;
    if (code == null) return const Err(UnauthenticatedFailure('profil'));
    final result = await _reference.countryConfig(code);
    if (result case Ok(:final value)) {
      _config = value;
      // Visiteur sans quartier : premier quartier de la première ville.
      _zone.value ??= value.cities.isEmpty
          ? null
          : value.zonesOf(value.cities.first.id).firstOrNull?.id;
    }
    return result;
  }

  @override
  Future<Result<HomeFeed>> homeFeed() async {
    final zoneId = _zone.value;
    if (zoneId == null) return const Ok(HomeFeed());
    return await _discovery.homeFeed(zoneId);
  }

  @override
  Future<Result<DiscoverResult>> discover() async {
    final zoneId = _zone.value;
    if (zoneId == null) return const Ok(DiscoverResult());
    return await _discovery.discover(zoneId);
  }

  @override
  Future<Result<ZoneMatch?>> locateZone() async {
    final position = await _location.current();
    switch (position) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: null):
        return const Ok(null);
      case Ok(value: final point?):
        final match = await _discovery.nearestZone(
          point.latitude,
          point.longitude,
          countryCode: _countryCode,
        );
        if (match case Ok(value: final m?) when !m.covered) {
          unawaited(trackOutsideCoverage(_events, m));
        }
        return match;
    }
  }

  @override
  Future<Result<SearchResults>> search(SearchQuery query) =>
      _discovery.search(query.copyWith(zoneId: query.zoneId ?? _zone.value));

  @override
  Future<Result<StorePageData>> storePage(String storeId) =>
      _discovery.storePage(storeId);

  @override
  Future<Result<ProductPageData>> productPage(String productId) =>
      _discovery.productPage(productId, zoneId: _zone.value);

  @override
  ImageProvider photo(String objectKey) =>
      dymNetworkImage(_environment.media(objectKey).toString());

  @override
  void searchPerformed(SearchQuery query, int total) => unawaited(
    _events.track(
      'search_performed',
      countryCode: _countryCode,
      props: {
        'results': total,
        'filters': query.activeFilters,
        'has_text': (query.text ?? '').trim().isNotEmpty,
      },
    ),
  );

  @override
  void productViewed(String productId) => unawaited(
    _events.track(
      'product_viewed',
      countryCode: _countryCode,
      entityType: 'product',
      entityId: productId,
    ),
  );
}
