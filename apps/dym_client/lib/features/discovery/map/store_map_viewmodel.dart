import 'dart:async';
import 'dart:math' as math;

import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_map/dym_map.dart';
import 'package:dym_models/dym_models.dart';
import 'package:stacked/stacked.dart';

/// Carte des boutiques (spec 095) : le cadre visible commande la liste,
/// les filtres et la position sont relus en base, rien n'est calculé ici.
class StoreMapViewModel extends BaseViewModel {
  new({required this._service, required this.config});

  final DiscoveryService _service;

  /// Référentiel du pays affiché (catégories, origines).
  final CountryConfig? config;

  List<PublicStore> _stores = const [];
  Failure? _failure;
  bool _openOnly = false;
  String? _categoryId;
  String? _selectedId;
  bool _positionUnavailable = false;
  bool _tracked = false;
  int _request = 0;
  DymBounds? _bounds;

  List<PublicStore> get stores => _stores;
  Failure? get failure => _failure;
  bool get offline => _failure is NetworkFailure;
  bool get openOnly => _openOnly;
  String? get categoryId => _categoryId;
  bool get positionUnavailable => _positionUnavailable;
  DiscoveryService get service => _service;

  /// Rien dans le cadre (après un chargement réussi).
  bool get empty =>
      _bounds != null && !isBusy && _failure == null && _stores.isEmpty;

  PublicStore? get selected =>
      _stores.where((s) => s.id == _selectedId).firstOrNull;

  List<Category> get categories => config?.topCategories ?? const [];

  Zone? get _zone =>
      config?.zones.where((z) => z.id == _service.zone.value).firstOrNull;

  /// Départ : position trouvée, sinon quartier choisi, sinon premier
  /// quartier situé du pays ; vue du monde à défaut.
  DymLatLng get initialCenter {
    if (_service.lastPosition case final p?) {
      return DymLatLng(p.latitude, p.longitude);
    }
    final zone =
        _zone ?? config?.zones.where((z) => z.latitude != null).firstOrNull;
    if (zone case Zone(:final latitude?, :final longitude?)) {
      return DymLatLng(latitude, longitude);
    }
    return const DymLatLng(20, 0);
  }

  double get initialZoom {
    if (_service.lastPosition != null) return 14;
    final hasZone = config?.zones.any((z) => z.latitude != null) ?? false;
    return hasZone ? 13 : 2;
  }

  /// Épingles : une par boutique située ; fermées grisées.
  List<DymMapPin> pins(String Function(String? origin) style) => [
    for (final s in _stores)
      if (_point(s) case final point?)
        DymMapPin(
          id: s.id,
          point: point,
          style: style(s.origin),
          label: s.name,
          dimmed: !s.openNow,
        ),
  ];

  /// Zone de livraison de la boutique choisie.
  List<DymMapArea> get areas {
    final s = selected;
    final point = s == null ? null : _point(s);
    if (s == null || point == null) return const [];
    return [
      DymMapArea(
        id: s.id,
        center: point,
        radiusM: (s.deliveryRadiusM ?? 5000).toDouble(),
      ),
    ];
  }

  static DymLatLng? _point(PublicStore s) {
    final lat = s.latitude ?? s.zoneLatitude;
    final lng = s.longitude ?? s.zoneLongitude;
    return lat == null || lng == null ? null : DymLatLng(lat, lng);
  }

  /// Commandes de la carte, données quand elle est prête.
  DymMapControls? controls;

  /// La carte s'est arrêtée : on relit les boutiques de ce cadre.
  Future<void> onCameraIdle(DymMapView view) async {
    _bounds = view.bounds ?? _approxBounds(view);
    await reload();
  }

  static DymBounds _approxBounds(DymMapView view) {
    final span = 360 / math.pow(2, view.zoom);
    final c = view.center;
    return DymBounds(
      southWest: DymLatLng(
        (c.latitude - span / 2).clamp(-90, 90),
        (c.longitude - span).clamp(-180, 180),
      ),
      northEast: DymLatLng(
        (c.latitude + span / 2).clamp(-90, 90),
        (c.longitude + span).clamp(-180, 180),
      ),
    );
  }

  Future<void> reload() async {
    final b = _bounds;
    if (b == null) return;
    final request = ++_request;
    _failure = null;
    setBusy(true);
    final result = await _service.mapStores(
      south: b.southWest.latitude,
      west: b.southWest.longitude,
      north: b.northEast.latitude,
      east: b.northEast.longitude,
      categoryId: _categoryId,
      openOnly: _openOnly,
    );
    // Une réponse plus ancienne que la dernière demande est ignorée.
    if (request != _request) return;
    switch (result) {
      case Ok(:final value):
        _stores = value;
        if (selected == null) _selectedId = null;
        if (!_tracked) {
          _tracked = true;
          _service.storeMapViewed(
            stores: value.length,
            openOnly: _openOnly,
            category: _categoryId != null,
          );
        }
      case Err(:final failure):
        _failure = failure;
    }
    setBusy(false);
  }

  Future<void> toggleOpen() async {
    _openOnly = !_openOnly;
    await reload();
  }

  Future<void> setCategory(String? id) async {
    _categoryId = id;
    await reload();
  }

  void select(String? id) {
    _selectedId = id;
    notifyListeners();
  }

  /// Recentre sur l'appareil, sur demande.
  Future<void> locateMe() async {
    _positionUnavailable = false;
    final result = await _service.myPosition();
    if (result case Ok(value: final p?)) {
      await controls?.moveTo(DymLatLng(p.latitude, p.longitude), zoom: 14);
    } else {
      _positionUnavailable = true;
    }
    notifyListeners();
  }

  Future<Result<List<Country>>> countries() => _service.countries();

  Future<Result<CountryConfig>> configOf(String code) =>
      _service.configOf(code);

  /// Explorateur : cadre la ville choisie (ses quartiers situés).
  Future<void> showCity(CountryConfig country, City city) async {
    final points = [
      for (final z in country.zonesOf(city.id))
        if (z case Zone(:final latitude?, :final longitude?))
          DymLatLng(latitude, longitude),
    ];
    final bounds = DymBounds.around(points);
    if (bounds == null) return;
    _selectedId = null;
    if (points.length == 1) {
      await controls?.moveTo(points.single, zoom: 13);
    } else {
      await controls?.fit(bounds);
    }
  }
}
