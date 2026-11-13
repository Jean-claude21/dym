import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Budgets d'images (PARCOURS §8, spec 062) : WebP seulement, vignettes
/// ≤ 30 Ko, photos plein écran ≤ 120 Ko. Les données coûtent cher.
void main() {
  const thumb = 30 * 1024;
  const full = 120 * 1024;

  List<File> images(String dir) =>
      Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => !f.path.endsWith('.md') && !f.path.endsWith('.txt'))
          .toList();

  test('images de dym_ui en WebP et dans leur budget', () {
    for (final f in images('assets').where((f) => !f.path.endsWith('.json'))) {
      expect(f.path, endsWith('.webp'), reason: f.path);
      final budget = f.path.contains('aisles') ? thumb : full;
      expect(f.lengthSync(), lessThanOrEqualTo(budget), reason: f.path);
    }
  });

  test(
    'animations de la marque (Lottie) légères, images intégrées en WebP',
    () {
      for (final f in images('assets').where((f) => f.path.endsWith('.json'))) {
        final splash = f.path.endsWith('splash.json');
        expect(f.lengthSync(), lessThanOrEqualTo((splash ? 160 : 40) * 1024));
        expect(f.readAsStringSync(), isNot(contains('data:image/png')));
      }
    },
  );

  test('photos des pages d’entrée dans le budget plein écran', () {
    for (final f in images('../../features/dym_auth/assets')) {
      expect(f.path, endsWith('.webp'), reason: f.path);
      expect(f.lengthSync(), lessThanOrEqualTo(full), reason: f.path);
    }
  });
}
