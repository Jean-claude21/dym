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

  /// Lieu dans n'importe quel pays ouvert (spec 110) : quartier, pays et
  /// référentiel suivent ; panier d'un autre pays signalé.
  Future<Result<PlaceChange>> moveTo(String zoneId, String countryCode);

  /// Vide le panier.
  Future<Result<void>> clearCart();

  /// Référentiel d'un autre pays (choix du quartier ailleurs).
  Future<Result<CountryConfig>> countryConfigOf(String countryCode);

  /// Recherche ou rayon, dans le quartier choisi.
  Future<Result<SearchResults>> search(SearchQuery query);

  /// Carte (spec 095) : boutiques dans un cadre, ouvertes d'abord.
  Future<Result<List<PublicStore>>> mapStores({
    required double south,
    required double west,
    required double north,
    required double east,
    String? categoryId,
    bool openOnly = false,
  });

  /// Dernière position trouvée sur demande (jamais conservée hors session).
  GeoPoint? get lastPosition;

  /// Position de l'appareil, sur demande (`null` : refusée ou indisponible).
  Future<Result<GeoPoint?>> myPosition();

  /// Pays ouverts (explorateur de la carte).
  Future<Result<List<Country>>> countries();

  /// Référentiel d'un autre pays (villes et quartiers de la carte).
  Future<Result<CountryConfig>> configOf(String countryCode);

  /// `store_map_viewed` : nombres et filtres seulement, jamais la position.
  void storeMapViewed({
    required int stores,
    required bool openOnly,
    required bool category,
  });

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
    this._visitor,
  }) : _zone = ValueNotifier(
         _auth.me?.profile?.zoneId ?? _visitor?.value?.zoneId,
       );

  /// Lieu de la visiteuse sans compte (spec 093).
  final VisitorPlaceStore? _visitor;

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

  /// Position de l'appareil trouvée (spec 094) : les boutiques sont cherchées
  /// autour d'elle ; un quartier choisi à la main l'efface.
  GeoPoint? _point;

  String? get _countryCode =>
      _auth.me?.profile?.countryCode ?? _visitor?.value?.countryCode;

  @override
  ValueListenable<String?> get zone => _zone;

  @override
  void selectZone(String zoneId) {
    _point = null;
    _zone.value = zoneId;
  }

  @override
  Future<Result<PlaceChange>> moveTo(String zoneId, String countryCode) async {
    PlaceChange change;
    if (_auth.me == null) {
      // Visiteuse : lieu gardé sur l'appareil.
      await _visitor?.save(
        VisitorPlace(zoneId: zoneId, countryCode: countryCode),
      );
      change = PlaceChange(countryCode: countryCode);
    } else {
      switch (await _discovery.setMyPlace(zoneId)) {
        case Ok(:final value):
          change = value;
        case Err(:final failure):
          return Err(failure);
      }
      // Profil relu : pays, devise et rayons suivent partout.
      await _auth.bootstrap();
    }
    if (_config?.country.code != countryCode) _config = null;
    _zone.value = zoneId;
    return Ok(change);
  }

  @override
  Future<Result<void>> clearCart() => _discovery.clearCart();

  @override
  Future<Result<CountryConfig>> countryConfigOf(String countryCode) =>
      _reference.countryConfig(countryCode);

  @override
  Future<Result<CountryConfig>> countryConfig() async {
    final code = _countryCode;
    final cached = _config;
    // Référentiel gardé tant que le pays ne change pas (spec 110).
    if (cached != null && cached.country.code == code) return Ok(cached);
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
    final point = _point;
    if (zoneId == null && point == null) return const Ok(DiscoverResult());
    return await _discovery.discover(
      zoneId,
      latitude: point?.latitude,
      longitude: point?.longitude,
    );
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
        // Tous les pays ouverts : la position décide (spec 110).
        final match = await _discovery.nearestZone(
          point.latitude,
          point.longitude,
        );
        if (match case Ok(value: final m?) when !m.covered) {
          unawaited(trackOutsideCoverage(_events, m));
        }
        if (match case Ok(value: final m?) when m.covered) _point = point;
        return match;
    }
  }

  @override
  Future<Result<SearchResults>> search(SearchQuery query) =>
      _discovery.search(query.copyWith(zoneId: query.zoneId ?? _zone.value));

  @override
  Future<Result<List<PublicStore>>> mapStores({
    required double south,
    required double west,
    required double north,
    required double east,
    String? categoryId,
    bool openOnly = false,
  }) => _discovery.mapStores(
    south: south,
    west: west,
    north: north,
    east: east,
    categoryId: categoryId,
    openOnly: openOnly,
  );

  @override
  GeoPoint? get lastPosition => _point;

  @override
  Future<Result<GeoPoint?>> myPosition() async {
    final result = await _location.current();
    if (result case Ok(value: final point?)) _point = point;
    return result;
  }

  @override
  Future<Result<List<Country>>> countries() => _reference.countries();

  @override
  Future<Result<CountryConfig>> configOf(String countryCode) async {
    if (_config case final c? when c.country.code == countryCode) {
      return Ok(c);
    }
    return await _reference.countryConfig(countryCode);
  }

  @override
  void storeMapViewed({
    required int stores,
    required bool openOnly,
    required bool category,
  }) => unawaited(
    _events.track(
      'store_map_viewed',
      countryCode: _countryCode,
      props: {'stores': stores, 'open_only': openOnly, 'category': category},
    ),
  );

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
