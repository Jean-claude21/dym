import 'package:dym_map/src/geo.dart';
import 'package:dym_map/src/map_models.dart';
import 'package:dym_map/src/maplibre_engine.dart';
import 'package:flutter/widgets.dart';

/// Ce que la carte doit montrer ; le moteur le traduit pour son fournisseur.
@immutable
class DymMapSpec {
  const new({
    required this.initialCenter,
    required this.initialZoom,
    this.pins = const [],
    this.pinStyles = const {},
    this.areas = const [],
    this.onPinTap,
    this.onMapTap,
    this.onCameraIdle,
    this.onReady,
    this.interactive = true,
    this.semanticLabel,
  });

  final DymLatLng initialCenter;
  final double initialZoom;
  final List<DymMapPin> pins;
  final Map<String, DymPinStyle> pinStyles;
  final List<DymMapArea> areas;
  final ValueChanged<String>? onPinTap;
  final ValueChanged<DymLatLng>? onMapTap;
  final ValueChanged<DymMapView>? onCameraIdle;
  final ValueChanged<DymMapControls>? onReady;
  final bool interactive;
  final String? semanticLabel;
}

/// Fournisseur de carte (MapLibre par défaut). En changer ne modifie
/// aucun écran : seules les apps choisissent le moteur, au démarrage.
abstract interface class DymMapEngine {
  Widget build(BuildContext context, DymMapSpec spec);
}

/// Carte DYM : fond aux couleurs de la marque, épingles par type,
/// regroupement, zones de livraison. Sans logique métier.
class DymMap extends StatelessWidget {
  const new({
    required this.initialCenter,
    super.key,
    this.initialZoom = 13,
    this.pins = const [],
    this.pinStyles = const {},
    this.areas = const [],
    this.onPinTap,
    this.onMapTap,
    this.onCameraIdle,
    this.onReady,
    this.interactive = true,
    this.semanticLabel,
  });

  /// Moteur utilisé par toutes les cartes ; les tests le remplacent pour
  /// ne pas créer de vue native.
  static DymMapEngine engine = const MapLibreEngine();

  final DymLatLng initialCenter;
  final double initialZoom;
  final List<DymMapPin> pins;
  final Map<String, DymPinStyle> pinStyles;
  final List<DymMapArea> areas;
  final ValueChanged<String>? onPinTap;
  final ValueChanged<DymLatLng>? onMapTap;
  final ValueChanged<DymMapView>? onCameraIdle;
  final ValueChanged<DymMapControls>? onReady;
  final bool interactive;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => engine.build(
    context,
    DymMapSpec(
      initialCenter: initialCenter,
      initialZoom: initialZoom,
      pins: pins,
      pinStyles: pinStyles,
      areas: areas,
      onPinTap: onPinTap,
      onMapTap: onMapTap,
      onCameraIdle: onCameraIdle,
      onReady: onReady,
      interactive: interactive,
      semanticLabel: semanticLabel,
    ),
  );
}

/// Moteur de test : aucune vue native, une épingle = un bouton nommé.
class FakeMapEngine implements DymMapEngine {
  new();

  /// Dernière carte construite.
  DymMapSpec? last;
  final moves = <DymLatLng>[];

  /// Commandes enregistrées dans [moves] (tests de viewmodel).
  DymMapControls get controls => _FakeControls(this);

  @override
  Widget build(BuildContext context, DymMapSpec spec) {
    last = spec;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      spec.onReady?.call(controls);
    });
    return Semantics(
      label: spec.semanticLabel,
      child: ColoredBox(
        color: const Color(0xFFE8F2EC),
        child: Center(
          child: Wrap(
            children: [
              for (final pin in spec.pins)
                GestureDetector(
                  key: ValueKey('pin-${pin.id}'),
                  onTap: () => spec.onPinTap?.call(pin.id),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Text(pin.label ?? pin.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FakeControls implements DymMapControls {
  new(this._engine);

  final FakeMapEngine _engine;

  @override
  Future<void> fit(DymBounds bounds) async => _engine.moves.add(bounds.center);

  @override
  Future<void> moveTo(DymLatLng point, {double? zoom}) async =>
      _engine.moves.add(point);
}
