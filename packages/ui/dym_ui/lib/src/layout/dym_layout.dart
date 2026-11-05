import 'dart:math' as math;

import 'package:dym_ui/src/layout/dym_window_class.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/widgets.dart';

/// Règles de mise en page adaptative (tokens `layout.*`).
abstract final class DymLayout {
  /// Marge latérale d'une classe de fenêtre : 16 / 24 / 32 / 32.
  static double gutterFor(DymWindowClass windowClass) => switch (windowClass) {
    DymWindowClass.compact => DymTokenLayout.gutterCompact,
    DymWindowClass.medium => DymTokenLayout.gutterMedium,
    DymWindowClass.expanded => DymTokenLayout.gutterExpanded,
    DymWindowClass.large => DymTokenLayout.gutterLarge,
  };

  /// Marge latérale de la fenêtre courante.
  static double gutter(BuildContext context) =>
      gutterFor(DymWindowClass.of(context));

  /// Marge latérale qui borne un contenu défilant à [maxWidth] et le centre,
  /// sans jamais descendre sous [gutter].
  ///
  /// À utiliser comme `padding` horizontal d'une liste : la zone de défilement
  /// garde toute la largeur (molette et glissement partout), le contenu reste
  /// borné. Sur téléphone, renvoie [gutter].
  static double sideInset(
    double availableWidth, {
    required double gutter,
    double maxWidth = DymTokenLayout.contentMax,
  }) => math.max(gutter, (availableWidth - maxWidth) / 2);

  /// Nombre de colonnes d'une grille pour une largeur disponible [width] :
  /// autant de tuiles d'au moins [minTileWidth] que possible, séparées par
  /// [spacing], borné à [min] et [max].
  ///
  /// Avec [itemCount], les lignes sont équilibrées pour ne pas laisser une
  /// tuile seule sur la dernière ligne (8 tuiles sur 7 colonnes → 4 + 4).
  static int columns(
    double width, {
    required double minTileWidth,
    double spacing = 0,
    int min = 1,
    int max = 12,
    int? itemCount,
  }) {
    assert(minTileWidth > 0, 'minTileWidth doit être positif');
    assert(min >= 1 && min <= max, 'bornes invalides');
    final fit = ((width + spacing) / (minTileWidth + spacing)).floor();
    final columns = math.min(max, math.max(min, fit));
    if (itemCount == null || itemCount <= columns) return columns;
    final rows = (itemCount / columns).ceil();
    return math.max(min, (itemCount / rows).ceil());
  }
}
