import 'package:flutter/widgets.dart';

/// Illustrations du design system : rayons (produits dans leurs contenants du
/// marché) et origines de boutique. Clés = `categories.icon` et
/// `store_origins.code` du référentiel ; clé inconnue → `null` (tuile de
/// repli).
abstract final class DymIllustrations {
  static const _aisles = {
    'legumes',
    'fruits',
    'fait-maison',
    'tubercules',
    'poissons',
    'epices',
    'boissons',
    'hygiene',
    'cereales',
    'huiles',
    'textile',
    'beaute',
  };

  static const _origins = {'marche', 'maison', 'magasin'};

  /// Illustration d'un rayon (`categories.icon`).
  static ImageProvider? aisle(String? key) => _aisles.contains(key)
      ? AssetImage('assets/aisles/$key.webp', package: 'dym_ui')
      : null;

  /// Étal en fête : boutique ouverte (app vendeuse, écran 22).
  static const ImageProvider storeOpened = AssetImage(
    'assets/scenes/store_opened.webp',
    package: 'dym_ui',
  );

  /// Zem (moto-taxi) de la pastille de livraison.
  static const ImageProvider zem = AssetImage(
    'assets/scenes/zem.webp',
    package: 'dym_ui',
  );

  /// Illustration d'une origine de boutique (`store_origins.code`).
  static ImageProvider? origin(String? code) => _origins.contains(code)
      ? AssetImage('assets/origins/$code.webp', package: 'dym_ui')
      : null;
}
