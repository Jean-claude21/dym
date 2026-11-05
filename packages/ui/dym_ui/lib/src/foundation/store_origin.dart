import 'package:dym_ui/src/theme/dym_colors.dart';
import 'package:flutter/material.dart';

/// Origine d'une boutique (décision 0010). Les libellés sont fournis par
/// l'appelant ; seuls l'icône et les couleurs sont portés ici.
enum StoreOrigin {
  /// Étal au marché.
  marche(Icons.beach_access_rounded),

  /// Vend depuis chez elle (fait maison).
  maison(Icons.home_rounded),

  /// Boutique ou épicerie de quartier.
  magasin(Icons.storefront_rounded);

  new(this.icon);

  /// Icône du badge.
  final IconData icon;

  /// Couleur de fond du badge.
  Color background(DymColors c) => switch (this) {
    StoreOrigin.marche => c.originMarcheBg,
    StoreOrigin.maison => c.originMaisonBg,
    StoreOrigin.magasin => c.originBoutiqueBg,
  };

  /// Couleur du texte et de l'icône du badge (contraste AA mesuré).
  Color foreground(DymColors c) => switch (this) {
    StoreOrigin.marche => c.originMarcheFg,
    StoreOrigin.maison => c.originMaisonFg,
    StoreOrigin.magasin => c.originBoutiqueFg,
  };
}
