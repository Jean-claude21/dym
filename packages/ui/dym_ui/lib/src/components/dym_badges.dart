import 'package:dym_ui/src/foundation/store_origin.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Badge d'origine : « Au marché », « Fait maison », « Boutique ».
class DymOriginBadge extends StatelessWidget {
  /// Crée un badge. [label] est fourni par l'appelant (localisation).
  const new({
    required this.origin,
    required this.label,
    super.key,
    this.dense = false,
  });

  /// Origine de la boutique.
  final StoreOrigin origin;

  /// Libellé affiché.
  final String label;

  /// Version compacte (cartes produit).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final fg = origin.foreground(c);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? DymTokenSpace.s2 : 10,
          vertical: dense ? 2 : DymTokenSpace.s1,
        ),
        decoration: BoxDecoration(
          color: origin.background(c),
          borderRadius: BorderRadius.circular(DymTokenRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(origin.icon, size: dense ? 13 : 15, color: fg),
            SizedBox(width: dense ? 3 : DymTokenSpace.s1),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.dym.text.label.copyWith(
                  fontSize: dense ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ton d'un [DymPromoBadge].
enum DymPromoTone {
  /// Rouge piment foncé, texte blanc : promotion (« −20 % »).
  promo,

  /// Menthe, texte vert profond : mise en avant (« Arrivage du jour »,
  /// « Bientôt »). Le jaune reste réservé au cash et aux notes.
  highlight,

  /// Rouge piment foncé : nouveauté (« Nouveau »).
  fresh,
}

/// Petit badge de promotion ou de mise en avant.
class DymPromoBadge extends StatelessWidget {
  /// Crée un badge.
  const new({required this.label, super.key, this.tone = DymPromoTone.promo});

  /// Libellé.
  final String label;

  /// Ton.
  final DymPromoTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final (bg, fg) = switch (tone) {
      DymPromoTone.promo || DymPromoTone.fresh => (c.pimentStrong, c.onBrand),
      DymPromoTone.highlight => (c.tintVertTendre, c.brandDeep),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DymTokenSpace.s2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DymTokenSpace.s2),
      ),
      child: Text(
        label,
        style: context.dym.text.label.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
