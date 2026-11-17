import 'dart:convert';

import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/widgets.dart' show Color;

/// Sources et calques ajoutés par DYM au fond de carte.
abstract final class DymMapLayers {
  static const pinsSource = 'dym-pins';
  static const areasSource = 'dym-areas';
  static const areaFill = 'dym-area-fill';
  static const areaLine = 'dym-area-line';
  static const routesSource = 'dym-routes';
  static const routeCase = 'dym-route-case';
  static const routeLine = 'dym-route-line';
  static const clusters = 'dym-clusters';
  static const clusterCount = 'dym-cluster-count';
  static const pins = 'dym-pins-icons';
  static const pinLabels = 'dym-pins-labels';

  /// Calques touchables : regroupements et épingles.
  static const List<String> tappable = [clusters, pins];
}

/// Fond OpenFreeMap (sans clé, schéma OpenMapTiles), données © OpenStreetMap.
/// Les adresses viennent de la configuration de l'app, jamais du code des
/// écrans ; celles-ci sont les valeurs publiques d'OpenFreeMap.
class DymMapTiles {
  const new({
    this.vectorUrl = 'https://tiles.openfreemap.org/planet',
    this.glyphsUrl =
        'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf',
  });

  final String vectorUrl;
  final String glyphsUrl;
}

String _hex(Color c) {
  int ch(double v) => (v * 255).round().clamp(0, 255);
  final rgb = (ch(c.r) << 16) | (ch(c.g) << 8) | ch(c.b);
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}

/// Style MapLibre complet aux couleurs DYM (« Épuré » : fond clair, verts
/// doux, routes blanches, textes sobres). Les épingles et zones de DYM sont
/// des calques du style, alimentés ensuite par `setGeoJsonSource`.
String dymMapStyle(DymColors c, {DymMapTiles tiles = const DymMapTiles()}) {
  final land = _hex(c.background);
  final muted = _hex(c.muted);
  final park = _hex(c.tintVertTendre);
  const water = '#cfe3ea';
  const road = '#ffffff';
  final roadCase = _hex(c.hairline);
  final major = _hex(c.tintPlantainClair);
  final majorCase = _hex(c.lineStrong);
  final text = _hex(c.textSecondary);
  final textStrong = _hex(c.textPrimary);
  final brand = _hex(c.brand);
  final brandDeep = _hex(c.brandDeep);
  final halo = _hex(c.card);
  const fontRegular = ['Noto Sans Regular'];
  const fontBold = ['Noto Sans Bold'];

  Map<String, Object?> roadLayer(
    String id,
    List<String> classes,
    String color,
    List<num> widths, {
    bool casing = false,
  }) => {
    'id': id,
    'type': 'line',
    'source': 'openmaptiles',
    'source-layer': 'transportation',
    'filter': [
      'all',
      [
        'match',
        ['get', 'class'],
        classes,
        true,
        false,
      ],
      [
        '!=',
        ['get', 'brunnel'],
        'tunnel',
      ],
    ],
    'layout': {'line-cap': 'round', 'line-join': 'round'},
    'paint': {
      'line-color': color,
      'line-width': [
        'interpolate',
        ['exponential', 1.5],
        ['zoom'],
        widths[0],
        widths[1],
        widths[2],
        widths[3] + (casing ? 2 : 0),
      ],
    },
  };

  final style = {
    'version': 8,
    'name': 'DYM',
    'glyphs': tiles.glyphsUrl,
    'sources': {
      'openmaptiles': {'type': 'vector', 'url': tiles.vectorUrl},
      DymMapLayers.pinsSource: {
        'type': 'geojson',
        'data': {'type': 'FeatureCollection', 'features': <Object>[]},
        'cluster': true,
        'clusterRadius': 44,
        'clusterMaxZoom': 14,
      },
      DymMapLayers.areasSource: {
        'type': 'geojson',
        'data': {'type': 'FeatureCollection', 'features': <Object>[]},
      },
      DymMapLayers.routesSource: {
        'type': 'geojson',
        'data': {'type': 'FeatureCollection', 'features': <Object>[]},
      },
    },
    'layers': [
      {
        'id': 'background',
        'type': 'background',
        'paint': {'background-color': land},
      },
      {
        'id': 'landuse',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'landuse',
        'filter': [
          'match',
          ['get', 'class'],
          ['residential', 'suburb', 'neighbourhood'],
          true,
          false,
        ],
        'paint': {'fill-color': muted, 'fill-opacity': 0.6},
      },
      {
        'id': 'park',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'park',
        'paint': {'fill-color': park},
      },
      {
        'id': 'landcover',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'landcover',
        'filter': [
          'match',
          ['get', 'class'],
          ['grass', 'wood', 'farmland'],
          true,
          false,
        ],
        'paint': {'fill-color': park, 'fill-opacity': 0.7},
      },
      {
        'id': 'water',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'water',
        'paint': {'fill-color': water},
      },
      {
        'id': 'waterway',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'waterway',
        'paint': {'line-color': water, 'line-width': 1.2},
      },
      {
        'id': 'building',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'building',
        'minzoom': 14,
        'paint': {'fill-color': muted, 'fill-outline-color': roadCase},
      },
      roadLayer(
        'road-minor-case',
        ['minor', 'service', 'track'],
        roadCase,
        [12, 0.5, 18, 14],
        casing: true,
      ),
      roadLayer(
        'road-minor',
        ['minor', 'service', 'track'],
        road,
        [12, 0.5, 18, 14],
      ),
      roadLayer(
        'road-major-case',
        ['primary', 'secondary', 'tertiary', 'trunk', 'motorway'],
        majorCase,
        [6, 0.6, 18, 20],
        casing: true,
      ),
      roadLayer(
        'road-major',
        ['primary', 'secondary', 'tertiary', 'trunk', 'motorway'],
        major,
        [6, 0.6, 18, 20],
      ),
      {
        'id': 'boundary',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'boundary',
        'filter': [
          '<=',
          ['get', 'admin_level'],
          4,
        ],
        'paint': {
          'line-color': majorCase,
          'line-dasharray': [2, 2],
          'line-width': 1,
        },
      },
      {
        'id': 'road-label',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'transportation_name',
        'minzoom': 14,
        'layout': {
          'symbol-placement': 'line',
          'text-field': [
            'coalesce',
            ['get', 'name:latin'],
            ['get', 'name'],
          ],
          'text-font': fontRegular,
          'text-size': 11,
        },
        'paint': {
          'text-color': text,
          'text-halo-color': halo,
          'text-halo-width': 1.2,
        },
      },
      {
        'id': 'place-label',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'place',
        'layout': {
          'text-field': [
            'coalesce',
            ['get', 'name:latin'],
            ['get', 'name'],
          ],
          'text-font': fontBold,
          'text-size': [
            'match',
            ['get', 'class'],
            ['city', 'country'],
            15,
            ['town'],
            13,
            11,
          ],
        },
        'paint': {
          'text-color': textStrong,
          'text-halo-color': halo,
          'text-halo-width': 1.5,
        },
      },
      // Zones de livraison des boutiques.
      {
        'id': DymMapLayers.areaFill,
        'type': 'fill',
        'source': DymMapLayers.areasSource,
        'paint': {'fill-color': brand, 'fill-opacity': 0.08},
      },
      {
        'id': DymMapLayers.areaLine,
        'type': 'line',
        'source': DymMapLayers.areasSource,
        'paint': {
          'line-color': brand,
          'line-width': 2,
          'line-dasharray': [3, 2],
        },
      },
      // Itinéraire (spec 109) : trait vert bordé de blanc, sous les épingles ;
      // tronçon déjà fait ou prévisionnel en pointillés.
      {
        'id': DymMapLayers.routeCase,
        'type': 'line',
        'source': DymMapLayers.routesSource,
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {'line-color': '#ffffff', 'line-width': 8},
      },
      {
        'id': DymMapLayers.routeLine,
        'type': 'line',
        'source': DymMapLayers.routesSource,
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': brand,
          'line-width': 5,
          'line-opacity': [
            'case',
            [
              '==',
              ['get', 'dashed'],
              true,
            ],
            0.55,
            1,
          ],
        },
      },
      // Regroupements : carré vert, nombre en blanc.
      {
        'id': DymMapLayers.clusters,
        'type': 'circle',
        'source': DymMapLayers.pinsSource,
        'filter': ['has', 'point_count'],
        'paint': {
          'circle-color': brand,
          'circle-radius': [
            'step',
            ['get', 'point_count'],
            16,
            10,
            20,
            50,
            26,
          ],
          'circle-stroke-color': halo,
          'circle-stroke-width': 3,
        },
      },
      {
        'id': DymMapLayers.clusterCount,
        'type': 'symbol',
        'source': DymMapLayers.pinsSource,
        'filter': ['has', 'point_count'],
        'layout': {
          'text-field': ['get', 'point_count_abbreviated'],
          'text-font': fontBold,
          'text-size': 13,
          'text-allow-overlap': true,
        },
        'paint': {'text-color': '#ffffff'},
      },
      // Icônes et noms en calques séparés : une icône s'affiche même si
      // les polices ne sont pas encore chargées.
      {
        'id': DymMapLayers.pins,
        'type': 'symbol',
        'source': DymMapLayers.pinsSource,
        'filter': [
          '!',
          ['has', 'point_count'],
        ],
        'layout': {
          'icon-image': ['get', 'icon'],
          'icon-anchor': 'bottom',
          'icon-allow-overlap': true,
        },
        'paint': {
          'icon-opacity': [
            'case',
            ['get', 'dimmed'],
            0.55,
            1,
          ],
        },
      },
      {
        'id': DymMapLayers.pinLabels,
        'type': 'symbol',
        'source': DymMapLayers.pinsSource,
        'minzoom': 14,
        'filter': [
          '!',
          ['has', 'point_count'],
        ],
        'layout': {
          'text-field': ['get', 'label'],
          'text-font': fontBold,
          'text-size': 12,
          'text-anchor': 'top',
          'text-offset': [0, 0.3],
          'text-optional': true,
        },
        'paint': {
          'text-color': brandDeep,
          'text-halo-color': halo,
          'text-halo-width': 1.5,
        },
      },
    ],
  };
  return jsonEncode(style);
}
