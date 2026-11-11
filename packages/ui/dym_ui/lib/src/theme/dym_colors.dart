import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Palette DYM exposée par le thème. Valeurs issues des tokens validés.
@immutable
class DymColors extends ThemeExtension<DymColors> {
  /// Palette complète.
  const new({
    required this.brand,
    required this.brandDeep,
    required this.plantain,
    required this.piment,
    required this.pimentStrong,
    required this.huile,
    required this.indigo,
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.onBrand,
    required this.tintPeche,
    required this.tintVertTendre,
    required this.tintPlantainClair,
    required this.tintPimentClair,
    required this.tintIndigoClair,
    required this.originMarcheBg,
    required this.originMarcheFg,
    required this.originMaisonBg,
    required this.originMaisonFg,
    required this.originBoutiqueBg,
    required this.originBoutiqueFg,
    required this.hairline,
    required this.lineStrong,
    required this.muted,
  });

  /// Thème clair « Épuré » (décision 0016).
  static const light = DymColors(
    brand: DymTokenColors.brandPrimary,
    brandDeep: DymTokenColors.brandPrimaryDeep,
    plantain: DymTokenColors.accentPlantain,
    piment: DymTokenColors.accentPiment,
    pimentStrong: DymTokenColors.accentPimentStrong,
    huile: DymTokenColors.accentHuile,
    indigo: DymTokenColors.accentIndigo,
    background: DymTokenColors.surfaceBackground,
    card: DymTokenColors.surfaceCard,
    textPrimary: DymTokenColors.textPrimary,
    textSecondary: DymTokenColors.textSecondary,
    onBrand: DymTokenColors.textOnBrand,
    tintPeche: DymTokenColors.tintPeche,
    tintVertTendre: DymTokenColors.tintVertTendre,
    tintPlantainClair: DymTokenColors.tintPlantainClair,
    tintPimentClair: DymTokenColors.tintPimentClair,
    tintIndigoClair: DymTokenColors.tintIndigoClair,
    originMarcheBg: DymTokenColors.originMarcheBg,
    originMarcheFg: DymTokenColors.originMarcheFg,
    originMaisonBg: DymTokenColors.originMaisonBg,
    originMaisonFg: DymTokenColors.originMaisonFg,
    originBoutiqueBg: DymTokenColors.originBoutiqueBg,
    originBoutiqueFg: DymTokenColors.originBoutiqueFg,
    hairline: DymTokenColors.lineHairline,
    lineStrong: DymTokenColors.lineStrong,
    muted: DymTokenColors.surfaceMuted,
  );

  /// Vert profond : action principale unique.
  final Color brand;

  /// Vert profond : fond de l'app vendeuse, texte vert sur fond clair.
  final Color brandDeep;

  /// Jaune plantain : mises en avant.
  final Color plantain;

  /// Rouge piment : aplats et grands textes.
  final Color piment;

  /// Rouge piment foncé : badges avec texte blanc.
  final Color pimentStrong;

  /// Orange huile de palme : touche décorative.
  final Color huile;

  /// Indigo : liens, badge « Boutique ».
  final Color indigo;

  /// Fond blanc cassé.
  final Color background;

  /// Fond des cartes.
  final Color card;

  /// Texte principal.
  final Color textPrimary;

  /// Texte secondaire.
  final Color textSecondary;

  /// Texte sur la couleur de marque.
  final Color onBrand;

  /// Teinte pêche.
  final Color tintPeche;

  /// Teinte vert tendre.
  final Color tintVertTendre;

  /// Teinte plantain clair.
  final Color tintPlantainClair;

  /// Teinte piment clair.
  final Color tintPimentClair;

  /// Teinte indigo clair.
  final Color tintIndigoClair;

  /// Fond du badge « Au marché ».
  final Color originMarcheBg;

  /// Texte du badge « Au marché ».
  final Color originMarcheFg;

  /// Fond du badge « Fait maison ».
  final Color originMaisonBg;

  /// Texte du badge « Fait maison ».
  final Color originMaisonFg;

  /// Fond du badge « Boutique ».
  final Color originBoutiqueBg;

  /// Texte du badge « Boutique ».
  final Color originBoutiqueFg;

  /// Filet de séparation et bordure de carte (1 px).
  final Color hairline;

  /// Bordure des contrôles (champs, boutons secondaires, puces).
  final Color lineStrong;

  /// Fond discret (squelettes, champs désactivés).
  final Color muted;

  @override
  DymColors copyWith({Color? brand, Color? background}) => DymColors(
    brand: brand ?? this.brand,
    brandDeep: brandDeep,
    plantain: plantain,
    piment: piment,
    pimentStrong: pimentStrong,
    huile: huile,
    indigo: indigo,
    background: background ?? this.background,
    card: card,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    onBrand: onBrand,
    tintPeche: tintPeche,
    tintVertTendre: tintVertTendre,
    tintPlantainClair: tintPlantainClair,
    tintPimentClair: tintPimentClair,
    tintIndigoClair: tintIndigoClair,
    originMarcheBg: originMarcheBg,
    originMarcheFg: originMarcheFg,
    originMaisonBg: originMaisonBg,
    originMaisonFg: originMaisonFg,
    originBoutiqueBg: originBoutiqueBg,
    originBoutiqueFg: originBoutiqueFg,
    hairline: hairline,
    lineStrong: lineStrong,
    muted: muted,
  );

  @override
  DymColors lerp(DymColors? other, double t) => t < 0.5 ? this : other ?? this;
}
