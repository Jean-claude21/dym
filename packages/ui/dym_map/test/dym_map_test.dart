import 'dart:convert';

import 'package:dym_map/dym_map.dart';
import 'package:dym_map/src/pin_painter.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('distance : Rouen–Paris vers 112 km, nulle sur place', () {
    const rouen = DymLatLng(49.443, 1.099);
    const paris = DymLatLng(48.857, 2.352);
    expect(distanceMeters(rouen, rouen), 0);
    expect(distanceMeters(rouen, paris), inInclusiveRange(105000, 120000));
  });

  test('cercle fermé, chaque point au rayon demandé', () {
    const center = DymLatLng(6.152, 1.218);
    final ring = circleRing(center, 5000, steps: 32);
    expect(ring, hasLength(33));
    expect(ring.first, ring.last);
    for (final p in ring) {
      final d = distanceMeters(center, DymLatLng(p[1], p[0]));
      expect(d, closeTo(5000, 5));
    }
  });

  test('cadre autour de points', () {
    final b = DymBounds.around(const [
      DymLatLng(49.4, 1),
      DymLatLng(49.5, 1.2),
    ])!;
    expect(b.southWest, const DymLatLng(49.4, 1));
    expect(b.contains(const DymLatLng(49.45, 1.1)), isTrue);
    expect(DymBounds.around(const []), isNull);
  });

  test('style : JSON MapLibre valide, couleurs DYM, calques DYM', () {
    final style =
        jsonDecode(dymMapStyle(DymColors.light)) as Map<String, dynamic>;
    expect(style['version'], 8);
    final layers = (style['layers'] as List).cast<Map<String, dynamic>>();
    final ids = layers.map((l) => l['id']).toSet();
    expect(
      ids,
      containsAll(['dym-clusters', 'dym-pins-icons', 'dym-area-fill']),
    );
    final background = layers.first['paint'] as Map;
    expect(background['background-color'], '#fafaf7');
  });

  testWidgets('épingle dessinée en PNG', (tester) async {
    final bytes = await tester.runAsync(
      () => paintPin(
        const DymPinStyle(
          icon: Icons.storefront_rounded,
          background: Color(0xFFE3E6F4),
          foreground: Color(0xFF2E3A8C),
        ),
      ),
    );
    expect(bytes!.sublist(1, 4), utf8.encode('PNG'));
  });
}
