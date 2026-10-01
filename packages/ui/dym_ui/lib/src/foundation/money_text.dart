import 'package:dym_core/dym_core.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:flutter/material.dart';

/// Affiche un [Money] avec le style de prix DYM (chiffres tabulaires).
class MoneyText extends StatelessWidget {
  /// Affiche [money]. [size] et [color] surchargent le style de prix.
  const new(this.money, {super.key, this.size, this.color, this.weight});

  /// Montant à afficher.
  final Money money;

  /// Taille de police (par défaut : token `typography.price`).
  final double? size;

  /// Couleur (par défaut : texte principal).
  final Color? color;

  /// Graisse (par défaut : token).
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) {
    final style = context.dym.text.price.copyWith(
      fontSize: size,
      color: color,
      fontWeight: weight,
    );
    return Text(
      money.format(),
      style: style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
    );
  }
}
