import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Origine du design system pour un code du référentiel.
StoreOrigin? originOf(String? code) =>
    StoreOrigin.values.where((o) => o.name == code).firstOrNull;

/// Libellé d'une origine (référentiel du pays).
String originLabel(CountryConfig? config, String? code, String locale) =>
    config?.storeOrigins
        .where((o) => o.code == code)
        .firstOrNull
        ?.label
        .resolve(locale) ??
    '';

/// Montant dans la devise d'un élément.
Money? moneyOf(CountryConfig? config, int? amountMinor) =>
    config == null || amountMinor == null ? null : config.money(amountMinor);

/// Illustration de repli d'une boutique sans photo.
ImageProvider storeFallback(String? origin) =>
    DymIllustrations.origin(origin) ?? DymIllustrations.storeOpened;

/// « Tokoin · Ouvert jusqu'à 19:00 » / « Tokoin · Fermé ».
String storeMeta(BuildContext context, PublicStore store) {
  final l10n = DymLocalizations.of(context);
  final status = !store.openNow
      ? l10n.storeClosedNow
      : store.closesAt == null
      ? l10n.storeOpenNow
      : l10n.storeOpenUntil(store.closesAt!);
  return l10n.placeAndMeta(store.zoneName, status);
}

/// Teintes des tuiles, en rotation (tokens `color.tint.*`).
List<Color> tileTints(DymColors c) => [
  c.tintVertTendre,
  c.tintPlantainClair,
  c.tintPeche,
  c.tintPimentClair,
  c.tintIndigoClair,
];

/// Carte d'une boutique (accueil, recherche).
class StoreTile extends StatelessWidget {
  const new({
    required this.store,
    required this.service,
    required this.config,
    required this.onTap,
    super.key,
    this.width = 200,
  });

  final PublicStore store;
  final DiscoveryService service;
  final CountryConfig? config;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final origin = originOf(store.origin) ?? StoreOrigin.marche;
    final fallback = storeFallback(store.origin);
    return DymStoreCard(
      cover: store.coverKey == null ? fallback : service.photo(store.coverKey!),
      avatar: fallback,
      name: store.name,
      origin: origin,
      originLabel: originLabel(config, store.origin, locale),
      meta: storeMeta(context, store),
      width: width,
      onTap: onTap,
    );
  }
}

/// Boutique en liste (design « Épuré ») : photo ronde, nom, origine,
/// quartier et horaires, chevron. Posée sur le fond, séparée par des filets.
class StoreRow extends StatelessWidget {
  const new({
    required this.store,
    required this.service,
    required this.config,
    required this.onTap,
    super.key,
  });

  final PublicStore store;
  final DiscoveryService service;
  final CountryConfig? config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final locale = Localizations.localeOf(context).languageCode;
    final origin = originOf(store.origin) ?? StoreOrigin.marche;
    final fallback = storeFallback(store.origin);
    final photo = store.coverKey == null
        ? fallback
        : service.photo(store.coverKey!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2 + 2),
          child: Row(
            children: [
              ClipOval(
                child: Image(
                  image: DymSizedImage.sized(context, photo, 52),
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 52,
                    height: 52,
                    color: c.tintVertTendre,
                    child: Icon(Icons.storefront_outlined, color: c.brandDeep),
                  ),
                ),
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: DymTokenSpace.s2,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DymOriginBadge(
                          origin: origin,
                          label: originLabel(config, store.origin, locale),
                          dense: true,
                        ),
                        Text(
                          storeMeta(context, store),
                          style: t.label.copyWith(
                            fontWeight: FontWeight.w400,
                            color: store.openNow
                                ? c.textSecondary
                                : c.pimentStrong,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte produit d'une grille (rayon, page boutique).
class ProductTile extends StatelessWidget {
  const new({
    required this.item,
    required this.service,
    required this.config,
    required this.onTap,
    super.key,
    this.tint,
    this.showStore = true,
  });

  final CatalogItem item;
  final DiscoveryService service;
  final CountryConfig? config;
  final VoidCallback onTap;
  final Color? tint;
  final bool showStore;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final price = moneyOf(config, item.displayPriceMinor);
    final unit = item.unitLabel?.resolve(locale) ?? '';
    final cart = CartScope.maybeOf(context);
    if (cart == null || !item.available) return _card(context, price, unit, 0);
    return ValueListenableBuilder(
      valueListenable: cart.service.cart,
      builder: (context, view, _) {
        // « + » ajoute toujours directement (première variante) ; toucher la
        // carte ouvre la fiche pour choisir une autre variante.
        final variant = item.defaultVariantId;
        return _card(
          context,
          price,
          unit,
          cartQuantityOf(view, variant),
          onQuantity: (q) {
            if (variant == null) {
              onTap(); // variante inconnue : choix sur la fiche
            } else if (cartQuantityOf(view, variant) == 0) {
              unawaited(addToCart(context, variant, quantity: q));
            } else {
              unawaited(cart.service.setQuantity(variant, q));
            }
          },
        );
      },
    );
  }

  Widget _card(
    BuildContext context,
    Money? price,
    String unit,
    int quantity, {
    ValueChanged<int>? onQuantity,
  }) {
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final origin = originOf(item.store.origin);
    return DymProductCard(
      quantity: quantity,
      onQuantityChanged: onQuantity,
      addLabel: l10n.cartAddShort,
      image: item.photoKey == null
          ? storeFallback(item.store.origin)
          : service.photo(item.photoKey!),
      name: item.name,
      unit: item.variantCount > 1 && price != null
          ? l10n.productFrom(price.format())
          : unit,
      price: price ?? Money.zero(config!.currency),
      tint: tint,
      onTap: onTap,
      badge: switch ((item.available, item.endOfMarketPercent)) {
        (false, _) => DymPromoBadge(label: l10n.productOutOfStock),
        (true, final int percent) => DymPromoBadge(
          label: l10n.endOfMarketBadge(percent),
        ),
        _ => null,
      },
      store: !showStore || origin == null
          ? null
          : DymProductStore(
              name: item.store.name,
              origin: origin,
              originLabel: originLabel(config, item.store.origin, locale),
              avatar: storeFallback(item.store.origin),
            ),
    );
  }
}

/// Produit en ligne (design « Épuré », planche 09) : photo carrée sur menthe,
/// nom, unité, prix à droite, « + » ou quantité au panier ; « Rupture » à la
/// place du « + ». Posé sur le fond, séparé par des filets.
class ProductRow extends StatelessWidget {
  const new({
    required this.item,
    required this.service,
    required this.config,
    required this.onTap,
    super.key,
    this.showStore = false,
  });

  final CatalogItem item;
  final DiscoveryService service;
  final CountryConfig? config;
  final VoidCallback onTap;
  final bool showStore;

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.maybeOf(context);
    if (cart == null || !item.available) return _row(context, null, 0);
    return ValueListenableBuilder(
      valueListenable: cart.service.cart,
      builder: (context, view, _) {
        final variant = item.defaultVariantId;
        return _row(context, (q) {
          if (variant == null) {
            onTap(); // variante inconnue : choix sur la fiche
          } else if (cartQuantityOf(view, variant) == 0) {
            unawaited(addToCart(context, variant, quantity: q));
          } else {
            unawaited(cart.service.setQuantity(variant, q));
          }
        }, cartQuantityOf(view, variant));
      },
    );
  }

  Widget _row(BuildContext context, ValueChanged<int>? onQuantity, int inCart) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final price = moneyOf(config, item.displayPriceMinor);
    final unit = item.unitLabel?.resolve(locale);
    final meta = [?unit, if (showStore) item.store.name].join(' · ');
    // Plusieurs formats : « dès 400 F CFA » à droite, une seule fois.
    final from = item.variantCount > 1 && price != null;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 80),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
          child: Row(
            children: [
              ProductThumb(
                image: item.photoKey == null
                    ? null
                    : service.photo(item.photoKey!),
                size: 64,
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.label.copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    if (item.endOfMarketPercent case final percent?)
                      Text(
                        l10n.endOfMarketBadge(percent),
                        style: t.label.copyWith(color: c.pimentStrong),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              if (price != null && inCart == 0)
                if (from)
                  Text(
                    l10n.productFrom(price.format()),
                    style: t.body.copyWith(fontWeight: FontWeight.w600),
                  )
                else
                  MoneyText(price, size: 15, color: c.textPrimary),
              const SizedBox(width: DymTokenSpace.s1),
              if (!item.available)
                DymPromoBadge(label: l10n.productOutOfStock)
              else if (inCart > 0 && onQuantity != null)
                DymQuantityStepper(
                  quantity: inCart,
                  dense: true,
                  decreaseLabel: l10n.productStockDecrease,
                  increaseLabel: l10n.productStockIncrease,
                  onChanged: onQuantity,
                )
              else if (onQuantity != null)
                RoundAddButton(
                  tooltip: l10n.cartAddShort,
                  onPressed: () => onQuantity(1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « + » vert de 32 px dans une zone tactile de 48 px.
class RoundAddButton extends StatelessWidget {
  const new({required this.tooltip, required this.onPressed, super.key});

  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: InkResponse(
          onTap: onPressed,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: onPressed == null ? c.muted : c.brand,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: onPressed == null ? c.textSecondary : c.onBrand,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Liste de produits à filets.
class ProductList extends StatelessWidget {
  const new({
    required this.items,
    required this.service,
    required this.config,
    required this.onOpen,
    super.key,
    this.showStore = false,
  });

  final List<CatalogItem> items;
  final DiscoveryService service;
  final CountryConfig? config;
  final ValueChanged<String> onOpen;
  final bool showStore;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Column(
      children: [
        for (final (i, item) in items.indexed) ...[
          if (i > 0) Divider(height: 1, color: c.hairline),
          ProductRow(
            item: item,
            service: service,
            config: config,
            showStore: showStore,
            onTap: () => onOpen(item.id),
          ),
        ],
      ],
    );
  }
}

/// Grille responsive de cartes produit.
class ProductGrid extends StatelessWidget {
  const new({
    required this.items,
    required this.service,
    required this.config,
    required this.onOpen,
    super.key,
    this.showStore = true,
  });

  final List<CatalogItem> items;
  final DiscoveryService service;
  final CountryConfig? config;
  final ValueChanged<String> onOpen;
  final bool showStore;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final tints = tileTints(c);
    return LayoutBuilder(
      builder: (context, box) {
        const spacing = DymTokenSpace.s3;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = DymLayout.columns(
          box.maxWidth,
          minTileWidth: 160 * scale,
          spacing: spacing,
          max: 5,
        );
        final width = (box.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final (i, item) in items.indexed)
              SizedBox(
                width: width,
                child: ProductTile(
                  item: item,
                  service: service,
                  config: config,
                  tint: tints[i % tints.length],
                  showStore: showStore,
                  onTap: () => onOpen(item.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Chargement, échec ou hors ligne d'un écran de découverte.
class DiscoveryState extends StatelessWidget {
  const new({
    required this.failure,
    required this.onRetry,
    super.key,
    this.goneMessage,
  });

  final Failure? failure;
  final VoidCallback onRetry;

  /// Message si la ressource n'existe plus (`NotFoundFailure`).
  final String? goneMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final current = failure;
    if (current == null) {
      return DymSkeleton(label: l10n.startupPreparing);
    }
    if (current is NotFoundFailure && goneMessage != null) {
      return DymStateView(
        kind: DymStateKind.empty,
        title: goneMessage!,
        message: '',
      );
    }
    final offline = current is NetworkFailure;
    return DymStateView(
      kind: offline ? DymStateKind.offline : DymStateKind.error,
      title: offline ? l10n.errorOffline : l10n.errorGeneric,
      message: l10n.storeSaveError,
      actionLabel: l10n.retry,
      onAction: onRetry,
    );
  }
}

/// Bouton rond blanc posé sur une photo (retour).
class PhotoButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Material(
      color: c.card,
      shape: const CircleBorder(),
      elevation: 1,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: c.textPrimary),
      ),
    );
  }
}
