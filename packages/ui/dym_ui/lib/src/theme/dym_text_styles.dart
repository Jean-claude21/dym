import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Styles de texte DYM (tokens `typography.*`), déjà colorés en encre.
@immutable
class DymTextStyles extends ThemeExtension<DymTextStyles> {
  /// Styles complets.
  const new({
    required this.display,
    required this.title,
    required this.price,
    required this.body,
    required this.label,
  });

  /// Styles validés, couleur de texte principale.
  static final light = DymTextStyles(
    display: DymTokenTypography.display.copyWith(
      color: DymTokenColors.textPrimary,
    ),
    title: DymTokenTypography.title.copyWith(color: DymTokenColors.textPrimary),
    price: DymTokenTypography.price.copyWith(color: DymTokenColors.textPrimary),
    body: DymTokenTypography.body.copyWith(color: DymTokenColors.textPrimary),
    label: DymTokenTypography.label.copyWith(color: DymTokenColors.textPrimary),
  );

  /// Titre d'écran.
  final TextStyle display;

  /// Titre de section.
  final TextStyle title;

  /// Prix (chiffres tabulaires).
  final TextStyle price;

  /// Texte courant.
  final TextStyle body;

  /// Badges, unités, boutique d'origine.
  final TextStyle label;

  @override
  DymTextStyles copyWith({TextStyle? display, TextStyle? body}) =>
      DymTextStyles(
        display: display ?? this.display,
        title: title,
        price: price,
        body: body ?? this.body,
        label: label,
      );

  @override
  DymTextStyles lerp(DymTextStyles? other, double t) =>
      t < 0.5 ? this : other ?? this;
}
