import 'package:dym_ui/src/components/dym_button.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Nature de l'état affiché par [DymStateView].
enum DymStateKind {
  /// Rien à afficher (panier vide, aucun résultat).
  empty(Icons.shopping_basket_outlined),

  /// Erreur récupérable.
  error(Icons.error_outline_rounded),

  /// Pas de connexion.
  offline(Icons.wifi_off_rounded);

  new(this.icon);

  /// Icône associée.
  final IconData icon;
}

/// État vide, erreur ou hors ligne (constitution VIII). Textes fournis par
/// l'appelant.
class DymStateView extends StatelessWidget {
  /// Crée la vue d'état.
  const new({
    required this.kind,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  /// Nature de l'état.
  final DymStateKind kind;

  /// Titre.
  final String title;

  /// Explication et piste de résolution.
  final String message;

  /// Libellé de l'action (« Réessayer »).
  final String? actionLabel;

  /// Action.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    // Design « Épuré » : une icône au trait, sans pastille de couleur.
    final iconColor = kind == DymStateKind.error ? c.piment : c.textSecondary;
    return Padding(
      padding: const EdgeInsets.all(DymTokenSpace.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kind.icon, size: 52, color: iconColor),
          const SizedBox(height: DymTokenSpace.s4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.dym.text.title.copyWith(fontSize: 18),
          ),
          const SizedBox(height: DymTokenSpace.s2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.dym.text.body.copyWith(color: c.textSecondary),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: DymTokenSpace.s5),
            DymButton(
              label: actionLabel!,
              onPressed: onAction,
              expanded: false,
            ),
          ],
        ],
      ),
    );
  }
}
