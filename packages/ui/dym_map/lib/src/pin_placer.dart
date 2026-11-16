import 'package:dym_map/src/dym_map.dart';
import 'package:dym_map/src/geo.dart';
import 'package:dym_map/src/map_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Placer un point précis (« Placer ma porte ») : la carte glisse sous une
/// épingle fixe au centre ; [onChanged] reçoit le centre à chaque arrêt.
/// Les textes viennent de l'appelant (localisation).
class DymPinPlacer extends StatefulWidget {
  const new({
    required this.initial,
    required this.onChanged,
    required this.hint,
    super.key,
    this.initialZoom = 17,
    this.areas = const [],
    this.semanticLabel,
  });

  final DymLatLng initial;
  final double initialZoom;
  final ValueChanged<DymLatLng> onChanged;

  /// Consigne affichée en haut (« Faites glisser la carte… »).
  final String hint;
  final List<DymMapArea> areas;
  final String? semanticLabel;

  @override
  State<DymPinPlacer> createState() => _DymPinPlacerState();
}

class _DymPinPlacerState extends State<DymPinPlacer> {
  bool _moving = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          onPointerDown: (_) => setState(() => _moving = true),
          child: DymMap(
            initialCenter: widget.initial,
            initialZoom: widget.initialZoom,
            areas: widget.areas,
            semanticLabel: widget.semanticLabel,
            onCameraIdle: (view) {
              if (mounted) setState(() => _moving = false);
              widget.onChanged(view.center);
            },
          ),
        ),
        IgnorePointer(
          child: Center(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 150),
              offset: Offset(0, _moving ? -0.62 : -0.5),
              child: Icon(Icons.location_on_rounded, size: 52, color: c.brand),
            ),
          ),
        ),
        Positioned(
          left: DymTokenSpace.s4,
          right: DymTokenSpace.s4,
          top: DymTokenSpace.s4,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(DymTokenRadius.card),
                border: Border.all(color: c.hairline),
                boxShadow: const [DymTokenShadows.floating],
              ),
              child: Padding(
                padding: const EdgeInsets.all(DymTokenSpace.s3),
                child: Text(widget.hint, style: t.body),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
