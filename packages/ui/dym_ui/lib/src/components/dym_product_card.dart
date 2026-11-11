import 'package:dym_core/dym_core.dart';
import 'package:dym_ui/src/components/dym_quantity_stepper.dart';
import 'package:dym_ui/src/foundation/dym_sized_image.dart';
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

  /// Ignorée depuis le design « Épuré » : les photos produits reposent
  /// toujours sur la menthe. Gardée pour la compatibilité des appels.
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
                dimension: compact ? 32 : DymTokenSize.addButton,
                child: Icon(Icons.add_rounded, color: c.onBrand, size: 22),
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
        color: c.tintVertTendre,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      padding: const EdgeInsets.all(DymTokenSpace.s2 + 2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DymSizedImage(
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
    final meta = [unit, ?store?.name].join(' · ');
    // Pas de cadre : la photo sur menthe porte la carte (design « Épuré »).
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: LayoutBuilder(
          builder: (context, box) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (box.hasBoundedHeight)
                Expanded(child: _image(context, null))
              else
                AspectRatio(aspectRatio: 1.1, child: _image(context, null)),
              const SizedBox(height: DymTokenSpace.s2),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.body.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.label.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: MoneyText(price, color: c.textPrimary, size: 16),
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
                        padding: const EdgeInsets.only(bottom: 4),
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
    );
  }

  Widget _buildCompact(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    // Le « + » se pose sur le coin de la photo : nom et prix gardent toute
    // la largeur de la carte.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _image(context, 84),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: onQuantityChanged == null
                      ? const SizedBox.shrink()
                      : quantity == 0
                      ? _CompactAdd(
                          label: '$addLabel $name',
                          onTap: () => onQuantityChanged!(1),
                        )
                      : SizedBox.square(
                          dimension: 44,
                          child: Center(
                            child: _QuantityDot(quantity: quantity),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: DymTokenSpace.s2),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.label.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MoneyText(price, size: 14, color: c.textPrimary),
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
