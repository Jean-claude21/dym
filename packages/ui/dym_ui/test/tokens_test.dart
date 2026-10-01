import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _tokens() => jsonDecode(
  File('../../../docs/design/tokens/dym.tokens.json').readAsStringSync(),
) as Map<String, dynamic>;

Color _hex(String hex) =>
    Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

double _contrast(Color a, Color b) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) => 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  final la = lum(a);
  final lb = lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('tokens générés = tokens validés (FR-005)', () {
    final json = _tokens();
    final color = json['color'] as Map<String, dynamic>;
    String value(String group, String name) =>
        ((color[group] as Map<String, dynamic>)[name]
                as Map<String, dynamic>)[r'$value']
            as String;

    test('couleurs de marque, accents, surfaces, textes', () {
      expect(DymTokenColors.brandPrimary, _hex(value('brand', 'primary')));
      expect(
        DymTokenColors.brandPrimaryDeep,
        _hex(value('brand', 'primary-deep')),
      );
      expect(DymTokenColors.accentPlantain, _hex(value('accent', 'plantain')));
      expect(
        DymTokenColors.accentPimentStrong,
        _hex(value('accent', 'piment-strong')),
      );
      expect(
        DymTokenColors.surfaceBackground,
        _hex(value('surface', 'background')),
      );
      expect(DymTokenColors.textPrimary, _hex(value('text', 'primary')));
      expect(DymTokenColors.textSecondary, _hex(value('text', 'secondary')));
    });

    test('alias résolus pour les origines de boutique', () {
      expect(DymTokenColors.originMarcheBg, DymTokenColors.tintVertTendre);
      expect(DymTokenColors.originMarcheFg, DymTokenColors.brandPrimaryDeep);
      expect(DymTokenColors.originBoutiqueFg, DymTokenColors.accentIndigo);
    });

    test('typographie : familles embarquées et chiffres tabulaires', () {
      expect(DymTokenTypography.display.fontFamily, contains('Nunito'));
      expect(DymTokenTypography.body.fontFamily, contains('NunitoSans'));
      expect(
        DymTokenTypography.price.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('tailles : cible tactile minimale 48', () {
      expect(DymTokenSize.touchMin, 48);
    });
  });

  group('contrastes texte/fond ≥ 4,5:1 (FR-009, SC-003)', () {
    const c = DymColors.light;
    final pairs = <String, (Color, Color)>{
      'blanc / primary': (c.onBrand, c.brand),
      'blanc / primary-deep': (c.onBrand, c.brandDeep),
      'encre / plantain': (c.textPrimary, c.plantain),
      'blanc / piment foncé': (c.onBrand, c.pimentStrong),
      'encre / crème': (c.textPrimary, c.background),
      'secondaire / crème': (c.textSecondary, c.background),
      'secondaire / blanc': (c.textSecondary, c.card),
      'primary / crème': (c.brand, c.background),
      'badge marché': (c.originMarcheFg, c.originMarcheBg),
      'badge maison': (c.originMaisonFg, c.originMaisonBg),
      'badge boutique': (c.originBoutiqueFg, c.originBoutiqueBg),
      'primary-deep / vert tendre': (c.brandDeep, c.tintVertTendre),
    };
    for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
      test(name, () => expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5)));
    }
  });
}
