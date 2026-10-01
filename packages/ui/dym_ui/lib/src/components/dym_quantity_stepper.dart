import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Compteur de quantité « − n + ».
class DymQuantityStepper extends StatelessWidget {
  /// Crée un compteur ; libellés d'accessibilité fournis par l'appelant.
  const new({
    required this.quantity,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 99,
    this.decreaseLabel = '−',
    this.increaseLabel = '+',
    this.dense = false,
  });

  /// Quantité affichée.
  final int quantity;

  /// Nouvelle quantité demandée.
  final ValueChanged<int> onChanged;

  /// Quantité minimale.
  final int min;

  /// Quantité maximale.
  final int max;

  /// Libellé d'accessibilité du bouton « − ».
  final String decreaseLabel;

  /// Libellé d'accessibilité du bouton « + ».
  final String increaseLabel;

  /// Version compacte (cartes, lignes de panier) : pastille visible de 40,
  /// zones tactiles de 44 × 48 conservées.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final buttonWidth = dense ? 44.0 : DymTokenSize.touchMin;
    Widget button(IconData icon, String label, int? next) => SizedBox(
      width: buttonWidth,
      height: DymTokenSize.touchMin,
      child: IconButton(
        tooltip: label,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tight(
          Size(buttonWidth, DymTokenSize.touchMin),
        ),
        onPressed: next == null ? null : () => onChanged(next),
        icon: Icon(icon, size: dense ? 20 : 22),
        color: c.brandDeep,
        disabledColor: c.brandDeep.withValues(alpha: 0.3),
      ),
    );
    // Zone tactile de 48 de haut ; pastille visible de 40 en version dense.
    final inset = dense ? 4.0 : 0.0;
    return SizedBox(
      height: DymTokenSize.touchMin,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            top: inset,
            bottom: inset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.tintVertTendre,
                borderRadius: BorderRadius.circular(DymTokenRadius.chip),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              button(
                Icons.remove_rounded,
                decreaseLabel,
                quantity > min ? quantity - 1 : null,
              ),
              Container(
                constraints: BoxConstraints(minWidth: dense ? 28 : 34),
                height: dense ? 28 : 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(DymTokenSpace.s2),
                ),
                child: AnimatedSwitcher(
                  duration: DymMotion.of(context, DymMotion.fast),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Text(
                    '$quantity',
                    key: ValueKey(quantity),
                    style: context.dym.text.price.copyWith(
                      fontSize: dense ? 15 : 16,
                    ),
                  ),
                ),
              ),
              button(
                Icons.add_rounded,
                increaseLabel,
                quantity < max ? quantity + 1 : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
