import 'package:dym_core/dym_core.dart';
import 'package:dym_ui/src/components/dym_badges.dart';
import 'package:dym_ui/src/components/dym_quantity_stepper.dart';
import 'package:dym_ui/src/foundation/money_text.dart';
import 'package:dym_ui/src/foundation/store_origin.dart';
import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Boutique d'origine affichée sur une carte produit.
@immutable
class DymProductStore {
  /// Décrit la boutique.
  const new({
    required this.name,
    required this.origin,
    required this.originLabel,
    this.avatar,
  });

  /// Nom de la boutique.
  final String name;

  /// Origine.
  final StoreOrigin origin;

  /// Libellé de l'origine.
  final String originLabel;

  /// Avatar de la boutique.
  final ImageProvider? avatar;
}

/// Disposition d'une [DymProductCard].
enum DymProductCardLayout {
  /// Grille de rayon (grande image, boutique, prix).
  grid,

  /// Rangée « Racheter » (compacte).
  compact,
}

/// Carte produit : image dans son contenant, nom, unité, boutique, prix,
/// et ajout au panier. Le bouton « + » se transforme en compteur animé.
class DymProductCard extends StatelessWidget {
  /// Crée une carte produit.
  const new({
    required this.image,
    required this.name,
    required this.unit,
    required this.price,
    super.key,
    this.onQuantityChanged,
    this.tint,
    this.store,
    this.badge,
    this.quantity = 0,
    this.layout = DymProductCardLayout.grid,
    this.addLabel = 'Ajouter',
    this.onTap,
  });

  /// Photo du produit dans son contenant (fond transparent).
  final ImageProvider image;

  /// Nom du produit.
  final String name;

  /// Unité du marché (« le tas », « la botte »).
  final String unit;

  /// Prix unitaire.
  final Money price;

  /// Quantité dans le panier (0 : bouton « + »).
  final int quantity;

  /// Nouvelle quantité demandée (0 retire le produit). Nul : pas d'ajout
  /// au panier sur la carte (consultation seule).
  final ValueChanged<int>? onQuantityChanged;

  /// Teinte de la tuile image (par défaut : pêche).
  final Color? tint;

  /// Boutique d'origine.
  final DymProductStore? store;

  /// Badge (promo, arrivage) superposé à l'image.
  final Widget? badge;

  /// Disposition.
  final DymProductCardLayout layout;

  /// Libellé d'accessibilité du bouton d'ajout.
  final String addLabel;

  /// Ouvre la fiche produit.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => switch (layout) {
    DymProductCardLayout.grid => _buildGrid(context),
    DymProductCardLayout.compact => _buildCompact(context),
  };

  Widget _addOrStepper(BuildContext context, {required bool compact}) {
    final c = context.dym.colors;
    final change = onQuantityChanged;
    if (change == null) return const SizedBox(height: DymTokenSize.touchMin);
    final add = Semantics(
      onTap: () => change(1),
      key: const ValueKey('add'),
      container: true,
      button: true,
      label: '$addLabel $name',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: DymTokenSize.touchMin,
        child: Center(
          child: Material(
            color: c.brand,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => change(1),
              child: SizedBox.square(
                dimension: compact ? 34 : DymTokenSize.addButton,
                child: Icon(Icons.add_rounded, color: c.onBrand, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
    return AnimatedSwitcher(
      duration: DymMotion.of(context, DymMotion.medium),
      switchInCurve: DymMotion.emphasized,
      switchOutCurve: DymMotion.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
          alignment: Alignment.centerRight,
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerRight,
        children: [...previous, ?current],
      ),
      child: quantity == 0
          ? add
          : const SizedBox(key: ValueKey('none'), height: 48),
    );
  }

  Widget _image(BuildContext context, double? height) {
    final c = context.dym.colors;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: tint ?? c.tintPeche,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile - 4),
      ),
      padding: const EdgeInsets.all(DymTokenSpace.s2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: image,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                Icon(Icons.shopping_basket_rounded, color: c.textSecondary),
          ),
          if (badge != null) Positioned(left: 0, top: 0, child: badge!),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      shadowColor: DymTokenShadows.card.color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s2),
          child: LayoutBuilder(
            builder: (context, box) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (box.hasBoundedHeight)
                  Expanded(child: _image(context, null))
                else
                  _image(context, 118),
                const SizedBox(height: DymTokenSpace.s2),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.title.copyWith(fontSize: 16),
                ),
                Text(
                  unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (store != null) ...[
                  const SizedBox(height: DymTokenSpace.s1),
                  _StoreLine(store: store!),
                ],
                const SizedBox(height: DymTokenSpace.s1),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: MoneyText(price, color: c.brandDeep, size: 18),
                      ),
                    ),
                    _addOrStepper(context, compact: false),
                  ],
                ),
                AnimatedSize(
                  duration: DymMotion.of(context, DymMotion.medium),
                  curve: DymMotion.standard,
                  child: quantity == 0 || onQuantityChanged == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Center(
                            child: DymQuantityStepper(
                              quantity: quantity,
                              onChanged: onQuantityChanged!,
                              dense: true,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.tile - 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile - 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _image(context, 72),
                  const SizedBox(height: DymTokenSpace.s1),
                  Padding(
                    padding: const EdgeInsets.only(right: 28),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.label.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 28),
                    child: Text(
                      '$unit · ${price.format()}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.label.copyWith(
                        fontSize: 11,
                        height: 1.2,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -8,
              bottom: -8,
              child: onQuantityChanged == null
                  ? const SizedBox.shrink()
                  : quantity == 0
                  ? _CompactAdd(
                      label: '$addLabel $name',
                      onTap: () => onQuantityChanged!(1),
                    )
                  : SizedBox.square(
                      dimension: 44,
                      child: Center(child: _QuantityDot(quantity: quantity)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactAdd extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      container: true,
      onTap: onTap,
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: Material(
            color: c.brand,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 28,
                child: Icon(Icons.add_rounded, color: c.onBrand, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreLine extends StatelessWidget {
  const new({required this.store});

  final DymProductStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Row(
      children: [
        if (store.avatar != null) ...[
          CircleAvatar(radius: 13, backgroundImage: store.avatar),
          const SizedBox(width: DymTokenSpace.s2),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.dym.text.label.copyWith(
                  fontSize: 12,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              DymOriginBadge(
                origin: store.origin,
                label: store.originLabel,
                dense: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuantityDot extends StatelessWidget {
  const new({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
      child: Text(
        '$quantity',
        style: context.dym.text.price.copyWith(fontSize: 14, color: c.onBrand),
      ),
    );
  }
}
