import 'package:dym_map/dym_map.dart' show DymMap;
import 'package:dym_map/src/dym_map.dart' show DymMap;
import 'package:dym_map/src/geo.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/widgets.dart' show Color, IconData;

/// Apparence d'un type d'épingle : carré à pointe, icône et couleurs DYM.
@immutable
class DymPinStyle {
  const new({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  bool operator ==(Object other) =>
      other is DymPinStyle &&
      other.icon == icon &&
      other.background == background &&
      other.foreground == foreground;

  @override
  int get hashCode => Object.hash(icon, background, foreground);
}

/// Épingle posée sur la carte.
@immutable
class DymMapPin {
  const new({
    required this.id,
    required this.point,
    required this.style,
    this.label,
    this.dimmed = false,
  });

  final String id;
  final DymLatLng point;

  /// Clé de [DymMap.pinStyles].
  final String style;

  /// Nom affiché sous l'épingle aux zooms proches.
  final String? label;

  /// Grisée (boutique fermée, par exemple).
  final bool dimmed;

  @override
  bool operator ==(Object other) =>
      other is DymMapPin &&
      other.id == id &&
      other.point == point &&
      other.style == style &&
      other.label == label &&
      other.dimmed == dimmed;

  @override
  int get hashCode => Object.hash(id, point, style, label, dimmed);
}

/// Cercle tracé sur la carte (zone de livraison d'une boutique).
@immutable
class DymMapArea {
  const new({required this.id, required this.center, required this.radiusM});

  final String id;
  final DymLatLng center;
  final double radiusM;

  @override
  bool operator ==(Object other) =>
      other is DymMapArea &&
      other.id == id &&
      other.center == center &&
      other.radiusM == radiusM;

  @override
  int get hashCode => Object.hash(id, center, radiusM);
}

/// Position visible de la carte après un déplacement.
@immutable
class DymMapView {
  const new({required this.center, required this.zoom, this.bounds});

  final DymLatLng center;
  final double zoom;
  final DymBounds? bounds;
}

/// Commandes de la carte affichée (recentrer, cadrer).
abstract interface class DymMapControls {
  Future<void> moveTo(DymLatLng point, {double? zoom});

  Future<void> fit(DymBounds bounds);
}
