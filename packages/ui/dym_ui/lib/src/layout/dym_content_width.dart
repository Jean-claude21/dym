import 'package:dym_ui/src/layout/dym_layout.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/widgets.dart';

/// Centre [child] et borne sa largeur à [maxWidth] (`layout.content-max` par
/// défaut, `layout.form-max` pour un formulaire ou une lecture).
///
/// Avec [padded], applique la marge latérale de la classe de fenêtre. Sans
/// [padded], c'est une identité tant que la place est inférieure à [maxWidth]
/// (téléphone) : les écrans validés ne changent pas.
class DymContentWidth extends StatelessWidget {
  /// Crée le conteneur.
  const new({
    required this.child,
    super.key,
    this.maxWidth = DymTokenLayout.contentMax,
    this.padded = false,
  });

  /// Conteneur borné à la largeur d'un formulaire.
  const new form({required this.child, super.key, this.padded = false})
    : maxWidth = DymTokenLayout.formMax;

  /// Contenu.
  final Widget child;

  /// Largeur maximale du contenu (hors marges).
  final double maxWidth;

  /// Applique la marge latérale de la classe de fenêtre.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      // Prend toute la largeur permise, comme sans conteneur.
      child: SizedBox(width: double.infinity, child: child),
    );
    if (padded) {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: DymLayout.gutter(context)),
        child: content,
      );
    }
    return Align(alignment: Alignment.topCenter, child: content);
  }
}
