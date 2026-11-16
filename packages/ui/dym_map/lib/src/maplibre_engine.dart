import 'dart:async';
import 'dart:convert';
import 'dart:math' show Point;

import 'package:dym_map/src/dym_map.dart';
import 'package:dym_map/src/dym_map_style.dart';
import 'package:dym_map/src/geo.dart';
import 'package:dym_map/src/map_models.dart';
import 'package:dym_map/src/pin_painter.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Moteur MapLibre : rendu vectoriel GPU, fond OpenFreeMap (décision 0022).
class MapLibreEngine implements DymMapEngine {
  const new({this.tiles = const DymMapTiles()});

  final DymMapTiles tiles;

  @override
  Widget build(BuildContext context, DymMapSpec spec) =>
      _MapLibreView(spec: spec, tiles: tiles);
}

class _MapLibreView extends StatefulWidget {
  const new({required this.spec, required this.tiles});

  final DymMapSpec spec;
  final DymMapTiles tiles;

  @override
  State<_MapLibreView> createState() => _MapLibreViewState();
}

class _MapLibreViewState extends State<_MapLibreView>
    implements DymMapControls {
  MapLibreMapController? _controller;
  bool _styleReady = false;
  final _images = <String>{};
  Symbol? _selectedSymbol;
  String? _style;

  DymMapSpec get spec => widget.spec;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _style ??= dymMapStyle(context.dym.colors, tiles: widget.tiles);
  }

  @override
  void didUpdateWidget(covariant _MapLibreView old) {
    super.didUpdateWidget(old);
    if (!_styleReady) return;
    if (!listEquals(old.spec.pins, spec.pins) ||
        !mapEquals(old.spec.pinStyles, spec.pinStyles) ||
        old.spec.selectedPinId != spec.selectedPinId) {
      unawaited(_pushPins());
    }
    if (!listEquals(old.spec.areas, spec.areas)) unawaited(_pushAreas());
  }

  Future<void> _onStyleLoaded() async {
    _styleReady = true;
    _images.clear();
    await _pushPins();
    await _pushAreas();
    spec.onReady?.call(this);
  }

  static String _imageName(String style) => 'dym-pin-$style';

  Future<void> _pushPins() async {
    final controller = _controller;
    if (controller == null) return;
    for (final MapEntry(:key, :value) in spec.pinStyles.entries) {
      if (_images.add(key)) {
        final bytes = await paintPin(value);
        await controller.addImage(_imageName(key), bytes, false, 3);
      }
    }
    Map<String, Object?> feature(DymMapPin pin) => {
      'type': 'Feature',
      'id': pin.id,
      'properties': {
        'pin': pin.id,
        'icon': _imageName(pin.style),
        'label': pin.label ?? '',
        'dimmed': pin.dimmed,
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [pin.point.longitude, pin.point.latitude],
      },
    };
    final selected = spec.selectedPinId;
    // Épingle choisie : annotation au-dessus des calques, jamais regroupée.
    final previous = _selectedSymbol;
    _selectedSymbol = null;
    if (previous != null) await controller.removeSymbol(previous);
    final chosen = spec.pins.where((p) => p.id == selected).firstOrNull;
    if (chosen != null) {
      _selectedSymbol = await controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(chosen.point.latitude, chosen.point.longitude),
          iconImage: _imageName(chosen.style),
          iconSize: 1.3,
          iconAnchor: 'bottom',
          zIndex: 10,
        ),
      );
    }
    await controller.setGeoJsonSource(DymMapLayers.pinsSource, {
      'type': 'FeatureCollection',
      'features': [
        for (final pin in spec.pins)
          if (pin.id != selected) feature(pin),
      ],
    });
  }

  Future<void> _pushAreas() async {
    await _controller?.setGeoJsonSource(DymMapLayers.areasSource, {
      'type': 'FeatureCollection',
      'features': [
        for (final area in spec.areas)
          {
            'type': 'Feature',
            'id': area.id,
            'properties': {'area': area.id},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [circleRing(area.center, area.radiusM)],
            },
          },
      ],
    });
  }

  Future<void> _onClick(Point<double> point, LatLng at) async {
    final controller = _controller;
    if (controller == null) return;
    final features = await controller.queryRenderedFeatures(
      point,
      DymMapLayers.tappable,
      null,
    );
    for (final raw in features) {
      final feature = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : Map<String, dynamic>.from(raw as Map);
      final props = Map<String, dynamic>.from(
        (feature['properties'] as Map?) ?? const {},
      );
      if (props['cluster_id'] case final num cluster) {
        final zoom = await controller.getClusterExpansionZoom(
          DymMapLayers.pinsSource,
          cluster.toInt(),
        );
        final coords = (feature['geometry'] as Map)['coordinates'] as List;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              (coords[1] as num).toDouble(),
              (coords[0] as num).toDouble(),
            ),
            zoom + 0.5,
          ),
        );
        return;
      }
      if (props['pin'] case final String id) {
        spec.onPinTap?.call(id);
        return;
      }
    }
    spec.onMapTap?.call(DymLatLng(at.latitude, at.longitude));
  }

  Future<void> _onIdle() async {
    final controller = _controller;
    final camera = controller?.cameraPosition;
    if (controller == null || camera == null) return;
    DymBounds? bounds;
    try {
      final region = await controller.getVisibleRegion();
      bounds = DymBounds(
        southWest: DymLatLng(
          region.southwest.latitude,
          region.southwest.longitude,
        ),
        northEast: DymLatLng(
          region.northeast.latitude,
          region.northeast.longitude,
        ),
      );
    } on Object {
      bounds = null;
    }
    spec.onCameraIdle?.call(
      DymMapView(
        center: DymLatLng(camera.target.latitude, camera.target.longitude),
        zoom: camera.zoom,
        bounds: bounds,
      ),
    );
  }

  @override
  Future<void> moveTo(DymLatLng point, {double? zoom}) async {
    await _controller?.animateCamera(
      zoom == null
          ? CameraUpdate.newLatLng(LatLng(point.latitude, point.longitude))
          : CameraUpdate.newLatLngZoom(
              LatLng(point.latitude, point.longitude),
              zoom,
            ),
    );
  }

  @override
  Future<void> fit(
    DymBounds bounds, {
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    final sw = bounds.southWest;
    final ne = bounds.northEast;
    if (sw == ne) {
      await moveTo(sw, zoom: 15);
      return;
    }
    await _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(sw.latitude, sw.longitude),
          northeast: LatLng(ne.latitude, ne.longitude),
        ),
        left: 24 + padding.left,
        top: 24 + padding.top,
        right: 24 + padding.right,
        bottom: 24 + padding.bottom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final interactive = spec.interactive;
    return Semantics(
      label: spec.semanticLabel,
      container: true,
      child: MapLibreMap(
        styleString: _style!,
        initialCameraPosition: CameraPosition(
          target: LatLng(
            spec.initialCenter.latitude,
            spec.initialCenter.longitude,
          ),
          zoom: spec.initialZoom,
        ),
        onMapCreated: (c) => _controller = c,
        onStyleLoadedCallback: () => unawaited(_onStyleLoaded()),
        onMapClick: (point, at) => unawaited(_onClick(point, at)),
        onCameraIdle: () => unawaited(_onIdle()),
        trackCameraPosition: true,
        compassEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        scrollGesturesEnabled: interactive,
        zoomGesturesEnabled: interactive,
        dragEnabled: interactive,
        doubleClickZoomEnabled: interactive,
        minMaxZoomPreference: const MinMaxZoomPreference(2, 19),
      ),
    );
  }
}
