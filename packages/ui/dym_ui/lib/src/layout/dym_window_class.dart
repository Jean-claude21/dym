import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/widgets.dart';

/// Classe de fenêtre selon la largeur (seuils `breakpoint.*`, Material 3).
///
/// Un seuil appartient à la classe supérieure : 600 est `medium`. Les classes
/// sont ordonnées, ce qui permet d'écrire `classe >= DymWindowClass.expanded`.
enum DymWindowClass implements Comparable<DymWindowClass> {
  /// Moins de 600 : téléphone portrait.
  compact,

  /// 600 à 839 : tablette portrait.
  medium,

  /// 840 à 1 199 : tablette ou téléphone en paysage.
  expanded,

  /// 1 200 et plus : bureau.
  large;

  /// Classe correspondant à une largeur en pixels logiques.
  static DymWindowClass fromWidth(double width) {
    if (width >= DymTokenBreakpoints.large) return large;
    if (width >= DymTokenBreakpoints.expanded) return expanded;
    if (width >= DymTokenBreakpoints.medium) return medium;
    return compact;
  }

  /// Classe de la fenêtre courante. Ne reconstruit qu'au changement de taille.
  static DymWindowClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  @override
  int compareTo(DymWindowClass other) => index - other.index;

  /// Vrai si cette classe est au moins [other].
  bool operator >=(DymWindowClass other) => index >= other.index;

  /// Vrai si cette classe est strictement plus petite que [other].
  bool operator <(DymWindowClass other) => index < other.index;
}
