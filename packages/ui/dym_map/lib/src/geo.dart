import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

/// Point géographique (degrés décimaux, WGS 84).
@immutable
class DymLatLng {
  const new(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is DymLatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'DymLatLng($latitude, $longitude)';
}

/// Cadre visible de la carte (sud-ouest, nord-est).
@immutable
class DymBounds {
  const new({required this.southWest, required this.northEast});

  /// Plus petit cadre contenant [points] ; nul si la liste est vide.
  static DymBounds? around(Iterable<DymLatLng> points) {
    if (points.isEmpty) return null;
    var south = 90.0;
    var west = 180.0;
    var north = -90.0;
    var east = -180.0;
    for (final p in points) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    return DymBounds(
      southWest: DymLatLng(south, west),
      northEast: DymLatLng(north, east),
    );
  }

  final DymLatLng southWest;
  final DymLatLng northEast;

  DymLatLng get center => DymLatLng(
    (southWest.latitude + northEast.latitude) / 2,
    (southWest.longitude + northEast.longitude) / 2,
  );

  bool contains(DymLatLng p) =>
      p.latitude >= southWest.latitude &&
      p.latitude <= northEast.latitude &&
      p.longitude >= southWest.longitude &&
      p.longitude <= northEast.longitude;

  @override
  bool operator ==(Object other) =>
      other is DymBounds &&
      other.southWest == southWest &&
      other.northEast == northEast;

  @override
  int get hashCode => Object.hash(southWest, northEast);
}

const _earthRadiusM = 6371000.0;

/// Distance en mètres entre deux points (haversine, comme `app.distance_m`).
double distanceMeters(DymLatLng a, DymLatLng b) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.sqrt(h));
}

/// Anneau de [steps] points (fermé) qui trace un cercle de [radiusM] mètres
/// autour de [center], en `[longitude, latitude]` (ordre GeoJSON).
List<List<double>> circleRing(
  DymLatLng center,
  double radiusM, {
  int steps = 64,
}) {
  final lat = center.latitude * math.pi / 180;
  final lng = center.longitude * math.pi / 180;
  final d = radiusM / _earthRadiusM;
  final ring = <List<double>>[];
  for (var i = 0; i <= steps; i++) {
    final bearing = 2 * math.pi * (i % steps) / steps;
    final pLat = math.asin(
      math.sin(lat) * math.cos(d) +
          math.cos(lat) * math.sin(d) * math.cos(bearing),
    );
    final pLng =
        lng +
        math.atan2(
          math.sin(bearing) * math.sin(d) * math.cos(lat),
          math.cos(d) - math.sin(lat) * math.sin(pLat),
        );
    ring.add([pLng * 180 / math.pi, pLat * 180 / math.pi]);
  }
  return ring;
}

/// Zoom qui montre à peu près un cercle de [radiusM] mètres dans une
/// largeur de [widthPx] pixels logiques, à la latitude [latitude].
double zoomForRadius(double radiusM, double widthPx, double latitude) {
  final metersPerPixel = (radiusM * 2.4) / math.max(widthPx, 1);
  final atEquator = 156543.03392 * math.cos(latitude * math.pi / 180);
  final zoom = math.log(atEquator / metersPerPixel) / math.ln2;
  return zoom.clamp(2, 18).toDouble();
}
